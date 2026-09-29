import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { SupabaseAuthGuard } from './supabase-auth.guard';
import { SupabaseTokenService } from './supabase-token.service';

/**
 * Supabase-session authentication for API routes the Flutter client calls.
 *
 * This is now the API's ONLY authentication. It used to sit alongside a second,
 * parallel stack (`AuthModule`/`UsersModule` — firebase-admin, passport-jwt,
 * bcryptjs, `/auth/login`, `/auth/register`, `/users`), which authenticated
 * nothing and was deleted under PD-A17: mounted-but-unused authentication is
 * unmaintained attack surface. The client's identity provider is unchanged.
 */
@Module({
  // Secrets are supplied per verification call, so no module-level secret here.
  imports: [JwtModule.register({})],
  providers: [SupabaseTokenService, SupabaseAuthGuard],
  exports: [SupabaseTokenService, SupabaseAuthGuard],
})
export class SupabaseAuthModule {}
