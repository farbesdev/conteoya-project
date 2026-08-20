import { apiClient } from './client'

export interface UserData {
  id: number
  name: string
  email: string
  role: 'ADMIN' | 'DIRECTOR' | 'PERSONERO'
  is_active: boolean
  personero_id?: number | null
}

export interface LoginResponse {
  message: string
  access_token: string
  token_type: string
  user: UserData
}

export const authService = {
  async login(login: string, password: string): Promise<LoginResponse> {
    return apiClient<LoginResponse>('/login', {
      method: 'POST',
      body: {
        email: login,
        password,
      },
    })
  },

  async me(): Promise<{ user: UserData }> {
    return apiClient<{ user: UserData }>('/me', {
      method: 'GET',
    })
  },

  async logout(): Promise<{ message: string }> {
    return apiClient<{ message: string }>('/logout', {
      method: 'POST',
    })
  },
}
