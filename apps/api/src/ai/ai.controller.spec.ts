import { INestApplication } from '@nestjs/common';
import { JwtModule, JwtService } from '@nestjs/jwt';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import type { App } from 'supertest/types';
import { AiController } from './ai.controller';
import { AiNutritionService } from './ai-nutrition.service';
import { SupabaseAuthGuard } from '../auth/supabase/supabase-auth.guard';
import { SupabaseTokenService } from '../auth/supabase/supabase-token.service';
import { API_CONFIG, resolveApiConfig } from '../config/api-config';

const SUPABASE_JWT_SECRET = 'test-supabase-jwt-signing-secret';
const ANTHROPIC_API_KEY = 'sk-ant-test-server-only-key';
const ENDPOINT = '/ai/nutrition/message';

const AI_REPLY = { text: 'Grilled salmon with quinoa — 520 kcal.' };

interface TokenClaims {
  sub?: string;
  role?: string;
  email?: string;
  [key: string]: unknown;
}

describe('AiController — authorization', () => {
  let app: INestApplication<App>;
  let jwt: JwtService;
  let reply: jest.Mock;

  const testConfig = resolveApiConfig({
    APP_ENV: 'qa',
    JWT_SECRET: 'api-jwt-secret',
    SUPABASE_URL: 'https://qa-ref.supabase.co',
    SUPABASE_JWT_SECRET,
    ANTHROPIC_API_KEY,
  });

  /** Mints a token the way Supabase Auth would for the given claims. */
  const sign = (claims: TokenClaims, expiresInSeconds = 3600) =>
    jwt.sign(
      { aud: 'authenticated', ...claims },
      { secret: SUPABASE_JWT_SECRET, expiresIn: expiresInSeconds },
    );

  const validToken = () =>
    sign({ sub: 'user-123', role: 'authenticated', email: 'a@example.com' });

  beforeEach(async () => {
    reply = jest.fn().mockResolvedValue(AI_REPLY);

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [JwtModule.register({})],
      controllers: [AiController],
      providers: [
        SupabaseTokenService,
        SupabaseAuthGuard,
        { provide: API_CONFIG, useValue: testConfig },
        { provide: AiNutritionService, useValue: { reply } },
      ],
    }).compile();

    app = moduleFixture.createNestApplication();
    jwt = moduleFixture.get(JwtService);
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  describe('rejects unauthenticated callers', () => {
    it('401s with no Authorization header', async () => {
      await request(app.getHttpServer())
        .post(ENDPOINT)
        .send({ message: 'hi' })
        .expect(401);

      expect(reply).not.toHaveBeenCalled();
    });

    it('401s on a non-bearer scheme', async () => {
      await request(app.getHttpServer())
        .post(ENDPOINT)
        .set('Authorization', 'Basic dXNlcjpwYXNz')
        .send({ message: 'hi' })
        .expect(401);

      expect(reply).not.toHaveBeenCalled();
    });

    it('401s on an empty bearer token', async () => {
      await request(app.getHttpServer())
        .post(ENDPOINT)
        .set('Authorization', 'Bearer   ')
        .send({ message: 'hi' })
        .expect(401);

      expect(reply).not.toHaveBeenCalled();
    });

    it('401s on a token that is not a JWT', async () => {
      await request(app.getHttpServer())
        .post(ENDPOINT)
        .set('Authorization', 'Bearer not-a-jwt')
        .send({ message: 'hi' })
        .expect(401);

      expect(reply).not.toHaveBeenCalled();
    });
  });

  describe('rejects forged and stale tokens', () => {
    it('401s on a token signed with the wrong secret', async () => {
      const forged = jwt.sign(
        { sub: 'user-123', role: 'authenticated' },
        { secret: 'attacker-secret', expiresIn: 3600 },
      );

      await request(app.getHttpServer())
        .post(ENDPOINT)
        .set('Authorization', `Bearer ${forged}`)
        .send({ message: 'hi' })
        .expect(401);

      expect(reply).not.toHaveBeenCalled();
    });

    it('401s on an expired token', async () => {
      const expired = sign({ sub: 'user-123', role: 'authenticated' }, -60);

      await request(app.getHttpServer())
        .post(ENDPOINT)
        .set('Authorization', `Bearer ${expired}`)
        .send({ message: 'hi' })
        .expect(401);

      expect(reply).not.toHaveBeenCalled();
    });

    it('401s on an unsigned ("alg: none") token', async () => {
      const b64 = (value: object) =>
        Buffer.from(JSON.stringify(value)).toString('base64url');
      const unsigned = `${b64({ alg: 'none', typ: 'JWT' })}.${b64({
        sub: 'user-123',
        role: 'authenticated',
      })}.`;

      await request(app.getHttpServer())
        .post(ENDPOINT)
        .set('Authorization', `Bearer ${unsigned}`)
        .send({ message: 'hi' })
        .expect(401);

      expect(reply).not.toHaveBeenCalled();
    });
  });

  describe('requires a signed-in user session, not just a valid signature', () => {
    it('401s on the Supabase anon/publishable key', async () => {
      // The anon key every client ships is a valid JWT signed with the same
      // project secret — it must not buy access to a paid AI endpoint.
      const anonKey = sign({ role: 'anon', iss: 'supabase' });

      await request(app.getHttpServer())
        .post(ENDPOINT)
        .set('Authorization', `Bearer ${anonKey}`)
        .send({ message: 'hi' })
        .expect(401);

      expect(reply).not.toHaveBeenCalled();
    });

    it('401s on a service_role key', async () => {
      const serviceKey = sign({ role: 'service_role', iss: 'supabase' });

      await request(app.getHttpServer())
        .post(ENDPOINT)
        .set('Authorization', `Bearer ${serviceKey}`)
        .send({ message: 'hi' })
        .expect(401);

      expect(reply).not.toHaveBeenCalled();
    });

    it('401s on a token with no subject', async () => {
      await request(app.getHttpServer())
        .post(ENDPOINT)
        .set('Authorization', `Bearer ${sign({ role: 'authenticated' })}`)
        .send({ message: 'hi' })
        .expect(401);

      expect(reply).not.toHaveBeenCalled();
    });
  });

  describe('accepts an authenticated user', () => {
    it('200s and returns the AI reply', async () => {
      const response = await request(app.getHttpServer())
        .post(ENDPOINT)
        .set('Authorization', `Bearer ${validToken()}`)
        .send({ message: 'What should I eat post-workout?', history: [] })
        .expect(201);

      expect(response.body).toEqual(AI_REPLY);
      expect(reply).toHaveBeenCalledTimes(1);
      expect(reply).toHaveBeenCalledWith(
        expect.objectContaining({ message: 'What should I eat post-workout?' }),
      );
    });

    it('accepts a lower-case bearer scheme', async () => {
      await request(app.getHttpServer())
        .post(ENDPOINT)
        .set('Authorization', `bearer ${validToken()}`)
        .send({ message: 'hi' })
        .expect(201);

      expect(reply).toHaveBeenCalledTimes(1);
    });

    it('forwards history and an image through to the AI service', async () => {
      const image = {
        mediaType: 'image/jpeg',
        data: Buffer.from('fake-jpeg').toString('base64'),
      };

      await request(app.getHttpServer())
        .post(ENDPOINT)
        .set('Authorization', `Bearer ${validToken()}`)
        .send({
          message: 'Analyze this meal photo.',
          history: [{ role: 'user', content: 'Hi' }],
          image,
        })
        .expect(201);

      expect(reply).toHaveBeenCalledWith({
        message: 'Analyze this meal photo.',
        history: [{ role: 'user', content: 'Hi' }],
        image,
      });
    });
  });

  describe('validates the request body — but only after authenticating', () => {
    it('400s on a missing message for an authenticated caller', async () => {
      await request(app.getHttpServer())
        .post(ENDPOINT)
        .set('Authorization', `Bearer ${validToken()}`)
        .send({})
        .expect(400);

      expect(reply).not.toHaveBeenCalled();
    });

    it('400s on an unsupported image media type', async () => {
      await request(app.getHttpServer())
        .post(ENDPOINT)
        .set('Authorization', `Bearer ${validToken()}`)
        .send({
          message: 'hi',
          image: { mediaType: 'application/pdf', data: 'AAAA' },
        })
        .expect(400);

      expect(reply).not.toHaveBeenCalled();
    });

    it('400s on an unknown history role', async () => {
      await request(app.getHttpServer())
        .post(ENDPOINT)
        .set('Authorization', `Bearer ${validToken()}`)
        .send({ message: 'hi', history: [{ role: 'system', content: 'x' }] })
        .expect(400);

      expect(reply).not.toHaveBeenCalled();
    });

    it('401 wins over 400 — an unauthenticated bad body is still 401', async () => {
      await request(app.getHttpServer()).post(ENDPOINT).send({}).expect(401);

      expect(reply).not.toHaveBeenCalled();
    });
  });

  describe('never leaks the server credential', () => {
    it('no response body or header contains the Anthropic key', async () => {
      const cases: Array<[string | null, object]> = [
        [null, { message: 'hi' }],
        ['Bearer not-a-jwt', { message: 'hi' }],
        [`Bearer ${validToken()}`, {}],
        [`Bearer ${validToken()}`, { message: 'hi' }],
      ];

      for (const [authorization, body] of cases) {
        const pending = request(app.getHttpServer()).post(ENDPOINT);
        if (authorization) pending.set('Authorization', authorization);
        const response = await pending.send(body);

        const serialized =
          JSON.stringify(response.body) + JSON.stringify(response.headers);
        expect(serialized).not.toContain(ANTHROPIC_API_KEY);
        expect(serialized).not.toContain('sk-ant-');
      }
    });
  });
});

describe('AiController — when Supabase auth is not configured', () => {
  let app: INestApplication<App>;
  let reply: jest.Mock;

  beforeEach(async () => {
    reply = jest.fn().mockResolvedValue(AI_REPLY);

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [JwtModule.register({})],
      controllers: [AiController],
      providers: [
        SupabaseTokenService,
        SupabaseAuthGuard,
        {
          provide: API_CONFIG,
          // No SUPABASE_JWT_SECRET.
          useValue: resolveApiConfig({ ANTHROPIC_API_KEY }),
        },
        { provide: AiNutritionService, useValue: { reply } },
      ],
    }).compile();

    app = moduleFixture.createNestApplication();
    await app.init();
  });

  afterEach(async () => {
    await app.close();
  });

  it('fails closed: no token is ever accepted', async () => {
    await request(app.getHttpServer())
      .post(ENDPOINT)
      .set('Authorization', 'Bearer anything')
      .send({ message: 'hi' })
      .expect(503);

    expect(reply).not.toHaveBeenCalled();
  });

  it('still rejects a missing header as unauthorized', async () => {
    await request(app.getHttpServer())
      .post(ENDPOINT)
      .send({ message: 'hi' })
      .expect(401);

    expect(reply).not.toHaveBeenCalled();
  });
});
