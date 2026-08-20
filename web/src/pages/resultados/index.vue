<script setup lang="ts">
import { useResultsStore } from '@/stores/useResultsStore'
import { useRealtimeStore } from '@/stores/useRealtimeStore'
import { useAuthStore } from '@/stores/useAuthStore'
import NavbarThemeSwitcher from '@/layouts/components/NavbarThemeSwitcher.vue'
import ResultsSummaryCards from '@/views/resultados/ResultsSummaryCards.vue'
import ElectionBarsChart from '@/views/resultados/ElectionBarsChart.vue'
import UbigeoCascadeFilter from '@/views/resultados/UbigeoCascadeFilter.vue'
import PresentationMode from '@/views/resultados/PresentationMode.vue'

definePage({
  meta: {
    layout: 'blank',
    public: true,
  },
})

const resultsStore = useResultsStore()
const realtimeStore = useRealtimeStore()
const authStore = useAuthStore()

const isPresentationOpen = ref(false)

onMounted(() => {
  resultsStore.fetchElectionResults()
  realtimeStore.startListening()
})

onUnmounted(() => {
  realtimeStore.stopListening()
})
</script>

<template>
  <div class="results-public-layout min-h-screen bg-surface">
    <!-- Navbar Superior Público Standalone (Sin layout default) -->
    <header class="public-header border-b bg-background px-4 py-3 sticky-top">
      <div class="d-flex align-center justify-space-between max-w-7xl mx-auto flex-wrap gap-2">
        <!-- Logo y Título -->
        <div class="d-flex align-center gap-x-3">
          <VAvatar color="primary" variant="flat" size="42" class="elevation-1">
            <VIcon icon="ri-bar-chart-2-fill" size="24" color="white" />
          </VAvatar>
          <div>
            <h1 class="text-h5 font-weight-black text-primary mb-0 d-flex align-center gap-x-2">
              ConteoYA <span class="text-caption font-weight-bold text-medium-emphasis">ERM 2026</span>
            </h1>
            <span class="text-caption text-medium-emphasis">
              Consolidación Electoral y Cómputo Rápido en Tiempo Real
            </span>
          </div>
        </div>

        <!-- Acciones: Indicador en Vivo, Selector de Tema, Modo TV, Botón de Acceso -->
        <div class="d-flex align-center gap-x-2">
          <!-- Indicador Realtime -->
          <VChip
            :color="realtimeStore.isConnected ? 'success' : 'warning'"
            variant="tonal"
            size="small"
            class="font-weight-bold d-none d-sm-flex"
          >
            <VIcon icon="ri-pulse-line" class="me-1" />
            {{ realtimeStore.isConnected ? 'EN VIVO' : 'ACTUALIZANDO' }}
          </VChip>

          <!-- Selector de Tema (Light / Dark / System) -->
          <NavbarThemeSwitcher />

          <!-- Modo TV / Proyección -->
          <VBtn
            variant="tonal"
            color="primary"
            prepend-icon="ri-tv-line"
            size="small"
            @click="isPresentationOpen = true"
          >
            Modo TV
          </VBtn>

          <!-- Acceso al Panel / Login -->
          <VBtn
            v-if="authStore.isAuthenticated"
            to="/admin/dashboard"
            variant="flat"
            color="primary"
            prepend-icon="ri-dashboard-line"
            size="small"
          >
            Panel Admin
          </VBtn>

          <VBtn
            v-else
            to="/login"
            variant="outlined"
            color="secondary"
            prepend-icon="ri-lock-line"
            size="small"
          >
            Acceso Personeros
          </VBtn>
        </div>
      </div>
    </header>

    <!-- Contenido Principal -->
    <main class="max-w-7xl mx-auto pa-4 pa-sm-6">
      <!-- Filtros de Ubigeo -->
      <UbigeoCascadeFilter />

      <!-- Tarjetas de KPIs -->
      <ResultsSummaryCards
        :summary="resultsStore.summary"
        :loading="resultsStore.loading"
        class="mb-6"
      />

      <!-- Gráfico de Resultados por Partido -->
      <ElectionBarsChart
        :organizations="resultsStore.organizations"
        :loading="resultsStore.loading"
      />
    </main>

    <!-- Modal de Modo TV / Pantalla Completa -->
    <PresentationMode
      v-if="isPresentationOpen"
      @close="isPresentationOpen = false"
    />
  </div>
</template>

<style scoped>
.results-public-layout {
  min-height: 100vh;
}
.max-w-7xl {
  max-width: 1280px;
  width: 100%;
}
.sticky-top {
  position: sticky;
  top: 0;
  z-index: 100;
}
</style>
