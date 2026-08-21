<script setup lang="ts">
import { candidatesService, type CandidateItem } from '@/api/candidates.service'

const props = defineProps<{
  modelValue: boolean
  candidate: CandidateItem | null
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
  (e: 'saved'): void
}>()

const isEdit = computed(() => !!props.candidate?.id)

const form = ref({
  document_number: '',
  full_name: '',
  photo_url: '',
  position: '',
  id_hoja_vida: '',
})

const photoFile = ref<File | null>(null)
const photoPreview = ref<string | null>(null)

const saving = ref(false)
const errorMessage = ref<string | null>(null)

const onFileChange = (e: Event) => {
  const target = e.target as HTMLInputElement
  if (target.files && target.files[0]) {
    photoFile.value = target.files[0]
    photoPreview.value = URL.createObjectURL(target.files[0])
  }
}

watch(
  () => props.candidate,
  (val) => {
    photoFile.value = null
    if (val) {
      photoPreview.value = val.photo_url || null
      form.value = {
        document_number: val.document_number || '',
        full_name: val.full_name || '',
        photo_url: val.photo_url || '',
        position: val.position || '',
        id_hoja_vida: val.id_hoja_vida || '',
      }
    } else {
      photoPreview.value = null
      form.value = {
        document_number: '',
        full_name: '',
        photo_url: '',
        position: '',
        id_hoja_vida: '',
      }
    }
    errorMessage.value = null
  },
  { immediate: true }
)

const handleSave = async () => {
  if (!form.value.document_number || !form.value.full_name) {
    errorMessage.value = 'El DNI y el nombre completo son obligatorios.'
    return
  }

  saving.value = true
  errorMessage.value = null

  try {
    const formData = new FormData()
    formData.append('document_number', form.value.document_number)
    formData.append('full_name', form.value.full_name)
    if (form.value.position) formData.append('position', form.value.position)
    if (form.value.id_hoja_vida) formData.append('id_hoja_vida', form.value.id_hoja_vida)
    if (form.value.photo_url) formData.append('photo_url', form.value.photo_url)
    if (photoFile.value) formData.append('photo_file', photoFile.value)

    if (isEdit.value && props.candidate) {
      formData.append('_method', 'PUT')
      await candidatesService.updateFormData(props.candidate.id, formData)
    } else {
      await candidatesService.createFormData(formData)
    }

    emit('saved')
    emit('update:modelValue', false)
  } catch (err: any) {
    errorMessage.value = err?._data?.message || 'Error al guardar el candidato.'
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <VDialog
    :model-value="modelValue"
    max-width="600"
    @update:model-value="emit('update:modelValue', $event)"
  >
    <VCard>
      <VCardTitle class="d-flex justify-space-between align-center pa-4 border-b">
        <span class="text-h6 font-weight-bold">
          {{ isEdit ? `Editar Candidato: ${candidate?.full_name}` : 'Registrar Nuevo Candidato' }}
        </span>
        <VBtn icon="ri-close-line" variant="text" density="compact" @click="emit('update:modelValue', false)" />
      </VCardTitle>

      <VCardText class="pa-4">
        <VAlert v-if="errorMessage" color="error" variant="tonal" class="mb-4">
          {{ errorMessage }}
        </VAlert>

        <!-- Preview y Selector de Fotografía Local -->
        <div class="d-flex align-center gap-x-4 mb-4 pa-3 bg-background rounded border">
          <VAvatar size="64" rounded="lg" color="primary" variant="tonal" class="elevation-1 border">
            <VImg
              v-if="photoPreview"
              :src="photoPreview"
              cover
            />
            <span v-else class="text-h5 font-weight-bold">
              {{ form.full_name ? form.full_name[0] : 'C' }}
            </span>
          </VAvatar>
          <div class="flex-grow-1">
            <div class="text-caption font-weight-bold mb-1">Fotografía del Candidato (Local Storage)</div>
            <VFileInput
              label="Subir / Cambiar fotografía"
              density="compact"
              variant="outlined"
              accept="image/*"
              prepend-icon=""
              prepend-inner-icon="ri-upload-2-line"
              hide-details
              @change="onFileChange"
            />
          </div>
        </div>

        <VRow dense>
          <VCol cols="12" sm="6">
            <VTextField
              v-model="form.document_number"
              label="DNI del Candidato"
              placeholder="12345678"
              variant="outlined"
              density="comfortable"
              :disabled="isEdit"
              maxlength="12"
            />
          </VCol>
          <VCol cols="12" sm="6">
            <VCombobox
              v-model="form.position"
              label="Cargo al que Postula"
              :items="[
                'ALCALDE DISTRITAL',
                'REGIDOR DISTRITAL',
                'ALCALDE PROVINCIAL',
                'REGIDOR PROVINCIAL',
                'GOBERNADOR REGIONAL',
                'VICEGOBERNADOR REGIONAL',
                'CONSEJERO REGIONAL',
                'ACCESITARIO',
              ]"
              placeholder="Seleccionar o escribir cargo..."
              variant="outlined"
              density="comfortable"
            />
          </VCol>
          <VCol cols="12">
            <VTextField
              v-model="form.full_name"
              label="Nombre Completo del Candidato"
              placeholder="María Elena Cornejo"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
          <VCol cols="12">
            <VTextField
              v-model="form.id_hoja_vida"
              label="ID Hoja de Vida JNE"
              placeholder="135790"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
        </VRow>
      </VCardText>

      <VCardActions class="pa-4 border-t d-flex justify-end gap-2">
        <VBtn variant="outlined" color="secondary" :disabled="saving" @click="emit('update:modelValue', false)">
          Cancelar
        </VBtn>
        <VBtn variant="flat" color="primary" :loading="saving" @click="handleSave">
          {{ isEdit ? 'Guardar Cambios' : 'Registrar Candidato' }}
        </VBtn>
      </VCardActions>
    </VCard>
  </VDialog>
</template>
