import { Module } from '@nestjs/common';
import { SupabaseAuthModule } from '../auth/supabase/supabase-auth.module';
import { AiController } from './ai.controller';
import { AiNutritionService } from './ai-nutrition.service';

@Module({
  imports: [SupabaseAuthModule],
  controllers: [AiController],
  providers: [AiNutritionService],
})
export class AiModule {}
