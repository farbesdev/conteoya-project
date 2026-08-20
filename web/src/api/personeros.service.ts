import { apiClient } from './client'

export interface PersoneroItem {
  id: number
  document_number: string
  dni?: string
  first_name?: string | null
  last_name_paternal?: string | null
  last_name_maternal?: string | null
  full_name?: string
  phone_number?: string | null
  political_org_name?: string | null
  political_organization_name?: string | null
  political_org_logo?: string | null
  political_org_short_name?: string | null
  email?: string | null
  user_id?: number | null
  is_active?: boolean
  personero_type?: string | null
  abogado_responsable?: string | null
  jee_name?: string | null
  department_name?: string | null
  province_name?: string | null
  district_name?: string | null
  assigned_polling_stations?: any[]
  polling_stations_count?: number
  polling_station_codes?: string[]
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

  async getById(id: number | string): Promise<{ message: string; data: PersoneroItem }> {
    return apiClient<{ message: string; data: PersoneroItem }>(`/personeros/${id}`)
  },

  async create(data: {
    document_number: string
    first_name?: string
    last_name?: string
    name?: string
    email?: string
    phone_number?: string
    political_organization_id?: number | null
    political_org_name?: string
    abogado_responsable?: string
    polling_station_ids?: number[]
  }): Promise<{ message: string; data: PersoneroItem }> {
    return apiClient<{ message: string; data: PersoneroItem }>('/personeros', {
      method: 'POST',
      body: data,
    })
  },

  async update(id: number | string, data: {
    first_name?: string
    last_name?: string
    name?: string
    email?: string
    phone_number?: string
    political_organization_id?: number | null
    political_org_name?: string
    abogado_responsable?: string
    polling_station_ids?: number[]
    is_active?: boolean
  }): Promise<{ message: string; data: PersoneroItem }> {
    return apiClient<{ message: string; data: PersoneroItem }>(`/personeros/${id}`, {
      method: 'PUT',
      body: data,
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

  async delete(personeroId: number): Promise<{ message: string }> {
    return apiClient<{ message: string }>(`/personeros/${personeroId}`, {
      method: 'DELETE',
    })
  },
}
