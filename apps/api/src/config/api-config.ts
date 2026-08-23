/**
 * Environment configuration for the 12 Circle API.
 *
 * Everything the API needs is read from the process environment in exactly one
 * place, so the same build can be deployed to dev / qa / prod by changing env
 * vars alone. `resolveApiConfig` is pure — it takes the environment map as an
 * argument — so it can be tested without mutating `process.env`.
 *
 * SECURITY: `anthropicApiKey` is a server-only secret. It is never returned to
 * a client, never logged (see `describeApiConfig`), and never shipped to the
 * Flutter app.
 */

export type ApiEnvironment = 'dev' | 'qa' | 'prod';

export const API_CONFIG = Symbol('API_CONFIG');

export interface ApiConfig {
  environment: ApiEnvironment;
  port: number;
  /** Signing secret for the API's own (NestJS) JWTs. */
  jwtSecret: string;
  /** Supabase project URL for this environment (informational / future use). */
  supabaseUrl: string;
  /** Supabase JWT signing secret — used to verify client access tokens. */
  supabaseJwtSecret: string;
  /** Anthropic API key. SERVER ONLY. */
  anthropicApiKey: string;
  /** Claude model the AI nutrition coach runs on. */
  anthropicModel: string;
  /** Max tokens per AI nutrition reply. */
  anthropicMaxTokens: number;
  /** Allowed browser origins; empty means "reflect any origin" (dev only). */
  corsOrigins: string[];
}

/** The model the Flutter client used before the integration moved server-side. */
export const DEFAULT_ANTHROPIC_MODEL = 'claude-sonnet-4-6';
export const DEFAULT_ANTHROPIC_MAX_TOKENS = 1024;
export const DEFAULT_PORT = 3000;

/** Returns the matching environment, or undefined when [value] isn't one. */
export function tryParseEnvironment(
  value: string | undefined,
): ApiEnvironment | undefined {
  switch ((value ?? '').trim().toLowerCase()) {
    case 'dev':
    case 'development':
      return 'dev';
    case 'qa':
    case 'staging':
      return 'qa';
    case 'prod':
    case 'production':
      return 'prod';
    default:
      return undefined;
  }
}

/** Strict form: an unrecognised APP_ENV is a deployment mistake, not a default. */
export function parseEnvironment(value: string | undefined): ApiEnvironment {
  if ((value ?? '').trim() === '') return 'dev';
  const environment = tryParseEnvironment(value);
  if (!environment) {
    throw new Error(
      `Unknown APP_ENV "${value}". Expected one of: dev, qa, prod.`,
    );
  }
  return environment;
}

/**
 * APP_ENV is authoritative. NODE_ENV is only consulted as a convenience when
 * APP_ENV is unset, and only when it names an environment we know — tooling
 * sets values like `test` that say nothing about which backend to talk to.
 */
function resolveEnvironment(env: NodeJS.ProcessEnv): ApiEnvironment {
  if ((env.APP_ENV ?? '').trim() !== '') return parseEnvironment(env.APP_ENV);
  return tryParseEnvironment(env.NODE_ENV) ?? 'dev';
}

function parsePositiveInt(value: string | undefined, fallback: number): number {
  if (value === undefined || value.trim() === '') return fallback;
  const parsed = Number(value);
  if (!Number.isInteger(parsed) || parsed <= 0) {
    throw new Error(`Expected a positive integer, received "${value}".`);
  }
  return parsed;
}

function parseList(value: string | undefined): string[] {
  if (!value) return [];
  return value
    .split(',')
    .map((entry) => entry.trim())
    .filter((entry) => entry.length > 0);
}

export function resolveApiConfig(
  env: NodeJS.ProcessEnv = process.env,
): ApiConfig {
  return {
    environment: resolveEnvironment(env),
    port: parsePositiveInt(env.PORT, DEFAULT_PORT),
    jwtSecret: env.JWT_SECRET ?? '',
    supabaseUrl: env.SUPABASE_URL ?? '',
    supabaseJwtSecret: env.SUPABASE_JWT_SECRET ?? '',
    anthropicApiKey: env.ANTHROPIC_API_KEY ?? '',
    anthropicModel: env.ANTHROPIC_MODEL?.trim() || DEFAULT_ANTHROPIC_MODEL,
    anthropicMaxTokens: parsePositiveInt(
      env.ANTHROPIC_MAX_TOKENS,
      DEFAULT_ANTHROPIC_MAX_TOKENS,
    ),
    corsOrigins: parseList(env.CORS_ORIGINS),
  };
}

/** Names of required settings that are absent. Empty means fully configured. */
export function missingRequiredSettings(config: ApiConfig): string[] {
  return [
    ...(config.jwtSecret ? [] : ['JWT_SECRET']),
    ...(config.supabaseJwtSecret ? [] : ['SUPABASE_JWT_SECRET']),
    ...(config.anthropicApiKey ? [] : ['ANTHROPIC_API_KEY']),
  ];
}

/**
 * A log-safe view of the config: secrets are reduced to a present/absent flag,
 * so nothing sensitive can reach stdout or an error reporter.
 */
export function describeApiConfig(config: ApiConfig): Record<string, unknown> {
  return {
    environment: config.environment,
    port: config.port,
    supabaseUrl: config.supabaseUrl || '<unset>',
    anthropicModel: config.anthropicModel,
    anthropicMaxTokens: config.anthropicMaxTokens,
    corsOrigins: config.corsOrigins,
    jwtSecret: config.jwtSecret ? '<set>' : '<unset>',
    supabaseJwtSecret: config.supabaseJwtSecret ? '<set>' : '<unset>',
    anthropicApiKey: config.anthropicApiKey ? '<set>' : '<unset>',
  };
}
