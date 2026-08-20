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
  { title: 'DNI', key: 'document_number', sortable: false },
  { title: 'Personero', key: 'full_name', sortable: false },
  { title: 'Organización Política', key: 'political_org_name', sortable: false },
  { title: 'Teléfono', key: 'phone_number', sortable: false },
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
      <!-- DNI -->
      <template #item.document_number="{ item }">
        <span class="font-weight-bold text-primary cursor-pointer" @click="openDetailDialog(item)">
          {{ item.document_number }}
        </span>
      </template>

      <!-- Nombres -->
      <template #item.full_name="{ item }">
        <div class="d-flex align-center gap-x-2">
          <VAvatar size="30" color="primary" variant="tonal">
            <span class="text-caption font-weight-bold">
              {{ item.first_name ? item.first_name[0] : (item.full_name ? item.full_name[0] : 'P') }}
            </span>
          </VAvatar>
          <span class="font-weight-medium cursor-pointer" @click="openDetailDialog(item)">
            {{ item.full_name || `${item.first_name || ''} ${item.last_name_paternal || ''} ${item.last_name_maternal || ''}`.trim() || 'Sin Nombre' }}
          </span>
        </div>
      </template>

      <!-- Organización Política -->
      <template #item.political_org_name="{ item }">
        <span class="text-body-2 text-medium-emphasis">
          {{ item.political_org_name || item.political_organization_name || 'N/A' }}
        </span>
      </template>

      <!-- Teléfono -->
      <template #item.phone_number="{ item }">
        <span class="text-body-2">{{ item.phone_number || '—' }}</span>
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
                variant="tonal"
                color="primary"
                prepend-icon="ri-archive-line"
                @click="openAssignDialog(item)"
              >
                Mesas
              </VBtn>
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
                DNI: {{ item.document_number }}
              </div>
            </div>
          </div>
          <PersoneroAccessSwitch :personero="item" @updated="item.is_active = $event" />
        </div>

        <div class="text-caption text-medium-emphasis mb-2">
          <div class="d-flex align-center gap-1 mb-1">
            <VIcon icon="ri-flag-line" size="14" />
            <span>{{ item.political_org_name || item.political_organization_name || 'Sin partido registrado' }}</span>
          </div>
          <div v-if="item.phone_number" class="d-flex align-center gap-1">
            <VIcon icon="ri-phone-line" size="14" />
            <span>{{ item.phone_number }}</span>
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
            variant="tonal"
            color="primary"
            prepend-icon="ri-archive-line"
            @click="openAssignDialog(item)"
          >
            Mesas
          </VBtn>
          <VBtn
            size="small"
            variant="outlined"
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
