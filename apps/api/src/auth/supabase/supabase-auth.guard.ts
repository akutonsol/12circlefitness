import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import type { Request } from 'express';
import { SupabaseTokenService, SupabaseUser } from './supabase-token.service';

export interface RequestWithSupabaseUser extends Request {
  user?: SupabaseUser;
}

const BEARER_PREFIX = 'bearer ';

/**
 * Requires a valid Supabase access token on `Authorization: Bearer <token>`.
 * On success the verified user is attached to `request.user`.
 */
@Injectable()
export class SupabaseAuthGuard implements CanActivate {
  constructor(private readonly tokens: SupabaseTokenService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<RequestWithSupabaseUser>();
    const header = request.headers?.authorization;

    if (typeof header !== 'string' || !header.toLowerCase().startsWith(BEARER_PREFIX)) {
      throw new UnauthorizedException('Missing bearer access token');
    }

    const token = header.slice(BEARER_PREFIX.length).trim();
    if (!token) {
      throw new UnauthorizedException('Missing bearer access token');
    }

    request.user = await this.tokens.verify(token);
    return true;
  }
}
