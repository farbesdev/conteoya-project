<script setup lang="ts">
import type { PersoneroItem } from '@/api/personeros.service'

const props = defineProps<{
  modelValue: boolean
  personero: PersoneroItem | null
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
}>()
</script>

<template>
  <VDialog
    :model-value="modelValue"
    max-width="650"
    @update:model-value="emit('update:modelValue', $event)"
  >
    <VCard v-if="personero">
      <VCardTitle class="d-flex justify-space-between align-center pa-4 border-b">
        <div class="d-flex align-center gap-x-2">
          <VAvatar color="primary" variant="tonal" size="38">
            <VIcon icon="ri-user-shared-line" size="20" />
          </VAvatar>
          <div>
            <span class="text-h6 font-weight-bold d-block">Ficha de Personero Electoral</span>
            <span class="text-caption text-medium-emphasis">DNI: {{ personero.document_number }}</span>
          </div>
        </div>
        <VBtn icon="ri-close-line" variant="text" density="compact" @click="emit('update:modelValue', false)" />
      </VCardTitle>

      <VCardText class="pa-4">
        <!-- Datos de Identidad y Contacto -->
        <div class="mb-4">
          <h4 class="text-subtitle-2 font-weight-bold text-primary mb-2 d-flex align-center gap-1">
            <VIcon icon="ri-id-card-line" size="16" /> Datos Personales
          </h4>
          <VRow dense>
            <VCol cols="12" sm="6">
              <span class="text-caption text-medium-emphasis d-block">Nombre Completo:</span>
              <span class="text-body-2 font-weight-medium">{{ personero.full_name || `${personero.first_name || ''} ${personero.last_name_paternal || ''}`.trim() || 'No registrado' }}</span>
            </VCol>
            <VCol cols="12" sm="6">
              <span class="text-caption text-medium-emphasis d-block">Documento (DNI):</span>
              <span class="text-body-2 font-weight-bold text-primary">{{ personero.document_number }}</span>
            </VCol>
            <VCol cols="12" sm="6" class="mt-2">
              <span class="text-caption text-medium-emphasis d-block">Correo Electrónico:</span>
              <span class="text-body-2">{{ personero.email || '—' }}</span>
            </VCol>
            <VCol cols="12" sm="6" class="mt-2">
              <span class="text-caption text-medium-emphasis d-block">Teléfono / Celular:</span>
              <span class="text-body-2">{{ personero.phone_number || '—' }}</span>
            </VCol>
          </VRow>
        </div>

        <VDivider class="my-3" />

        <!-- Filiación Política y Acreditación JEE -->
        <div class="mb-4">
          <h4 class="text-subtitle-2 font-weight-bold text-primary mb-2 d-flex align-center gap-1">
            <VIcon icon="ri-flag-line" size="16" /> Filiación y Acreditación Electoral
          </h4>
          <VRow dense>
            <VCol cols="12" sm="6">
              <span class="text-caption text-medium-emphasis d-block">Organización Política:</span>
              <span class="text-body-2 font-weight-medium">{{ personero.political_org_name || personero.political_organization_name || 'Sin partido registrado' }}</span>
            </VCol>
            <VCol cols="12" sm="6">
              <span class="text-caption text-medium-emphasis d-block">Tipo de Personero:</span>
              <span class="text-body-2">{{ personero.personero_type || 'PERSONERO DE MESA' }}</span>
            </VCol>
            <VCol cols="12" sm="6" class="mt-2">
              <span class="text-caption text-medium-emphasis d-block">JEE Competente:</span>
              <span class="text-body-2">{{ personero.jee_name || 'JEE Lima Centro' }}</span>
            </VCol>
            <VCol cols="12" sm="6" class="mt-2">
              <span class="text-caption text-medium-emphasis d-block">Abogado Responsable:</span>
              <span class="text-body-2">{{ personero.abogado_responsable || '—' }}</span>
            </VCol>
          </VRow>
        </div>

        <VDivider class="my-3" />

        <!-- Mesas Asignadas -->
        <div>
          <h4 class="text-subtitle-2 font-weight-bold text-primary mb-2 d-flex align-center gap-1">
            <VIcon icon="ri-archive-line" size="16" /> Mesas Asignadas ({{ personero.assigned_polling_stations?.length || 0 }})
          </h4>
          <div v-if="personero.assigned_polling_stations && personero.assigned_polling_stations.length > 0" class="d-flex flex-wrap gap-2">
            <VChip
              v-for="st in personero.assigned_polling_stations"
              :key="st.id"
              color="primary"
              variant="tonal"
              size="small"
              class="font-weight-medium"
            >
              Mesa {{ st.code }} - {{ st.location_name || st.district_name || 'Local de Votación' }}
            </VChip>
          </div>
          <span v-else class="text-caption text-disabled">
            No tiene mesas de sufragio asignadas actualmente.
          </span>
        </div>
      </VCardText>

      <VCardActions class="pa-4 border-t d-flex justify-end">
        <VBtn variant="outlined" color="secondary" @click="emit('update:modelValue', false)">
          Cerrar
        </VBtn>
      </VCardActions>
    </VCard>
  </VDialog>
</template>
