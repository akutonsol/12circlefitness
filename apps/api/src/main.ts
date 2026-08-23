import { Logger } from '@nestjs/common';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { configureApp } from './app.setup';
import { describeApiConfig, missingRequiredSettings } from './config/api-config';

async function bootstrap() {
  // bodyParser: false — configureApp registers parsers with a limit large
  // enough for base64 meal photos.
  const app = await NestFactory.create(AppModule, { bodyParser: false });
  const config = configureApp(app);
  const logger = new Logger('Bootstrap');

  const missing = missingRequiredSettings(config);
  if (missing.length > 0) {
    logger.warn(
      `Missing environment configuration: ${missing.join(', ')}. ` +
        'Features depending on these will return 503.',
    );
  }
  logger.log(`Configuration: ${JSON.stringify(describeApiConfig(config))}`);

  await app.listen(config.port);
  logger.log(`API listening on :${config.port} (${config.environment})`);
}
void bootstrap();
