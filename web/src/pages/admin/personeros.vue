<script setup lang="ts">
import PersonerosDataTable from '@/views/personeros/PersonerosDataTable.vue'

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
        <h2 class="text-h5 font-weight-bold text-high-emphasis">Gestión de Personeros</h2>
        <span class="text-caption text-medium-emphasis">
          Asignación multi-mesa, control de credenciales y activación de cuentas
        </span>
      </div>
    </div>

    <PersonerosDataTable />
  </div>
</template>
