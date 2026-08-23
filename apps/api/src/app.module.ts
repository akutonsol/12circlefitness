import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AiModule } from './ai/ai.module';
import { ApiConfigModule } from './config/api-config.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';

@Module({
  imports: [
    // Loads apps/api/.env into process.env before ApiConfigModule reads it.
    ConfigModule.forRoot({ isGlobal: true }),
    ApiConfigModule,
    AuthModule,
    UsersModule,
    AiModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
