<script setup lang="ts">
import { useResultsStore } from '@/stores/useResultsStore'
import { useRealtimeStore } from '@/stores/useRealtimeStore'
import ResultsSummaryCards from '@/views/resultados/ResultsSummaryCards.vue'
import ElectionBarsChart from '@/views/resultados/ElectionBarsChart.vue'

definePage({
  meta: {
    layout: 'default',
  },
})

const resultsStore = useResultsStore()
const realtimeStore = useRealtimeStore()

onMounted(() => {
  resultsStore.fetchElectionResults()
  realtimeStore.startListening()
})

onUnmounted(() => {
  realtimeStore.stopListening()
})

const formatNumber = (val?: number) => {
  if (val === undefined || val === null) return '0'
  return new Intl.NumberFormat('es-PE').format(val)
}
</script>

<template>
  <div>
    <!-- Encabezado de Control -->
    <div class="d-flex align-center justify-space-between flex-wrap gap-2 mb-6">
      <div>
        <h2 class="text-h5 font-weight-bold text-high-emphasis">
          Panel de Control Electoral — ConteoYA
        </h2>
        <span class="text-caption text-medium-emphasis">
          Supervisión en vivo de ingesta, auditoría de actas y consolidación nacional
        </span>
      </div>

      <div class="d-flex align-center gap-x-2">
        <!-- Indicador y Toggle de Tiempo Real / Pausa (Ahorro de Recursos) -->
        <VBtn
          :color="realtimeStore.isPaused ? 'secondary' : (realtimeStore.isConnected ? 'success' : 'warning')"
          :variant="realtimeStore.isPaused ? 'outlined' : 'tonal'"
          size="small"
          class="font-weight-bold"
          :prepend-icon="realtimeStore.isPaused ? 'ri-pause-circle-line' : 'ri-pulse-line'"
          @click="realtimeStore.togglePause()"
        >
          {{ realtimeStore.isPaused ? 'En Pausa (Ahorro VPS)' : (realtimeStore.isConnected ? 'En Vivo (Reverb)' : 'En Vivo (Polling)') }}
        </VBtn>

        <VBtn
          to="/resultados"
          target="_blank"
          variant="outlined"
          color="primary"
          size="small"
          prepend-icon="ri-external-link-line"
        >
          Ver Dashboard Público
        </VBtn>

        <VBtn
          icon="ri-refresh-line"
          variant="tonal"
          color="secondary"
          density="comfortable"
          :loading="resultsStore.loading"
          @click="resultsStore.fetchElectionResults()"
        />
      </div>
    </div>

    <!-- KPIs Principales -->
    <ResultsSummaryCards
      :summary="resultsStore.summary"
      :loading="resultsStore.loading"
      class="mb-6"
    />

    <!-- Layout Dividido: Gráfico de Votos y Actividad en Vivo -->
    <VRow>
      <!-- Gráfico de Votos Consolidados -->
      <VCol cols="12" lg="8">
        <ElectionBarsChart
          :organizations="resultsStore.organizations"
          :loading="resultsStore.loading"
        />
      </VCol>

      <!-- Feed de Actividad en Vivo -->
      <VCol cols="12" lg="4">
        <VCard class="border h-100" elevation="0">
          <VCardItem class="pb-2">
            <template #title>
              <div class="d-flex align-center justify-space-between">
                <div class="d-flex align-center gap-x-2">
                  <VIcon icon="ri-radar-line" color="primary" />
                  <span class="text-subtitle-1 font-weight-bold">Actividad en Vivo</span>
                </div>
                <VChip
                  size="x-small"
                  :color="realtimeStore.isPaused ? 'secondary' : 'primary'"
                  variant="tonal"
                  class="cursor-pointer font-weight-bold"
                  @click="realtimeStore.togglePause()"
                >
                  {{ realtimeStore.isPaused ? 'Pausado' : 'Tiempo Real' }}
                </VChip>
              </div>
            </template>
          </VCardItem>

          <VDivider />

          <VCardText class="pa-4">
            <div v-if="realtimeStore.isPaused" class="text-center py-8 text-medium-emphasis">
              <VIcon icon="ri-pause-circle-line" size="40" class="mb-2 text-secondary" />
              <p class="text-body-2 font-weight-medium mb-1">Actualización en tiempo real pausada</p>
              <span class="text-caption text-disabled">Modo ahorro de CPU/RAM activo. Haz clic en el botón superior para reanudar o refresca manualmente.</span>
            </div>

            <div v-else-if="!realtimeStore.recentActivities.length" class="text-center py-8 text-medium-emphasis">
              <VIcon icon="ri-broadcast-line" size="40" class="mb-2 text-primary" />
              <p class="text-body-2 mb-0">Esperando confirmación de nuevas actas electorales...</p>
            </div>

            <VTimeline
              v-else
              density="compact"
              side="end"
              class="v-timeline--dense"
            >
              <VTimelineItem
                v-for="act in realtimeStore.recentActivities"
                :key="act.id"
                :dot-color="act.color"
                size="x-small"
              >
                <div class="d-flex justify-space-between align-center mb-1">
                  <span class="text-caption font-weight-bold text-high-emphasis">{{ act.text }}</span>
                  <span class="text-caption text-disabled ms-2">{{ act.time }}</span>
                </div>
              </VTimelineItem>
            </VTimeline>
          </VCardText>
        </VCard>
      </VCol>
    </VRow>
  </div>
</template>
