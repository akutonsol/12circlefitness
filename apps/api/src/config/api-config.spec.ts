import {
  DEFAULT_ANTHROPIC_MAX_TOKENS,
  DEFAULT_ANTHROPIC_MODEL,
  DEFAULT_PORT,
  describeApiConfig,
  missingRequiredSettings,
  parseEnvironment,
  resolveApiConfig,
} from './api-config';

const fullEnv: NodeJS.ProcessEnv = {
  APP_ENV: 'qa',
  PORT: '4000',
  JWT_SECRET: 'api-jwt-secret',
  SUPABASE_URL: 'https://qa-ref.supabase.co',
  SUPABASE_JWT_SECRET: 'qa-supabase-jwt-secret',
  ANTHROPIC_API_KEY: 'sk-ant-test-key',
  ANTHROPIC_MODEL: 'claude-opus-5',
  ANTHROPIC_MAX_TOKENS: '2048',
  CORS_ORIGINS: 'https://qa.12circle.test, https://qa-admin.12circle.test',
};

describe('API environment configuration', () => {
  describe('environment selection', () => {
    it('resolves dev, qa and prod', () => {
      expect(parseEnvironment('dev')).toBe('dev');
      expect(parseEnvironment('qa')).toBe('qa');
      expect(parseEnvironment('prod')).toBe('prod');
    });

    it('accepts long-form aliases and is case-insensitive', () => {
      expect(parseEnvironment('DEVELOPMENT')).toBe('dev');
      expect(parseEnvironment(' Staging ')).toBe('qa');
      expect(parseEnvironment('production')).toBe('prod');
    });

    it('defaults to dev when unset', () => {
      expect(parseEnvironment(undefined)).toBe('dev');
      expect(resolveApiConfig({}).environment).toBe('dev');
    });

    it('rejects an unknown environment instead of guessing', () => {
      expect(() => parseEnvironment('prd')).toThrow(/Unknown APP_ENV/);
      expect(() => resolveApiConfig({ APP_ENV: 'live' })).toThrow(
        /Unknown APP_ENV/,
      );
    });

    it('falls back to NODE_ENV when APP_ENV is absent', () => {
      expect(resolveApiConfig({ NODE_ENV: 'production' }).environment).toBe(
        'prod',
      );
    });

    it('ignores a NODE_ENV that names no backend, such as jest\'s "test"', () => {
      expect(resolveApiConfig({ NODE_ENV: 'test' }).environment).toBe('dev');
    });

    it('APP_ENV wins over NODE_ENV', () => {
      expect(
        resolveApiConfig({ APP_ENV: 'qa', NODE_ENV: 'production' }).environment,
      ).toBe('qa');
    });

    it('still rejects a typo in APP_ENV even when NODE_ENV is valid', () => {
      expect(() =>
        resolveApiConfig({ APP_ENV: 'prd', NODE_ENV: 'production' }),
      ).toThrow(/Unknown APP_ENV/);
    });
  });

  describe('value resolution', () => {
    it('reads every setting from the environment', () => {
      const config = resolveApiConfig(fullEnv);

      expect(config).toEqual({
        environment: 'qa',
        port: 4000,
        jwtSecret: 'api-jwt-secret',
        supabaseUrl: 'https://qa-ref.supabase.co',
        supabaseJwtSecret: 'qa-supabase-jwt-secret',
        anthropicApiKey: 'sk-ant-test-key',
        anthropicModel: 'claude-opus-5',
        anthropicMaxTokens: 2048,
        corsOrigins: [
          'https://qa.12circle.test',
          'https://qa-admin.12circle.test',
        ],
      });
    });

    it('applies documented defaults when optional settings are absent', () => {
      const config = resolveApiConfig({});

      expect(config.port).toBe(DEFAULT_PORT);
      expect(config.anthropicModel).toBe(DEFAULT_ANTHROPIC_MODEL);
      expect(config.anthropicMaxTokens).toBe(DEFAULT_ANTHROPIC_MAX_TOKENS);
      expect(config.corsOrigins).toEqual([]);
    });

    it('is pure — it never mutates the environment it reads', () => {
      const env = { ...fullEnv };
      resolveApiConfig(env);
      expect(env).toEqual(fullEnv);
    });

    it('rejects a malformed port rather than silently using the default', () => {
      expect(() => resolveApiConfig({ PORT: 'eighty' })).toThrow();
      expect(() => resolveApiConfig({ PORT: '-1' })).toThrow();
      expect(resolveApiConfig({ PORT: '' }).port).toBe(DEFAULT_PORT);
    });

    it('two environments resolve to independent configurations', () => {
      const qa = resolveApiConfig({ ...fullEnv, APP_ENV: 'qa' });
      const prod = resolveApiConfig({
        APP_ENV: 'prod',
        SUPABASE_URL: 'https://prod-ref.supabase.co',
        SUPABASE_JWT_SECRET: 'prod-supabase-jwt-secret',
        ANTHROPIC_API_KEY: 'sk-ant-prod-key',
      });

      expect(qa.supabaseUrl).not.toBe(prod.supabaseUrl);
      expect(qa.supabaseJwtSecret).not.toBe(prod.supabaseJwtSecret);
      expect(qa.anthropicApiKey).not.toBe(prod.anthropicApiKey);
    });
  });

  describe('required settings', () => {
    it('reports nothing missing for a fully configured environment', () => {
      expect(missingRequiredSettings(resolveApiConfig(fullEnv))).toEqual([]);
    });

    it('names each absent secret', () => {
      expect(missingRequiredSettings(resolveApiConfig({}))).toEqual([
        'JWT_SECRET',
        'SUPABASE_JWT_SECRET',
        'ANTHROPIC_API_KEY',
      ]);
    });

    it('names only the settings that are actually absent', () => {
      const config = resolveApiConfig({
        JWT_SECRET: 'x',
        SUPABASE_JWT_SECRET: 'y',
      });
      expect(missingRequiredSettings(config)).toEqual(['ANTHROPIC_API_KEY']);
    });
  });

  describe('log safety', () => {
    it('never includes a secret value in the loggable description', () => {
      const described = JSON.stringify(
        describeApiConfig(resolveApiConfig(fullEnv)),
      );

      expect(described).not.toContain('sk-ant-test-key');
      expect(described).not.toContain('qa-supabase-jwt-secret');
      expect(described).not.toContain('api-jwt-secret');
    });

    it('still reports whether each secret is set', () => {
      expect(describeApiConfig(resolveApiConfig(fullEnv))).toMatchObject({
        environment: 'qa',
        anthropicApiKey: '<set>',
        supabaseJwtSecret: '<set>',
        jwtSecret: '<set>',
      });
      expect(describeApiConfig(resolveApiConfig({}))).toMatchObject({
        anthropicApiKey: '<unset>',
        supabaseJwtSecret: '<unset>',
        jwtSecret: '<unset>',
      });
    });
  });
});
