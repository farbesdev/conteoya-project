<script setup lang="ts">
import PoliticalOrgsDataTable from '@/views/organizaciones/PoliticalOrgsDataTable.vue'

definePage({
  meta: {
    layout: 'default',
    requiresAuth: true,
  },
})
</script>

<template>
  <div>
    <!-- Encabezado de la página -->
    <div class="mb-6">
      <h2 class="text-h4 font-weight-black mb-1">
        Organizaciones Políticas
      </h2>
      <p class="text-body-2 text-medium-emphasis mb-0">
        Gestión de partidos, alianzas y movimientos regionales participantes con logos vectoriales y rasterizados optimizados en WebP.
      </p>
    </div>

    <PoliticalOrgsDataTable />
  </div>
</template>
