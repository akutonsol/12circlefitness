import { Global, Module } from '@nestjs/common';
import { API_CONFIG, resolveApiConfig } from './api-config';

/**
 * Provides the resolved [ApiConfig] under the `API_CONFIG` token. Global so any
 * module can inject it, and a single provider so tests can swap the whole
 * config with `overrideProvider(API_CONFIG)`.
 */
@Global()
@Module({
  providers: [{ provide: API_CONFIG, useFactory: () => resolveApiConfig() }],
  exports: [API_CONFIG],
})
export class ApiConfigModule {}
