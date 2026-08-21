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

const saving = ref(false)
const errorMessage = ref<string | null>(null)

watch(
  () => props.candidate,
  (val) => {
    if (val) {
      form.value = {
        document_number: val.document_number || '',
        full_name: val.full_name || '',
        photo_url: val.photo_url || '',
        position: val.position || '',
        id_hoja_vida: val.id_hoja_vida || '',
      }
    } else {
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
    if (isEdit.value && props.candidate) {
      await candidatesService.update(props.candidate.id, form.value)
    } else {
      await candidatesService.create(form.value)
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
    max-width="560"
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
            <VTextField
              v-model="form.position"
              label="Cargo al que Postula"
              placeholder="Gobernador Regional"
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
          <VCol cols="12" sm="6">
            <VTextField
              v-model="form.id_hoja_vida"
              label="ID Hoja de Vida JNE"
              placeholder="135790"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
          <VCol cols="12">
            <VTextField
              v-model="form.photo_url"
              label="URL Fotografía Oficial (JNE / Servidor)"
              placeholder="https://declara.jne.gob.pe/fotocandidato.jpg"
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
