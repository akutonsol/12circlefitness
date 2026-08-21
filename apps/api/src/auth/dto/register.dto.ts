import { IsEmail, IsString, IsEnum, MinLength } from 'class-validator';

export type Role = 'client' | 'coach' | 'admin' | 'vendor';

export class RegisterDto {
  @IsEmail()
  email!: string;

  @IsString()
  @MinLength(6)
  password!: string;

  @IsString()
  firstName!: string;

  @IsString()
  lastName!: string;

  @IsEnum(['client', 'coach', 'admin', 'vendor'])
  role!: Role;
}