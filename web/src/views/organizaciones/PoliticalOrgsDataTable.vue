<script setup lang="ts">
import { politicalOrganizationsService, type PoliticalOrganizationFullItem } from '@/api/political-organizations.service'
import { useDebounceFn } from '@vueuse/core'
import DesktopDatatable from '@/components/DesktopDatatable.vue'
import MovilCardList from '@/components/MovilCardList.vue'
import PoliticalOrgDetailDialog from './PoliticalOrgDetailDialog.vue'
import PoliticalOrgFormDialog from './PoliticalOrgFormDialog.vue'

const search = ref('')
const loading = ref(false)
const orgs = ref<PoliticalOrganizationFullItem[]>([])
const totalItems = ref(0)
const page = ref(1)
const itemsPerPage = ref(15)

// Modal Detalle
const isDetailOpen = ref(false)
const orgToDetail = ref<PoliticalOrganizationFullItem | null>(null)

// Modal Crear / Editar
const isFormOpen = ref(false)
const orgToEdit = ref<PoliticalOrganizationFullItem | null>(null)

// Modal Eliminar
const isDeleteDialogOpen = ref(false)
const orgToDelete = ref<PoliticalOrganizationFullItem | null>(null)
const deleting = ref(false)

const headers = [
  { title: '#', key: 'index', sortable: false, align: 'center' as const },
  { title: 'Logo', key: 'logo', sortable: false, align: 'center' as const },
  { title: 'Organización Política', key: 'name', sortable: false },
  { title: 'Sigla', key: 'short_name', sortable: false, align: 'center' as const },
  { title: 'Tipo', key: 'org_type', sortable: false },
  { title: 'Acciones', key: 'actions', sortable: false, align: 'end' as const },
]

const loadOrgs = async () => {
  loading.value = true
  try {
    const res = await politicalOrganizationsService.list({
      search: search.value || undefined,
      page: page.value,
      per_page: itemsPerPage.value,
    })
    orgs.value = res.data
    totalItems.value = res.meta.total
  } catch (error) {
    console.error('Error cargando organizaciones políticas:', error)
  } finally {
    loading.value = false
  }
}

watch([page, itemsPerPage], () => {
  loadOrgs()
})

const onSearchInput = useDebounceFn(() => {
  page.value = 1
  loadOrgs()
}, 400)

const openCreateDialog = () => {
  orgToEdit.value = null
  isFormOpen.value = true
}

const openEditDialog = (org: PoliticalOrganizationFullItem) => {
  orgToEdit.value = org
  isFormOpen.value = true
}

const openDetailDialog = (org: PoliticalOrganizationFullItem) => {
  orgToDetail.value = org
  isDetailOpen.value = true
}

const confirmDelete = (org: PoliticalOrganizationFullItem) => {
  orgToDelete.value = org
  isDeleteDialogOpen.value = true
}

const handleDelete = async () => {
  if (!orgToDelete.value) return
  deleting.value = true
  try {
    await politicalOrganizationsService.delete(orgToDelete.value.id)
    isDeleteDialogOpen.value = false
    orgToDelete.value = null
    await loadOrgs()
  } catch (error) {
    console.error('Error al eliminar organización política:', error)
  } finally {
    deleting.value = false
  }
}

onMounted(() => {
  loadOrgs()
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
              <VIcon icon="ri-flag-2-line" color="primary" size="22" />
            </VAvatar>
            <div>
              <span class="text-h6 font-weight-bold d-block">Organizaciones Políticas</span>
              <span class="text-caption text-medium-emphasis">Partidos y movimientos registrados con logos optimizados en WebP</span>
            </div>
          </div>
          <div class="d-flex align-center gap-2 flex-wrap flex-grow-1 flex-sm-grow-0">
            <VTextField
              v-model="search"
              density="compact"
              variant="outlined"
              placeholder="Buscar por partido o sigla..."
              prepend-inner-icon="ri-search-line"
              style="min-width: 220px;"
              clearable
              hide-details
              @update:model-value="onSearchInput"
              @click:clear="loadOrgs"
            />
            <VBtn
              icon="ri-refresh-line"
              variant="tonal"
              color="secondary"
              density="comfortable"
              :loading="loading"
              @click="loadOrgs"
            />
            <VBtn
              variant="flat"
              color="primary"
              prepend-icon="ri-add-line"
              density="comfortable"
              @click="openCreateDialog"
            >
              Nueva Organización
            </VBtn>
          </div>
        </div>
      </VCardItem>
    </VCard>

    <!-- Vista Desktop: Tabla con Logos -->
    <DesktopDatatable
      v-model:page="page"
      v-model:items-per-page="itemsPerPage"
      :headers="headers"
      :items="orgs"
      :items-length="totalItems"
      :loading="loading"
      loading-text="Cargando organizaciones políticas..."
      no-data-text="No se encontraron organizaciones políticas."
    >
      <!-- Numeración (#) -->
      <template #item.index="{ index }">
        <span class="font-weight-bold text-medium-emphasis">
          #{{ (page - 1) * itemsPerPage + index + 1 }}
        </span>
      </template>

      <!-- Logo Oficial Centrado -->
      <template #item.logo="{ item }">
        <div class="d-flex justify-center py-1">
          <VAvatar size="36" class="elevation-1 border cursor-pointer" color="surface" @click="openDetailDialog(item)">
            <VImg
              v-if="item.logo_url"
              :src="item.logo_url"
              cover
            />
            <VIcon v-else icon="ri-flag-2-fill" size="18" color="primary" />
          </VAvatar>
        </div>
      </template>

      <!-- Nombre de la Organización -->
      <template #item.name="{ item }">
        <div class="cursor-pointer" @click="openDetailDialog(item)">
          <div class="font-weight-bold text-high-emphasis">{{ item.name }}</div>
          <small v-if="item.jee_id" class="text-caption text-medium-emphasis">
            ID JEE: <span class="text-primary">{{ item.jee_id }}</span>
          </small>
        </div>
      </template>

      <!-- Sigla -->
      <template #item.short_name="{ item }">
        <VChip v-if="item.short_name" size="small" color="primary" variant="tonal" class="font-weight-bold">
          {{ item.short_name }}
        </VChip>
        <span v-else class="text-disabled">—</span>
      </template>

      <!-- Tipo de Organización -->
      <template #item.org_type="{ item }">
        <VChip size="x-small" color="secondary" variant="outlined">
          {{ item.org_type || 'PARTIDO POLÍTICO' }}
        </VChip>
      </template>

      <!-- Acciones Completas CRUD -->
      <template #item.actions="{ item }">
        <div class="d-flex align-center justify-end gap-1">
          <VTooltip text="Ver Ficha" location="top">
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

          <VTooltip text="Editar Organización y Logo" location="top">
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

          <VTooltip text="Eliminar Organización" location="top">
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

    <!-- Vista Móvil: Tarjetas con Logo -->
    <MovilCardList
      v-model:page="page"
      :items="orgs"
      :items-length="totalItems"
      :items-per-page="itemsPerPage"
      :loading="loading"
      loading-text="Cargando organizaciones..."
      no-data-text="No se encontraron organizaciones."
    >
      <template #card="{ item }">
        <div class="d-flex justify-space-between align-start mb-2">
          <div class="d-flex align-center gap-x-3">
            <VAvatar size="44" class="elevation-1 border" color="surface">
              <VImg
                v-if="item.logo_url"
                :src="item.logo_url"
                cover
              />
              <VIcon v-else icon="ri-flag-2-fill" size="20" color="primary" />
            </VAvatar>
            <div>
              <div class="font-weight-bold text-subtitle-2 line-clamp-1 cursor-pointer" @click="openDetailDialog(item)">
                {{ item.name }}
              </div>
              <div class="text-caption text-primary font-weight-medium">
                {{ item.short_name || item.org_type }}
              </div>
            </div>
          </div>
          <VChip size="x-small" color="secondary" variant="outlined">
            {{ item.org_type }}
          </VChip>
        </div>

        <div class="d-flex justify-end align-center gap-2 pt-2 border-t">
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
            color="error"
            icon="ri-delete-bin-line"
            @click="confirmDelete(item)"
          />
        </div>
      </template>
    </MovilCardList>

    <!-- Modal Detalle -->
    <PoliticalOrgDetailDialog
      v-model="isDetailOpen"
      :org="orgToDetail"
    />

    <!-- Modal Formulario Crear / Editar con Subida de Logo WebP -->
    <PoliticalOrgFormDialog
      v-model="isFormOpen"
      :org="orgToEdit"
      @saved="loadOrgs"
    />

    <!-- Modal Confirmar Eliminación -->
    <VDialog v-model="isDeleteDialogOpen" max-width="450">
      <VCard class="pa-2">
        <VCardTitle class="d-flex align-center gap-x-2 text-error">
          <VIcon icon="ri-error-warning-line" />
          <span>Eliminar Organización Política</span>
        </VCardTitle>
        <VCardText>
          ¿Está seguro de que desea eliminar la organización <strong>{{ orgToDelete?.name }}</strong>?
        </VCardText>
        <VCardActions class="d-flex justify-end gap-2">
          <VBtn variant="outlined" color="secondary" :disabled="deleting" @click="isDeleteDialogOpen = false">
            Cancelar
          </VBtn>
          <VBtn variant="flat" color="error" :loading="deleting" @click="handleDelete">
            Eliminar Organización
          </VBtn>
        </VCardActions>
      </VCard>
    </VDialog>
  </div>
</template>
