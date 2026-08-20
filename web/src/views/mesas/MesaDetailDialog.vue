<script setup lang="ts">
import type { PollingStationItem } from '@/api/mesas.service'
import { resultsService } from '@/api/results.service'

const props = defineProps<{
  modelValue: boolean
  mesa: PollingStationItem | null
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', val: boolean): void
}>()

const isOpen = computed({
  get: () => props.modelValue,
  set: (val) => emit('update:modelValue', val),
})

const loadingActs = ref(false)
const mesaActs = ref<any[]>([])

watch(() => props.mesa, async (m) => {
  if (!m) return
  loadingActs.value = true
  mesaActs.value = []
  try {
    const res = await resultsService.getStationResults(m.code)
    mesaActs.value = res.data?.acts || []
  } catch (e) {
    console.error(e)
  } finally {
    loadingActs.value = false
  }
}, { immediate: true })
</script>

<template>
  <VDialog v-model="isOpen" max-width="700">
    <VCard v-if="mesa">
      <VCardTitle class="d-flex justify-space-between align-center pa-4 border-b">
        <div class="d-flex align-center gap-x-2">
          <VIcon icon="ri-archive-line" color="primary" />
          <span class="text-h6 font-weight-bold">Ficha de Mesa Nº {{ mesa.code }}</span>
        </div>
        <VBtn icon="ri-close-line" variant="text" density="compact" @click="isOpen = false" />
      </VCardTitle>

      <VCardText class="pa-4">
        <!-- Detalles Generales -->
        <VRow class="mb-4">
          <VCol cols="12" sm="6">
            <div class="text-caption text-medium-emphasis">Local de Votación</div>
            <div class="font-weight-bold">{{ mesa.location_name }}</div>
            <div class="text-caption">{{ mesa.address || 'Sin dirección registrada' }}</div>
          </VCol>
          <VCol cols="12" sm="6">
            <div class="text-caption text-medium-emphasis">Ubicación Geográfica</div>
            <div class="font-weight-bold">{{ mesa.district_name }}, {{ mesa.province_name }}</div>
            <div class="text-caption">Departamento: {{ mesa.department_name }} • ODPE: {{ mesa.odpe || 'N/A' }}</div>
          </VCol>
          <VCol cols="12" sm="6">
            <div class="text-caption text-medium-emphasis">Electores Hábiles</div>
            <div class="font-weight-bold text-primary">{{ mesa.registered_voters }} registrados</div>
          </VCol>
          <VCol cols="12" sm="6">
            <div class="text-caption text-medium-emphasis">Estado de Mesa</div>
            <VChip size="small" :color="mesa.status === 'ACTIVE' ? 'success' : 'secondary'" variant="tonal">
              {{ mesa.status }}
            </VChip>
          </VCol>
        </VRow>

        <VDivider class="my-4" />

        <h4 class="text-subtitle-1 font-weight-bold mb-3">Actas Registradas en Esta Mesa</h4>

        <div v-if="loadingActs" class="text-center py-6">
          <VProgressCircular indeterminate color="primary" />
        </div>

        <div v-else-if="!mesaActs.length" class="text-center py-6 text-medium-emphasis">
          <VIcon icon="ri-file-warning-line" size="36" class="mb-1" />
          <p class="mb-0 text-caption">No se han registrado actas para esta mesa aún.</p>
        </div>

        <div v-else class="d-flex flex-column gap-y-3">
          <div
            v-for="act in mesaActs"
            :key="act.id"
            class="pa-3 rounded border bg-surface"
          >
            <div class="d-flex justify-space-between align-center mb-2">
              <span class="font-weight-bold text-body-2">Acta #{{ act.id }} ({{ act.act_code || 'S/N' }})</span>
              <VChip
                size="x-small"
                :color="act.status === 'CONFIRMED' || act.status === 'SYNCED' ? 'success' : 'warning'"
                variant="tonal"
                class="font-weight-bold"
              >
                {{ act.status }}
              </VChip>
            </div>

            <div v-if="act.totals" class="d-flex gap-x-3 text-caption text-medium-emphasis mb-2">
              <span>Emitidos: <strong>{{ act.totals.total_votes }}</strong></span>
              <span>Blancos: <strong>{{ act.totals.blank_votes }}</strong></span>
              <span>Nulos: <strong>{{ act.totals.null_votes }}</strong></span>
              <span>Impugnados: <strong>{{ act.totals.challenged_votes }}</strong></span>
            </div>

            <!-- Votos por partido -->
            <div v-if="act.results?.length" class="mt-2">
              <div
                v-for="res in act.results"
                :key="res.political_organization_id"
                class="d-flex justify-space-between text-caption py-1 border-t"
              >
                <span>{{ res.organization_name || 'Organización' }}</span>
                <span class="font-weight-bold">{{ res.votes }} votos ({{ res.source }})</span>
              </div>
            </div>
          </div>
        </div>
      </VCardText>

      <VCardActions class="pa-4 border-t d-flex justify-end">
        <VBtn variant="tonal" color="primary" @click="isOpen = false">
          Cerrar
        </VBtn>
      </VCardActions>
    </VCard>
  </VDialog>
</template>
