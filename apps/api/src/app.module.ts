import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { AiModule } from './ai/ai.module';
import { ApiConfigModule } from './config/api-config.module';

@Module({
  imports: [
    // Loads apps/api/.env into process.env before ApiConfigModule reads it.
    ConfigModule.forRoot({ isGlobal: true }),
    ApiConfigModule,
    // PD-A17: the parallel auth stack (AuthModule/UsersModule — firebase-admin,
    // passport-jwt, bcryptjs, /auth/login, /auth/register, /users) was DELETED.
    // It authenticated nothing: every live surface is Supabase-authenticated via
    // SupabaseAuthGuard. Mounted-but-unused authentication is unmaintained
    // attack surface, which is why PD-A17 authorizes removal independently of
    // where — or whether — this API is ever deployed.
    AiModule,
  ],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
