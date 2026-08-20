<script setup lang="ts">
import { personerosService, type PersoneroItem } from '@/api/personeros.service'
import PersoneroAccessSwitch from './PersoneroAccessSwitch.vue'
import PersoneroDialog from './PersoneroDialog.vue'

const search = ref('')
const loading = ref(false)
const personeros = ref<PersoneroItem[]>([])
const totalItems = ref(0)
const page = ref(1)
const itemsPerPage = ref(15)

const isDialogOpen = ref(false)
const selectedPersonero = ref<PersoneroItem | null>(null)

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

const openAssignDialog = (p: PersoneroItem) => {
  selectedPersonero.value = p
  isDialogOpen.value = true
}

onMounted(() => {
  loadPersoneros()
})
</script>

<template>
  <div>
    <VCard class="border" elevation="0">
      <VCardItem class="pb-2">
        <template #title>
          <div class="d-flex align-center justify-space-between flex-wrap gap-2">
            <div class="d-flex align-center gap-x-2">
              <VIcon icon="ri-user-shared-line" color="primary" />
              <span class="text-h6 font-weight-bold">Directorio de Personeros Electorales</span>
            </div>
            <div class="d-flex align-center gap-x-2">
              <VTextField
                v-model="search"
                density="compact"
                variant="outlined"
                placeholder="Buscar por DNI, nombres o partido..."
                prepend-inner-icon="ri-search-line"
                style="min-width: 320px;"
                clearable
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
            </div>
          </div>
        </template>
      </VCardItem>

      <VDivider />

      <VDataTableServer
        v-model:items-per-page="itemsPerPage"
        v-model:page="page"
        :headers="headers"
        :items="personeros"
        :items-length="totalItems"
        :loading="loading"
        density="comfortable"
        class="text-no-wrap"
      >
        <!-- DNI -->
        <template #item.document_number="{ item }">
          <span class="font-weight-bold text-primary">{{ item.document_number }}</span>
        </template>

        <!-- Nombres -->
        <template #item.full_name="{ item }">
          <div class="d-flex align-center gap-x-2">
            <VAvatar size="30" color="primary" variant="tonal">
              <span class="text-caption font-weight-bold">
                {{ item.first_name ? item.first_name[0] : (item.full_name ? item.full_name[0] : 'P') }}
              </span>
            </VAvatar>
            <span>{{ item.full_name || `${item.first_name || ''} ${item.last_name_paternal || ''} ${item.last_name_maternal || ''}`.trim() || 'Sin Nombre' }}</span>
          </div>
        </template>

        <!-- Organización Política -->
        <template #item.political_org_name="{ item }">
          <span class="text-body-2 text-medium-emphasis">
            {{ item.political_org_name || 'N/A' }}
          </span>
        </template>

        <!-- Teléfono -->
        <template #item.phone_number="{ item }">
          <span class="text-body-2">{{ item.phone_number || '—' }}</span>
        </template>

        <!-- Mesas Asignadas -->
        <template #item.polling_stations="{ item }">
          <div class="d-flex align-center gap-x-1 flex-wrap">
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

        <!-- Acciones -->
        <template #item.actions="{ item }">
          <VBtn
            size="small"
            variant="tonal"
            color="primary"
            prepend-icon="ri-archive-line"
            @click="openAssignDialog(item)"
          >
            Mesas
          </VBtn>
        </template>
      </VDataTableServer>
    </VCard>

    <!-- Diálogo de asignación multi-mesa -->
    <PersoneroDialog
      v-model="isDialogOpen"
      :personero="selectedPersonero"
      @saved="loadPersoneros"
    />
  </div>
</template>
