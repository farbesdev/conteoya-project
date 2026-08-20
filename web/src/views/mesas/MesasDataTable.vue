<script setup lang="ts">
import { mesasService, type PollingStationItem } from '@/api/mesas.service'
import { useDebounceFn } from '@vueuse/core'
import DesktopDatatable from '@/components/DesktopDatatable.vue'
import MovilCardList from '@/components/MovilCardList.vue'
import MesaDetailDialog from './MesaDetailDialog.vue'
import MesaFormDialog from './MesaFormDialog.vue'

const search = ref('')
const loading = ref(false)
const mesas = ref<PollingStationItem[]>([])
const totalItems = ref(0)
const page = ref(1)
const itemsPerPage = ref(15)

// Detalle
const isDetailOpen = ref(false)
const selectedMesa = ref<PollingStationItem | null>(null)

// Formulario Crear / Editar
const isFormOpen = ref(false)
const mesaToEdit = ref<PollingStationItem | null>(null)

// Eliminar
const isDeleteDialogOpen = ref(false)
const mesaToDelete = ref<PollingStationItem | null>(null)
const deleting = ref(false)

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

const openCreateDialog = () => {
  mesaToEdit.value = null
  isFormOpen.value = true
}

const openEditDialog = (m: PollingStationItem) => {
  mesaToEdit.value = m
  isFormOpen.value = true
}

const openDetailDialog = (m: PollingStationItem) => {
  selectedMesa.value = m
  isDetailOpen.value = true
}

const confirmDelete = (m: PollingStationItem) => {
  mesaToDelete.value = m
  isDeleteDialogOpen.value = true
}

const handleDelete = async () => {
  if (!mesaToDelete.value) return
  deleting.value = true
  try {
    await mesasService.delete(mesaToDelete.value.id)
    isDeleteDialogOpen.value = false
    mesaToDelete.value = null
    await loadMesas()
  } catch (error) {
    console.error('Error eliminando mesa:', error)
  } finally {
    deleting.value = false
  }
}

onMounted(() => {
  loadMesas()
})
</script>

<template>
  <div class="d-flex flex-column gap-y-4">
    <!-- Barra Superior -->
    <VCard class="border" elevation="0">
      <VCardItem class="py-3">
        <div class="d-flex align-center justify-space-between flex-wrap gap-3">
          <div class="d-flex align-center gap-x-2">
            <VAvatar color="primary" variant="tonal" size="40">
              <VIcon icon="ri-archive-line" color="primary" size="22" />
            </VAvatar>
            <div>
              <span class="text-h6 font-weight-bold d-block">Explorador de Mesas Electorales</span>
              <span class="text-caption text-medium-emphasis">Padrón de 87,000 mesas de sufragio a nivel nacional</span>
            </div>
          </div>
          <div class="d-flex align-center gap-2 flex-wrap flex-grow-1 flex-sm-grow-0">
            <VTextField
              v-model="search"
              density="compact"
              variant="outlined"
              placeholder="Buscar por código de mesa, local o ubigeo..."
              prepend-inner-icon="ri-search-line"
              clearable
              hide-details
              style="min-width: 220px;"
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
            <VBtn
              variant="flat"
              color="primary"
              prepend-icon="ri-add-line"
              density="comfortable"
              @click="openCreateDialog"
            >
              Nueva Mesa
            </VBtn>
          </div>
        </div>
      </VCardItem>
    </VCard>

    <!-- Vista Desktop: Tabla -->
    <DesktopDatatable
      v-model:page="page"
      v-model:items-per-page="itemsPerPage"
      :headers="headers"
      :items="mesas"
      :items-length="totalItems"
      :loading="loading"
      loading-text="Cargando mesas de votación..."
      no-data-text="No se encontraron mesas de votación."
    >
      <!-- Mesa Code -->
      <template #item.code="{ item }">
        <span class="font-weight-bold text-primary cursor-pointer" @click="openDetailDialog(item)">
          Nº {{ item.code }}
        </span>
      </template>

      <!-- Local -->
      <template #item.location_name="{ item }">
        <div class="cursor-pointer" @click="openDetailDialog(item)">
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

      <!-- Acciones Completas CRUD -->
      <template #item.actions="{ item }">
        <div class="d-flex align-center justify-end gap-1">
          <VTooltip text="Ver Ficha y Actas de la Mesa" location="top">
            <template #activator="{ props: tipProps }">
              <VBtn
                v-bind="tipProps"
                size="small"
                variant="text"
                color="info"
                icon="ri-eye-line"
                @click="openDetailDialog(item)"
              />
            </template>
          </VTooltip>

          <VTooltip text="Editar Mesa" location="top">
            <template #activator="{ props: tipProps }">
              <VBtn
                v-bind="tipProps"
                size="small"
                variant="text"
                color="primary"
                icon="ri-edit-line"
                @click="openEditDialog(item)"
              />
            </template>
          </VTooltip>

          <VTooltip text="Eliminar Mesa" location="top">
            <template #activator="{ props: tipProps }">
              <VBtn
                v-bind="tipProps"
                size="small"
                variant="text"
                color="error"
                icon="ri-delete-bin-line"
                @click="confirmDelete(item)"
              />
            </template>
          </VTooltip>
        </div>
      </template>
    </DesktopDatatable>

    <!-- Vista Móvil: Tarjetas -->
    <MovilCardList
      v-model:page="page"
      :items="mesas"
      :items-length="totalItems"
      :items-per-page="itemsPerPage"
      :loading="loading"
      loading-text="Cargando mesas..."
      no-data-text="No se encontraron mesas."
    >
      <template #card="{ item }">
        <div class="d-flex justify-space-between align-start mb-2">
          <div class="d-flex align-center gap-x-2">
            <VAvatar size="34" color="primary" variant="tonal">
              <VIcon icon="ri-archive-line" size="18" />
            </VAvatar>
            <div>
              <div class="font-weight-bold text-subtitle-2 text-primary cursor-pointer" @click="openDetailDialog(item)">
                Mesa Nº {{ item.code }}
              </div>
              <div class="text-caption text-medium-emphasis">
                ODPE: {{ item.odpe || 'N/A' }}
              </div>
            </div>
          </div>
          <VChip size="x-small" color="primary" variant="tonal" class="font-weight-bold">
            {{ item.registered_voters }} electores
          </VChip>
        </div>

        <div class="bg-background pa-2 rounded mb-3 text-caption cursor-pointer" @click="openDetailDialog(item)">
          <div class="font-weight-bold text-high-emphasis mb-0.5">
            {{ item.location_name }}
          </div>
          <div class="text-medium-emphasis">
            {{ item.district_name }}, {{ item.province_name }} ({{ item.department_name }})
          </div>
          <div v-if="item.address" class="text-disabled text-truncate mt-0.5">
            {{ item.address }}
          </div>
        </div>

        <div class="d-flex justify-end align-center gap-2 pt-2 border-t">
          <VBtn
            size="small"
            variant="tonal"
            color="primary"
            prepend-icon="ri-eye-line"
            class="flex-grow-1"
            @click="openDetailDialog(item)"
          >
            Ver Actas
          </VBtn>
          <VBtn
            size="small"
            variant="text"
            color="primary"
            icon="ri-edit-line"
            @click="openEditDialog(item)"
          />
          <VBtn
            size="small"
            variant="text"
            color="error"
            icon="ri-delete-bin-line"
            @click="confirmDelete(item)"
          />
        </div>
      </template>
    </MovilCardList>

    <!-- Modal Detalle Mesa y Actas -->
    <MesaDetailDialog
      v-model="isDetailOpen"
      :mesa="selectedMesa"
    />

    <!-- Modal Crear / Editar Mesa -->
    <MesaFormDialog
      v-model="isFormOpen"
      :mesa="mesaToEdit"
      @saved="loadMesas"
    />

    <!-- Diálogo Confirmación Eliminar -->
    <VDialog v-model="isDeleteDialogOpen" max-width="450">
      <VCard class="pa-2">
        <VCardTitle class="d-flex align-center gap-x-2 text-error">
          <VIcon icon="ri-error-warning-line" />
          <span>Eliminar Mesa Electoral</span>
        </VCardTitle>
        <VCardText>
          ¿Está seguro de que desea eliminar la mesa <strong>Nº {{ mesaToDelete?.code }}</strong>?
          Esta acción desvinculará sus actas y personeros asignados.
        </VCardText>
        <VCardActions class="d-flex justify-end gap-2">
          <VBtn variant="outlined" color="secondary" :disabled="deleting" @click="isDeleteDialogOpen = false">
            Cancelar
          </VBtn>
          <VBtn variant="flat" color="error" :loading="deleting" @click="handleDelete">
            Eliminar Mesa
          </VBtn>
        </VCardActions>
      </VCard>
    </VDialog>
  </div>
</template>
