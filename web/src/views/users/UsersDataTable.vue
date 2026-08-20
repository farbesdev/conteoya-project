<script setup lang="ts">
import { usersService, type UserItem } from '@/api/users.service'
import ResetPasswordDialog from './ResetPasswordDialog.vue'

const search = ref('')
const selectedRole = ref<string | null>(null)
const loading = ref(false)
const users = ref<UserItem[]>([])
const totalItems = ref(0)
const page = ref(1)
const itemsPerPage = ref(15)

const isResetOpen = ref(false)
const selectedUser = ref<UserItem | null>(null)

const isCreateOpen = ref(false)
const newUser = ref({
  name: '',
  email: '',
  password: '',
  role: 'DIRECTOR',
})
const savingUser = ref(false)
const createError = ref<string | null>(null)

const headers = [
  { title: 'ID', key: 'id', sortable: false },
  { title: 'Nombre Completo', key: 'name', sortable: false },
  { title: 'Email', key: 'email', sortable: false },
  { title: 'Rol', key: 'role', sortable: false },
  { title: 'Estado', key: 'is_active', sortable: false },
  { title: 'Acciones', key: 'actions', sortable: false, align: 'end' as const },
]

const loadUsers = async () => {
  loading.value = true
  try {
    const res = await usersService.list({
      search: search.value || undefined,
      role: selectedRole.value || undefined,
      page: page.value,
      per_page: itemsPerPage.value,
    })
    users.value = res.data
    totalItems.value = res.meta.total
  } catch (error) {
    console.error('Error cargando usuarios:', error)
  } finally {
    loading.value = false
  }
}

watch([page, itemsPerPage, selectedRole], () => {
  loadUsers()
})

const onSearchInput = useDebounceFn(() => {
  page.value = 1
  loadUsers()
}, 400)

const openResetDialog = (user: UserItem) => {
  selectedUser.value = user
  isResetOpen.value = true
}

const handleCreateUser = async () => {
  savingUser.value = true
  createError.value = null
  try {
    await usersService.create(newUser.value)
    isCreateOpen.value = false
    newUser.value = { name: '', email: '', password: '', role: 'DIRECTOR' }
    await loadUsers()
  } catch (err: any) {
    createError.value = err?._data?.message || 'Error al crear usuario.'
  } finally {
    savingUser.value = false
  }
}

onMounted(() => {
  loadUsers()
})
</script>

<template>
  <div>
    <VCard class="border" elevation="0">
      <VCardItem class="pb-2">
        <template #title>
          <div class="d-flex align-center justify-space-between flex-wrap gap-2">
            <div class="d-flex align-center gap-x-2">
              <VIcon icon="ri-shield-user-line" color="primary" />
              <span class="text-h6 font-weight-bold">Administración de Usuarios y Roles</span>
            </div>
            <div class="d-flex align-center gap-x-2 flex-wrap">
              <VSelect
                v-model="selectedRole"
                :items="[
                  { title: 'Todos los roles', value: null },
                  { title: 'ADMIN', value: 'ADMIN' },
                  { title: 'DIRECTOR', value: 'DIRECTOR' },
                  { title: 'PERSONERO', value: 'PERSONERO' },
                ]"
                density="compact"
                variant="outlined"
                style="min-width: 160px;"
              />
              <VTextField
                v-model="search"
                density="compact"
                variant="outlined"
                placeholder="Buscar por nombre o email..."
                prepend-inner-icon="ri-search-line"
                style="min-width: 250px;"
                clearable
                @update:model-value="onSearchInput"
                @click:clear="loadUsers"
              />
              <VBtn
                variant="flat"
                color="primary"
                prepend-icon="ri-user-add-line"
                density="comfortable"
                @click="isCreateOpen = true"
              >
                Nuevo Usuario
              </VBtn>
            </div>
          </div>
        </template>
      </VCardItem>

      <VDivider />

      <VDataTableServer
        v-model:items-per-page="itemsPerPage"
        v-model:page="page"
        :headers="headers"
        :items="users"
        :items-length="totalItems"
        :loading="loading"
        density="comfortable"
        class="text-no-wrap"
      >
        <!-- Nombre -->
        <template #item.name="{ item }">
          <div class="d-flex align-center gap-x-2">
            <VAvatar size="32" color="primary" variant="tonal">
              <span class="text-caption font-weight-bold">{{ item.name[0] }}</span>
            </VAvatar>
            <span class="font-weight-medium">{{ item.name }}</span>
          </div>
        </template>

        <!-- Rol -->
        <template #item.role="{ item }">
          <VChip
            size="small"
            :color="item.role === 'ADMIN' ? 'error' : (item.role === 'DIRECTOR' ? 'primary' : 'secondary')"
            variant="tonal"
            class="font-weight-bold"
          >
            {{ item.role }}
          </VChip>
        </template>

        <!-- Estado -->
        <template #item.is_active="{ item }">
          <VChip size="x-small" :color="item.is_active ? 'success' : 'secondary'" variant="flat">
            {{ item.is_active ? 'Activo' : 'Inactivo' }}
          </VChip>
        </template>

        <!-- Acciones -->
        <template #item.actions="{ item }">
          <VBtn
            size="small"
            variant="tonal"
            color="secondary"
            prepend-icon="ri-key-2-line"
            @click="openResetDialog(item)"
          >
            Resetear Clave
          </VBtn>
        </template>
      </VDataTableServer>
    </VCard>

    <!-- Dialog Reset Clave -->
    <ResetPasswordDialog
      v-model="isResetOpen"
      :user="selectedUser"
      @saved="loadUsers"
    />

    <!-- Dialog Crear Usuario -->
    <VDialog v-model="isCreateOpen" max-width="500">
      <VCard>
        <VCardTitle class="d-flex justify-space-between align-center pa-4 border-b">
          <span class="text-h6 font-weight-bold">Crear Usuario del Sistema</span>
          <VBtn icon="ri-close-line" variant="text" density="compact" @click="isCreateOpen = false" />
        </VCardTitle>

        <VCardText class="pa-4">
          <VAlert v-if="createError" color="error" variant="tonal" class="mb-4">
            {{ createError }}
          </VAlert>

          <VTextField
            v-model="newUser.name"
            label="Nombre Completo"
            placeholder="Juan Pérez"
            variant="outlined"
            density="comfortable"
            class="mb-3"
          />

          <VTextField
            v-model="newUser.email"
            label="Correo Electrónico"
            placeholder="usuario@conteoya.pe"
            type="email"
            variant="outlined"
            density="comfortable"
            class="mb-3"
          />

          <VTextField
            v-model="newUser.password"
            label="Contraseña"
            placeholder="Min. 8 caracteres"
            type="password"
            variant="outlined"
            density="comfortable"
            class="mb-3"
          />

          <VSelect
            v-model="newUser.role"
            :items="[
              { title: 'DIRECTOR (Supervisión y control)', value: 'DIRECTOR' },
              { title: 'ADMIN (Acceso total al sistema)', value: 'ADMIN' },
            ]"
            label="Rol de Usuario"
            variant="outlined"
            density="comfortable"
          />
        </VCardText>

        <VCardActions class="pa-4 border-t d-flex justify-end gap-x-2">
          <VBtn variant="outlined" color="secondary" @click="isCreateOpen = false">
            Cancelar
          </VBtn>
          <VBtn variant="flat" color="primary" :loading="savingUser" @click="handleCreateUser">
            Guardar Usuario
          </VBtn>
        </VCardActions>
      </VCard>
    </VDialog>
  </div>
</template>
