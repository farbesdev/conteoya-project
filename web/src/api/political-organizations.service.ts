import { apiClient } from './client'
import type { PaginatedResponse } from './personeros.service'

export interface PoliticalOrganizationFullItem {
  id: number
  jee_id?: number | null
  name: string
  short_name?: string | null
  org_type: string
  logo_url?: string | null
  raw_logo_url?: string | null
  local_logo_url?: string | null
  created_at?: string
  updated_at?: string
}

export const politicalOrganizationsService = {
  async list(params?: { search?: string; page?: number; per_page?: number }): Promise<PaginatedResponse<PoliticalOrganizationFullItem>> {
    return apiClient<PaginatedResponse<PoliticalOrganizationFullItem>>('/political-organizations', {
      params,
    })
  },

  async getById(id: number): Promise<{ message: string; data: PoliticalOrganizationFullItem }> {
    return apiClient<{ message: string; data: PoliticalOrganizationFullItem }>(`/political-organizations/${id}`)
  },

  async create(formData: FormData): Promise<{ message: string; data: PoliticalOrganizationFullItem }> {
    return apiClient<{ message: string; data: PoliticalOrganizationFullItem }>('/political-organizations', {
      method: 'POST',
      body: formData,
    })
  },

  async update(id: number, formData: FormData): Promise<{ message: string; data: PoliticalOrganizationFullItem }> {
    return apiClient<{ message: string; data: PoliticalOrganizationFullItem }>(`/political-organizations/${id}`, {
      method: 'POST', // POST a /political-organizations/{id} para soportar multipart/form-data con archivo de logo
      body: formData,
    })
  },

  async delete(id: number): Promise<{ message: string }> {
    return apiClient<{ message: string }>(`/political-organizations/${id}`, {
      method: 'DELETE',
    })
  },
}
