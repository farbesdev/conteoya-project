<script setup lang="ts">
import { personerosService, type PersoneroItem } from '@/api/personeros.service'
import { mesasService, type PollingStationItem } from '@/api/mesas.service'

const props = defineProps<{
  modelValue: boolean
  personero: PersoneroItem | null
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', val: boolean): void
  (e: 'saved'): void
}>()

const isOpen = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val),
})

const searchStation = ref('')
const loadingStations = ref(false)
const availableStations = ref<PollingStationItem[]>([])
const selectedStationIds = ref<number[]>([])
const saving = ref(false)
const successMessage = ref<string | null>(null)
const errorMessage = ref<string | null>(null)

watch(() => props.personero, (p) => {
  if (p) {
    selectedStationIds.value = p.assigned_polling_stations?.map((s: any) => s.id) || []
  } else {
    selectedStationIds.value = []
  }
  successMessage.value = null
  errorMessage.value = null
}, { immediate: true })

const searchPollingStations = async (query: string) => {
  if (!query || query.length < 2) return
  loadingStations.value = true
  try {
    const res = await mesasService.list({ search: query, per_page: 20 })
    availableStations.value = res.data
  } catch (e) {
    console.error(e)
  } finally {
    loadingStations.value = false
  }
}

const saveAssignments = async () => {
  if (!props.personero) return
  saving.value = true
  errorMessage.value = null
  successMessage.value = null
  try {
    await personerosService.assignPollingStations(props.personero.id, selectedStationIds.value)
    successMessage.value = 'Mesas asignadas exitosamente.'
    emit('saved')
    setTimeout(() => {
      isOpen.value = false
    }, 1200)
  } catch (err: any) {
    errorMessage.value = err?._data?.message || 'Error al asignar mesas.'
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <VDialog v-model="isOpen" max-width="600" persistent>
    <VCard>
      <VCardTitle class="d-flex justify-space-between align-center pa-4 border-b">
        <span class="text-h6 font-weight-bold">
          Asignación de Mesas — {{ personero?.full_name || personero?.document_number }}
        </span>
        <VBtn icon="ri-close-line" variant="text" density="compact" @click="isOpen = false" />
      </VCardTitle>

      <VCardText class="pa-4">
        <VAlert v-if="successMessage" color="success" variant="tonal" class="mb-4">
          {{ successMessage }}
        </VAlert>

        <VAlert v-if="errorMessage" color="error" variant="tonal" class="mb-4">
          {{ errorMessage }}
        </VAlert>

        <div class="mb-4 text-body-2">
          <p class="mb-1"><strong>DNI:</strong> {{ personero?.document_number }}</p>
          <p class="mb-1"><strong>Organización:</strong> {{ personero?.political_org_name || 'N/A' }}</p>
          <p class="mb-0"><strong>Teléfono:</strong> {{ personero?.phone_number || 'N/A' }}</p>
        </div>

        <VDivider class="my-4" />

        <h4 class="text-subtitle-1 font-weight-bold mb-2">Buscar y Asignar Mesas</h4>
        <p class="text-caption text-medium-emphasis mb-3">
          Escriba el número de mesa (ej. 030390) o el nombre del distrito/local para asignar.
        </p>

        <VAutocomplete
          v-model="selectedStationIds"
          :items="availableStations"
          item-title="code"
          item-value="id"
          label="Mesas Electorales Asignadas"
          multiple
          chips
          closable-chips
          placeholder="Buscar por código de mesa..."
          :loading="loadingStations"
          variant="outlined"
          density="comfortable"
          @update:search="searchPollingStations"
        >
          <template #chip="{ props: chipProps, item }">
            <VChip v-bind="chipProps" color="primary" variant="tonal">
              Mesa {{ item.raw.code }} ({{ item.raw.district_name || 'Mesa' }})
            </VChip>
          </template>

          <template #item="{ props: itemProps, item }">
            <VListItem v-bind="itemProps" :title="`Mesa ${item.raw.code} - ${item.raw.location_name}`" :subtitle="`${item.raw.district_name}, ${item.raw.province_name} • ${item.raw.registered_voters} electores`" />
          </template>
        </VAutocomplete>
      </VCardText>

      <VCardActions class="pa-4 border-t d-flex justify-end gap-x-2">
        <VBtn variant="outlined" color="secondary" @click="isOpen = false">
          Cancelar
        </VBtn>
        <VBtn variant="flat" color="primary" :loading="saving" @click="saveAssignments">
          Guardar Asignación
        </VBtn>
      </VCardActions>
    </VCard>
  </VDialog>
</template>
