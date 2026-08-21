import { apiClient } from './client'
import type { PaginatedResponse } from './personeros.service'

export interface UserItem {
  id: number
  name: string
  email: string
  role: 'ADMIN' | 'DIRECTOR' | 'PERSONERO'
  role_id: number
  is_active: boolean
  created_at?: string
  personero?: any
}

export const usersService = {
  async list(params?: { search?: string; role?: string; page?: number; per_page?: number }): Promise<PaginatedResponse<UserItem>> {
    return apiClient<PaginatedResponse<UserItem>>('/users', {
      params,
    })
  },

  async getById(id: number): Promise<{ message: string; data: UserItem }> {
    return apiClient<{ message: string; data: UserItem }>(`/users/${id}`)
  },

  async create(data: { name: string; email: string; password?: string; role: string; is_active?: boolean }): Promise<any> {
    return apiClient('/users', {
      method: 'POST',
      body: data,
    })
  },

  async update(id: number, data: { name?: string; email?: string; role?: string; is_active?: boolean }): Promise<any> {
    return apiClient(`/users/${id}`, {
      method: 'PUT',
      body: data,
    })
  },

  async delete(id: number): Promise<{ message: string }> {
    return apiClient<{ message: string }>(`/users/${id}`, {
      method: 'DELETE',
    })
  },

  async resetPassword(id: number, newPassword?: string): Promise<{ message: string; generated_password?: string }> {
    return apiClient<{ message: string; generated_password?: string }>(`/users/${id}/reset-password`, {
      method: 'POST',
      body: newPassword ? { password: newPassword, password_confirmation: newPassword } : {},
    })
  },
}
