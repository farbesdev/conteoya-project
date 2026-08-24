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

export interface CandidateJsonImportProgress {
  status: 'idle' | 'running' | 'completed' | 'canceled' | 'failed'
  file_name?: string | null
  total: number
  processed: number
  new_candidates: number
  updated_candidates: number
  new_lists: number
  percentage: number
  last_candidate_name?: string
  error_message?: string
  started_at?: string | null
  updated_at?: string | null
}

export const candidatesService = {
  async list(params?: { search?: string; status?: string; page?: number; per_page?: number }): Promise<PaginatedResponse<CandidateItem>> {
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

  async createFormData(formData: FormData): Promise<{ message: string; data: CandidateItem }> {
    return apiClient<{ message: string; data: CandidateItem }>('/candidates', {
      method: 'POST',
      body: formData,
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

  async updateFormData(id: number, formData: FormData): Promise<{ message: string; data: CandidateItem }> {
    return apiClient<{ message: string; data: CandidateItem }>(`/candidates/${id}`, {
      method: 'POST',
      body: formData,
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

  async getCv(candidateId: number): Promise<{ message: string; candidate: CandidateItem; data: any }> {
    return apiClient<{ message: string; candidate: CandidateItem; data: any }>(`/candidates/${candidateId}/cv`)
  },

  async updateCv(candidateId: number, data: any): Promise<{ message: string; data: any }> {
    return apiClient<{ message: string; data: any }>(`/candidates/${candidateId}/cv`, {
      method: 'PUT',
      body: data,
    })
  },

  uploadJson(file: File, onProgress?: (percent: number) => void): Promise<{ message: string; data: CandidateJsonImportProgress }> {
    return new Promise((resolve, reject) => {
      const xhr = new XMLHttpRequest()
      const baseUrl = import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000/api/v1'
      xhr.open('POST', `${baseUrl}/candidates/import-json`)
      xhr.setRequestHeader('Accept', 'application/json')
      const token = useCookie<string | null>('accessToken').value
      if (token) {
        xhr.setRequestHeader('Authorization', `Bearer ${token}`)
      }
      xhr.upload.onprogress = (event) => {
        if (event.lengthComputable && onProgress) {
          const percent = Math.round((event.loaded / event.total) * 100)
          onProgress(percent)
        }
      }
      xhr.onload = () => {
        if (xhr.status >= 200 && xhr.status < 300) {
          try {
            resolve(JSON.parse(xhr.responseText))
          } catch {
            resolve({ message: 'Importación iniciada', data: {} as any })
          }
        } else {
          try {
            const err = JSON.parse(xhr.responseText)
            reject(err)
          } catch {
            reject(new Error(`Error en la subida (${xhr.status})`))
          }
        }
      }
      xhr.onerror = () => reject(new Error('Error de conexión al subir el archivo.'))
      const formData = new FormData()
      formData.append('file', file)
      xhr.send(formData)
    })
  },

  async getImportStatus(): Promise<{ message: string; data: CandidateJsonImportProgress }> {
    return apiClient<{ message: string; data: CandidateJsonImportProgress }>('/candidates/import-json/status')
  },

  async cancelImport(): Promise<{ message: string; data: CandidateJsonImportProgress }> {
    return apiClient<{ message: string; data: CandidateJsonImportProgress }>('/candidates/import-json/cancel', {
      method: 'POST',
    })
  },
}
