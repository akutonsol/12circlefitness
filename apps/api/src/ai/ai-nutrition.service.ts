import Anthropic from '@anthropic-ai/sdk';
import {
  Inject,
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { API_CONFIG } from '../config/api-config';
import type { ApiConfig } from '../config/api-config';
import {
  NutritionMessageDto,
  NutritionMessageResponse,
} from './dto/nutrition-message.dto';

/**
 * The AI Nutrition Coach persona. Moved here verbatim from the Flutter client
 * so the prompt — and the API key that pays for it — live server-side.
 */
export const NUTRITION_SYSTEM_PROMPT = `You are an expert AI Nutrition Coach for 12 Circle Fitness,
a premium fitness platform designed for women seeking sustainable body transformation.
Your role is to:
- Analyze meal photos and estimate calories and macros accurately
- Generate personalized meal plans
- Create detailed grocery lists
- Answer nutrition questions with science-backed advice
- Be encouraging, supportive and empowering
- Focus on sustainable, healthy eating habits
Keep responses concise, actionable and motivating.`;

/**
 * Calls Claude on behalf of an authenticated client.
 *
 * The Anthropic API key is read from server-side configuration only. It is
 * never included in a response and never written to a log: upstream failures
 * are logged by class/status and returned to the caller as a generic
 * 503 so nothing about the credential can leak through an error path.
 */
@Injectable()
export class AiNutritionService {
  private readonly logger = new Logger(AiNutritionService.name);
  private client: Anthropic | null = null;

  constructor(@Inject(API_CONFIG) protected readonly config: ApiConfig) {}

  /**
   * Builds the Anthropic client. Overridable so tests can supply a stub
   * transport — the key still flows through the real client, so a test can
   * assert what the server actually sends.
   */
  protected createClient(apiKey: string): Anthropic {
    return new Anthropic({ apiKey });
  }

  get isConfigured(): boolean {
    return this.config.anthropicApiKey.length > 0;
  }

  private getClient(): Anthropic {
    if (!this.isConfigured) {
      throw new ServiceUnavailableException('AI is not configured');
    }
    this.client ??= this.createClient(this.config.anthropicApiKey);
    return this.client;
  }

  async reply(dto: NutritionMessageDto): Promise<NutritionMessageResponse> {
    const client = this.getClient();

    const userContent: Anthropic.ContentBlockParam[] = [];
    if (dto.image) {
      userContent.push({
        type: 'image',
        source: {
          type: 'base64',
          media_type: dto.image
            .mediaType as Anthropic.Base64ImageSource['media_type'],
          data: dto.image.data,
        },
      });
    }
    userContent.push({ type: 'text', text: dto.message });

    const messages: Anthropic.MessageParam[] = [
      ...(dto.history ?? []).map(
        (turn): Anthropic.MessageParam => ({
          role: turn.role,
          content: turn.content,
        }),
      ),
      { role: 'user', content: userContent },
    ];

    let response: Anthropic.Message;
    try {
      response = await client.messages.create({
        model: this.config.anthropicModel,
        max_tokens: this.config.anthropicMaxTokens,
        system: NUTRITION_SYSTEM_PROMPT,
        messages,
      });
    } catch (error) {
      throw this.toClientSafeError(error);
    }

    const text = response.content
      .filter(
        (block): block is Anthropic.TextBlock => block.type === 'text',
      )
      .map((block) => block.text)
      .join('')
      .trim();

    if (!text) {
      this.logger.warn(
        `Claude returned no text (stop_reason=${response.stop_reason})`,
      );
      throw new ServiceUnavailableException('AI returned an empty response');
    }

    return { text };
  }

  /**
   * Maps an upstream failure onto a response that reveals nothing about the
   * credential or the upstream request. The detail is logged, not returned.
   */
  private toClientSafeError(error: unknown): ServiceUnavailableException {
    if (error instanceof Anthropic.AuthenticationError) {
      this.logger.error('Anthropic rejected the server API key (401)');
    } else if (error instanceof Anthropic.RateLimitError) {
      this.logger.warn('Anthropic rate limit reached (429)');
    } else if (error instanceof Anthropic.APIError) {
      this.logger.error(`Anthropic API error ${error.status}`);
    } else if (error instanceof Error) {
      this.logger.error(`Anthropic request failed: ${error.name}`);
    } else {
      this.logger.error('Anthropic request failed');
    }
    return new ServiceUnavailableException('AI is temporarily unavailable');
  }
}
