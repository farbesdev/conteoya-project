import { apiClient } from './client'

export interface PersoneroItem {
  id: number
  document_number: string
  first_name?: string | null
  last_name_paternal?: string | null
  last_name_maternal?: string | null
  full_name?: string
  phone_number?: string | null
  political_org_name?: string | null
  user_id?: number | null
  is_active?: boolean
  assigned_polling_stations?: any[]
  polling_stations_count?: number
}

export interface PaginatedResponse<T> {
  message: string
  data: T[]
  meta: {
    current_page: number
    last_page: number
    per_page: number
    total: number
    has_more: boolean
  }
}

export const personerosService = {
  async list(params?: { search?: string; page?: number; per_page?: number }): Promise<PaginatedResponse<PersoneroItem>> {
    return apiClient<PaginatedResponse<PersoneroItem>>('/personeros', {
      params,
    })
  },

  async assignPollingStations(personeroId: number, pollingStationIds: number[]): Promise<{ message: string }> {
    return apiClient<{ message: string }>(`/personeros/${personeroId}/polling-stations`, {
      method: 'POST',
      body: { polling_station_ids: pollingStationIds },
    })
  },

  async toggleAccess(personeroId: number): Promise<{ message: string; is_active: boolean }> {
    return apiClient<{ message: string; is_active: boolean }>(`/personeros/${personeroId}/toggle-access`, {
      method: 'PATCH',
    })
  },
}
