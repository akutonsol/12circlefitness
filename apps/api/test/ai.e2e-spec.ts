import { INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import type { App } from 'supertest/types';
import { AppModule } from './../src/app.module';
import { configureApp } from './../src/app.setup';
import { AiNutritionService } from './../src/ai/ai-nutrition.service';

const SUPABASE_JWT_SECRET = 'e2e-supabase-jwt-signing-secret';
const ANTHROPIC_API_KEY = 'sk-ant-e2e-server-only-key';
const ENDPOINT = '/ai/nutrition/message';

/**
 * End-to-end check that the AI route is wired into the real application graph
 * and closed to unauthenticated callers. The Anthropic call itself is stubbed —
 * what's under test is the route, the guard and the configuration wiring.
 */
describe('AI endpoints (e2e)', () => {
  let app: INestApplication<App>;
  let jwt: JwtService;
  const reply = jest.fn();

  const originalEnv = { ...process.env };

  beforeAll(async () => {
    process.env.APP_ENV = 'qa';
    process.env.JWT_SECRET = 'e2e-api-jwt-secret';
    process.env.SUPABASE_JWT_SECRET = SUPABASE_JWT_SECRET;
    process.env.ANTHROPIC_API_KEY = ANTHROPIC_API_KEY;

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(AiNutritionService)
      .useValue({ reply })
      .compile();

    app = moduleFixture.createNestApplication({ bodyParser: false });
    configureApp(app);
    jwt = moduleFixture.get(JwtService);
    await app.init();
  });

  afterAll(async () => {
    await app.close();
    process.env = originalEnv;
  });

  beforeEach(() => {
    reply.mockReset();
    reply.mockResolvedValue({ text: 'Try eggs and oats.' });
  });

  it('rejects an unauthenticated request', async () => {
    await request(app.getHttpServer())
      .post(ENDPOINT)
      .send({ message: 'What should I eat?' })
      .expect(401);

    expect(reply).not.toHaveBeenCalled();
  });

  it('rejects the Supabase anon key', async () => {
    const anonKey = jwt.sign(
      { role: 'anon', iss: 'supabase' },
      { secret: SUPABASE_JWT_SECRET, expiresIn: 3600 },
    );

    await request(app.getHttpServer())
      .post(ENDPOINT)
      .set('Authorization', `Bearer ${anonKey}`)
      .send({ message: 'What should I eat?' })
      .expect(401);

    expect(reply).not.toHaveBeenCalled();
  });

  it('serves an authenticated user', async () => {
    const token = jwt.sign(
      { sub: 'user-42', role: 'authenticated', aud: 'authenticated' },
      { secret: SUPABASE_JWT_SECRET, expiresIn: 3600 },
    );

    const response = await request(app.getHttpServer())
      .post(ENDPOINT)
      .set('Authorization', `Bearer ${token}`)
      .send({ message: 'What should I eat?', history: [] })
      .expect(201);

    expect(response.body).toEqual({ text: 'Try eggs and oats.' });
    expect(reply).toHaveBeenCalledTimes(1);
  });

  it('accepts a meal photo larger than Express\' default body limit', async () => {
    const token = jwt.sign(
      { sub: 'user-42', role: 'authenticated', aud: 'authenticated' },
      { secret: SUPABASE_JWT_SECRET, expiresIn: 3600 },
    );
    // ~1.3 MB of base64 — far beyond the 100kb default, well inside our limit.
    const data = Buffer.alloc(1_000_000, 7).toString('base64');

    await request(app.getHttpServer())
      .post(ENDPOINT)
      .set('Authorization', `Bearer ${token}`)
      .send({
        message: 'Analyze this meal photo.',
        history: [],
        image: { mediaType: 'image/jpeg', data },
      })
      .expect(201);

    expect(reply).toHaveBeenCalledTimes(1);
    expect(reply.mock.calls[0][0].image.data).toHaveLength(data.length);
  });

  it('never returns the Anthropic key on any path', async () => {
    const token = jwt.sign(
      { sub: 'user-42', role: 'authenticated', aud: 'authenticated' },
      { secret: SUPABASE_JWT_SECRET, expiresIn: 3600 },
    );

    for (const authorization of [null, 'Bearer bogus', `Bearer ${token}`]) {
      const pending = request(app.getHttpServer()).post(ENDPOINT);
      if (authorization) pending.set('Authorization', authorization);
      const response = await pending.send({ message: 'hi' });

      const serialized =
        JSON.stringify(response.body) + JSON.stringify(response.headers);
      expect(serialized).not.toContain(ANTHROPIC_API_KEY);
      expect(serialized).not.toContain('sk-ant-');
    }
  });
});
