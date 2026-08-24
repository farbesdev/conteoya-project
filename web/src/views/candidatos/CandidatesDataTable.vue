<script setup lang="ts">
import { candidatesService, type CandidateItem, type CandidateCvSyncProgress } from '@/api/candidates.service'
import { useDebounceFn } from '@vueuse/core'
import DesktopDatatable from '@/components/DesktopDatatable.vue'
import MovilCardList from '@/components/MovilCardList.vue'
import CandidateDetailDialog from './CandidateDetailDialog.vue'
import CandidateFormDialog from './CandidateFormDialog.vue'
import CandidateCvDialog from './CandidateCvDialog.vue'
import CandidateImportDialog from './CandidateImportDialog.vue'

const search = ref('')
const selectedStatus = ref<string | null>(null)
const loading = ref(false)
const candidates = ref<CandidateItem[]>([])
const totalItems = ref(0)
const page = ref(1)
const itemsPerPage = ref(15)

const statusOptions = [
  { title: 'Todos los estados', value: null },
  { title: 'ADMITIDO', value: 'ADMITIDO' },
  { title: 'INSCRITO', value: 'INSCRITO' },
  { title: 'PUBLICADO PARA TACHAS', value: 'PUBLICADO PARA TACHAS' },
  { title: 'IMPROCEDENTE', value: 'IMPROCEDENTE' },
  { title: 'RECIBIDO', value: 'RECIBIDO' },
  { title: 'INADMISIBLE', value: 'INADMISIBLE' },
  { title: 'TACHA EN TRAMITE', value: 'TACHA EN TRAMITE' },
  { title: 'APELACIÓN', value: 'APELACIÓN' },
  { title: 'RENUNCIA', value: 'RENUNCIA' },
  { title: 'EXCLUSION', value: 'EXCLUSION' },
  { title: 'RETIRO', value: 'RETIRO' },
  { title: 'TACHADO', value: 'TACHADO' },
  { title: 'FALLECIDO', value: 'FALLECIDO' },
]

// Sincronización Asíncrona de Hojas de Vida (Redis Queue)
const syncProgress = ref<CandidateCvSyncProgress | null>(null)
const isSyncing = computed(() => syncProgress.value?.status === 'running')
const syncPollingTimer = ref<any>(null)
const syncLoading = ref(false)
const syncMessage = ref<string | null>(null)

// Modal Mostrar Detalle
const isDetailOpen = ref(false)
const candidateToDetail = ref<CandidateItem | null>(null)

// Modal Hoja de Vida (Visor y Editor)
const isCvOpen = ref(false)
const candidateToCv = ref<CandidateItem | null>(null)

// Modal Importar Padrón JSON JEE
const isImportOpen = ref(false)

// Modal Crear / Editar
const isFormOpen = ref(false)
const candidateToEdit = ref<CandidateItem | null>(null)

// Modal Eliminar
const isDeleteDialogOpen = ref(false)
const candidateToDelete = ref<CandidateItem | null>(null)
const deleting = ref(false)

const headers = [
  { title: '#', key: 'index', sortable: false, align: 'center' as const },
  { title: 'Candidato', key: 'candidate', sortable: false },
  { title: 'Cargo Postulado', key: 'position', sortable: false },
  { title: 'Partido', key: 'party', sortable: false, align: 'center' as const },
  { title: 'Estado', key: 'status', sortable: false, align: 'center' as const },
  { title: 'Acciones', key: 'actions', sortable: false, align: 'end' as const },
]

const getStatusColor = (status?: string) => {
  const s = (status || '').toUpperCase()
  if (s.includes('ADMIT') || s.includes('INSCRIT') || s.includes('OFICIAL')) return 'success'
  if (s.includes('TACHA EN TRAMITE') || s.includes('PUBLICADO') || s.includes('APELACI') || s.includes('RECIBID') || s.includes('INADMIS')) return 'warning'
  if (s.includes('IMPROC') || s.includes('EXCLU') || s.includes('TACHADO') || s.includes('RETIRO') || s.includes('RENUNC') || s.includes('FALLEC')) return 'error'
  return 'secondary'
}

const loadCandidates = async () => {
  loading.value = true
  try {
    const res = await candidatesService.list({
      search: search.value || undefined,
      status: selectedStatus.value || undefined,
      page: page.value,
      per_page: itemsPerPage.value,
    })
    candidates.value = res.data
    totalItems.value = res.meta.total
  } catch (error) {
    console.error('Error cargando candidatos:', error)
  } finally {
    loading.value = false
  }
}

// Métodos de Sincronización Asíncrona de Hojas de Vida
const checkSyncStatus = async () => {
  try {
    const res = await candidatesService.getCvSyncStatus()
    syncProgress.value = res.data
    if (res.data.status === 'running') {
      startSyncPolling()
    } else {
      stopSyncPolling()
    }
  } catch (error) {
    console.error('Error consultando estado de sync:', error)
    stopSyncPolling()
  }
}

const startSyncPolling = () => {
  if (!syncPollingTimer.value) {
    syncPollingTimer.value = setInterval(async () => {
      try {
        const res = await candidatesService.getCvSyncStatus()
        syncProgress.value = res.data
        if (res.data.status !== 'running') {
          stopSyncPolling()
          if (res.data.status === 'completed') {
            syncMessage.value = '¡Sincronización de Hojas de Vida completada exitosamente!'
            loadCandidates()
          }
        }
      } catch {
        stopSyncPolling()
      }
    }, 2500)
  }
}

const stopSyncPolling = () => {
  if (syncPollingTimer.value) {
    clearInterval(syncPollingTimer.value)
    syncPollingTimer.value = null
  }
}

const triggerCvSync = async () => {
  syncLoading.value = true
  syncMessage.value = null
  try {
    const res = await candidatesService.startCvSync({ chunk: 50, delay_ms: 250 })
    syncProgress.value = res.data
    startSyncPolling()
  } catch (error: any) {
    syncMessage.value = error?._data?.message || 'Error al iniciar la sincronización.'
  } finally {
    syncLoading.value = false
  }
}

const cancelCvSync = async () => {
  try {
    const res = await candidatesService.cancelCvSync()
    syncProgress.value = res.data
    stopSyncPolling()
  } catch (error) {
    console.error('Error cancelando sync:', error)
  }
}

watch([page, itemsPerPage], () => {
  loadCandidates()
})

watch(selectedStatus, () => {
  page.value = 1
  loadCandidates()
})

const onSearchInput = useDebounceFn(() => {
  page.value = 1
  loadCandidates()
}, 400)

const openCreateDialog = () => {
  candidateToEdit.value = null
  isFormOpen.value = true
}

const openEditDialog = (c: CandidateItem) => {
  candidateToEdit.value = c
  isFormOpen.value = true
}

const openCvDialog = (c: CandidateItem) => {
  candidateToCv.value = c
  isCvOpen.value = true
}

const openDetailDialog = (c: CandidateItem) => {
  candidateToDetail.value = c
  isDetailOpen.value = true
}

const confirmDelete = (c: CandidateItem) => {
  candidateToDelete.value = c
  isDeleteDialogOpen.value = true
}

const handleDelete = async () => {
  if (!candidateToDelete.value) return
  deleting.value = true
  try {
    await candidatesService.delete(candidateToDelete.value.id)
    isDeleteDialogOpen.value = false
    candidateToDelete.value = null
    await loadCandidates()
  } catch (error) {
    console.error('Error al eliminar candidato:', error)
  } finally {
    deleting.value = false
  }
}

onMounted(() => {
  loadCandidates()
  checkSyncStatus()
})

onUnmounted(() => {
  stopSyncPolling()
})
</script>

<template>
  <div class="d-flex flex-column gap-y-4">
    <!-- Banner de Sincronización en Tiempo Real (Redis Queue) -->
    <VCard
      v-if="isSyncing || syncMessage"
      class="border elevation-1"
      :color="isSyncing ? 'primary' : 'success'"
      variant="tonal"
    >
      <VCardItem class="py-3">
        <div class="d-flex align-center justify-space-between flex-wrap gap-3">
          <div class="d-flex align-center gap-x-3">
            <VProgressCircular
              v-if="isSyncing"
              indeterminate
              size="28"
              width="3"
              color="primary"
            />
            <VIcon v-else icon="ri-checkbox-circle-line" color="success" size="28" />

            <div>
              <div class="font-weight-bold text-subtitle-2">
                <span v-if="isSyncing">
                  Sincronizando Hojas de Vida JNE en segundo plano (Redis):
                  {{ (syncProgress?.processed || 0).toLocaleString() }} de {{ (syncProgress?.total || 0).toLocaleString() }} candidatos ({{ syncProgress?.percentage || 0 }}%)
                </span>
                <span v-else>{{ syncMessage }}</span>
              </div>
              <small v-if="isSyncing && syncProgress?.last_candidate_name" class="text-caption text-medium-emphasis d-block">
                Procesando: <strong class="text-high-emphasis">{{ syncProgress.last_candidate_name }}</strong>
                • Exitosos: {{ syncProgress.success_count }} • Errores: {{ syncProgress.error_count }}
              </small>
            </div>
          </div>

          <div class="d-flex align-center gap-2">
            <VBtn
              v-if="isSyncing"
              size="small"
              variant="outlined"
              color="error"
              density="comfortable"
              prepend-icon="ri-stop-circle-line"
              @click="cancelCvSync"
            >
              Detener Sincronización
            </VBtn>
            <VBtn
              v-if="syncMessage && !isSyncing"
              size="small"
              variant="text"
              density="compact"
              icon="ri-close-line"
              @click="syncMessage = null"
            />
          </div>
        </div>

        <VProgressLinear
          v-if="isSyncing"
          :model-value="syncProgress?.percentage || 0"
          height="6"
          rounded
          color="primary"
          class="mt-3"
          striped
        />
      </VCardItem>
    </VCard>

    <!-- Barra Superior -->
    <VCard class="border" elevation="0">
      <VCardItem class="py-3">
        <div class="d-flex align-center justify-space-between flex-wrap gap-3">
          <div class="d-flex align-center gap-x-2">
            <VAvatar color="primary" variant="tonal" size="40">
              <VIcon icon="ri-user-star-line" color="primary" size="22" />
            </VAvatar>
            <div>
              <span class="text-h6 font-weight-bold d-block">Padrón Oficial de Candidatos</span>
              <span class="text-caption text-medium-emphasis">Galería fotográfica, estado de listas y hojas de vida JNE ERM 2026</span>
            </div>
          </div>
          <div class="d-flex align-center gap-2 flex-wrap flex-grow-1 flex-sm-grow-0">
            <VSelect
              v-model="selectedStatus"
              :items="statusOptions"
              item-title="title"
              item-value="value"
              density="compact"
              variant="outlined"
              placeholder="Filtrar por estado"
              prepend-inner-icon="ri-filter-3-line"
              style="min-width: 190px;"
              clearable
              hide-details
            />
            <VTextField
              v-model="search"
              density="compact"
              variant="outlined"
              placeholder="Buscar por candidato, DNI o cargo..."
              prepend-inner-icon="ri-search-line"
              style="min-width: 220px;"
              clearable
              hide-details
              @update:model-value="onSearchInput"
              @click:clear="loadCandidates"
            />
            <VBtn
              icon="ri-refresh-line"
              variant="tonal"
              color="secondary"
              density="comfortable"
              :loading="loading"
              @click="loadCandidates"
            />
            <VBtn
              variant="tonal"
              color="primary"
              prepend-icon="ri-file-download-line"
              density="comfortable"
              :loading="syncLoading || isSyncing"
              @click="triggerCvSync"
            >
              {{ isSyncing ? 'Sincronizando...' : 'Sincronizar Hojas de Vida' }}
            </VBtn>
            <VBtn
              variant="tonal"
              color="success"
              prepend-icon="ri-file-upload-line"
              density="comfortable"
              @click="isImportOpen = true"
            >
              Importar Padrón (JSON)
            </VBtn>
            <VBtn
              variant="flat"
              color="primary"
              prepend-icon="ri-user-add-line"
              density="comfortable"
              @click="openCreateDialog"
            >
              Nuevo Candidato
            </VBtn>
          </div>
        </div>
      </VCardItem>
    </VCard>

    <!-- Vista Desktop: Tabla con Fotos -->
    <DesktopDatatable
      v-model:page="page"
      v-model:items-per-page="itemsPerPage"
      :headers="headers"
      :items="candidates"
      :items-length="totalItems"
      :loading="loading"
      loading-text="Cargando padrón de candidatos..."
      no-data-text="No se encontraron candidatos registrados."
    >
      <!-- Numeración (#) -->
      <template #item.index="{ index }">
        <span class="font-weight-bold text-medium-emphasis">
          #{{ (page - 1) * itemsPerPage + index + 1 }}
        </span>
      </template>

      <!-- Candidato con Fotografía y DNI debajo -->
      <template #item.candidate="{ item }">
        <div class="d-flex align-center gap-x-3 cursor-pointer py-1" @click="openDetailDialog(item)">
          <VAvatar size="42" rounded="lg" color="primary" variant="tonal" class="elevation-1 border">
            <VImg
              v-if="item.photo_url"
              :src="item.photo_url"
              cover
            />
            <span v-else class="text-subtitle-2 font-weight-bold">
              {{ item.full_name ? item.full_name[0] : 'C' }}
            </span>
          </VAvatar>
          <div>
            <div class="font-weight-bold text-high-emphasis">{{ item.full_name }}</div>
            <small class="text-caption text-medium-emphasis">
              DNI: <span class="font-weight-bold text-primary">{{ item.document_number || item.dni }}</span>
              <span v-if="item.id_hoja_vida" class="ms-2 text-disabled">• HV: {{ item.id_hoja_vida }}</span>
            </small>
          </div>
        </div>
      </template>

      <!-- Cargo Postulado -->
      <template #item.position="{ item }">
        <div>
          <div class="font-weight-bold text-body-2 text-high-emphasis">{{ item.position || 'CANDIDATO OFICIAL' }}</div>
          <div class="text-caption text-medium-emphasis">
            {{ [item.district_name, item.province_name, item.department_name].filter(Boolean).join(' / ') || item.electoral_level_name || 'Elecciones ERM 2026' }}
          </div>
        </div>
      </template>

      <!-- Partido: Logo Centrado con Tooltip -->
      <template #item.party="{ item }">
        <div class="d-flex justify-center">
          <VTooltip :text="item.political_org_name || 'Lista Oficial'" location="top">
            <template #activator="{ props: tipProps }">
              <VAvatar v-bind="tipProps" size="34" class="elevation-1 border cursor-pointer" color="surface">
                <VImg
                  v-if="item.political_org_logo"
                  :src="item.political_org_logo"
                  cover
                />
                <VIcon v-else icon="ri-flag-2-fill" size="18" color="primary" />
              </VAvatar>
            </template>
          </VTooltip>
        </div>
      </template>

      <!-- Estado de Candidatura -->
      <template #item.status="{ item }">
        <div class="d-flex justify-center">
          <VChip
            size="small"
            :color="getStatusColor(item.status)"
            variant="tonal"
            class="font-weight-bold"
          >
            {{ item.status || 'INSCRITO' }}
          </VChip>
        </div>
      </template>

      <!-- Acciones Completas CRUD -->
      <template #item.actions="{ item }">
        <div class="d-flex align-center justify-end gap-1">
          <VTooltip text="Ver Ficha Oficial" location="top">
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

          <VTooltip text="Ver / Editar Hoja de Vida" location="top">
            <template #activator="{ props: tipProps }">
              <VBtn
                v-bind="tipProps"
                size="small"
                variant="text"
                color="warning"
                icon="ri-file-text-line"
                @click="openCvDialog(item)"
              />
            </template>
          </VTooltip>

          <VTooltip text="Editar Candidato" location="top">
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

          <VTooltip text="Eliminar Candidato" location="top">
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

    <!-- Vista Móvil: Tarjetas con Foto -->
    <MovilCardList
      v-model:page="page"
      :items="candidates"
      :items-length="totalItems"
      :items-per-page="itemsPerPage"
      :loading="loading"
      loading-text="Cargando candidatos..."
      no-data-text="No se encontraron candidatos."
    >
      <template #card="{ item }">
        <div class="d-flex justify-space-between align-start mb-2">
          <div class="d-flex align-center gap-x-3">
            <VAvatar size="48" rounded="lg" color="primary" variant="tonal" class="elevation-1 border">
              <VImg
                v-if="item.photo_url"
                :src="item.photo_url"
                cover
              />
              <span v-else class="font-weight-bold">
                {{ item.full_name ? item.full_name[0] : 'C' }}
              </span>
            </VAvatar>
            <div>
              <div class="font-weight-bold text-subtitle-2 line-clamp-1 cursor-pointer" @click="openDetailDialog(item)">
                {{ item.full_name }}
              </div>
              <div class="text-caption text-primary font-weight-medium">
                DNI: {{ item.document_number || item.dni }}
              </div>
            </div>
          </div>
          <VChip size="x-small" :color="getStatusColor(item.status)" variant="tonal" class="font-weight-bold">
            {{ item.status || 'INSCRITO' }}
          </VChip>
        </div>

        <div class="bg-background pa-2 rounded mb-3 text-caption">
          <div class="d-flex align-center gap-2 mb-1 font-weight-medium">
            <VAvatar size="22" class="elevation-1 border" color="surface">
              <VImg
                v-if="item.political_org_logo"
                :src="item.political_org_logo"
                cover
              />
              <VIcon v-else icon="ri-flag-line" size="12" color="primary" />
            </VAvatar>
            <span>{{ item.political_org_name || 'Lista Oficial' }}</span>
          </div>
          <div class="text-medium-emphasis">
            Cargo: <span class="font-weight-bold text-high-emphasis">{{ item.position }}</span>
          </div>
        </div>

        <div class="d-flex justify-end align-center gap-2 pt-2 border-t">
          <VBtn
            size="small"
            variant="text"
            color="info"
            icon="ri-eye-line"
            @click="openDetailDialog(item)"
          />
          <VBtn
            size="small"
            variant="text"
            color="warning"
            icon="ri-file-text-line"
            @click="openCvDialog(item)"
          />
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

    <!-- Modal Detalle Candidato -->
    <CandidateDetailDialog
      v-model="isDetailOpen"
      :candidate="candidateToDetail"
    />

    <!-- Modal Hoja de Vida (Visor y Editor) -->
    <CandidateCvDialog
      v-model="isCvOpen"
      :candidate="candidateToCv"
      @saved="loadCandidates"
    />

    <!-- Modal Importación de Padrón JEE (JSON) -->
    <CandidateImportDialog
      v-model="isImportOpen"
      @imported="loadCandidates"
    />

    <!-- Modal Crear / Editar Candidato -->
    <CandidateFormDialog
      v-model="isFormOpen"
      :candidate="candidateToEdit"
      @saved="loadCandidates"
    />

    <!-- Modal Eliminar Candidato -->
    <VDialog v-model="isDeleteDialogOpen" max-width="450">
      <VCard class="pa-2">
        <VCardTitle class="d-flex align-center gap-x-2 text-error">
          <VIcon icon="ri-error-warning-line" />
          <span>Eliminar Candidato</span>
        </VCardTitle>
        <VCardText>
          ¿Está seguro de que desea eliminar al candidato <strong>{{ candidateToDelete?.full_name }}</strong> (DNI: {{ candidateToDelete?.document_number }})?
        </VCardText>
        <VCardActions class="d-flex justify-end gap-2">
          <VBtn variant="outlined" color="secondary" :disabled="deleting" @click="isDeleteDialogOpen = false">
            Cancelar
          </VBtn>
          <VBtn variant="flat" color="error" :loading="deleting" @click="handleDelete">
            Eliminar Candidato
          </VBtn>
        </VCardActions>
      </VCard>
    </VDialog>
  </div>
</template>
