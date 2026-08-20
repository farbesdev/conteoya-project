<script setup lang="ts">
import ActsAuditView from '@/views/actas/ActsAuditView.vue'

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
        <h2 class="text-h5 font-weight-bold text-high-emphasis">Auditoría y Revisión de Actas</h2>
        <span class="text-caption text-medium-emphasis">
          Verificación de evidencias en Cloudflare R2, consistencia de sumas y comparativa de OCR asistido
        </span>
      </div>
    </div>

    <ActsAuditView />
  </div>
</template>
