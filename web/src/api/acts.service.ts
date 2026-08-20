import { apiClient } from './client'
import type { PaginatedResponse } from './personeros.service'

export interface ActItem {
  id: number
  act_code?: string | null
  election_id: number
  electoral_level_id: number
  polling_station_id: number
  status: 'DRAFT' | 'CONFIRMED' | 'SYNCED' | 'OBSERVED'
  captured_at?: string | null
  confirmed_at?: string | null
  polling_station?: {
    id: number
    code: string
    department_name?: string
    province_name?: string
    district_name?: string
  }
  totals?: {
    registered_voters: number
    voters_who_voted: number
    total_votes: number
    blank_votes: number
    null_votes: number
    challenged_votes: number
    is_valid_total: boolean
  }
  results?: Array<{
    political_organization_id?: number
    political_organization?: {
      id: number
      name: string
      short_name: string
      logo_url?: string
    }
    votes: number
    source: string
    confidence?: number | null
  }>
  evidences?: Array<{
    id: number
    evidence_type: string
    file_path: string
    file_hash: string
    status: string
    created_at?: string
  }>
  captured_by_personero?: {
    id: number
    document_number: string
    user?: {
      name: string
      email: string
    }
  }
}

export interface ActsFilterParams {
  search?: string
  status?: string
  election_id?: number
  page?: number
  per_page?: number
}

export const actsService = {
  async list(params?: ActsFilterParams): Promise<PaginatedResponse<ActItem>> {
    return apiClient<PaginatedResponse<ActItem>>('/acts', {
      params,
    })
  },

  async getById(id: number): Promise<{ data: ActItem }> {
    return apiClient<{ data: ActItem }>(`/acts/${id}`)
  },

  async confirm(id: number): Promise<{ message: string; data: ActItem }> {
    return apiClient<{ message: string; data: ActItem }>(`/acts/${id}/confirm`, {
      method: 'POST',
    })
  },

  async getDownloadUrl(actId: number, evidenceId: number): Promise<{ download_url: string }> {
    return apiClient<{ download_url: string }>(`/acts/${actId}/evidence/${evidenceId}/download`)
  },
}
