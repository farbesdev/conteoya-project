<script setup lang="ts">
import { personerosService, type PersoneroItem } from '@/api/personeros.service'

const props = defineProps<{
  modelValue: boolean
  personero: PersoneroItem | null
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
  (e: 'saved'): void
}>()

const isEdit = computed(() => !!props.personero?.id)

const form = ref({
  document_number: '',
  first_name: '',
  last_name: '',
  name: '',
  email: '',
  phone_number: '',
  political_org_name: '',
})

const saving = ref(false)
const errorMessage = ref<string | null>(null)

watch(
  () => props.personero,
  (val) => {
    if (val) {
      form.value = {
        document_number: val.document_number || '',
        first_name: val.first_name || '',
        last_name: val.last_name_paternal || '',
        name: val.full_name || '',
        email: val.email || '',
        phone_number: val.phone_number || '',
        political_org_name: val.political_org_name || val.political_organization_name || '',
      }
    } else {
      form.value = {
        document_number: '',
        first_name: '',
        last_name: '',
        name: '',
        email: '',
        phone_number: '',
        political_org_name: '',
      }
    }
    errorMessage.value = null
  },
  { immediate: true }
)

const handleSave = async () => {
  if (!form.value.document_number) {
    errorMessage.value = 'El número de DNI es obligatorio.'
    return
  }

  saving.value = true
  errorMessage.value = null

  try {
    if (isEdit.value && props.personero) {
      await personerosService.update(props.personero.id, form.value)
    } else {
      await personerosService.create(form.value)
    }
    emit('saved')
    emit('update:modelValue', false)
  } catch (err: any) {
    errorMessage.value = err?._data?.message || 'Error al procesar el personero.'
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <VDialog
    :model-value="modelValue"
    max-width="580"
    @update:model-value="emit('update:modelValue', $event)"
  >
    <VCard>
      <VCardTitle class="d-flex justify-space-between align-center pa-4 border-b">
        <span class="text-h6 font-weight-bold">
          {{ isEdit ? 'Editar Personero Electoral' : 'Registrar Nuevo Personero' }}
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
              label="DNI (8 dígitos)"
              placeholder="12345678"
              variant="outlined"
              density="comfortable"
              :disabled="isEdit"
              maxlength="12"
            />
          </VCol>
          <VCol cols="12" sm="6">
            <VTextField
              v-model="form.phone_number"
              label="Teléfono / Móvil"
              placeholder="987654321"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
          <VCol cols="12" sm="6">
            <VTextField
              v-model="form.first_name"
              label="Nombres"
              placeholder="Juan Carlos"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
          <VCol cols="12" sm="6">
            <VTextField
              v-model="form.last_name"
              label="Apellidos"
              placeholder="Pérez Gómez"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
          <VCol cols="12">
            <VTextField
              v-model="form.email"
              label="Correo Electrónico"
              placeholder="personero@partido.pe"
              type="email"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
          <VCol cols="12">
            <VTextField
              v-model="form.political_org_name"
              label="Organización Política"
              placeholder="Nombre del partido político o alianza"
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
          {{ isEdit ? 'Guardar Cambios' : 'Crear Personero' }}
        </VBtn>
      </VCardActions>
    </VCard>
  </VDialog>
</template>
