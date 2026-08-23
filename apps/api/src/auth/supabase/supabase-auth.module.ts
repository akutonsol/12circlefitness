import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { SupabaseAuthGuard } from './supabase-auth.guard';
import { SupabaseTokenService } from './supabase-token.service';

/**
 * Supabase-session authentication for API routes the Flutter client calls.
 * Sits alongside the API's own JWT auth (`AuthModule`) rather than replacing
 * it — the client's identity provider is unchanged.
 */
@Module({
  // Secrets are supplied per verification call, so no module-level secret here.
  imports: [JwtModule.register({})],
  providers: [SupabaseTokenService, SupabaseAuthGuard],
  exports: [SupabaseTokenService, SupabaseAuthGuard],
})
export class SupabaseAuthModule {}
