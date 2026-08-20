<script setup lang="ts">
import type { UserItem } from '@/api/users.service'

const props = defineProps<{
  modelValue: boolean
  user: UserItem | null
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
}>()
</script>

<template>
  <VDialog
    :model-value="modelValue"
    max-width="500"
    @update:model-value="emit('update:modelValue', $event)"
  >
    <VCard v-if="user">
      <VCardTitle class="d-flex justify-space-between align-center pa-4 border-b">
        <div class="d-flex align-center gap-x-2">
          <VAvatar color="primary" variant="tonal" size="38">
            <span class="font-weight-bold">{{ user.name ? user.name[0] : 'U' }}</span>
          </VAvatar>
          <div>
            <span class="text-h6 font-weight-bold d-block">{{ user.name }}</span>
            <span class="text-caption text-medium-emphasis">ID de Cuenta: #{{ user.id }}</span>
          </div>
        </div>
        <VBtn icon="ri-close-line" variant="text" density="compact" @click="emit('update:modelValue', false)" />
      </VCardTitle>

      <VCardText class="pa-4">
        <VRow dense>
          <VCol cols="12" class="mb-2">
            <span class="text-caption text-medium-emphasis d-block">Correo Electrónico:</span>
            <span class="text-body-2 font-weight-medium">{{ user.email }}</span>
          </VCol>

          <VCol cols="12" sm="6" class="mb-2">
            <span class="text-caption text-medium-emphasis d-block">Rol de Acceso:</span>
            <VChip
              size="small"
              :color="user.role === 'ADMIN' ? 'error' : (user.role === 'DIRECTOR' ? 'primary' : 'secondary')"
              variant="tonal"
              class="font-weight-bold mt-1"
            >
              {{ user.role }}
            </VChip>
          </VCol>

          <VCol cols="12" sm="6" class="mb-2">
            <span class="text-caption text-medium-emphasis d-block">Estado de la Cuenta:</span>
            <VChip
              size="small"
              :color="user.is_active ? 'success' : 'secondary'"
              variant="flat"
              class="mt-1"
            >
              {{ user.is_active ? 'Activo' : 'Inactivo / Suspendido' }}
            </VChip>
          </VCol>

          <VCol cols="12" class="mt-2">
            <span class="text-caption text-medium-emphasis d-block">Fecha de Registro:</span>
            <span class="text-body-2">{{ user.created_at || 'Registro inicial del sistema' }}</span>
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
