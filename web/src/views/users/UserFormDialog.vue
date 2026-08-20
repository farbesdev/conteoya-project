<script setup lang="ts">
import { usersService, type UserItem } from '@/api/users.service'

const props = defineProps<{
  modelValue: boolean
  user: UserItem | null
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
  (e: 'saved'): void
}>()

const isEdit = computed(() => !!props.user?.id)

const form = ref({
  name: '',
  email: '',
  password: '',
  role: 'DIRECTOR',
  is_active: true,
})

const saving = ref(false)
const errorMessage = ref<string | null>(null)

watch(
  () => props.user,
  (val) => {
    if (val) {
      form.value = {
        name: val.name || '',
        email: val.email || '',
        password: '',
        role: val.role || 'DIRECTOR',
        is_active: val.is_active ?? true,
      }
    } else {
      form.value = {
        name: '',
        email: '',
        password: '',
        role: 'DIRECTOR',
        is_active: true,
      }
    }
    errorMessage.value = null
  },
  { immediate: true }
)

const handleSave = async () => {
  if (!form.value.name || !form.value.email) {
    errorMessage.value = 'El nombre y correo electrónico son obligatorios.'
    return
  }

  saving.value = true
  errorMessage.value = null

  try {
    if (isEdit.value && props.user) {
      await usersService.update(props.user.id, {
        name: form.value.name,
        email: form.value.email,
        role: form.value.role,
        is_active: form.value.is_active,
      })
    } else {
      if (!form.value.password) {
        errorMessage.value = 'La contraseña es obligatoria para nuevos usuarios.'
        saving.value = false
        return
      }
      await usersService.create(form.value)
    }

    emit('saved')
    emit('update:modelValue', false)
  } catch (err: any) {
    errorMessage.value = err?._data?.message || 'Error al guardar el usuario.'
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <VDialog
    :model-value="modelValue"
    max-width="500"
    @update:model-value="emit('update:modelValue', $event)"
  >
    <VCard>
      <VCardTitle class="d-flex justify-space-between align-center pa-4 border-b">
        <span class="text-h6 font-weight-bold">
          {{ isEdit ? `Editar Usuario: ${user?.name}` : 'Crear Usuario del Sistema' }}
        </span>
        <VBtn icon="ri-close-line" variant="text" density="compact" @click="emit('update:modelValue', false)" />
      </VCardTitle>

      <VCardText class="pa-4">
        <VAlert v-if="errorMessage" color="error" variant="tonal" class="mb-4">
          {{ errorMessage }}
        </VAlert>

        <VTextField
          v-model="form.name"
          label="Nombre Completo"
          placeholder="Juan Pérez"
          variant="outlined"
          density="comfortable"
          class="mb-3"
        />

        <VTextField
          v-model="form.email"
          label="Correo Electrónico"
          placeholder="usuario@conteoya.pe"
          type="email"
          variant="outlined"
          density="comfortable"
          class="mb-3"
        />

        <VTextField
          v-if="!isEdit"
          v-model="form.password"
          label="Contraseña"
          placeholder="Min. 8 caracteres"
          type="password"
          variant="outlined"
          density="comfortable"
          class="mb-3"
        />

        <VSelect
          v-model="form.role"
          :items="[
            { title: 'DIRECTOR (Supervisión y control)', value: 'DIRECTOR' },
            { title: 'ADMIN (Acceso total al sistema)', value: 'ADMIN' },
            { title: 'PERSONERO (Captura móvil y actas)', value: 'PERSONERO' },
          ]"
          label="Rol de Usuario"
          variant="outlined"
          density="comfortable"
          class="mb-3"
        />

        <VSwitch
          v-if="isEdit"
          v-model="form.is_active"
          label="Usuario Activo"
          color="primary"
          density="compact"
        />
      </VCardText>

      <VCardActions class="pa-4 border-t d-flex justify-end gap-x-2">
        <VBtn variant="outlined" color="secondary" :disabled="saving" @click="emit('update:modelValue', false)">
          Cancelar
        </VBtn>
        <VBtn variant="flat" color="primary" :loading="saving" @click="handleSave">
          {{ isEdit ? 'Guardar Cambios' : 'Crear Usuario' }}
        </VBtn>
      </VCardActions>
    </VCard>
  </VDialog>
</template>
