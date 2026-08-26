<script setup lang="ts">
import { personerosService, type PersoneroItem } from '@/api/personeros.service'
import { useDebounceFn } from '@vueuse/core'
import DesktopDatatable from '@/components/DesktopDatatable.vue'
import MovilCardList from '@/components/MovilCardList.vue'
import PersoneroAccessSwitch from './PersoneroAccessSwitch.vue'
import PersoneroDialog from './PersoneroDialog.vue'
import PersoneroDetailDialog from './PersoneroDetailDialog.vue'
import PersoneroFormDialog from './PersoneroFormDialog.vue'

const search = ref('')
const loading = ref(false)
const personeros = ref<PersoneroItem[]>([])
const totalItems = ref(0)
const page = ref(1)
const itemsPerPage = ref(15)
const is_active_filter = ref<boolean | undefined>(undefined)

// Diálogo Asignación Mesas
const isAssignOpen = ref(false)
const selectedPersonero = ref<PersoneroItem | null>(null)

// Diálogo Mostrar Detalle
const isDetailOpen = ref(false)
const personeroToDetail = ref<PersoneroItem | null>(null)

// Diálogo Crear / Editar Formulario
const isFormOpen = ref(false)
const personeroToEdit = ref<PersoneroItem | null>(null)

// Diálogo Eliminar
const isDeleteDialogOpen = ref(false)
const personeroToDelete = ref<PersoneroItem | null>(null)
const deleting = ref(false)

const headers = [
  { title: 'Personero', key: 'full_name', sortable: false },
  { title: 'Partido', key: 'political_org_name', sortable: false, align: 'center' as const },
  { title: 'Mesas Asignadas', key: 'polling_stations', sortable: false },
  { title: 'Acceso Activo', key: 'is_active', sortable: false },
  { title: 'Acciones', key: 'actions', sortable: false, align: 'end' as const },
]

const loadPersoneros = async () => {
  loading.value = true
  try {
    const res = await personerosService.list({
      search: search.value || undefined,
      page: page.value,
      per_page: itemsPerPage.value,
      is_active: is_active_filter.value,
    })
    personeros.value = res.data
    totalItems.value = res.meta.total
  } catch (error) {
    console.error('Error cargando personeros:', error)
  } finally {
    loading.value = false
  }
}

watch([page, itemsPerPage], () => {
  loadPersoneros()
})

watch(is_active_filter, () => {
  if (page.value === 1) {
    loadPersoneros()
  } else {
    page.value = 1
  }
})

const onSearchInput = useDebounceFn(() => {
  page.value = 1
  loadPersoneros()
}, 400)

const openCreateDialog = () => {
  personeroToEdit.value = null
  isFormOpen.value = true
}

const openEditDialog = (p: PersoneroItem) => {
  personeroToEdit.value = p
  isFormOpen.value = true
}

const openDetailDialog = (p: PersoneroItem) => {
  personeroToDetail.value = p
  isDetailOpen.value = true
}

const openAssignDialog = (p: PersoneroItem) => {
  selectedPersonero.value = p
  isAssignOpen.value = true
}

const confirmDelete = (p: PersoneroItem) => {
  personeroToDelete.value = p
  isDeleteDialogOpen.value = true
}

const handleDelete = async () => {
  if (!personeroToDelete.value) return
  deleting.value = true
  try {
    await personerosService.delete(personeroToDelete.value.id)
    isDeleteDialogOpen.value = false
    personeroToDelete.value = null
    await loadPersoneros()
  } catch (error) {
    console.error('Error al eliminar personero:', error)
  } finally {
    deleting.value = false
  }
}

onMounted(() => {
  loadPersoneros()
})
</script>

<template>
  <div class="d-flex flex-column gap-y-4">
    <!-- Barra Superior de Búsqueda y Acciones -->
    <VCard class="border" elevation="0">
      <VCardItem class="py-3">
        <div class="d-flex align-center justify-space-between flex-wrap gap-3">
          <div class="d-flex align-center gap-x-2">
            <VAvatar color="primary" variant="tonal" size="40">
              <VIcon icon="ri-user-shared-line" color="primary" size="22" />
            </VAvatar>
            <div>
              <span class="text-h6 font-weight-bold d-block">Directorio de Personeros Electorales</span>
              <span class="text-caption text-medium-emphasis">{{ totalItems }} personeros registrados</span>
            </div>
          </div>
          <div class="d-flex align-center gap-2 flex-wrap flex-grow-1 flex-sm-grow-0">
            <VTextField
              v-model="search"
              density="compact"
              variant="outlined"
              placeholder="Buscar por DNI, nombres o partido..."
              prepend-inner-icon="ri-search-line"
              clearable
              hide-details
              style="min-width: 220px;"
              @update:model-value="onSearchInput"
              @click:clear="loadPersoneros"
            />
            <VSelect
              v-model="is_active_filter"
              density="compact"
              variant="outlined"
              :items="[
                { title: 'Todos los estados', value: undefined },
                { title: 'Activos', value: true },
                { title: 'Inactivos', value: false }
              ]"
              item-title="title"
              item-value="value"
              hide-details
              style="min-width: 160px; max-width: 180px;"
            />
            <VBtn
              icon="ri-refresh-line"
              variant="tonal"
              color="secondary"
              density="comfortable"
              :loading="loading"
              @click="loadPersoneros"
            />
            <VBtn
              variant="flat"
              color="primary"
              prepend-icon="ri-user-add-line"
              density="comfortable"
              @click="openCreateDialog"
            >
              Nuevo Personero
            </VBtn>
          </div>
        </div>
      </VCardItem>
    </VCard>

    <!-- Vista Desktop: Tabla Avanzada -->
    <DesktopDatatable
      v-model:page="page"
      v-model:items-per-page="itemsPerPage"
      :headers="headers"
      :items="personeros"
      :items-length="totalItems"
      :loading="loading"
      loading-text="Cargando directorio de personeros..."
      no-data-text="No se encontraron personeros."
    >
      <!-- Personero: Nombre + DNI debajo -->
      <template #item.full_name="{ item }">
        <div class="d-flex align-center gap-x-3 cursor-pointer py-1" @click="openDetailDialog(item)">
          <VAvatar size="34" color="primary" variant="tonal">
            <span class="text-caption font-weight-bold">
              {{ item.first_name ? item.first_name[0] : (item.full_name ? item.full_name[0] : 'P') }}
            </span>
          </VAvatar>
          <div>
            <div class="font-weight-medium text-high-emphasis">
              {{ item.full_name || `${item.first_name || ''} ${item.last_name_paternal || ''} ${item.last_name_maternal || ''}`.trim() || 'Sin Nombre' }}
            </div>
            <small class="text-caption text-medium-emphasis">
              DNI: <span class="font-weight-bold text-primary">{{ item.document_number || item.dni }}</span>
            </small>
          </div>
        </div>
      </template>

      <!-- Partido: Solo Logo Centrado con Tooltip -->
      <template #item.political_org_name="{ item }">
        <div class="d-flex justify-center">
          <VTooltip :text="item.political_org_name || item.political_organization_name || 'Sin partido registrado'" location="top">
            <template #activator="{ props: tipProps }">
              <VAvatar v-bind="tipProps" size="34" class="elevation-1 border cursor-pointer" color="surface">
                <VImg
                  v-if="item.political_org_logo"
                  :src="item.political_org_logo"
                  cover
                />
                <VIcon v-else icon="ri-flag-2-fill" size="18" color="primary" />
              </VAvatar>
            </template>
          </VTooltip>
        </div>
      </template>

      <!-- Mesas Asignadas -->
      <template #item.polling_stations="{ item }">
        <div class="d-flex align-center gap-1 flex-wrap">
          <VChip
            v-for="st in (item.assigned_polling_stations || []).slice(0, 3)"
            :key="st.id"
            size="x-small"
            color="primary"
            variant="tonal"
          >
            {{ st.code }}
          </VChip>
          <VChip
            v-if="(item.assigned_polling_stations || []).length > 3"
            size="x-small"
            color="secondary"
            variant="outlined"
          >
            +{{ (item.assigned_polling_stations?.length || 0) - 3 }}
          </VChip>
          <span v-if="!item.assigned_polling_stations?.length" class="text-caption text-disabled">
            Sin mesas
          </span>
        </div>
      </template>

      <!-- Switch de Acceso -->
      <template #item.is_active="{ item }">
        <PersoneroAccessSwitch :personero="item" @updated="item.is_active = $event" />
      </template>

      <!-- Acciones Completas CRUD -->
      <template #item.actions="{ item }">
        <div class="d-flex align-center justify-end gap-1">
          <VTooltip text="Ver Ficha Detallada" location="top">
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

          <VTooltip text="Editar Personero" location="top">
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

          <VTooltip text="Asignar Mesas" location="top">
            <template #activator="{ props: tipProps }">
              <VBtn
                v-bind="tipProps"
                size="small"
                variant="text"
                color="primary"
                icon="ri-archive-line"
                @click="openAssignDialog(item)"
              />
            </template>
          </VTooltip>

          <VTooltip text="Eliminar Personero" location="top">
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

    <!-- Vista Móvil: Tarjetas Adaptativas -->
    <MovilCardList
      v-model:page="page"
      :items="personeros"
      :items-length="totalItems"
      :items-per-page="itemsPerPage"
      :loading="loading"
      loading-text="Cargando personeros..."
      no-data-text="No se encontraron personeros."
    >
      <template #card="{ item }">
        <div class="d-flex justify-space-between align-start mb-2">
          <div class="d-flex align-center gap-x-2">
            <VAvatar size="36" color="primary" variant="tonal">
              <span class="font-weight-bold">
                {{ item.first_name ? item.first_name[0] : (item.full_name ? item.full_name[0] : 'P') }}
              </span>
            </VAvatar>
            <div>
              <div class="font-weight-bold text-subtitle-2 line-clamp-1 cursor-pointer" @click="openDetailDialog(item)">
                {{ item.full_name || item.document_number }}
              </div>
              <div class="text-caption text-primary font-weight-medium">
                DNI: {{ item.document_number || item.dni }}
              </div>
            </div>
          </div>
          <PersoneroAccessSwitch :personero="item" @updated="item.is_active = $event" />
        </div>

        <div class="text-caption text-medium-emphasis mb-2">
          <div class="d-flex align-center gap-2 mb-1">
            <VAvatar size="22" class="elevation-1 border" color="surface">
              <VImg
                v-if="item.political_org_logo"
                :src="item.political_org_logo"
                cover
              />
              <VIcon v-else icon="ri-flag-line" size="12" color="primary" />
            </VAvatar>
            <span class="font-weight-medium text-high-emphasis">{{ item.political_org_name || item.political_organization_name || 'Sin partido registrado' }}</span>
          </div>
        </div>

        <!-- Mesas -->
        <div class="mb-3">
          <span class="text-caption font-weight-medium text-medium-emphasis d-block mb-1">Mesas asignadas:</span>
          <div class="d-flex gap-1 flex-wrap">
            <VChip
              v-for="st in (item.assigned_polling_stations || []).slice(0, 4)"
              :key="st.id"
              size="x-small"
              color="primary"
              variant="tonal"
            >
              {{ st.code }}
            </VChip>
            <VChip
              v-if="(item.assigned_polling_stations || []).length > 4"
              size="x-small"
              color="secondary"
              variant="outlined"
            >
              +{{ (item.assigned_polling_stations?.length || 0) - 4 }}
            </VChip>
            <span v-if="!item.assigned_polling_stations?.length" class="text-caption text-disabled">
              Ninguna asignada
            </span>
          </div>
        </div>

        <!-- Botones de Acción Móvil -->
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
            color="primary"
            icon="ri-archive-line"
            @click="openAssignDialog(item)"
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

    <!-- Diálogo Ficha / Detalle -->
    <PersoneroDetailDialog
      v-model="isDetailOpen"
      :personero="personeroToDetail"
    />

    <!-- Diálogo Formulario Crear / Editar -->
    <PersoneroFormDialog
      v-model="isFormOpen"
      :personero="personeroToEdit"
      @saved="loadPersoneros"
    />

    <!-- Diálogo de asignación multi-mesa -->
    <PersoneroDialog
      v-model="isAssignOpen"
      :personero="selectedPersonero"
      @saved="loadPersoneros"
    />

    <!-- Diálogo de confirmación de eliminación -->
    <VDialog v-model="isDeleteDialogOpen" max-width="450">
      <VCard class="pa-2">
        <VCardTitle class="d-flex align-center gap-x-2 text-error">
          <VIcon icon="ri-error-warning-line" />
          <span>Eliminar Personero</span>
        </VCardTitle>
        <VCardText>
          ¿Está seguro de que desea eliminar al personero
          <strong>{{ personeroToDelete?.full_name || personeroToDelete?.document_number }}</strong>?
          Esta acción desvinculará sus mesas asignadas y eliminará su cuenta de usuario asociada.
        </VCardText>
        <VCardActions class="d-flex justify-end gap-2">
          <VBtn variant="outlined" color="secondary" :disabled="deleting" @click="isDeleteDialogOpen = false">
            Cancelar
          </VBtn>
          <VBtn variant="flat" color="error" :loading="deleting" @click="handleDelete">
            Eliminar Definitivamente
          </VBtn>
        </VCardActions>
      </VCard>
    </VDialog>
  </div>
</template>
