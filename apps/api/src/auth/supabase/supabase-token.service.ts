import {
  Inject,
  Injectable,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { API_CONFIG } from '../../config/api-config';
import type { ApiConfig } from '../../config/api-config';

/** The subset of a verified Supabase access token the API acts on. */
export interface SupabaseUser {
  userId: string;
  email?: string;
  /** Supabase token role. Always `authenticated` for a signed-in end user. */
  tokenRole: string;
  /** 12 Circle application role from user/app metadata, when present. */
  appRole?: string;
}

interface SupabaseJwtPayload {
  sub?: unknown;
  email?: unknown;
  role?: unknown;
  aud?: unknown;
  user_metadata?: { role?: unknown } | null;
  app_metadata?: { role?: unknown } | null;
}

/** Only a signed-in end user may act — never the anon or service_role key. */
const END_USER_TOKEN_ROLE = 'authenticated';

/**
 * Verifies Supabase access tokens issued to the Flutter client.
 *
 * The client authenticates against Supabase Auth (unchanged); this service is
 * how the NestJS API trusts that session. Tokens are verified locally against
 * the project's HS256 signing secret — no network round-trip per request.
 *
 * Note the `role` check: the Supabase anon/publishable key is itself a valid
 * JWT signed with the same secret. Requiring `role === "authenticated"` is what
 * stops an anonymous key — which every client ships — from being accepted as a
 * user session, and likewise rejects a leaked `service_role` key on this path.
 */
@Injectable()
export class SupabaseTokenService {
  constructor(
    @Inject(API_CONFIG) private readonly config: ApiConfig,
    private readonly jwtService: JwtService,
  ) {}

  get isConfigured(): boolean {
    return this.config.supabaseJwtSecret.length > 0;
  }

  async verify(token: string): Promise<SupabaseUser> {
    if (!this.isConfigured) {
      // A misconfigured server must not look like a rejected credential.
      throw new ServiceUnavailableException(
        'Supabase authentication is not configured on this server',
      );
    }

    let payload: SupabaseJwtPayload;
    try {
      payload = await this.jwtService.verifyAsync<SupabaseJwtPayload>(token, {
        secret: this.config.supabaseJwtSecret,
        algorithms: ['HS256'],
      });
    } catch {
      // Never surface the underlying jsonwebtoken message — it can hint at
      // which part of the token was wrong.
      throw new UnauthorizedException('Invalid or expired access token');
    }

    const userId = typeof payload.sub === 'string' ? payload.sub.trim() : '';
    if (!userId) {
      throw new UnauthorizedException('Access token has no subject');
    }

    if (payload.role !== END_USER_TOKEN_ROLE) {
      throw new UnauthorizedException(
        'Access token is not a signed-in user session',
      );
    }

    return {
      userId,
      email: typeof payload.email === 'string' ? payload.email : undefined,
      tokenRole: END_USER_TOKEN_ROLE,
      appRole: readRole(payload.user_metadata) ?? readRole(payload.app_metadata),
    };
  }
}

function readRole(metadata: { role?: unknown } | null | undefined) {
  const role = metadata?.role;
  return typeof role === 'string' && role.length > 0 ? role : undefined;
}
