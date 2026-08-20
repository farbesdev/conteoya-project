<script setup lang="ts">
import MesasDataTable from '@/views/mesas/MesasDataTable.vue'

definePage({
  meta: {
    layout: 'default',
  },
})
</script>

<template>
  <div>
    <div class="d-flex align-center justify-space-between mb-4">
      <div>
        <h2 class="text-h5 font-weight-bold text-high-emphasis">Mesas Electorales</h2>
        <span class="text-caption text-medium-emphasis">
          Directorio nacional de 87,000 mesas, locales de votación y actas asignadas
        </span>
      </div>
    </div>

    <MesasDataTable />
  </div>
</template>
