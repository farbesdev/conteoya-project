import { apiClient } from './client'
import type { PaginatedResponse } from './personeros.service'

export interface CandidateItem {
  id: number
  document_number: string
  dni: string
  full_name: string
  name: string
  photo_url?: string | null
  local_photo_url?: string | null
  id_hoja_vida?: string | null
  cv_url?: string | null
  voto_informado_url?: string | null
  position?: string
  status?: string
  list_number?: number | null
  political_org_name?: string
  political_org_short_name?: string
  political_org_logo?: string | null
  electoral_level_name?: string
  department_name?: string | null
  province_name?: string | null
  district_name?: string | null
}

export interface CandidateCvSyncProgress {
  status: 'idle' | 'running' | 'completed' | 'canceled' | 'failed'
  total: number
  processed: number
  success_count: number
  error_count: number
  percentage: number
  last_candidate_name?: string
  started_at?: string | null
  updated_at?: string | null
}

export const candidatesService = {
  async list(params?: { search?: string; page?: number; per_page?: number }): Promise<PaginatedResponse<CandidateItem>> {
    return apiClient<PaginatedResponse<CandidateItem>>('/candidates', {
      params,
    })
  },

  async getById(id: number): Promise<{ message: string; data: CandidateItem }> {
    return apiClient<{ message: string; data: CandidateItem }>(`/candidates/${id}`)
  },

  async create(data: {
    document_number: string
    full_name: string
    photo_url?: string
    position?: string
    id_hoja_vida?: string
  }): Promise<{ message: string; data: CandidateItem }> {
    return apiClient<{ message: string; data: CandidateItem }>('/candidates', {
      method: 'POST',
      body: data,
    })
  },

  async update(id: number, data: {
    full_name?: string
    photo_url?: string
    position?: string
    id_hoja_vida?: string
  }): Promise<{ message: string; data: CandidateItem }> {
    return apiClient<{ message: string; data: CandidateItem }>(`/candidates/${id}`, {
      method: 'PUT',
      body: data,
    })
  },

  async delete(id: number): Promise<{ message: string }> {
    return apiClient<{ message: string }>(`/candidates/${id}`, {
      method: 'DELETE',
    })
  },

  async startCvSync(params?: { chunk?: number; delay_ms?: number; limit?: number }): Promise<{ message: string; data: CandidateCvSyncProgress }> {
    return apiClient<{ message: string; data: CandidateCvSyncProgress }>('/candidates/sync-cvs', {
      method: 'POST',
      body: params || {},
    })
  },

  async getCvSyncStatus(): Promise<{ message: string; data: CandidateCvSyncProgress }> {
    return apiClient<{ message: string; data: CandidateCvSyncProgress }>('/candidates/sync-cvs/status')
  },

  async cancelCvSync(): Promise<{ message: string; data: CandidateCvSyncProgress }> {
    return apiClient<{ message: string; data: CandidateCvSyncProgress }>('/candidates/sync-cvs/cancel', {
      method: 'POST',
    })
  },
}
