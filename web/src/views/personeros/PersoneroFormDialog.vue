<script setup lang="ts">
import { catalogsService, type PoliticalOrgItem } from '@/api/catalogs.service'
import { personerosService, type PersoneroItem } from '@/api/personeros.service'
import { useDebounceFn } from '@vueuse/core'

const props = defineProps<{
  modelValue: boolean
  personero: PersoneroItem | null
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
  (e: 'saved'): void
}>()

const isEdit = computed(() => !!props.personero?.id)

const form = ref({
  document_number: '',
  first_name: '',
  last_name: '',
  name: '',
  email: '',
  phone_number: '',
  political_organization_id: null as number | null,
  political_org_name: '',
  abogado_responsable: '',
})

// Búsqueda bajo demanda de Organizaciones Políticas (sin cargar las 74 por defecto)
const orgSearch = ref('')
const politicalOrgs = ref<PoliticalOrgItem[]>([])
const loadingOrgs = ref(false)

const searchOrgs = useDebounceFn(async (query: string) => {
  if (!query || query.trim().length < 2) {
    return
  }
  loadingOrgs.value = true
  try {
    const res = await catalogsService.getPoliticalOrganizations(query.trim())
    politicalOrgs.value = res.data || []
  } catch (error) {
    console.error('Error buscando partidos:', error)
  } finally {
    loadingOrgs.value = false
  }
}, 300)

const onOrgSearchInput = (val: string) => {
  if (val && typeof val === 'string') {
    searchOrgs(val)
  }
}

const onOrgChange = (orgId: number | null) => {
  if (!orgId) {
    form.value.political_org_name = ''
    return
  }
  const found = politicalOrgs.value.find(o => o.id === orgId)
  if (found) {
    form.value.political_org_name = found.name
  }
}

const saving = ref(false)
const errorMessage = ref<string | null>(null)

watch(
  () => props.personero,
  (val) => {
    if (val) {
      const orgName = val.political_org_name || val.political_organization_name || ''
      form.value = {
        document_number: val.document_number || '',
        first_name: val.first_name || '',
        last_name: val.last_name_paternal || '',
        name: val.full_name || '',
        email: val.email || '',
        phone_number: val.phone_number || '',
        political_organization_id: null,
        political_org_name: orgName,
        abogado_responsable: val.abogado_responsable || '',
      }

      // Si tiene partido asignado, inicializar únicamente ese partido en la lista
      if (orgName) {
        politicalOrgs.value = [
          {
            id: 0,
            name: orgName,
            logo_url: val.political_org_logo || undefined,
          },
        ]
        form.value.political_organization_id = 0
      } else {
        politicalOrgs.value = []
      }
    } else {
      form.value = {
        document_number: '',
        first_name: '',
        last_name: '',
        name: '',
        email: '',
        phone_number: '',
        political_organization_id: null,
        political_org_name: '',
        abogado_responsable: '',
      }
      politicalOrgs.value = []
      orgSearch.value = ''
    }
    errorMessage.value = null
  },
  { immediate: true }
)

const handleSave = async () => {
  if (!form.value.document_number) {
    errorMessage.value = 'El número de DNI es obligatorio.'
    return
  }

  saving.value = true
  errorMessage.value = null

  try {
    const payload = {
      ...form.value,
      // Si el id es 0 (item preexistente con solo nombre), no enviar id numérico
      political_organization_id: form.value.political_organization_id && form.value.political_organization_id > 0
        ? form.value.political_organization_id
        : null,
    }

    if (isEdit.value && props.personero) {
      await personerosService.update(props.personero.id, payload)
    } else {
      await personerosService.create(payload)
    }
    emit('saved')
    emit('update:modelValue', false)
  } catch (err: any) {
    errorMessage.value = err?._data?.message || 'Error al procesar el personero.'
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <VDialog
    :model-value="modelValue"
    max-width="620"
    @update:model-value="emit('update:modelValue', $event)"
  >
    <VCard>
      <VCardTitle class="d-flex justify-space-between align-center pa-4 border-b">
        <div class="d-flex align-center gap-x-2">
          <VAvatar color="primary" variant="tonal" size="34">
            <VIcon icon="ri-user-shared-line" size="20" />
          </VAvatar>
          <span class="text-h6 font-weight-bold">
            {{ isEdit ? 'Editar Personero Electoral' : 'Registrar Nuevo Personero' }}
          </span>
        </div>
        <VBtn icon="ri-close-line" variant="text" density="compact" @click="emit('update:modelValue', false)" />
      </VCardTitle>

      <VCardText class="pa-4">
        <VAlert v-if="errorMessage" color="error" variant="tonal" class="mb-4">
          {{ errorMessage }}
        </VAlert>

        <VRow dense>
          <!-- DNI y Teléfono -->
          <VCol cols="12" sm="6">
            <VTextField
              v-model="form.document_number"
              label="DNI (8 dígitos)"
              placeholder="12345678"
              variant="outlined"
              density="comfortable"
              :disabled="isEdit"
              maxlength="12"
            />
          </VCol>
          <VCol cols="12" sm="6">
            <VTextField
              v-model="form.phone_number"
              label="Teléfono / Móvil"
              placeholder="987654321"
              variant="outlined"
              density="comfortable"
            />
          </VCol>

          <!-- Nombres y Apellidos -->
          <VCol cols="12" sm="6">
            <VTextField
              v-model="form.first_name"
              label="Nombres"
              placeholder="Juan Carlos"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
          <VCol cols="12" sm="6">
            <VTextField
              v-model="form.last_name"
              label="Apellidos"
              placeholder="Pérez Gómez"
              variant="outlined"
              density="comfortable"
            />
          </VCol>

          <!-- Correo Electrónico -->
          <VCol cols="12">
            <VTextField
              v-model="form.email"
              label="Correo Electrónico"
              placeholder="personero@partido.pe"
              type="email"
              variant="outlined"
              density="comfortable"
            />
          </VCol>

          <!-- VAutocomplete de Organización Política con Búsqueda Remota Bajo Demanda -->
          <VCol cols="12">
            <VAutocomplete
              v-model="form.political_organization_id"
              :items="politicalOrgs"
              item-title="name"
              item-value="id"
              :loading="loadingOrgs"
              no-filter
              clearable
              label="Organización Política / Partido"
              placeholder="Escriba para buscar partido o alianza (ej. Popular, Alianza, Nacional)..."
              prepend-inner-icon="ri-search-2-line"
              variant="outlined"
              density="comfortable"
              no-data-text="Escriba al menos 2 letras para buscar partidos registrados..."
              @update:search="onOrgSearchInput"
              @update:model-value="onOrgChange"
            >
              <!-- Ítem del menú desplegable con logo -->
              <template #item="{ props: itemProps, item }">
                <VListItem v-bind="itemProps" :title="undefined">
                  <template #prepend>
                    <VAvatar size="28" class="elevation-1 border me-2" color="surface">
                      <VImg
                        v-if="item.raw.logo_url"
                        :src="item.raw.logo_url"
                        cover
                      />
                      <VIcon v-else icon="ri-flag-2-fill" size="14" color="primary" />
                    </VAvatar>
                  </template>
                  <VListItemTitle class="font-weight-medium text-body-2">
                    {{ item.raw.name }}
                  </VListItemTitle>
                  <VListItemSubtitle v-if="item.raw.short_name" class="text-caption text-medium-emphasis">
                    {{ item.raw.short_name }}
                  </VListItemSubtitle>
                </VListItem>
              </template>

              <!-- Selección actual -->
              <template #selection="{ item }">
                <div class="d-flex align-center gap-x-2">
                  <VAvatar size="22" class="elevation-1 border" color="surface">
                    <VImg
                      v-if="item.raw.logo_url"
                      :src="item.raw.logo_url"
                      cover
                    />
                    <VIcon v-else icon="ri-flag-2-fill" size="12" color="primary" />
                  </VAvatar>
                  <span class="text-body-2 font-weight-medium">{{ item.raw.name }}</span>
                </div>
              </template>
            </VAutocomplete>
          </VCol>

          <!-- Abogado Responsable JEE -->
          <VCol cols="12">
            <VTextField
              v-model="form.abogado_responsable"
              label="Abogado Responsable JEE (Opcional)"
              placeholder="Dr. Carlos Mendoza - Reg. CAL 45123"
              prepend-inner-icon="ri-scales-3-line"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
        </VRow>
      </VCardText>

      <VCardActions class="pa-4 border-t d-flex justify-end gap-2">
        <VBtn variant="outlined" color="secondary" :disabled="saving" @click="emit('update:modelValue', false)">
          Cancelar
        </VBtn>
        <VBtn variant="flat" color="primary" :loading="saving" @click="handleSave">
          {{ isEdit ? 'Guardar Cambios' : 'Crear Personero' }}
        </VBtn>
      </VCardActions>
    </VCard>
  </VDialog>
</template>
