import { apiClient } from './client'

export interface DepartmentItem {
  id: number
  code: string
  name: string
}

export interface ProvinceItem {
  id: number
  code: string
  name: string
  department_code: string
}

export interface DistrictItem {
  id: number
  code: string
  name: string
  province_code: string
  department_code: string
}

export interface ElectionItem {
  id: number
  code: string
  name: string
  date: string
  status: string
  levels?: Array<{
    id: number
    code: string
    name: string
    has_preferential_vote: boolean
  }>
}

export interface PoliticalOrgItem {
  id: number
  name: string
  short_name?: string
  logo_url?: string
  status?: string
}

export const catalogsService = {
  async getDepartments(): Promise<{ data: DepartmentItem[] }> {
    return apiClient<{ data: DepartmentItem[] }>('/departments')
  },

  async getProvinces(departmentCode?: string): Promise<{ data: ProvinceItem[] }> {
    return apiClient<{ data: ProvinceItem[] }>('/provinces', {
      params: departmentCode ? { department_code: departmentCode } : undefined,
    })
  },

  async getDistricts(provinceCode?: string, departmentCode?: string): Promise<{ data: DistrictItem[] }> {
    return apiClient<{ data: DistrictItem[] }>('/districts', {
      params: {
        province_code: provinceCode,
        department_code: departmentCode,
      },
    })
  },

  async getElections(): Promise<{ data: ElectionItem[] }> {
    return apiClient<{ data: ElectionItem[] }>('/elections')
  },

  async getPoliticalOrganizations(): Promise<{ data: PoliticalOrgItem[] }> {
    return apiClient<{ data: PoliticalOrgItem[] }>('/political-organizations')
  },
}
