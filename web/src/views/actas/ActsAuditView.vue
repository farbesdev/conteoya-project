<script setup lang="ts">
import { actsService, type ActItem } from '@/api/acts.service'
import ActOcrComparison from './ActOcrComparison.vue'

const search = ref('')
const selectedStatus = ref<string | null>(null)
const loading = ref(false)
const acts = ref<ActItem[]>([])
const totalItems = ref(0)
const page = ref(1)
const itemsPerPage = ref(15)

const isDetailOpen = ref(false)
const selectedAct = ref<ActItem | null>(null)
const loadingDetail = ref(false)
const evidenceDownloadUrl = ref<string | null>(null)

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
  <div>
    <VCard class="border" elevation="0">
      <VCardItem class="pb-2">
        <template #title>
          <div class="d-flex align-center justify-space-between flex-wrap gap-2">
            <div class="d-flex align-center gap-x-2">
              <VIcon icon="ri-file-shield-line" color="primary" />
              <span class="text-h6 font-weight-bold">Auditoría y Revisión de Actas Electorales</span>
            </div>
            <div class="d-flex align-center gap-x-2 flex-wrap">
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
                style="min-width: 170px;"
              />
              <VTextField
                v-model="search"
                density="compact"
                variant="outlined"
                placeholder="Buscar por acta o mesa..."
                prepend-inner-icon="ri-search-line"
                style="min-width: 250px;"
                clearable
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
            </div>
          </div>
        </template>
      </VCardItem>

      <VDivider />

      <VDataTableServer
        v-model:items-per-page="itemsPerPage"
        v-model:page="page"
        :headers="headers"
        :items="acts"
        :items-length="totalItems"
        :loading="loading"
        density="comfortable"
        class="text-no-wrap"
      >
        <!-- ID -->
        <template #item.id="{ item }">
          <span class="font-weight-bold">#{{ item.id }}</span>
        </template>

        <!-- Código de Acta -->
        <template #item.act_code="{ item }">
          <span class="text-primary font-weight-medium">{{ item.act_code || 'S/N' }}</span>
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

        <!-- Acciones -->
        <template #item.actions="{ item }">
          <VBtn
            size="small"
            variant="tonal"
            color="primary"
            prepend-icon="ri-scan-2-line"
            @click="openActDetail(item)"
          >
            Revisar
          </VBtn>
        </template>
      </VDataTableServer>
    </VCard>

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
                  max-height="400"
                  contain
                  class="rounded cursor-zoom-in"
                />
                <div v-else class="text-center text-grey-400 pa-6">
                  <VIcon icon="ri-image-line" size="48" class="mb-2" />
                  <p class="mb-0 text-caption">No se adjuntó evidencia fotográfica para esta acta.</p>
                </div>
              </div>
            </VCol>

            <!-- Comparativa OCR vs Digitado -->
            <VCol cols="12" md="6">
              <h4 class="text-subtitle-2 font-weight-bold mb-2 d-flex align-center gap-x-1">
                <VIcon icon="ri-scales-3-line" size="18" /> Comparativa Digitado vs OCR Asistido
              </h4>

              <ActOcrComparison :act="selectedAct" />
            </VCol>
          </VRow>
        </VCardText>

        <VCardActions class="pa-4 border-t d-flex justify-space-between align-center">
          <VChip
            :color="selectedAct.status === 'CONFIRMED' ? 'success' : 'warning'"
            variant="tonal"
            class="font-weight-bold"
          >
            Estado: {{ selectedAct.status }}
          </VChip>

          <div class="d-flex gap-x-2">
            <VBtn
              v-if="selectedAct.status !== 'CONFIRMED'"
              color="success"
              variant="flat"
              prepend-icon="ri-checkbox-circle-line"
              @click="confirmAct(selectedAct.id)"
            >
              Confirmar Acta
            </VBtn>
            <VBtn variant="tonal" color="secondary" @click="isDetailOpen = false">
              Cerrar
            </VBtn>
          </div>
        </VCardActions>
      </VCard>
    </VDialog>
  </div>
</template>
