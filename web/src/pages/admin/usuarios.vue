<script setup lang="ts">
import UsersDataTable from '@/views/users/UsersDataTable.vue'

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
        <h2 class="text-h5 font-weight-bold text-high-emphasis">Gestión de Usuarios</h2>
        <span class="text-caption text-medium-emphasis">
          Administración de cuentas con roles de Administrador y Director
        </span>
      </div>
    </div>

    <UsersDataTable />
  </div>
</template>
