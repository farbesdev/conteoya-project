<script setup lang="ts">
import { candidatesService, type CandidateItem } from '@/api/candidates.service'
import TiptapEditor from '@/@core/components/TiptapEditor.vue'

const props = defineProps<{
  modelValue: boolean
  candidate: CandidateItem | null
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
  (e: 'saved'): void
}>()

const activeTab = ref('general')
const loading = ref(false)
const saving = ref(false)
const errorMessage = ref<string | null>(null)
const successMessage = ref<string | null>(null)

// Formulario de Hoja de Vida
const cvForm = ref({
  id_hoja_vida: '',
  general_data: '' as any,
  academic_data: '' as any,
  work_experience: '' as any,
  political_trajectory: '' as any,
  sworn_declaration: '' as any,
  penal_sentences: '' as any,
  additional_info: '',
})

// Modo de visualización/edición: 'view' o 'edit'
const isEditMode = ref(false)

const loadCv = async () => {
  if (!props.candidate) return
  loading.value = true
  errorMessage.value = null
  successMessage.value = null
  isEditMode.value = false

  try {
    const res = await candidatesService.getCv(props.candidate.id)
    const cv = res.data

    cvForm.value = {
      id_hoja_vida: props.candidate.id_hoja_vida || cv?.id_hoja_vida || '',
      general_data: cv?.general_data || null,
      academic_data: cv?.academic_data || null,
      work_experience: cv?.work_experience || null,
      political_trajectory: cv?.political_trajectory || null,
      sworn_declaration: cv?.sworn_declaration || null,
      penal_sentences: cv?.penal_sentences || null,
      additional_info: typeof cv?.additional_info === 'string' ? cv.additional_info : (cv?.additional_info ? JSON.stringify(cv.additional_info, null, 2) : ''),
    }
  } catch (err: any) {
    // Si aún no está sincronizado en BD, inicializar formulario en limpio sin error bloqueante
    cvForm.value = {
      id_hoja_vida: props.candidate.id_hoja_vida || '',
      general_data: null,
      academic_data: null,
      work_experience: null,
      political_trajectory: null,
      sworn_declaration: null,
      penal_sentences: null,
      additional_info: '',
    }
  } finally {
    loading.value = false
  }
}

const saveCv = async () => {
  if (!props.candidate) return
  saving.value = true
  errorMessage.value = null
  successMessage.value = null

  try {
    await candidatesService.updateCv(props.candidate.id, {
      id_hoja_vida: cvForm.value.id_hoja_vida,
      general_data: cvForm.value.general_data,
      academic_data: cvForm.value.academic_data,
      work_experience: cvForm.value.work_experience,
      political_trajectory: cvForm.value.political_trajectory,
      sworn_declaration: cvForm.value.sworn_declaration,
      penal_sentences: cvForm.value.penal_sentences,
      additional_info: cvForm.value.additional_info,
    })

    successMessage.value = '¡Hoja de Vida actualizada con éxito!'
    isEditMode.value = false
    emit('saved')
  } catch (err: any) {
    errorMessage.value = err?._data?.message || 'Error al guardar los cambios en la hoja de vida.'
  } finally {
    saving.value = false
  }
}

watch(() => props.modelValue, (newVal) => {
  if (newVal) {
    activeTab.value = 'general'
    loadCv()
  }
})
</script>

<template>
  <VDialog
    :model-value="modelValue"
    max-width="900"
    scrollable
    @update:model-value="emit('update:modelValue', $event)"
  >
    <VCard v-if="candidate">
      <!-- Cabecera del Modal con Foto Local Storage -->
      <VCardTitle class="d-flex justify-space-between align-center pa-4 border-b bg-surface">
        <div class="d-flex align-center gap-x-3">
          <VAvatar size="48" rounded="lg" color="primary" variant="tonal" class="elevation-1 border">
            <VImg
              v-if="candidate.photo_url"
              :src="candidate.photo_url"
              cover
            />
            <span v-else class="text-h6 font-weight-bold">
              {{ candidate.full_name ? candidate.full_name[0] : 'C' }}
            </span>
          </VAvatar>
          <div>
            <div class="d-flex align-center gap-2">
              <span class="text-h6 font-weight-bold">{{ candidate.full_name }}</span>
              <VChip size="x-small" color="primary" variant="tonal">
                DNI: {{ candidate.document_number || candidate.dni }}
              </VChip>
            </div>
            <span class="text-caption text-medium-emphasis">
              Hoja de Vida JNE • ID: <strong class="text-primary">{{ candidate.id_hoja_vida || cvForm.id_hoja_vida || 'Pendiente' }}</strong>
            </span>
          </div>
        </div>

        <div class="d-flex align-center gap-2">
          <VBtn
            v-if="!isEditMode"
            size="small"
            variant="tonal"
            color="primary"
            prepend-icon="ri-edit-line"
            @click="isEditMode = true"
          >
            Editar Hoja de Vida
          </VBtn>
          <VBtn
            v-else
            size="small"
            variant="outlined"
            color="secondary"
            prepend-icon="ri-eye-line"
            @click="isEditMode = false"
          >
            Modo Lectura
          </VBtn>
          <VBtn icon="ri-close-line" variant="text" density="compact" @click="emit('update:modelValue', false)" />
        </div>
      </VCardTitle>

      <!-- Mensajes de estado -->
      <VAlert
        v-if="successMessage"
        type="success"
        variant="tonal"
        closable
        class="ma-3 mb-0"
        @click:close="successMessage = null"
      >
        {{ successMessage }}
      </VAlert>

      <VAlert
        v-if="errorMessage"
        type="error"
        variant="tonal"
        closable
        class="ma-3 mb-0"
        @click:close="errorMessage = null"
      >
        {{ errorMessage }}
      </VAlert>

      <!-- Tabs de Navegación -->
      <VTabs v-model="activeTab" class="border-b" color="primary" density="compact">
        <VTab value="general">
          <VIcon icon="ri-user-line" class="me-1" size="18" /> Datos Personales
        </VTab>
        <VTab value="academic">
          <VIcon icon="ri-graduation-cap-line" class="me-1" size="18" /> Formación Académica
        </VTab>
        <VTab value="experience">
          <VIcon icon="ri-briefcase-line" class="me-1" size="18" /> Experiencia Laboral
        </VTab>
        <VTab value="trajectory">
          <VIcon icon="ri-government-line" class="me-1" size="18" /> Trayectoria Política
        </VTab>
        <VTab value="sentences">
          <VIcon icon="ri-scales-3-line" class="me-1" size="18" /> Declaración & Sentencias
        </VTab>
        <VTab value="editor">
          <VIcon icon="ri-file-edit-line" class="me-1" size="18" /> Notas / Editor
        </VTab>
      </VTabs>

      <!-- Contenido Principal -->
      <VCardText class="pa-4" style="max-height: 60vh;">
        <div v-if="loading" class="text-center py-8">
          <VProgressCircular indeterminate color="primary" size="40" />
          <div class="mt-2 text-caption text-medium-emphasis">Cargando datos de la hoja de vida...</div>
        </div>

        <div v-else>
          <!-- TAB 1: DATOS PERSONALES -->
          <div v-if="activeTab === 'general'">
            <div v-if="!isEditMode">
              <VRow dense>
                <VCol cols="12" sm="6">
                  <div class="text-caption text-medium-emphasis">Nombre Completo:</div>
                  <div class="font-weight-medium">{{ candidate.full_name }}</div>
                </VCol>
                <VCol cols="12" sm="6">
                  <div class="text-caption text-medium-emphasis">Documento de Identidad:</div>
                  <div class="font-weight-medium">{{ candidate.document_number }}</div>
                </VCol>
                <VCol cols="12" sm="6" class="mt-2">
                  <div class="text-caption text-medium-emphasis">Cargo Postulado:</div>
                  <div class="font-weight-medium">{{ candidate.position || 'Candidato Oficial' }}</div>
                </VCol>
                <VCol cols="12" sm="6" class="mt-2">
                  <div class="text-caption text-medium-emphasis">Organización Política:</div>
                  <div class="font-weight-medium">{{ candidate.political_org_name || 'Lista Oficial' }}</div>
                </VCol>
                <VCol cols="12" sm="6" class="mt-2">
                  <div class="text-caption text-medium-emphasis">ID Hoja de Vida:</div>
                  <div class="font-weight-bold text-primary">{{ cvForm.id_hoja_vida || 'Declarada en JEE' }}</div>
                </VCol>
                <VCol cols="12" sm="6" class="mt-2">
                  <div class="text-caption text-medium-emphasis">Estado en JEE:</div>
                  <VChip size="x-small" color="primary" variant="tonal" class="font-weight-bold mt-1">
                    {{ candidate.status || 'INSCRITO' }}
                  </VChip>
                </VCol>
              </VRow>

              <div v-if="cvForm.general_data" class="mt-4 pa-3 bg-background rounded border">
                <div class="font-weight-bold text-caption text-medium-emphasis mb-2">Datos Sincronizados JNE:</div>
                <pre class="text-caption" style="white-space: pre-wrap;">{{ JSON.stringify(cvForm.general_data, null, 2) }}</pre>
              </div>
            </div>

            <div v-else class="d-flex flex-column gap-3">
              <VTextField
                v-model="cvForm.id_hoja_vida"
                label="ID Hoja de Vida (JNE)"
                density="compact"
                variant="outlined"
                placeholder="Ej: 135892"
              />
              <VTextarea
                v-model="cvForm.general_data"
                label="Datos Generales (JSON o Texto estructurado)"
                rows="6"
                density="compact"
                variant="outlined"
                placeholder="Información general del candidato..."
              />
            </div>
          </div>

          <!-- TAB 2: FORMACIÓN ACADÉMICA -->
          <div v-if="activeTab === 'academic'">
            <div v-if="!isEditMode">
              <div v-if="cvForm.academic_data" class="pa-3 bg-background rounded border">
                <pre class="text-caption" style="white-space: pre-wrap;">{{ JSON.stringify(cvForm.academic_data, null, 2) }}</pre>
              </div>
              <div v-else class="text-center py-6 text-medium-emphasis">
                <VIcon icon="ri-graduation-cap-line" size="36" class="mb-2 text-disabled" />
                <div>No se registran datos académicos locales. Se obtendrán al sincronizar o puedes editarlos manualmente.</div>
              </div>
            </div>
            <div v-else>
              <VTextarea
                v-model="cvForm.academic_data"
                label="Estudios Universitarios, Técnicos y Postgrados"
                rows="8"
                density="compact"
                variant="outlined"
                placeholder="Registra títulos, grados académicos, instituciones y años..."
              />
            </div>
          </div>

          <!-- TAB 3: EXPERIENCIA LABORAL -->
          <div v-if="activeTab === 'experience'">
            <div v-if="!isEditMode">
              <div v-if="cvForm.work_experience" class="pa-3 bg-background rounded border">
                <pre class="text-caption" style="white-space: pre-wrap;">{{ JSON.stringify(cvForm.work_experience, null, 2) }}</pre>
              </div>
              <div v-else class="text-center py-6 text-medium-emphasis">
                <VIcon icon="ri-briefcase-line" size="36" class="mb-2 text-disabled" />
                <div>No se registra experiencia laboral sincronizada.</div>
              </div>
            </div>
            <div v-else>
              <VTextarea
                v-model="cvForm.work_experience"
                label="Centros de Trabajo, Oficios y Cargos desempeñados"
                rows="8"
                density="compact"
                variant="outlined"
                placeholder="Centros de trabajo, sector público/privado, periodos..."
              />
            </div>
          </div>

          <!-- TAB 4: TRAYECTORIA POLÍTICA -->
          <div v-if="activeTab === 'trajectory'">
            <div v-if="!isEditMode">
              <div v-if="cvForm.political_trajectory" class="pa-3 bg-background rounded border">
                <pre class="text-caption" style="white-space: pre-wrap;">{{ JSON.stringify(cvForm.political_trajectory, null, 2) }}</pre>
              </div>
              <div v-else class="text-center py-6 text-medium-emphasis">
                <VIcon icon="ri-government-line" size="36" class="mb-2 text-disabled" />
                <div>No se registra trayectoria política o cargos de elección popular previos.</div>
              </div>
            </div>
            <div v-else>
              <VTextarea
                v-model="cvForm.political_trajectory"
                label="Cargos de Elección Popular y Partidarios"
                rows="8"
                density="compact"
                variant="outlined"
                placeholder="Cargos en partidos políticos, elecciones anteriores, etc."
              />
            </div>
          </div>

          <!-- TAB 5: DECLARACIÓN & SENTENCIAS -->
          <div v-if="activeTab === 'sentences'">
            <div v-if="!isEditMode">
              <div class="mb-3">
                <h4 class="text-subtitle-2 font-weight-bold mb-1">Sentencias Penales / Civiles:</h4>
                <div v-if="cvForm.penal_sentences" class="pa-3 bg-background rounded border">
                  <pre class="text-caption" style="white-space: pre-wrap;">{{ JSON.stringify(cvForm.penal_sentences, null, 2) }}</pre>
                </div>
                <div v-else class="text-caption text-success font-weight-medium">
                  <VIcon icon="ri-checkbox-circle-line" size="16" color="success" class="me-1" />
                  No registra antecedentes ni sentencias condenatorias declaradas.
                </div>
              </div>

              <div>
                <h4 class="text-subtitle-2 font-weight-bold mb-1">Declaración Jurada de Bienes y Rentas:</h4>
                <div v-if="cvForm.sworn_declaration" class="pa-3 bg-background rounded border">
                  <pre class="text-caption" style="white-space: pre-wrap;">{{ JSON.stringify(cvForm.sworn_declaration, null, 2) }}</pre>
                </div>
                <div v-else class="text-caption text-medium-emphasis">
                  No registra declaración jurada de ingresos localmente.
                </div>
              </div>
            </div>
            <div v-else class="d-flex flex-column gap-3">
              <VTextarea
                v-model="cvForm.penal_sentences"
                label="Sentencias Penales y Civiles Declaradas"
                rows="4"
                density="compact"
                variant="outlined"
              />
              <VTextarea
                v-model="cvForm.sworn_declaration"
                label="Declaración Jurada de Ingresos, Bienes Muebles e Inmuebles"
                rows="4"
                density="compact"
                variant="outlined"
              />
            </div>
          </div>

          <!-- TAB 6: NOTAS / EDITOR TIPTAP -->
          <div v-if="activeTab === 'editor'">
            <div class="mb-2 text-caption text-medium-emphasis">
              Editor de texto enriquecido para observaciones, notas de campaña o resumen ejecutivo del candidato:
            </div>
            <div class="border rounded bg-surface">
              <TiptapEditor v-model="cvForm.additional_info" />
            </div>
          </div>
        </div>
      </VCardText>

      <!-- Acciones Inferiores -->
      <VCardActions class="pa-4 border-t d-flex justify-space-between align-center bg-surface">
        <div class="d-flex align-center gap-2">
          <VBtn
            v-if="candidate.id_hoja_vida"
            variant="text"
            color="primary"
            size="small"
            prepend-icon="ri-external-link-line"
            :href="candidate.cv_url || `https://declara.jne.gob.pe/HojaVida/HojaVida?idHojaVida=${candidate.id_hoja_vida}`"
            target="_blank"
          >
            JNE Declara Oficial
          </VBtn>
        </div>

        <div class="d-flex align-center gap-2">
          <VBtn variant="outlined" color="secondary" @click="emit('update:modelValue', false)">
            Cerrar
          </VBtn>
          <VBtn
            v-if="isEditMode || activeTab === 'editor'"
            variant="flat"
            color="primary"
            prepend-icon="ri-save-line"
            :loading="saving"
            @click="saveCv"
          >
            Guardar Cambios
          </VBtn>
        </div>
      </VCardActions>
    </VCard>
  </VDialog>
</template>
