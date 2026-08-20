<script setup lang="ts">
import { mesasService, type PollingStationItem } from '@/api/mesas.service'
import MesaDetailDialog from './MesaDetailDialog.vue'

const search = ref('')
const loading = ref(false)
const mesas = ref<PollingStationItem[]>([])
const totalItems = ref(0)
const page = ref(1)
const itemsPerPage = ref(15)

const isDialogOpen = ref(false)
const selectedMesa = ref<PollingStationItem | null>(null)

const headers = [
  { title: 'Mesa', key: 'code', sortable: false },
  { title: 'Local de Votación', key: 'location_name', sortable: false },
  { title: 'Distrito', key: 'district_name', sortable: false },
  { title: 'Provincia', key: 'province_name', sortable: false },
  { title: 'Departamento', key: 'department_name', sortable: false },
  { title: 'ODPE', key: 'odpe', sortable: false },
  { title: 'Electores', key: 'registered_voters', sortable: false },
  { title: 'Acciones', key: 'actions', sortable: false, align: 'end' as const },
]

const loadMesas = async () => {
  loading.value = true
  try {
    const res = await mesasService.list({
      search: search.value || undefined,
      page: page.value,
      per_page: itemsPerPage.value,
    })
    mesas.value = res.data
    totalItems.value = res.meta.total
  } catch (error) {
    console.error('Error cargando mesas:', error)
  } finally {
    loading.value = false
  }
}

watch([page, itemsPerPage], () => {
  loadMesas()
})

const onSearchInput = useDebounceFn(() => {
  page.value = 1
  loadMesas()
}, 400)

const openDetailDialog = (m: PollingStationItem) => {
  selectedMesa.value = m
  isDialogOpen.value = true
}

onMounted(() => {
  loadMesas()
})
</script>

<template>
  <div>
    <VCard class="border" elevation="0">
      <VCardItem class="pb-2">
        <template #title>
          <div class="d-flex align-center justify-space-between flex-wrap gap-2">
            <div class="d-flex align-center gap-x-2">
              <VIcon icon="ri-archive-line" color="primary" />
              <span class="text-h6 font-weight-bold">Explorador de Mesas Electorales (87,000 Mesas)</span>
            </div>
            <div class="d-flex align-center gap-x-2">
              <VTextField
                v-model="search"
                density="compact"
                variant="outlined"
                placeholder="Buscar por código de mesa, local o ubigeo..."
                prepend-inner-icon="ri-search-line"
                style="min-width: 320px;"
                clearable
                @update:model-value="onSearchInput"
                @click:clear="loadMesas"
              />
              <VBtn
                icon="ri-refresh-line"
                variant="tonal"
                color="secondary"
                density="comfortable"
                :loading="loading"
                @click="loadMesas"
              />
            </div>
          </div>
        </template>
      </VCardItem>

      <VDivider />

      <VDataTableServer
        v-model:items-per-page="itemsPerPage"
        v-model:page="page"
        :headers="headers"
        :items="mesas"
        :items-length="totalItems"
        :loading="loading"
        density="comfortable"
        class="text-no-wrap"
      >
        <!-- Mesa Code -->
        <template #item.code="{ item }">
          <span class="font-weight-bold text-primary">Nº {{ item.code }}</span>
        </template>

        <!-- Local -->
        <template #item.location_name="{ item }">
          <div>
            <div class="font-weight-medium text-high-emphasis">{{ item.location_name }}</div>
            <div class="text-caption text-medium-emphasis">{{ item.address || '—' }}</div>
          </div>
        </template>

        <!-- Electores -->
        <template #item.registered_voters="{ item }">
          <VChip size="small" color="primary" variant="tonal" class="font-weight-bold">
            {{ item.registered_voters }} electores
          </VChip>
        </template>

        <!-- Acciones -->
        <template #item.actions="{ item }">
          <VBtn
            size="small"
            variant="tonal"
            color="primary"
            prepend-icon="ri-eye-line"
            @click="openDetailDialog(item)"
          >
            Ver Actas
          </VBtn>
        </template>
      </VDataTableServer>
    </VCard>

    <MesaDetailDialog
      v-model="isDialogOpen"
      :mesa="selectedMesa"
    />
  </div>
</template>
