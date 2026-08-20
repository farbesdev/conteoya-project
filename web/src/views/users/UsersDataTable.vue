<script setup lang="ts">
import { usersService, type UserItem } from '@/api/users.service'
import { useDebounceFn } from '@vueuse/core'
import DesktopDatatable from '@/components/DesktopDatatable.vue'
import MovilCardList from '@/components/MovilCardList.vue'
import ResetPasswordDialog from './ResetPasswordDialog.vue'
import UserDetailDialog from './UserDetailDialog.vue'
import UserFormDialog from './UserFormDialog.vue'

const search = ref('')
const selectedRole = ref<string | null>(null)
const loading = ref(false)
const users = ref<UserItem[]>([])
const totalItems = ref(0)
const page = ref(1)
const itemsPerPage = ref(15)

// Modal Reset Clave
const isResetOpen = ref(false)
const selectedUser = ref<UserItem | null>(null)

// Modal Mostrar Detalle
const isDetailOpen = ref(false)
const userToDetail = ref<UserItem | null>(null)

// Modal Crear / Editar Formulario
const isFormOpen = ref(false)
const userToEdit = ref<UserItem | null>(null)

// Modal Eliminar Usuario
const isDeleteDialogOpen = ref(false)
const userToDelete = ref<UserItem | null>(null)
const deleting = ref(false)

const headers = [
  { title: '#', key: 'index', sortable: false, align: 'center' as const },
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

const openCreateDialog = () => {
  userToEdit.value = null
  isFormOpen.value = true
}

const openEditDialog = (user: UserItem) => {
  userToEdit.value = user
  isFormOpen.value = true
}

const openDetailDialog = (user: UserItem) => {
  userToDetail.value = user
  isDetailOpen.value = true
}

const openResetDialog = (user: UserItem) => {
  selectedUser.value = user
  isResetOpen.value = true
}

const confirmDelete = (user: UserItem) => {
  userToDelete.value = user
  isDeleteDialogOpen.value = true
}

const handleDelete = async () => {
  if (!userToDelete.value) return
  deleting.value = true
  try {
    await usersService.delete(userToDelete.value.id)
    isDeleteDialogOpen.value = false
    userToDelete.value = null
    await loadUsers()
  } catch (error) {
    console.error('Error al eliminar usuario:', error)
  } finally {
    deleting.value = false
  }
}

onMounted(() => {
  loadUsers()
})
</script>

<template>
  <div class="d-flex flex-column gap-y-4">
    <!-- Barra Superior -->
    <VCard class="border" elevation="0">
      <VCardItem class="py-3">
        <div class="d-flex align-center justify-space-between flex-wrap gap-3">
          <div class="d-flex align-center gap-x-2">
            <VAvatar color="primary" variant="tonal" size="40">
              <VIcon icon="ri-shield-user-line" color="primary" size="22" />
            </VAvatar>
            <div>
              <span class="text-h6 font-weight-bold d-block">Administración de Cuentas y Accesos</span>
              <span class="text-caption text-medium-emphasis">Gestión de roles y restablecimiento de credenciales</span>
            </div>
          </div>
          <div class="d-flex align-center gap-2 flex-wrap flex-grow-1 flex-sm-grow-0">
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
              style="min-width: 150px;"
              hide-details
            />
            <VTextField
              v-model="search"
              density="compact"
              variant="outlined"
              placeholder="Buscar por nombre o email..."
              prepend-inner-icon="ri-search-line"
              style="min-width: 200px;"
              clearable
              hide-details
              @update:model-value="onSearchInput"
              @click:clear="loadUsers"
            />
            <VBtn
              icon="ri-refresh-line"
              variant="tonal"
              color="secondary"
              density="comfortable"
              :loading="loading"
              @click="loadUsers"
            />
            <VBtn
              variant="flat"
              color="primary"
              prepend-icon="ri-user-add-line"
              density="comfortable"
              @click="openCreateDialog"
            >
              Nuevo Usuario
            </VBtn>
          </div>
        </div>
      </VCardItem>
    </VCard>

    <!-- Vista Desktop: Tabla -->
    <DesktopDatatable
      v-model:page="page"
      v-model:items-per-page="itemsPerPage"
      :headers="headers"
      :items="users"
      :items-length="totalItems"
      :loading="loading"
      loading-text="Cargando usuarios..."
      no-data-text="No se encontraron usuarios registrados."
    >
      <!-- Numeración (#) -->
      <template #item.index="{ index }">
        <span class="font-weight-bold text-medium-emphasis">
          #{{ (page - 1) * itemsPerPage + index + 1 }}
        </span>
      </template>

      <!-- Nombre Completo con DNI debajo -->
      <template #item.name="{ item }">
        <div class="d-flex align-center gap-x-3 cursor-pointer py-1" @click="openDetailDialog(item)">
          <VAvatar size="34" color="primary" variant="tonal">
            <span class="text-caption font-weight-bold">{{ item.name ? item.name[0] : 'U' }}</span>
          </VAvatar>
          <div>
            <div class="font-weight-medium text-high-emphasis">{{ item.name }}</div>
            <small class="text-caption text-medium-emphasis">
              DNI: <span class="font-weight-bold text-primary">{{ item.personero?.document_number || '—' }}</span>
            </small>
          </div>
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

      <!-- Acciones Completas CRUD -->
      <template #item.actions="{ item }">
        <div class="d-flex align-center justify-end gap-1">
          <VTooltip text="Ver Detalle de Usuario" location="top">
            <template #activator="{ props: tipProps }">
              <VBtn
                v-bind="tipProps"
                size="small"
                variant="text"
                color="info"
                icon="ri-eye-line"
                @click="openDetailDialog(item)"
              />
            </template>
          </VTooltip>

          <VTooltip text="Editar Usuario" location="top">
            <template #activator="{ props: tipProps }">
              <VBtn
                v-bind="tipProps"
                size="small"
                variant="text"
                color="primary"
                icon="ri-edit-line"
                @click="openEditDialog(item)"
              />
            </template>
          </VTooltip>

          <VTooltip text="Restablecer Contraseña" location="top">
            <template #activator="{ props: tipProps }">
              <VBtn
                v-bind="tipProps"
                size="small"
                variant="text"
                color="secondary"
                icon="ri-key-2-line"
                @click="openResetDialog(item)"
              />
            </template>
          </VTooltip>

          <VTooltip text="Eliminar Usuario" location="top">
            <template #activator="{ props: tipProps }">
              <VBtn
                v-bind="tipProps"
                size="small"
                variant="text"
                color="error"
                icon="ri-delete-bin-line"
                @click="confirmDelete(item)"
              />
            </template>
          </VTooltip>
        </div>
      </template>
    </DesktopDatatable>

    <!-- Vista Móvil: Tarjetas -->
    <MovilCardList
      v-model:page="page"
      :items="users"
      :items-length="totalItems"
      :items-per-page="itemsPerPage"
      :loading="loading"
      loading-text="Cargando usuarios..."
      no-data-text="No se encontraron usuarios."
    >
      <template #card="{ item }">
        <div class="d-flex justify-space-between align-start mb-2">
          <div class="d-flex align-center gap-x-2">
            <VAvatar size="34" color="primary" variant="tonal">
              <span class="font-weight-bold">{{ item.name ? item.name[0] : 'U' }}</span>
            </VAvatar>
            <div>
              <div class="font-weight-bold text-subtitle-2 line-clamp-1 cursor-pointer" @click="openDetailDialog(item)">
                {{ item.name }}
              </div>
              <div class="text-caption text-medium-emphasis">
                {{ item.email }} • DNI: {{ item.personero?.document_number || '—' }}
              </div>
            </div>
          </div>
          <VChip
            size="x-small"
            :color="item.role === 'ADMIN' ? 'error' : (item.role === 'DIRECTOR' ? 'primary' : 'secondary')"
            variant="tonal"
            class="font-weight-bold"
          >
            {{ item.role }}
          </VChip>
        </div>

        <div class="d-flex justify-space-between align-center bg-background pa-2 rounded mb-3 text-caption">
          <div>
            <span class="text-medium-emphasis">Estado:</span>
            <span :class="item.is_active ? 'text-success font-weight-bold ms-1' : 'text-disabled ms-1'">
              {{ item.is_active ? 'Activo' : 'Inactivo' }}
            </span>
          </div>
        </div>

        <div class="d-flex justify-end align-center flex-wrap gap-2 pt-2 border-t">
          <VBtn
            size="small"
            variant="text"
            color="info"
            icon="ri-eye-line"
            @click="openDetailDialog(item)"
          />
          <VBtn
            size="small"
            variant="text"
            color="primary"
            icon="ri-edit-line"
            @click="openEditDialog(item)"
          />
          <VBtn
            size="small"
            variant="text"
            color="secondary"
            icon="ri-key-2-line"
            @click="openResetDialog(item)"
          />
          <VBtn
            size="small"
            variant="text"
            color="error"
            icon="ri-delete-bin-line"
            @click="confirmDelete(item)"
          />
        </div>
      </template>
    </MovilCardList>

    <!-- Dialog Ficha Detalle Usuario -->
    <UserDetailDialog
      v-model="isDetailOpen"
      :user="userToDetail"
    />

    <!-- Dialog Crear / Editar Usuario -->
    <UserFormDialog
      v-model="isFormOpen"
      :user="userToEdit"
      @saved="loadUsers"
    />

    <!-- Dialog Reset Clave -->
    <ResetPasswordDialog
      v-model="isResetOpen"
      :user="selectedUser"
      @saved="loadUsers"
    />

    <!-- Dialog Eliminar Usuario -->
    <VDialog v-model="isDeleteDialogOpen" max-width="450">
      <VCard class="pa-2">
        <VCardTitle class="d-flex align-center gap-x-2 text-error">
          <VIcon icon="ri-error-warning-line" />
          <span>Eliminar Usuario</span>
        </VCardTitle>
        <VCardText>
          ¿Está seguro de que desea eliminar al usuario <strong>{{ userToDelete?.name }}</strong> ({{ userToDelete?.email }})?
          Esta acción revocará todas sus sesiones activas permanentemente.
        </VCardText>
        <VCardActions class="d-flex justify-end gap-2">
          <VBtn variant="outlined" color="secondary" :disabled="deleting" @click="isDeleteDialogOpen = false">
            Cancelar
          </VBtn>
          <VBtn variant="flat" color="error" :loading="deleting" @click="handleDelete">
            Eliminar Usuario
          </VBtn>
        </VCardActions>
      </VCard>
    </VDialog>
  </div>
</template>
