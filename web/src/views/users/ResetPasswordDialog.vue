<script setup lang="ts">
import { usersService, type UserItem } from '@/api/users.service'

const props = defineProps<{
  modelValue: boolean
  user: UserItem | null
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', val: boolean): void
  (e: 'saved'): void
}>()

const isOpen = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val),
})

const newPassword = ref('')
const saving = ref(false)
const generatedPassword = ref<string | null>(null)
const errorMessage = ref<string | null>(null)

watch(() => props.user, () => {
  newPassword.value = ''
  generatedPassword.value = null
  errorMessage.value = null
})

const handleReset = async () => {
  if (!props.user) return
  saving.value = true
  errorMessage.value = null
  generatedPassword.value = null
  try {
    const res = await usersService.resetPassword(props.user.id, newPassword.value || undefined)
    generatedPassword.value = res.generated_password || newPassword.value || 'Contraseña reseteada con éxito'
    emit('saved')
  } catch (err: any) {
    errorMessage.value = err?._data?.message || 'Error al resetear contraseña.'
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <VDialog v-model="isOpen" max-width="500">
    <VCard v-if="user">
      <VCardTitle class="d-flex justify-space-between align-center pa-4 border-b">
        <span class="text-h6 font-weight-bold">Resetear Contraseña — {{ user.name }}</span>
        <VBtn icon="ri-close-line" variant="text" density="compact" @click="isOpen = false" />
      </VCardTitle>

      <VCardText class="pa-4">
        <VAlert v-if="generatedPassword" color="success" variant="tonal" class="mb-4">
          <div class="text-subtitle-2 font-weight-bold">Nueva contraseña asignada:</div>
          <code class="text-h6 font-weight-black text-primary">{{ generatedPassword }}</code>
        </VAlert>

        <VAlert v-if="errorMessage" color="error" variant="tonal" class="mb-4">
          {{ errorMessage }}
        </VAlert>

        <p class="text-body-2 text-medium-emphasis mb-3">
          Deje el campo vacío para generar una contraseña segura aleatoria automáticamente, o escriba una nueva.
        </p>

        <VTextField
          v-model="newPassword"
          label="Nueva Contraseña (Opcional)"
          placeholder="Dejar en blanco para autogenerar"
          type="password"
          variant="outlined"
          density="comfortable"
        />
      </VCardText>

      <VCardActions class="pa-4 border-t d-flex justify-end gap-x-2">
        <VBtn variant="outlined" color="secondary" @click="isOpen = false">
          {{ generatedPassword ? 'Cerrar' : 'Cancelar' }}
        </VBtn>
        <VBtn
          v-if="!generatedPassword"
          variant="flat"
          color="primary"
          :loading="saving"
          @click="handleReset"
        >
          Confirmar Reseteo
        </VBtn>
      </VCardActions>
    </VCard>
  </VDialog>
</template>
