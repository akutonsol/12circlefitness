import {
  Body,
  Controller,
  Post,
  UseGuards,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { SupabaseAuthGuard } from '../auth/supabase/supabase-auth.guard';
import { AiNutritionService } from './ai-nutrition.service';
import {
  NutritionMessageDto,
  NutritionMessageResponse,
} from './dto/nutrition-message.dto';

/**
 * AI endpoints, reached by the Flutter client with its Supabase access token.
 *
 * Every route here is behind [SupabaseAuthGuard]: the Anthropic key is a paid
 * server credential, so an unauthenticated caller must never be able to spend
 * it. The guard is applied at the controller level so a route added later is
 * protected by default rather than by remembering to annotate it.
 */
@Controller('ai')
@UseGuards(SupabaseAuthGuard)
@UsePipes(
  new ValidationPipe({
    whitelist: true,
    forbidNonWhitelisted: true,
    transform: true,
  }),
)
export class AiController {
  constructor(private readonly nutrition: AiNutritionService) {}

  @Post('nutrition/message')
  async nutritionMessage(
    @Body() dto: NutritionMessageDto,
  ): Promise<NutritionMessageResponse> {
    return this.nutrition.reply(dto);
  }
}
