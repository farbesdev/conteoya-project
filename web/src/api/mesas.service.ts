import { apiClient } from './client'
import type { PaginatedResponse } from './personeros.service'

export interface PollingStationItem {
  id: number
  code: string
  location_name: string
  address?: string | null
  district_code?: string
  district_name?: string
  province_name?: string
  department_name?: string
  odpe?: string
  registered_voters: number
  status: string
}

export interface MesasFilterParams {
  search?: string
  department_name?: string
  province_name?: string
  district_name?: string
  page?: number
  per_page?: number
}

export const mesasService = {
  async list(params?: MesasFilterParams): Promise<PaginatedResponse<PollingStationItem>> {
    return apiClient<PaginatedResponse<PollingStationItem>>('/polling-stations', {
      params,
    })
  },

  async getById(id: number): Promise<{ message: string; data: PollingStationItem }> {
    return apiClient<{ message: string; data: PollingStationItem }>(`/polling-stations/${id}`)
  },

  async create(data: {
    code: string
    registered_voters: number
    status?: string
    location_name?: string
    address?: string
    department_name?: string
    province_name?: string
    district_name?: string
    odpe?: string
  }): Promise<{ message: string; data: PollingStationItem }> {
    return apiClient<{ message: string; data: PollingStationItem }>('/polling-stations', {
      method: 'POST',
      body: data,
    })
  },

  async update(id: number, data: {
    code?: string
    registered_voters?: number
    status?: string
    location_name?: string
    address?: string
    department_name?: string
    province_name?: string
    district_name?: string
    odpe?: string
  }): Promise<{ message: string; data: PollingStationItem }> {
    return apiClient<{ message: string; data: PollingStationItem }>(`/polling-stations/${id}`, {
      method: 'PUT',
      body: data,
    })
  },

  async delete(id: number): Promise<{ message: string }> {
    return apiClient<{ message: string }>(`/polling-stations/${id}`, {
      method: 'DELETE',
    })
  },
}
