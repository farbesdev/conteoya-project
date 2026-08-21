<script setup lang="ts">
import CandidatesDataTable from '@/views/candidatos/CandidatesDataTable.vue'

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
        Padrón de Candidatos
      </h2>
      <p class="text-body-2 text-medium-emphasis mb-0">
        Directorio fotográfico y registro de candidaturas oficiales JEE para las Elecciones Regionales y Municipales 2026.
      </p>
    </div>

    <CandidatesDataTable />
  </div>
</template>
