<script setup lang="ts">
import { politicalOrganizationsService, type PoliticalOrganizationFullItem } from '@/api/political-organizations.service'

const props = defineProps<{
  modelValue: boolean
  org: PoliticalOrganizationFullItem | null
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
  (e: 'saved'): void
}>()

const isEdit = computed(() => !!props.org?.id)

const form = ref({
  name: '',
  short_name: '',
  org_type: 'PARTIDO POLÍTICO',
})

const logoFile = ref<File | null>(null)
const logoPreview = ref<string | null>(null)
const fileInputRef = ref<HTMLInputElement | null>(null)

const saving = ref(false)
const errorMessage = ref<string | null>(null)

watch(
  () => props.org,
  (val) => {
    if (val) {
      form.value = {
        name: val.name || '',
        short_name: val.short_name || '',
        org_type: val.org_type || 'PARTIDO POLÍTICO',
      }
      logoPreview.value = val.logo_url || null
    } else {
      form.value = {
        name: '',
        short_name: '',
        org_type: 'PARTIDO POLÍTICO',
      }
      logoPreview.value = null
    }
    logoFile.value = null
    errorMessage.value = null
  },
  { immediate: true }
)

const onFileSelected = (event: Event) => {
  const target = event.target as HTMLInputElement
  if (target.files && target.files[0]) {
    const file = target.files[0]
    logoFile.value = file

    const reader = new FileReader()
    reader.onload = (e) => {
      logoPreview.value = e.target?.result as string
    }
    reader.readAsDataURL(file)
  }
}

const triggerFileInput = () => {
  fileInputRef.value?.click()
}

const handleSave = async () => {
  if (!form.value.name) {
    errorMessage.value = 'El nombre de la organización política es obligatorio.'
    return
  }

  saving.value = true
  errorMessage.value = null

  try {
    const formData = new FormData()
    formData.append('name', form.value.name)
    if (form.value.short_name) {
      formData.append('short_name', form.value.short_name)
    }
    formData.append('org_type', form.value.org_type)

    if (logoFile.value) {
      formData.append('logo', logoFile.value)
    }

    if (isEdit.value && props.org) {
      await politicalOrganizationsService.update(props.org.id, formData)
    } else {
      await politicalOrganizationsService.create(formData)
    }

    emit('saved')
    emit('update:modelValue', false)
  } catch (err: any) {
    errorMessage.value = err?._data?.message || 'Error al guardar la organización política.'
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
          {{ isEdit ? `Editar Organización: ${org?.name}` : 'Registrar Organización Política' }}
        </span>
        <VBtn icon="ri-close-line" variant="text" density="compact" @click="emit('update:modelValue', false)" />
      </VCardTitle>

      <VCardText class="pa-4">
        <VAlert v-if="errorMessage" color="error" variant="tonal" class="mb-4">
          {{ errorMessage }}
        </VAlert>

        <!-- Subida y Previsualización de Logo (Conversión automática a WebP) -->
        <div class="d-flex align-center gap-x-4 mb-4 pa-3 border rounded bg-background">
          <VAvatar size="64" class="elevation-1 border" color="surface">
            <VImg
              v-if="logoPreview"
              :src="logoPreview"
              cover
            />
            <VIcon v-else icon="ri-flag-2-line" size="30" color="primary" />
          </VAvatar>

          <div>
            <div class="font-weight-medium text-body-2 mb-1">
              Logo de la Agrupación (Se optimiza a WebP)
            </div>
            <input
              ref="fileInputRef"
              type="file"
              accept="image/png,image/jpeg,image/jpg,image/webp,image/svg+xml"
              class="d-none"
              @change="onFileSelected"
            >
            <VBtn
              size="small"
              variant="tonal"
              color="primary"
              prepend-icon="ri-upload-cloud-2-line"
              @click="triggerFileInput"
            >
              {{ logoPreview ? 'Cambiar Logo' : 'Subir Logo' }}
            </VBtn>
            <span class="text-caption text-disabled ms-2">PNG, JPG, SVG hasta 5MB</span>
          </div>
        </div>

        <VRow dense>
          <VCol cols="12">
            <VTextField
              v-model="form.name"
              label="Nombre de la Organización Política"
              placeholder="Acción Popular, Fuerza Popular, Somos Perú..."
              variant="outlined"
              density="comfortable"
            />
          </VCol>
          <VCol cols="12" sm="6">
            <VTextField
              v-model="form.short_name"
              label="Sigla / Nombre Corto"
              placeholder="AP, FP, SP..."
              variant="outlined"
              density="comfortable"
            />
          </VCol>
          <VCol cols="12" sm="6">
            <VSelect
              v-model="form.org_type"
              label="Tipo de Organización"
              :items="[
                'PARTIDO POLÍTICO',
                'MOVIMIENTO REGIONAL',
                'ALIANZA ELECTORAL',
                'ORGANIZACIÓN LOCAL',
              ]"
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
          {{ isEdit ? 'Guardar Cambios' : 'Registrar Organización' }}
        </VBtn>
      </VCardActions>
    </VCard>
  </VDialog>
</template>
