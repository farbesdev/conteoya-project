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
    const res = await apiClient<DepartmentItem[] | { data: DepartmentItem[] }>('/departments')
    const list = Array.isArray(res) ? res : (res?.data || [])
    return { data: list }
  },

  async getProvinces(departmentCode?: string): Promise<{ data: ProvinceItem[] }> {
    const res = await apiClient<ProvinceItem[] | { data: ProvinceItem[] }>('/provinces', {
      params: departmentCode ? { department_code: departmentCode } : undefined,
    })
    const list = Array.isArray(res) ? res : (res?.data || [])
    return { data: list }
  },

  async getDistricts(provinceCode?: string, departmentCode?: string): Promise<{ data: DistrictItem[] }> {
    const res = await apiClient<DistrictItem[] | { data: DistrictItem[] }>('/districts', {
      params: {
        province_code: provinceCode,
        department_code: departmentCode,
      },
    })
    const list = Array.isArray(res) ? res : (res?.data || [])
    return { data: list }
  },

  async getElections(): Promise<{ data: ElectionItem[] }> {
    const res = await apiClient<ElectionItem[] | { data: ElectionItem[] }>('/elections')
    const list = Array.isArray(res) ? res : (res?.data || [])
    return { data: list }
  },

  async getPoliticalOrganizations(search?: string): Promise<{ data: PoliticalOrgItem[] }> {
    const res = await apiClient<PoliticalOrgItem[] | { data: PoliticalOrgItem[] }>('/political-organizations', {
      params: search ? { search } : undefined,
    })
    const list = Array.isArray(res) ? res : (res?.data || [])
    return { data: list }
  },
}
