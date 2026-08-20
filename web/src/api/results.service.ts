import { apiClient } from './client'

export interface ResultsSummary {
  total_stations: number
  processed_stations: number
  pending_stations: number
  confirmed_acts_count: number
  coverage_percentage: number
  registered_voters: number
  voters_who_voted: number
  participation_percentage: number
  total_votes: number
  valid_votes: number
  blank_votes: number
  null_votes: number
  challenged_votes: number
  valid_votes_percentage: number
  blank_votes_percentage: number
  null_votes_percentage: number
  challenged_votes_percentage: number
  updated_at: string
}

export interface OrganizationResult {
  rank: number
  political_organization_id: number
  organization_name: string
  short_name: string
  logo_url?: string | null
  votes: number
  percentage_valid_votes: number
  percentage_total_votes: number
}

export interface ElectionResultsResponse {
  message: string
  election: {
    id: number
    code: string
    name: string
    date: string
  }
  data: {
    summary: ResultsSummary
    organizations: OrganizationResult[]
    non_party_votes: {
      blank_votes: number
      blank_percentage: number
      null_votes: number
      null_percentage: number
      challenged_votes: number
      challenged_pct: number
    }
    updated_at: string
  }
}

export interface FilterParams {
  election_id?: number
  electoral_level_id?: number
  department_code?: string
  province_code?: string
  district_code?: string
}

export const resultsService = {
  async getSummary(params?: FilterParams): Promise<{ data: ResultsSummary }> {
    return apiClient<{ data: ResultsSummary }>('/results/summary', {
      params,
    })
  },

  async getElectionResults(electionId: number, params?: FilterParams): Promise<ElectionResultsResponse> {
    return apiClient<ElectionResultsResponse>(`/results/elections/${electionId}`, {
      params,
    })
  },

  async getStationResults(code: string): Promise<any> {
    return apiClient<any>(`/results/polling-stations/${code}`)
  },
}
