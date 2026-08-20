<script setup lang="ts">
import type { ActItem } from '@/api/acts.service'

const props = defineProps<{
  act: ActItem | null
}>()

const formatNumber = (val?: number) => {
  if (val === undefined || val === null) return '0'
  return new Intl.NumberFormat('es-PE').format(val)
}
</script>

<template>
  <div v-if="act">
    <VTable density="comfortable" class="border rounded">
      <thead>
        <tr class="bg-surface">
          <th>Organización Política</th>
          <th class="text-center">Votos Digitados</th>
          <th class="text-center">Fuente</th>
          <th class="text-center">Confianza OCR/IA</th>
          <th class="text-center">Estado Consistencia</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="res in act.results" :key="res.political_organization_id">
          <td>
            <div class="d-flex align-center gap-x-2">
              <VAvatar size="26" color="primary" variant="tonal">
                <span class="text-caption font-weight-bold">
                  {{ res.political_organization?.short_name?.substring(0, 2) || 'P' }}
                </span>
              </VAvatar>
              <span class="font-weight-medium">{{ res.political_organization?.name || 'Organización' }}</span>
            </div>
          </td>
          <td class="text-center font-weight-bold text-h6">
            {{ formatNumber(res.votes) }}
          </td>
          <td class="text-center">
            <VChip
              size="x-small"
              :color="res.source === 'MANUAL' ? 'primary' : 'info'"
              variant="tonal"
            >
              {{ res.source }}
            </VChip>
          </td>
          <td class="text-center">
            <div v-if="res.confidence" class="d-flex align-center justify-center gap-x-1">
              <span class="text-caption font-weight-bold">{{ (res.confidence * 100).toFixed(0) }}%</span>
              <VIcon
                :icon="res.confidence > 0.8 ? 'ri-checkbox-circle-line' : 'ri-alert-line'"
                :color="res.confidence > 0.8 ? 'success' : 'warning'"
                size="16"
              />
            </div>
            <span v-else class="text-caption text-disabled">—</span>
          </td>
          <td class="text-center">
            <VChip size="x-small" color="success" variant="tonal">
              Confirmado por Personero
            </VChip>
          </td>
        </tr>
      </tbody>
    </VTable>

    <!-- Resumen de Totales del Acta -->
    <div v-if="act.totals" class="mt-4 pa-3 rounded bg-surface border">
      <div class="d-flex justify-space-between align-center flex-wrap gap-2 text-caption">
        <span>Votantes que votaron: <strong>{{ act.totals.voters_who_voted }}</strong></span>
        <span>Total Votos Emitidos: <strong>{{ act.totals.total_votes }}</strong></span>
        <span>Blancos: <strong>{{ act.totals.blank_votes }}</strong></span>
        <span>Nulos: <strong>{{ act.totals.null_votes }}</strong></span>
        <span>Impugnados: <strong>{{ act.totals.challenged_votes }}</strong></span>
        <VChip
          size="x-small"
          :color="act.totals.is_valid_total ? 'success' : 'warning'"
          variant="flat"
        >
          {{ act.totals.is_valid_total ? 'Totales Cuadrados' : 'Advertencia Totales' }}
        </VChip>
      </div>
    </div>
  </div>
</template>
