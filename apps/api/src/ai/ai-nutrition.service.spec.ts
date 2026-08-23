import Anthropic from '@anthropic-ai/sdk';
import { Logger, ServiceUnavailableException } from '@nestjs/common';
import {
  AiNutritionService,
  NUTRITION_SYSTEM_PROMPT,
} from './ai-nutrition.service';
import { resolveApiConfig } from '../config/api-config';
import type { ApiConfig } from '../config/api-config';
import { NutritionMessageDto } from './dto/nutrition-message.dto';

const ANTHROPIC_API_KEY = 'sk-ant-test-server-only-key';

interface CapturedRequest {
  url: string;
  headers: Record<string, string>;
  body: Record<string, any>;
}

/** Replays a canned Anthropic response and records what the SDK sent. */
function stubTransport(
  status: number,
  payload: unknown,
): { fetch: typeof fetch; captured: CapturedRequest[] } {
  const captured: CapturedRequest[] = [];

  const stub = (async (input: any, init: any = {}) => {
    const headers: Record<string, string> = {};
    new Headers(init.headers ?? {}).forEach((value, key) => {
      headers[key.toLowerCase()] = value;
    });
    captured.push({
      url: String(input),
      headers,
      body: JSON.parse(String(init.body ?? '{}')),
    });

    return new Response(JSON.stringify(payload), {
      status,
      headers: { 'content-type': 'application/json' },
    });
  }) as unknown as typeof fetch;

  return { fetch: stub, captured };
}

/** Subclass that routes the real SDK client through the stub transport. */
class TestAiNutritionService extends AiNutritionService {
  keysUsed: string[] = [];

  constructor(
    config: ApiConfig,
    private readonly transport: typeof fetch,
  ) {
    super(config);
  }

  protected override createClient(apiKey: string): Anthropic {
    this.keysUsed.push(apiKey);
    return new Anthropic({
      apiKey,
      fetch: this.transport,
      maxRetries: 0,
    });
  }
}

const okPayload = {
  id: 'msg_1',
  type: 'message',
  role: 'assistant',
  model: 'claude-sonnet-4-6',
  stop_reason: 'end_turn',
  content: [{ type: 'text', text: 'Grilled salmon with quinoa — 520 kcal.' }],
  usage: { input_tokens: 10, output_tokens: 12 },
};

const configuredEnv = {
  APP_ENV: 'qa',
  ANTHROPIC_API_KEY,
  ANTHROPIC_MODEL: 'claude-sonnet-4-6',
  ANTHROPIC_MAX_TOKENS: '1024',
};

function build(
  env: NodeJS.ProcessEnv,
  status = 200,
  payload: unknown = okPayload,
) {
  const { fetch, captured } = stubTransport(status, payload);
  return {
    service: new TestAiNutritionService(resolveApiConfig(env), fetch),
    captured,
  };
}

const basicDto: NutritionMessageDto = {
  message: 'What should I eat post-workout?',
  history: [],
};

describe('AiNutritionService', () => {
  /** Everything the service logged during a test, so we can assert on it. */
  let logged: string[];

  beforeEach(() => {
    logged = [];
    const record = (message: unknown) => {
      logged.push(String(message));
    };
    jest.spyOn(Logger.prototype, 'error').mockImplementation(record);
    jest.spyOn(Logger.prototype, 'warn').mockImplementation(record);
    jest.spyOn(Logger.prototype, 'log').mockImplementation(record);
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  describe('server-side credential', () => {
    it('uses the API key from server configuration only', async () => {
      const { service, captured } = build(configuredEnv);
      await service.reply(basicDto);

      expect(service.keysUsed).toEqual([ANTHROPIC_API_KEY]);
      expect(captured).toHaveLength(1);
      expect(captured[0].headers['x-api-key']).toBe(ANTHROPIC_API_KEY);
      expect(captured[0].url).toContain('api.anthropic.com');
    });

    it('reuses one client rather than re-reading the key per request', async () => {
      const { service } = build(configuredEnv);
      await service.reply(basicDto);
      await service.reply(basicDto);

      expect(service.keysUsed).toEqual([ANTHROPIC_API_KEY]);
    });

    it('reports itself unconfigured and refuses to call out when no key is set', async () => {
      const { service, captured } = build({ APP_ENV: 'qa' });

      expect(service.isConfigured).toBe(false);
      await expect(service.reply(basicDto)).rejects.toBeInstanceOf(
        ServiceUnavailableException,
      );
      expect(captured).toHaveLength(0);
      expect(service.keysUsed).toEqual([]);
    });
  });

  describe('request construction preserves the nutrition coach', () => {
    it('sends the coach system prompt and configured model', async () => {
      const { service, captured } = build(configuredEnv);
      await service.reply(basicDto);

      expect(captured[0].body.system).toBe(NUTRITION_SYSTEM_PROMPT);
      expect(captured[0].body.model).toBe('claude-sonnet-4-6');
      expect(captured[0].body.max_tokens).toBe(1024);
    });

    it('honours a model override from the environment', async () => {
      const { service, captured } = build({
        ...configuredEnv,
        ANTHROPIC_MODEL: 'claude-opus-5',
        ANTHROPIC_MAX_TOKENS: '4096',
      });
      await service.reply(basicDto);

      expect(captured[0].body.model).toBe('claude-opus-5');
      expect(captured[0].body.max_tokens).toBe(4096);
    });

    it('appends the user turn after the conversation history', async () => {
      const { service, captured } = build(configuredEnv);
      await service.reply({
        message: 'And for dinner?',
        history: [
          { role: 'user', content: 'Hi' },
          { role: 'assistant', content: 'Hello!' },
        ],
      });

      const messages = captured[0].body.messages;
      expect(messages).toHaveLength(3);
      expect(messages[0]).toEqual({ role: 'user', content: 'Hi' });
      expect(messages[1]).toEqual({ role: 'assistant', content: 'Hello!' });
      expect(messages[2].role).toBe('user');
      expect(messages[2].content).toEqual([
        { type: 'text', text: 'And for dinner?' },
      ]);
    });

    it('sends a meal photo as a base64 image block before the text', async () => {
      const data = Buffer.from('fake-jpeg').toString('base64');
      const { service, captured } = build(configuredEnv);
      await service.reply({
        message: 'Analyze this meal photo.',
        history: [],
        image: { mediaType: 'image/jpeg', data },
      });

      const content = captured[0].body.messages[0].content;
      expect(content[0]).toEqual({
        type: 'image',
        source: { type: 'base64', media_type: 'image/jpeg', data },
      });
      expect(content[1]).toEqual({
        type: 'text',
        text: 'Analyze this meal photo.',
      });
    });
  });

  describe('response handling', () => {
    it('returns the concatenated text blocks', async () => {
      const { service } = build(configuredEnv);
      await expect(service.reply(basicDto)).resolves.toEqual({
        text: 'Grilled salmon with quinoa — 520 kcal.',
      });
    });

    it('joins multiple text blocks into one reply', async () => {
      const { service } = build(configuredEnv, 200, {
        ...okPayload,
        content: [
          { type: 'text', text: 'Part one. ' },
          { type: 'text', text: 'Part two.' },
        ],
      });

      await expect(service.reply(basicDto)).resolves.toEqual({
        text: 'Part one. Part two.',
      });
    });

    it('treats a text-free response as unavailable rather than empty', async () => {
      const { service } = build(configuredEnv, 200, {
        ...okPayload,
        content: [],
      });

      await expect(service.reply(basicDto)).rejects.toBeInstanceOf(
        ServiceUnavailableException,
      );
    });
  });

  describe('upstream failures never expose the credential', () => {
    const failures: Array<[string, number, unknown]> = [
      ['401 invalid key', 401, { type: 'error', error: { type: 'authentication_error', message: `invalid x-api-key: ${ANTHROPIC_API_KEY}` } }],
      ['429 rate limited', 429, { type: 'error', error: { type: 'rate_limit_error', message: 'slow down' } }],
      ['500 upstream', 500, { type: 'error', error: { type: 'api_error', message: 'boom' } }],
    ];

    it.each(failures)('maps %s to a generic 503', async (_name, status, payload) => {
      const { service } = build(configuredEnv, status, payload);

      await expect(service.reply(basicDto)).rejects.toBeInstanceOf(
        ServiceUnavailableException,
      );
    });

    it('the error surfaced to the caller contains no key material', async () => {
      const { service } = build(configuredEnv, ...failures[0].slice(1) as [number, unknown]);

      try {
        await service.reply(basicDto);
        fail('expected the request to fail');
      } catch (error) {
        const serialized = JSON.stringify(
          error instanceof ServiceUnavailableException
            ? error.getResponse()
            : error,
        );
        expect(serialized).not.toContain(ANTHROPIC_API_KEY);
        expect(serialized).not.toContain('sk-ant-');
        expect(serialized).toContain('AI is temporarily unavailable');
      }
    });

    it('nothing the service logs contains key material', async () => {
      for (const [, status, payload] of failures) {
        const { service } = build(configuredEnv, status, payload);
        await expect(service.reply(basicDto)).rejects.toBeInstanceOf(
          ServiceUnavailableException,
        );
      }

      expect(logged.length).toBeGreaterThan(0);
      for (const line of logged) {
        expect(line).not.toContain(ANTHROPIC_API_KEY);
        expect(line).not.toContain('sk-ant-');
      }
    });
  });
});
