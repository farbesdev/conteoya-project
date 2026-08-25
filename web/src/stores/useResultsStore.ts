import { defineStore } from 'pinia'
import {
  resultsService,
  type ResultsSummary,
  type OrganizationResult,
  type FilterParams,
} from '@/api/results.service'

export const useResultsStore = defineStore('results', () => {
  const summary = ref<ResultsSummary | null>(null)
  const organizations = ref<OrganizationResult[]>([])
  const nonPartyVotes = ref({
    blank_votes: 0,
    blank_percentage: 0,
    null_votes: 0,
    null_percentage: 0,
    challenged_votes: 0,
    challenged_pct: 0,
  })
  const currentElection = ref<{ id: number; code: string; name: string; date: string } | null>(null)
  const filters = ref<FilterParams>({
    election_id: 1,
    electoral_level_id: 1,
    department_code: undefined,
    province_code: undefined,
    district_code: undefined,
  })
  const loading = ref(false)
  const lastUpdated = ref<string>(new Date().toISOString())

  const fetchSummary = async () => {
    try {
      const res = await resultsService.getSummary(filters.value)
      summary.value = res.data
      lastUpdated.value = res.data.updated_at
    } catch (error) {
      console.error('Error cargando resumen:', error)
    }
  }

  const fetchElectionResults = async (electionId = filters.value.election_id || 1) => {
    loading.value = true
    try {
      const res = await resultsService.getElectionResults(electionId, filters.value)
      currentElection.value = res.election
      summary.value = res.data.summary
      organizations.value = res.data.organizations
      nonPartyVotes.value = res.data.non_party_votes
      lastUpdated.value = res.data.updated_at
    } catch (error) {
      console.error('Error cargando resultados por elección:', error)
    } finally {
      loading.value = false
    }
  }

  const setFilter = (key: keyof FilterParams, value: any) => {
    filters.value[key] = value
    if (key === 'department_code') {
      filters.value.province_code = undefined
      filters.value.district_code = undefined
    } else if (key === 'province_code') {
      filters.value.district_code = undefined
    }
    fetchElectionResults()
  }

  const resetFilters = () => {
    filters.value = {
      election_id: 1,
      electoral_level_id: 1,
      department_code: undefined,
      province_code: undefined,
      district_code: undefined,
    }
    fetchElectionResults()
  }

  return {
    summary,
    organizations,
    nonPartyVotes,
    currentElection,
    filters,
    loading,
    lastUpdated,
    fetchSummary,
    fetchElectionResults,
    setFilter,
    resetFilters,
  }
})
