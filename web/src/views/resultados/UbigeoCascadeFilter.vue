<script setup lang="ts">
import { catalogsService, type DepartmentItem, type ProvinceItem, type DistrictItem, type ElectionItem } from '@/api/catalogs.service'
import { useResultsStore } from '@/stores/useResultsStore'

const resultsStore = useResultsStore()

const elections = ref<ElectionItem[]>([])
const departments = ref<DepartmentItem[]>([])
const provinces = ref<ProvinceItem[]>([])
const districts = ref<DistrictItem[]>([])

const selectedElectionId = ref<number>(1)
const selectedDeptCode = ref<string | null>(null)
const selectedProvCode = ref<string | null>(null)
const selectedDistCode = ref<string | null>(null)

const loadingDepts = ref(false)
const loadingProvs = ref(false)
const loadingDists = ref(false)

onMounted(async () => {
  try {
    const [elecRes, deptRes] = await Promise.all([
      catalogsService.getElections().catch(() => ({ data: [] })),
      catalogsService.getDepartments().catch(() => ({ data: [] })),
    ])
    elections.value = elecRes.data || []
    departments.value = deptRes.data || []
  } catch (error) {
    console.error('Error cargando catálogos de ubigeo:', error)
  }
})

const onElectionChange = (val: number) => {
  selectedElectionId.value = val
  resultsStore.setFilter('election_id', val)
}

const onDeptChange = async (val: string | null) => {
  selectedDeptCode.value = val
  selectedProvCode.value = null
  selectedDistCode.value = null
  provinces.value = []
  districts.value = []

  resultsStore.setFilter('department_code', val || undefined)

  if (val) {
    loadingProvs.value = true
    try {
      const res = await catalogsService.getProvinces(val)
      provinces.value = res.data || []
    } catch (e) {
      console.error(e)
    } finally {
      loadingProvs.value = false
    }
  }
}

const onProvChange = async (val: string | null) => {
  selectedProvCode.value = val
  selectedDistCode.value = null
  districts.value = []

  resultsStore.setFilter('province_code', val || undefined)

  if (val) {
    loadingDists.value = true
    try {
      const res = await catalogsService.getDistricts(val, selectedDeptCode.value || undefined)
      districts.value = res.data || []
    } catch (e) {
      console.error(e)
    } finally {
      loadingDists.value = false
    }
  }
}

const onDistChange = (val: string | null) => {
  selectedDistCode.value = val
  resultsStore.setFilter('district_code', val || undefined)
}

const clearFilters = () => {
  selectedDeptCode.value = null
  selectedProvCode.value = null
  selectedDistCode.value = null
  provinces.value = []
  districts.value = []
  resultsStore.resetFilters()
}
</script>

<template>
  <VCard class="border mb-4" elevation="0">
    <VCardText class="pa-4">
      <VRow align="center" dense>
        <!-- Selección de Elección -->
        <VCol cols="12" md="3" sm="6">
          <VSelect
            :model-value="selectedElectionId"
            :items="elections.length ? elections : [{ id: 1, name: 'Elecciones Regionales y Municipales 2026' }]"
            item-title="name"
            item-value="id"
            label="Proceso Electoral"
            density="compact"
            variant="outlined"
            prepend-inner-icon="ri-government-line"
            @update:model-value="onElectionChange"
          />
        </VCol>

        <!-- Departamento -->
        <VCol cols="12" md="3" sm="6">
          <VAutocomplete
            v-model="selectedDeptCode"
            :items="departments"
            item-title="name"
            item-value="code"
            label="Departamento / Región"
            density="compact"
            variant="outlined"
            clearable
            placeholder="Nacional / Todo el país"
            prepend-inner-icon="ri-map-pin-line"
            :loading="loadingDepts"
            @update:model-value="onDeptChange"
          />
        </VCol>

        <!-- Provincia -->
        <VCol cols="12" md="3" sm="6">
          <VAutocomplete
            v-model="selectedProvCode"
            :items="provinces"
            item-title="name"
            item-value="code"
            label="Provincia"
            density="compact"
            variant="outlined"
            clearable
            :disabled="!selectedDeptCode"
            placeholder="Todas las provincias"
            prepend-inner-icon="ri-map-pin-2-line"
            :loading="loadingProvs"
            @update:model-value="onProvChange"
          />
        </VCol>

        <!-- Distrito -->
        <VCol cols="12" md="2" sm="6">
          <VAutocomplete
            v-model="selectedDistCode"
            :items="districts"
            item-title="name"
            item-value="code"
            label="Distrito"
            density="compact"
            variant="outlined"
            clearable
            :disabled="!selectedProvCode"
            placeholder="Todos los distritos"
            prepend-inner-icon="ri-community-line"
            :loading="loadingDists"
            @update:model-value="onDistChange"
          />
        </VCol>

        <!-- Botón Limpiar / Recargar -->
        <VCol cols="12" md="1" class="d-flex gap-x-1 justify-end">
          <VBtn
            icon="ri-filter-off-line"
            variant="tonal"
            color="secondary"
            density="comfortable"
            title="Limpiar Filtros"
            @click="clearFilters"
          />
          <VBtn
            icon="ri-refresh-line"
            variant="tonal"
            color="primary"
            density="comfortable"
            :loading="resultsStore.loading"
            title="Actualizar Datos"
            @click="resultsStore.fetchElectionResults()"
          />
        </VCol>
      </VRow>
    </VCardText>
  </VCard>
</template>
