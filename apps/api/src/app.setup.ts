import { INestApplication } from '@nestjs/common';
import { json, urlencoded } from 'express';
import { API_CONFIG } from './config/api-config';
import type { ApiConfig } from './config/api-config';

/**
 * Body limit for the AI nutrition endpoint: a meal photo arrives base64-encoded
 * (~1.34x its byte size), well past Express' 100kb default.
 */
export const MAX_REQUEST_BODY_SIZE = '12mb';

/**
 * Applies the runtime configuration every instance of the app needs — body
 * limits and CORS. Shared by `main.ts` and the e2e tests so what's tested is
 * what actually runs.
 *
 * Requires the app to have been created with `{ bodyParser: false }`, so these
 * parsers are the only ones registered rather than sitting behind Nest's
 * 100kb defaults.
 */
export function configureApp(app: INestApplication): ApiConfig {
  const config = app.get<ApiConfig>(API_CONFIG);

  app.use(json({ limit: MAX_REQUEST_BODY_SIZE }));
  app.use(urlencoded({ extended: true, limit: MAX_REQUEST_BODY_SIZE }));

  app.enableCors({
    origin: config.corsOrigins.length > 0 ? config.corsOrigins : true,
  });

  return config;
}
