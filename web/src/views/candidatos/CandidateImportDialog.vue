<script setup lang="ts">
import { ref, computed, watch, onUnmounted } from 'vue'
import { candidatesService, type CandidateJsonImportProgress } from '@/api/candidates.service'

const props = defineProps<{
  modelValue: boolean
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
  (e: 'imported'): void
}>()

const isOpen = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val),
})

// Estado de selección de archivo
const selectedFile = ref<File | null>(null)
const isDragging = ref(false)
const errorMessage = ref<string | null>(null)

// Estados de Proceso
const isUploading = ref(false)
const uploadProgress = ref(0)
const importProgress = ref<CandidateJsonImportProgress | null>(null)
const pollingTimer = ref<any>(null)

const isProcessing = computed(() => {
  return isUploading.value || importProgress.value?.status === 'running'
})

const isCompleted = computed(() => {
  return importProgress.value?.status === 'completed'
})

const formatFileSize = (bytes: number): string => {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(2))} ${sizes[i]}`
}

const onFileSelected = (e: Event) => {
  const target = e.target as HTMLInputElement
  if (target.files && target.files[0]) {
    validateAndSetFile(target.files[0])
  }
}

const onDrop = (e: DragEvent) => {
  isDragging.value = false
  if (e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files[0]) {
    validateAndSetFile(e.dataTransfer.files[0])
  }
}

const validateAndSetFile = (file: File) => {
  errorMessage.value = null
  if (!file.name.toLowerCase().endsWith('.json')) {
    errorMessage.value = 'Formato inválido. Por favor seleccione un archivo con extensión .json'
    selectedFile.value = null
    return
  }
  selectedFile.value = file
}

const removeFile = () => {
  if (isProcessing.value) return
  selectedFile.value = null
  errorMessage.value = null
  uploadProgress.value = 0
}

// Iniciar subida y procesamiento
const startImport = async () => {
  if (!selectedFile.value || isProcessing.value) return

  errorMessage.value = null
  isUploading.value = true
  uploadProgress.value = 0

  try {
    const res = await candidatesService.uploadJson(selectedFile.value, (percent) => {
      uploadProgress.value = percent
    })

    isUploading.value = false
    importProgress.value = res.data
    startPolling()
  } catch (error: any) {
    isUploading.value = false
    errorMessage.value = error?.message || error?._data?.message || 'Error al subir el archivo JSON.'
  }
}

const startPolling = () => {
  stopPolling()
  pollingTimer.value = setInterval(async () => {
    try {
      const res = await candidatesService.getImportStatus()
      importProgress.value = res.data

      if (res.data.status !== 'running') {
        stopPolling()
        if (res.data.status === 'completed') {
          emit('imported')
        }
      }
    } catch {
      stopPolling()
    }
  }, 2000)
}

const stopPolling = () => {
  if (pollingTimer.value) {
    clearInterval(pollingTimer.value)
    pollingTimer.value = null
  }
}

const cancelImport = async () => {
  try {
    const res = await candidatesService.cancelImport()
    importProgress.value = res.data
    stopPolling()
  } catch (error) {
    console.error('Error al cancelar importación:', error)
  }
}

const checkExistingStatus = async () => {
  try {
    const res = await candidatesService.getImportStatus()
    if (res.data && res.data.status === 'running') {
      importProgress.value = res.data
      startPolling()
    }
  } catch {
    // idle
  }
}

const closeDialog = () => {
  if (isCompleted.value) {
    selectedFile.value = null
    importProgress.value = null
    uploadProgress.value = 0
  }
  isOpen.value = false
}

watch(
  () => props.modelValue,
  (val) => {
    if (val) {
      checkExistingStatus()
    }
  }
)

onUnmounted(() => {
  stopPolling()
})
</script>

<template>
  <VDialog
    v-model="isOpen"
    max-width="640"
    persistent
  >
    <VCard class="rounded-lg">
      <!-- Encabezado -->
      <VCardTitle class="d-flex align-center justify-space-between py-4 px-6 border-b">
        <div class="d-flex align-center gap-x-3">
          <VAvatar color="primary" variant="tonal" size="40">
            <VIcon icon="ri-file-upload-line" color="primary" size="22" />
          </VAvatar>
          <div>
            <div class="text-h6 font-weight-bold">Importar Padrón JEE (JSON)</div>
            <div class="text-caption text-medium-emphasis">
              Carga masiva de candidatos oficiales JEE ERM 2026 (>150MB)
            </div>
          </div>
        </div>

        <VBtn
          icon="ri-close-line"
          variant="text"
          density="comfortable"
          :disabled="isUploading"
          @click="closeDialog"
        />
      </VCardTitle>

      <VCardText class="pa-6">
        <!-- Error Alert -->
        <VAlert
          v-if="errorMessage"
          type="error"
          variant="tonal"
          closable
          class="mb-4"
          @click:close="errorMessage = null"
        >
          {{ errorMessage }}
        </VAlert>

        <!-- Zona 1: Selección / Drag & Drop de Archivo (Si no está en ejecución ni completado) -->
        <div v-if="!importProgress || importProgress.status === 'idle' || importProgress.status === 'canceled' || importProgress.status === 'failed'">
          <div
            v-if="!selectedFile"
            class="d-flex flex-column align-center justify-center pa-8 rounded-lg border-2 border-dashed text-center cursor-pointer transition-all"
            :class="isDragging ? 'bg-primary-lighten-5 border-primary' : 'border-color-default'"
            @dragover.prevent="isDragging = true"
            @dragleave.prevent="isDragging = false"
            @drop.prevent="onDrop"
            @click="($refs.fileInput as HTMLInputElement)?.click()"
          >
            <input
              ref="fileInput"
              type="file"
              accept=".json"
              class="d-none"
              @change="onFileSelected"
            >

            <VAvatar color="primary" variant="tonal" size="56" class="mb-3">
              <VIcon icon="ri-upload-cloud-2-line" size="32" color="primary" />
            </VAvatar>

            <div class="text-subtitle-1 font-weight-bold mb-1">
              Arrastra y suelta tu archivo JSON aquí
            </div>
            <div class="text-body-2 text-medium-emphasis mb-3">
              o haz clic para explorar en tu equipo (soporta archivos de más de 150MB)
            </div>

            <VChip size="small" color="primary" variant="outlined">
              <VIcon start icon="ri-file-code-line" size="16" />
              Formato oficial: candidatos_todos_jee.json
            </VChip>
          </div>

          <!-- Archivo Seleccionado -->
          <div v-else class="border rounded-lg pa-4">
            <div class="d-flex align-center justify-space-between flex-wrap gap-2">
              <div class="d-flex align-center gap-x-3">
                <VAvatar color="success" variant="tonal" size="44">
                  <VIcon icon="ri-file-text-line" color="success" size="24" />
                </VAvatar>
                <div>
                  <div class="font-weight-bold text-subtitle-2 text-truncate" style="max-width: 380px;">
                    {{ selectedFile.name }}
                  </div>
                  <div class="text-caption text-medium-emphasis">
                    Tamaño: {{ formatFileSize(selectedFile.size) }}
                  </div>
                </div>
              </div>

              <VBtn
                icon="ri-delete-bin-line"
                color="error"
                variant="text"
                density="comfortable"
                :disabled="isUploading"
                @click="removeFile"
              />
            </div>

            <!-- Progreso de Subida HTTP -->
            <div v-if="isUploading" class="mt-4">
              <div class="d-flex justify-space-between text-caption font-weight-bold mb-1">
                <span>Subiendo archivo al servidor...</span>
                <span>{{ uploadProgress }}%</span>
              </div>
              <VProgressLinear
                :model-value="uploadProgress"
                height="8"
                rounded
                color="primary"
                striped
              />
            </div>
          </div>

          <!-- Nota Informativa -->
          <div class="d-flex align-start gap-x-2 mt-4 text-caption text-medium-emphasis">
            <VIcon icon="ri-information-line" size="18" color="info" class="flex-shrink-0 mt-0.5" />
            <div>
              <strong>Importación Inteligente:</strong> El sistema procesará el archivo en streaming continuo, vinculando automáticamente organizaciones políticas, listas electorales, candidatos y candidaturas. Solo se insertarán registros nuevos o actualizarán los estados modificados.
            </div>
          </div>
        </div>

        <!-- Zona 2: Progreso de Importación Asíncrona (En Ejecución) -->
        <div v-else-if="importProgress.status === 'running'" class="py-4">
          <div class="d-flex align-center gap-x-3 mb-4">
            <VProgressCircular
              indeterminate
              color="primary"
              size="40"
              width="4"
            />
            <div>
              <div class="text-subtitle-1 font-weight-bold">
                Procesando Padrón JEE en Segundo Plano
              </div>
              <div class="text-caption text-medium-emphasis">
                {{ importProgress.file_name || 'Archivo JSON' }}
              </div>
            </div>
          </div>

          <VCard variant="tonal" color="primary" class="pa-4 mb-4">
            <div class="d-flex justify-space-between text-caption mb-1">
              <span class="font-weight-medium">Registros procesados:</span>
              <span class="font-weight-bold">{{ importProgress.processed.toLocaleString() }} registros</span>
            </div>
            <div class="d-flex justify-space-between text-caption mb-1">
              <span class="font-weight-medium">Nuevos candidatos:</span>
              <span class="font-weight-bold text-success">+{{ importProgress.new_candidates.toLocaleString() }}</span>
            </div>
            <div class="d-flex justify-space-between text-caption mb-1">
              <span class="font-weight-medium">Nuevas listas:</span>
              <span class="font-weight-bold text-info">+{{ importProgress.new_lists.toLocaleString() }}</span>
            </div>
            <div v-if="importProgress.last_candidate_name" class="d-flex justify-space-between text-caption border-t pt-2 mt-2">
              <span class="font-weight-medium text-truncate" style="max-width: 140px;">Último procesado:</span>
              <span class="font-weight-medium text-truncate" style="max-width: 320px;">{{ importProgress.last_candidate_name }}</span>
            </div>
          </VCard>

          <VProgressLinear
            indeterminate
            height="8"
            rounded
            color="primary"
            class="mb-4"
          />

          <div class="d-flex justify-space-between align-center">
            <span class="text-caption text-medium-emphasis">
              Puedes cerrar esta ventana; el proceso continuará ejecutándose.
            </span>
            <VBtn
              variant="outlined"
              color="error"
              size="small"
              prepend-icon="ri-stop-circle-line"
              @click="cancelImport"
            >
              Cancelar Proceso
            </VBtn>
          </div>
        </div>

        <!-- Zona 3: Importación Completada Exitosamente -->
        <div v-else-if="importProgress.status === 'completed'" class="py-4 text-center">
          <VAvatar color="success" variant="tonal" size="64" class="mb-3">
            <VIcon icon="ri-checkbox-circle-fill" color="success" size="40" />
          </VAvatar>

          <div class="text-h6 font-weight-bold text-success mb-1">
            ¡Importación Completada Exitosamente!
          </div>
          <div class="text-body-2 text-medium-emphasis mb-4">
            El padrón oficial JEE ha sido actualizado en la base de datos.
          </div>

          <VRow class="mb-4">
            <VCol cols="4">
              <VCard variant="tonal" color="primary" class="pa-3 text-center">
                <div class="text-h6 font-weight-bold">{{ importProgress.processed.toLocaleString() }}</div>
                <div class="text-caption">Total Procesados</div>
              </VCard>
            </VCol>
            <VCol cols="4">
              <VCard variant="tonal" color="success" class="pa-3 text-center">
                <div class="text-h6 font-weight-bold">+{{ importProgress.new_candidates.toLocaleString() }}</div>
                <div class="text-caption">Candidatos Nuevos</div>
              </VCard>
            </VCol>
            <VCol cols="4">
              <VCard variant="tonal" color="info" class="pa-3 text-center">
                <div class="text-h6 font-weight-bold">+{{ importProgress.new_lists.toLocaleString() }}</div>
                <div class="text-caption">Listas Nuevas</div>
              </VCard>
            </VCol>
          </VRow>
        </div>
      </VCardText>

      <!-- Acciones Inferiores -->
      <VCardActions class="py-4 px-6 border-t d-flex justify-end gap-x-2">
        <VBtn
          variant="text"
          color="secondary"
          :disabled="isUploading"
          @click="closeDialog"
        >
          {{ isCompleted ? 'Cerrar y Actualizar' : 'Cancelar' }}
        </VBtn>

        <VBtn
          v-if="!importProgress || importProgress.status === 'idle' || importProgress.status === 'canceled' || importProgress.status === 'failed'"
          color="primary"
          variant="flat"
          prepend-icon="ri-upload-2-line"
          :disabled="!selectedFile || isProcessing"
          :loading="isUploading"
          @click="startImport"
        >
          Iniciar Importación
        </VBtn>
      </VCardActions>
    </VCard>
  </VDialog>
</template>

<style scoped>
.border-color-default {
  border-color: rgba(var(--v-border-color), var(--v-border-opacity));
}
.transition-all {
  transition: all 0.2s ease-in-out;
}
</style>
