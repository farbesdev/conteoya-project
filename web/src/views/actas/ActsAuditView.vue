<script setup lang="ts">
import { actsService, type ActItem } from '@/api/acts.service'
import { useDebounceFn } from '@vueuse/core'
import DesktopDatatable from '@/components/DesktopDatatable.vue'
import MovilCardList from '@/components/MovilCardList.vue'
import ActOcrComparison from './ActOcrComparison.vue'
import ActFormDialog from './ActFormDialog.vue'
import ActEditDialog from './ActEditDialog.vue'

const search = ref('')
const selectedStatus = ref<string | null>(null)
const loading = ref(false)
const acts = ref<ActItem[]>([])
const totalItems = ref(0)
const page = ref(1)
const itemsPerPage = ref(15)

// Modal Auditoría / Detalle
const isDetailOpen = ref(false)
const selectedAct = ref<ActItem | null>(null)
const loadingDetail = ref(false)
const evidenceDownloadUrl = ref<string | null>(null)

// Modal Crear Acta
const isCreateOpen = ref(false)

// Modal Editar Acta
const isEditOpen = ref(false)
const actToEdit = ref<ActItem | null>(null)

// Modal Eliminar Acta
const isDeleteDialogOpen = ref(false)
const actToDelete = ref<ActItem | null>(null)
const deleting = ref(false)

const headers = [
  { title: 'Acta ID', key: 'id', sortable: false },
  { title: 'Código de Acta', key: 'act_code', sortable: false },
  { title: 'Mesa', key: 'polling_station', sortable: false },
  { title: 'Ubicación', key: 'location', sortable: false },
  { title: 'Votos Emitidos', key: 'total_votes', sortable: false },
  { title: 'Evidencias R2', key: 'evidences', sortable: false },
  { title: 'Estado', key: 'status', sortable: false },
  { title: 'Acciones', key: 'actions', sortable: false, align: 'end' as const },
]

const loadActs = async () => {
  loading.value = true
  try {
    const res = await actsService.list({
      search: search.value || undefined,
      status: selectedStatus.value || undefined,
      page: page.value,
      per_page: itemsPerPage.value,
    })
    acts.value = res.data
    totalItems.value = res.meta.total
  } catch (error) {
    console.error('Error cargando actas:', error)
  } finally {
    loading.value = false
  }
}

watch([page, itemsPerPage, selectedStatus], () => {
  loadActs()
})

const onSearchInput = useDebounceFn(() => {
  page.value = 1
  loadActs()
}, 400)

const openActDetail = async (act: ActItem) => {
  loadingDetail.value = true
  selectedAct.value = act
  isDetailOpen.value = true
  evidenceDownloadUrl.value = null

  try {
    const res = await actsService.getById(act.id)
    selectedAct.value = res.data

    if (res.data.evidences && res.data.evidences.length > 0) {
      const ev = res.data.evidences[0]
      const urlRes = await actsService.getDownloadUrl(act.id, ev.id).catch(() => null)
      if (urlRes?.download_url) {
        evidenceDownloadUrl.value = urlRes.download_url
      }
    }
  } catch (e) {
    console.error(e)
  } finally {
    loadingDetail.value = false
  }
}

const openEditDialog = (act: ActItem) => {
  actToEdit.value = act
  isEditOpen.value = true
}

const confirmDelete = (act: ActItem) => {
  actToDelete.value = act
  isDeleteDialogOpen.value = true
}

const handleDelete = async () => {
  if (!actToDelete.value) return
  deleting.value = true
  try {
    await actsService.delete(actToDelete.value.id)
    isDeleteDialogOpen.value = false
    actToDelete.value = null
    await loadActs()
  } catch (error) {
    console.error('Error al eliminar acta:', error)
  } finally {
    deleting.value = false
  }
}

const confirmAct = async (actId: number) => {
  try {
    await actsService.confirm(actId)
    await loadActs()
    if (selectedAct.value && selectedAct.value.id === actId) {
      selectedAct.value.status = 'CONFIRMED'
    }
  } catch (e) {
    console.error(e)
  }
}

onMounted(() => {
  loadActs()
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
              <VIcon icon="ri-file-shield-line" color="primary" size="22" />
            </VAvatar>
            <div>
              <span class="text-h6 font-weight-bold d-block">Auditoría y Revisión de Actas Electorales</span>
              <span class="text-caption text-medium-emphasis">Control de calidad, digitalización y verificación OCR/R2</span>
            </div>
          </div>
          <div class="d-flex align-center gap-2 flex-wrap flex-grow-1 flex-sm-grow-0">
            <VSelect
              v-model="selectedStatus"
              :items="[
                { title: 'Todos los estados', value: null },
                { title: 'CONFIRMED', value: 'CONFIRMED' },
                { title: 'DRAFT', value: 'DRAFT' },
                { title: 'SYNCED', value: 'SYNCED' },
                { title: 'OBSERVED', value: 'OBSERVED' },
              ]"
              density="compact"
              variant="outlined"
              style="min-width: 150px;"
              hide-details
            />
            <VTextField
              v-model="search"
              density="compact"
              variant="outlined"
              placeholder="Buscar por acta o mesa..."
              prepend-inner-icon="ri-search-line"
              style="min-width: 200px;"
              clearable
              hide-details
              @update:model-value="onSearchInput"
              @click:clear="loadActs"
            />
            <VBtn
              icon="ri-refresh-line"
              variant="tonal"
              color="secondary"
              density="comfortable"
              :loading="loading"
              @click="loadActs"
            />
            <VBtn
              variant="flat"
              color="primary"
              prepend-icon="ri-file-add-line"
              density="comfortable"
              @click="isCreateOpen = true"
            >
              Registrar Acta
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
      :items="acts"
      :items-length="totalItems"
      :loading="loading"
      loading-text="Cargando actas electorales..."
      no-data-text="No se encontraron actas registradas."
    >
      <!-- ID -->
      <template #item.id="{ item }">
        <span class="font-weight-bold cursor-pointer" @click="openActDetail(item)">#{{ item.id }}</span>
      </template>

      <!-- Código de Acta -->
      <template #item.act_code="{ item }">
        <span class="text-primary font-weight-medium cursor-pointer" @click="openActDetail(item)">
          {{ item.act_code || 'S/N' }}
        </span>
      </template>

      <!-- Mesa -->
      <template #item.polling_station="{ item }">
        <VChip size="small" color="primary" variant="tonal" class="font-weight-bold">
          Mesa {{ item.polling_station?.code || item.polling_station_id }}
        </VChip>
      </template>

      <!-- Ubicación -->
      <template #item.location="{ item }">
        <span class="text-body-2 text-medium-emphasis">
          {{ item.polling_station?.district_name || 'Distrito' }}, {{ item.polling_station?.department_name || 'Región' }}
        </span>
      </template>

      <!-- Votos Totales -->
      <template #item.total_votes="{ item }">
        <span class="font-weight-bold">{{ item.totals?.total_votes ?? '—' }}</span>
      </template>

      <!-- Evidencias -->
      <template #item.evidences="{ item }">
        <div class="d-flex align-center gap-x-1">
          <VIcon
            :icon="item.evidences?.length ? 'ri-image-2-line' : 'ri-image-line'"
            :color="item.evidences?.length ? 'success' : 'disabled'"
            size="18"
          />
          <span class="text-caption">{{ item.evidences?.length || 0 }} fotos</span>
        </div>
      </template>

      <!-- Estado -->
      <template #item.status="{ item }">
        <VChip
          size="x-small"
          :color="item.status === 'CONFIRMED' || item.status === 'SYNCED' ? 'success' : (item.status === 'OBSERVED' ? 'error' : 'warning')"
          variant="tonal"
          class="font-weight-bold"
        >
          {{ item.status }}
        </VChip>
      </template>

      <!-- Acciones Completas CRUD -->
      <template #item.actions="{ item }">
        <div class="d-flex align-center justify-end gap-1">
          <VTooltip text="Auditar y Ver Evidencia R2" location="top">
            <template #activator="{ props: tipProps }">
              <VBtn
                v-bind="tipProps"
                size="small"
                variant="tonal"
                color="primary"
                prepend-icon="ri-scan-2-line"
                @click="openActDetail(item)"
              >
                Revisar
              </VBtn>
            </template>
          </VTooltip>

          <VTooltip text="Editar Acta" location="top">
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

          <VTooltip text="Eliminar Acta" location="top">
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
      :items="acts"
      :items-length="totalItems"
      :items-per-page="itemsPerPage"
      :loading="loading"
      loading-text="Cargando actas..."
      no-data-text="No se encontraron actas."
    >
      <template #card="{ item }">
        <div class="d-flex justify-space-between align-start mb-2">
          <div>
            <div class="d-flex align-center gap-x-2">
              <span class="font-weight-bold text-subtitle-2 text-primary cursor-pointer" @click="openActDetail(item)">
                Acta Nº {{ item.act_code || `#${item.id}` }}
              </span>
              <VChip size="x-small" color="primary" variant="tonal" class="font-weight-bold">
                Mesa {{ item.polling_station?.code || item.polling_station_id }}
              </VChip>
            </div>
            <div class="text-caption text-medium-emphasis">
              {{ item.polling_station?.district_name }}, {{ item.polling_station?.department_name }}
            </div>
          </div>
          <VChip
            size="x-small"
            :color="item.status === 'CONFIRMED' || item.status === 'SYNCED' ? 'success' : (item.status === 'OBSERVED' ? 'error' : 'warning')"
            variant="tonal"
            class="font-weight-bold"
          >
            {{ item.status }}
          </VChip>
        </div>

        <div class="d-flex justify-space-between align-center bg-background pa-2 rounded mb-3 text-caption">
          <div>
            <span class="text-medium-emphasis">Total Votos:</span>
            <strong class="ms-1">{{ item.totals?.total_votes ?? '0' }}</strong>
          </div>
          <div class="d-flex align-center gap-1">
            <VIcon icon="ri-image-2-line" size="14" :color="item.evidences?.length ? 'success' : 'disabled'" />
            <span>{{ item.evidences?.length || 0 }} fotos R2</span>
          </div>
        </div>

        <div class="d-flex justify-end align-center gap-2 pt-2 border-t">
          <VBtn
            size="small"
            variant="tonal"
            color="primary"
            prepend-icon="ri-scan-2-line"
            class="flex-grow-1"
            @click="openActDetail(item)"
          >
            Auditar
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

    <!-- Modal Registrar Acta -->
    <ActFormDialog
      v-model="isCreateOpen"
      @saved="loadActs"
    />

    <!-- Modal Editar Acta -->
    <ActEditDialog
      v-model="isEditOpen"
      :act="actToEdit"
      @saved="loadActs"
    />

    <!-- Diálogo Eliminar Acta -->
    <VDialog v-model="isDeleteDialogOpen" max-width="450">
      <VCard class="pa-2">
        <VCardTitle class="d-flex align-center gap-x-2 text-error">
          <VIcon icon="ri-error-warning-line" />
          <span>Eliminar Acta Electoral</span>
        </VCardTitle>
        <VCardText>
          ¿Está seguro de que desea eliminar el acta <strong>Nº {{ actToDelete?.act_code || `#${actToDelete?.id}` }}</strong>?
          Esta acción eliminará sus totales, resultados por partido y evidencias fotográficas vinculadas.
        </VCardText>
        <VCardActions class="d-flex justify-end gap-2">
          <VBtn variant="outlined" color="secondary" :disabled="deleting" @click="isDeleteDialogOpen = false">
            Cancelar
          </VBtn>
          <VBtn variant="flat" color="error" :loading="deleting" @click="handleDelete">
            Eliminar Acta
          </VBtn>
        </VCardActions>
      </VCard>
    </VDialog>

    <!-- Modal de Revisión y Auditoría con Visor R2 y Comparativa OCR -->
    <VDialog v-model="isDetailOpen" max-width="1000">
      <VCard v-if="selectedAct">
        <VCardTitle class="d-flex justify-space-between align-center pa-4 border-b">
          <div class="d-flex align-center gap-x-2">
            <VIcon icon="ri-file-shield-line" color="primary" />
            <span class="text-h6 font-weight-bold">
              Auditoría de Acta Nº {{ selectedAct.act_code || selectedAct.id }} (Mesa {{ selectedAct.polling_station?.code }})
            </span>
          </div>
          <VBtn icon="ri-close-line" variant="text" density="compact" @click="isDetailOpen = false" />
        </VCardTitle>

        <VCardText class="pa-4">
          <VRow>
            <!-- Visor de Fotografía R2 -->
            <VCol cols="12" md="6">
              <h4 class="text-subtitle-2 font-weight-bold mb-2 d-flex align-center gap-x-1">
                <VIcon icon="ri-image-line" size="18" /> Fotografía de Evidencia (Cloudflare R2)
              </h4>

              <div class="border rounded pa-2 d-flex align-center justify-center bg-grey-900" style="min-height: 350px;">
                <VImg
                  v-if="evidenceDownloadUrl"
                  :src="evidenceDownloadUrl"
                  cover
                  class="rounded max-h-96"
                />
                <div v-else class="text-center text-medium-emphasis py-12">
                  <VIcon icon="ri-image-line" size="48" class="mb-2" />
                  <p class="text-caption mb-0">No hay fotografía cargada o procesando URL...</p>
                </div>
              </div>
            </VCol>

            <!-- Comparativa OCR y Totales -->
            <VCol cols="12" md="6">
              <h4 class="text-subtitle-2 font-weight-bold mb-2 d-flex align-center gap-x-1">
                <VIcon icon="ri-cpu-line" size="18" /> Validación OCR y Sumas
              </h4>

              <!-- Totales -->
              <div class="pa-3 rounded border bg-background mb-4 text-body-2">
                <div class="d-flex justify-space-between mb-1">
                  <span>Votos Emitidos:</span>
                  <strong>{{ selectedAct.totals?.total_votes ?? 0 }}</strong>
                </div>
                <div class="d-flex justify-space-between mb-1">
                  <span>Votantes que votaron:</span>
                  <span>{{ selectedAct.totals?.voters_who_voted ?? 0 }}</span>
                </div>
                <div class="d-flex justify-space-between mb-1 text-caption text-medium-emphasis">
                  <span>Blancos / Nulos / Impugnados:</span>
                  <span>{{ selectedAct.totals?.blank_votes ?? 0 }} / {{ selectedAct.totals?.null_votes ?? 0 }} / {{ selectedAct.totals?.challenged_votes ?? 0 }}</span>
                </div>
              </div>

              <!-- Comparativa OCR por Lista -->
              <ActOcrComparison :act="selectedAct" />
            </VCol>
          </VRow>
        </VCardText>

        <VCardActions class="pa-4 border-t d-flex justify-end gap-x-2">
          <VBtn variant="outlined" color="secondary" @click="isDetailOpen = false">
            Cerrar
          </VBtn>
          <VBtn
            v-if="selectedAct.status !== 'CONFIRMED'"
            variant="flat"
            color="success"
            prepend-icon="ri-check-line"
            @click="confirmAct(selectedAct.id)"
          >
            Aprobar y Confirmar Acta
          </VBtn>
        </VCardActions>
      </VCard>
    </VDialog>
  </div>
</template>
