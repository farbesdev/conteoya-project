<script setup lang="ts">
import { useResultsStore } from '@/stores/useResultsStore'
import { useRealtimeStore } from '@/stores/useRealtimeStore'

const emit = defineEmits<{
  (e: 'close'): void
}>()

const resultsStore = useResultsStore()
const realtimeStore = useRealtimeStore()

const formatNumber = (val?: number) => {
  if (val === undefined || val === null) return '0'
  return new Intl.NumberFormat('es-PE').format(val)
}
</script>

<template>
  <div class="presentation-container bg-grey-900 text-white pa-6 d-flex flex-column">
    <!-- Header -->
    <div class="d-flex align-center justify-space-between pb-4 border-b border-grey-700">
      <div class="d-flex align-center gap-x-4">
        <VAvatar color="primary" size="48" class="elevation-2">
          <VIcon icon="ri-bar-chart-fill" size="28" color="white" />
        </VAvatar>
        <div>
          <h1 class="text-h4 font-weight-black tracking-wide text-white mb-0">
            CONTEOYA — RESULTADOS EN VIVO
          </h1>
          <span class="text-subtitle-1 text-grey-400">
            Elecciones Regionales y Municipales 2026 • Modo Pantalla Gigante / TV
          </span>
        </div>
      </div>

      <div class="d-flex align-center gap-x-3">
        <VChip color="success" variant="flat" size="large" class="font-weight-bold">
          <VIcon icon="ri-pulse-line" class="me-1" /> EN VIVO
        </VChip>
        <VBtn icon="ri-close-large-line" variant="tonal" color="white" @click="emit('close')" />
      </div>
    </div>

    <!-- KPI Row -->
    <div class="grid-kpis my-6">
      <div class="kpi-box bg-grey-800 pa-4 rounded-lg border border-grey-700">
        <span class="text-caption text-uppercase text-grey-400 font-weight-bold">Actas Procesadas</span>
        <div class="text-h3 font-weight-black text-primary my-1">
          {{ resultsStore.summary?.coverage_percentage ?? 0 }}%
        </div>
        <span class="text-body-2 text-grey-300">
          {{ formatNumber(resultsStore.summary?.processed_stations) }} de {{ formatNumber(resultsStore.summary?.total_stations) }} mesas
        </span>
      </div>

      <div class="kpi-box bg-grey-800 pa-4 rounded-lg border border-grey-700">
        <span class="text-caption text-uppercase text-grey-400 font-weight-bold">Participación</span>
        <div class="text-h3 font-weight-black text-success my-1">
          {{ resultsStore.summary?.participation_percentage ?? 0 }}%
        </div>
        <span class="text-body-2 text-grey-300">
          {{ formatNumber(resultsStore.summary?.voters_who_voted) }} ciudadanos
        </span>
      </div>

      <div class="kpi-box bg-grey-800 pa-4 rounded-lg border border-grey-700">
        <span class="text-caption text-uppercase text-grey-400 font-weight-bold">Votos Válidos</span>
        <div class="text-h3 font-weight-black text-info my-1">
          {{ formatNumber(resultsStore.summary?.valid_votes) }}
        </div>
        <span class="text-body-2 text-grey-300">
          {{ resultsStore.summary?.valid_votes_percentage ?? 0 }}% del total
        </span>
      </div>

      <div class="kpi-box bg-grey-800 pa-4 rounded-lg border border-grey-700">
        <span class="text-caption text-uppercase text-grey-400 font-weight-bold">Blancos / Nulos</span>
        <div class="text-h3 font-weight-black text-warning my-1">
          {{ formatNumber((resultsStore.summary?.blank_votes ?? 0) + (resultsStore.summary?.null_votes ?? 0)) }}
        </div>
        <span class="text-body-2 text-grey-300">
          Blancos: {{ formatNumber(resultsStore.summary?.blank_votes) }} • Nulos: {{ formatNumber(resultsStore.summary?.null_votes) }}
        </span>
      </div>
    </div>

    <!-- Ranking Bars (Top 6) -->
    <div class="flex-grow-1 overflow-y-auto d-flex flex-column gap-y-3">
      <div
        v-for="(org, i) in resultsStore.organizations.slice(0, 6)"
        :key="org.political_organization_id"
        class="party-row bg-grey-800 pa-4 rounded-lg border border-grey-700"
      >
        <div class="d-flex align-center justify-space-between mb-2">
          <div class="d-flex align-center gap-x-3">
            <span class="text-h5 font-weight-black text-amber-400">#{{ org.rank }}</span>
            <span class="text-h6 font-weight-bold text-white">{{ org.organization_name }}</span>
            <span class="text-subtitle-2 text-grey-400">({{ org.short_name }})</span>
          </div>
          <div class="d-flex align-center gap-x-4">
            <span class="text-h5 font-weight-black text-white">{{ formatNumber(org.votes) }} votos</span>
            <VChip color="primary" variant="flat" size="large" class="font-weight-black text-h6">
              {{ org.percentage_valid_votes }}%
            </VChip>
          </div>
        </div>
        <VProgressLinear
          :model-value="org.percentage_valid_votes"
          color="primary"
          height="16"
          rounded
          striped
        />
      </div>
    </div>

    <!-- Ticker / Footer -->
    <div class="mt-4 pt-3 border-t border-grey-700 d-flex justify-space-between align-center text-caption text-grey-400">
      <span>Última actualización: {{ new Date(resultsStore.lastUpdated).toLocaleTimeString() }}</span>
      <span>ConteoYA — Sistema de Cómputo Rápido y Transparencia Electoral</span>
    </div>
  </div>
</template>

<style scoped>
.presentation-container {
  position: fixed;
  inset: 0;
  z-index: 9999;
  background-color: #0f172a;
}
.grid-kpis {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 1rem;
}
</style>
