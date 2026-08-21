import { Injectable } from '@nestjs/common';

export interface User {
  id: string;
  email: string;
  password: string;
  firstName: string;
  lastName: string;
  role: string;
  createdAt: Date;
}

@Injectable()
export class UsersService {
  private users: User[] = [];

  async create(data: {
    email: string;
    password: string;
    firstName: string;
    lastName: string;
    role: string;
  }): Promise<User> {
    const user: User = {
      id: Math.random().toString(36).substr(2, 9),
      email: data.email,
      password: data.password,
      firstName: data.firstName,
      lastName: data.lastName,
      role: data.role || 'client',
      createdAt: new Date(),
    };
    this.users.push(user);
    return user;
  }

  async findByEmail(email: string): Promise<User | undefined> {
    return this.users.find(u => u.email === email);
  }

  async findById(id: string): Promise<User | undefined> {
    return this.users.find(u => u.id === id);
  }

  async findAll(): Promise<User[]> {
    return this.users;
  }
}