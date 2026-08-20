<script setup lang="ts">
import type { PoliticalOrganizationFullItem } from '@/api/political-organizations.service'

const props = defineProps<{
  modelValue: boolean
  org: PoliticalOrganizationFullItem | null
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
}>()
</script>

<template>
  <VDialog
    :model-value="modelValue"
    max-width="560"
    @update:model-value="emit('update:modelValue', $event)"
  >
    <VCard v-if="org">
      <VCardTitle class="d-flex justify-space-between align-center pa-4 border-b">
        <div class="d-flex align-center gap-x-2">
          <VIcon icon="ri-flag-2-line" color="primary" />
          <span class="text-h6 font-weight-bold">Ficha de Organización Política</span>
        </div>
        <VBtn icon="ri-close-line" variant="text" density="compact" @click="emit('update:modelValue', false)" />
      </VCardTitle>

      <VCardText class="pa-4">
        <!-- Logo y Nombre -->
        <div class="d-flex align-center gap-x-4 mb-4">
          <VAvatar size="72" class="elevation-2 border" color="surface">
            <VImg
              v-if="org.logo_url"
              :src="org.logo_url"
              cover
            />
            <VIcon v-else icon="ri-flag-2-fill" size="36" color="primary" />
          </VAvatar>
          <div>
            <h3 class="text-h6 font-weight-bold mb-1">{{ org.name }}</h3>
            <div class="d-flex align-center gap-2 flex-wrap">
              <VChip v-if="org.short_name" size="small" color="primary" variant="tonal" class="font-weight-bold">
                Sigla: {{ org.short_name }}
              </VChip>
              <VChip size="small" color="secondary" variant="outlined">
                {{ org.org_type || 'PARTIDO POLÍTICO' }}
              </VChip>
            </div>
          </div>
        </div>

        <VDivider class="my-3" />

        <VRow dense>
          <VCol cols="12" sm="6">
            <span class="text-caption text-medium-emphasis d-block">ID JEE:</span>
            <span class="text-body-2 font-weight-bold text-primary">{{ org.jee_id || 'Registro Local' }}</span>
          </VCol>
          <VCol cols="12" sm="6">
            <span class="text-caption text-medium-emphasis d-block">Tipo de Organización:</span>
            <span class="text-body-2 font-weight-medium">{{ org.org_type }}</span>
          </VCol>
          <VCol cols="12" class="mt-2">
            <span class="text-caption text-medium-emphasis d-block">URL del Logo (.webp):</span>
            <span class="text-caption text-truncate d-block text-disabled">{{ org.logo_url || 'No asignada' }}</span>
          </VCol>
        </VRow>
      </VCardText>

      <VCardActions class="pa-4 border-t d-flex justify-end">
        <VBtn variant="outlined" color="secondary" @click="emit('update:modelValue', false)">
          Cerrar
        </VBtn>
      </VCardActions>
    </VCard>
  </VDialog>
</template>
