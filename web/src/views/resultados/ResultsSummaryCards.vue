<script setup lang="ts">
import type { ResultsSummary } from '@/api/results.service'

const props = defineProps<{
  summary: ResultsSummary | null
  loading?: boolean
}>()

const formatNumber = (val?: number) => {
  if (val === undefined || val === null) return '0'
  return new Intl.NumberFormat('es-PE').format(val)
}
</script>

<template>
  <VRow>
    <!-- Cobertura y Actas Procesadas -->
    <VCol cols="12" sm="6" md="3">
      <VCard class="h-100 border" elevation="0">
        <VCardText>
          <div class="d-flex align-center justify-space-between mb-2">
            <span class="text-caption text-uppercase font-weight-bold text-medium-emphasis">Actas Procesadas</span>
            <VAvatar color="primary" variant="tonal" size="36">
              <VIcon icon="ri-file-chart-line" size="20" />
            </VAvatar>
          </div>
          <div class="d-flex align-baseline gap-x-2">
            <h3 class="text-h4 font-weight-bold text-primary">
              {{ summary?.coverage_percentage ?? 0 }}%
            </h3>
            <span class="text-body-2 text-medium-emphasis">
              ({{ formatNumber(summary?.processed_stations) }} / {{ formatNumber(summary?.total_stations) }})
            </span>
          </div>
          <VProgressLinear
            :model-value="summary?.coverage_percentage ?? 0"
            color="primary"
            height="8"
            rounded
            class="mt-3"
          />
          <div class="d-flex justify-space-between text-caption text-medium-emphasis mt-1">
            <span>Pendientes: {{ formatNumber(summary?.pending_stations) }}</span>
            <span>Confirmadas: {{ formatNumber(summary?.confirmed_acts_count) }}</span>
          </div>
        </VCardText>
      </VCard>
    </VCol>

    <!-- Participación Ciudadana -->
    <VCol cols="12" sm="6" md="3">
      <VCard class="h-100 border" elevation="0">
        <VCardText>
          <div class="d-flex align-center justify-space-between mb-2">
            <span class="text-caption text-uppercase font-weight-bold text-medium-emphasis">Participación Ciudadana</span>
            <VAvatar color="success" variant="tonal" size="36">
              <VIcon icon="ri-user-voice-line" size="20" />
            </VAvatar>
          </div>
          <div class="d-flex align-baseline gap-x-2">
            <h3 class="text-h4 font-weight-bold text-success">
              {{ summary?.participation_percentage ?? 0 }}%
            </h3>
            <span class="text-body-2 text-medium-emphasis">
              ({{ formatNumber(summary?.voters_who_voted) }} votantes)
            </span>
          </div>
          <VProgressLinear
            :model-value="summary?.participation_percentage ?? 0"
            color="success"
            height="8"
            rounded
            class="mt-3"
          />
          <div class="d-flex justify-space-between text-caption text-medium-emphasis mt-1">
            <span>Electores Hábiles:</span>
            <span class="font-weight-bold">{{ formatNumber(summary?.registered_voters) }}</span>
          </div>
        </VCardText>
      </VCard>
    </VCol>

    <!-- Votos Válidos -->
    <VCol cols="12" sm="6" md="3">
      <VCard class="h-100 border" elevation="0">
        <VCardText>
          <div class="d-flex align-center justify-space-between mb-2">
            <span class="text-caption text-uppercase font-weight-bold text-medium-emphasis">Votos Válidos</span>
            <VAvatar color="info" variant="tonal" size="36">
              <VIcon icon="ri-checkbox-circle-line" size="20" />
            </VAvatar>
          </div>
          <div class="d-flex align-baseline gap-x-2">
            <h3 class="text-h4 font-weight-bold text-info">
              {{ formatNumber(summary?.valid_votes) }}
            </h3>
            <span class="text-body-2 text-medium-emphasis">
              ({{ summary?.valid_votes_percentage ?? 0 }}%)
            </span>
          </div>
          <VProgressLinear
            :model-value="summary?.valid_votes_percentage ?? 0"
            color="info"
            height="8"
            rounded
            class="mt-3"
          />
          <div class="d-flex justify-space-between text-caption text-medium-emphasis mt-1">
            <span>Total Emitidos:</span>
            <span class="font-weight-bold">{{ formatNumber(summary?.total_votes) }}</span>
          </div>
        </VCardText>
      </VCard>
    </VCol>

    <!-- Votos No Válidos (Blancos, Nulos, Impugnados) -->
    <VCol cols="12" sm="6" md="3">
      <VCard class="h-100 border" elevation="0">
        <VCardText>
          <div class="d-flex align-center justify-space-between mb-2">
            <span class="text-caption text-uppercase font-weight-bold text-medium-emphasis">Blancos / Nulos</span>
            <VAvatar color="warning" variant="tonal" size="36">
              <VIcon icon="ri-indeterminate-circle-line" size="20" />
            </VAvatar>
          </div>
          <div class="d-flex align-baseline gap-x-2">
            <h3 class="text-h4 font-weight-bold text-warning">
              {{ formatNumber((summary?.blank_votes ?? 0) + (summary?.null_votes ?? 0) + (summary?.challenged_votes ?? 0)) }}
            </h3>
            <span class="text-body-2 text-medium-emphasis">
              ({{ ((summary?.blank_votes_percentage ?? 0) + (summary?.null_votes_percentage ?? 0) + (summary?.challenged_votes_percentage ?? 0)).toFixed(1) }}%)
            </span>
          </div>
          <div class="mt-3 d-flex gap-x-2 text-caption">
            <VChip size="x-small" color="secondary" variant="tonal">
              Blancos: {{ formatNumber(summary?.blank_votes) }}
            </VChip>
            <VChip size="x-small" color="error" variant="tonal">
              Nulos: {{ formatNumber(summary?.null_votes) }}
            </VChip>
            <VChip size="x-small" color="warning" variant="tonal">
              Impugnados: {{ formatNumber(summary?.challenged_votes) }}
            </VChip>
          </div>
        </VCardText>
      </VCard>
    </VCol>
  </VRow>
</template>
