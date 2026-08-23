import { Type } from 'class-transformer';
import {
  ArrayMaxSize,
  IsArray,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  ValidateNested,
} from 'class-validator';

/** Media types the Claude vision API accepts for base64 image blocks. */
export const SUPPORTED_IMAGE_MEDIA_TYPES = [
  'image/jpeg',
  'image/png',
  'image/gif',
  'image/webp',
] as const;

/** ~5 MB of binary once base64-decoded — the Anthropic per-image ceiling. */
export const MAX_IMAGE_BASE64_LENGTH = 7_000_000;
export const MAX_MESSAGE_LENGTH = 8_000;
export const MAX_HISTORY_TURNS = 40;
export const MAX_HISTORY_CONTENT_LENGTH = 16_000;

export class NutritionImageDto {
  @IsIn(SUPPORTED_IMAGE_MEDIA_TYPES as unknown as string[])
  mediaType!: string;

  /** Base64-encoded image bytes (no data: prefix). */
  @IsString()
  @IsNotEmpty()
  @MaxLength(MAX_IMAGE_BASE64_LENGTH)
  data!: string;
}

export class NutritionTurnDto {
  @IsIn(['user', 'assistant'])
  role!: 'user' | 'assistant';

  @IsString()
  @MaxLength(MAX_HISTORY_CONTENT_LENGTH)
  content!: string;
}

export class NutritionMessageDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(MAX_MESSAGE_LENGTH)
  message!: string;

  @IsOptional()
  @IsArray()
  @ArrayMaxSize(MAX_HISTORY_TURNS)
  @ValidateNested({ each: true })
  @Type(() => NutritionTurnDto)
  history?: NutritionTurnDto[];

  @IsOptional()
  @ValidateNested()
  @Type(() => NutritionImageDto)
  image?: NutritionImageDto;
}

export interface NutritionMessageResponse {
  text: string;
}
