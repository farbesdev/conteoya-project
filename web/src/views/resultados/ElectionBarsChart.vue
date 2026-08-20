<script setup lang="ts">
import type { OrganizationResult } from '@/api/results.service'

const props = defineProps<{
  organizations: OrganizationResult[]
  loading?: boolean
}>()

const partyColors = [
  '#E53935', // Rojo
  '#1E88E5', // Azul
  '#43A047', // Verde
  '#FB8C00', // Naranja
  '#8E24AA', // Morado
  '#00ACC1', // Cyan
  '#FDD835', // Amarillo
  '#3949AB', // Indigo
  '#D81B60', // Rosa
  '#6D4C41', // Marrón
]

const getColor = (index: number) => partyColors[index % partyColors.length]

const formatNumber = (val?: number) => {
  if (val === undefined || val === null) return '0'
  return new Intl.NumberFormat('es-PE').format(val)
}
</script>

<template>
  <VCard class="border" elevation="0">
    <VCardItem>
      <template #title>
        <div class="d-flex align-center gap-x-2">
          <VIcon icon="ri-bar-chart-horizontal-line" color="primary" />
          <span class="text-h6 font-weight-bold">Votos Consolidados por Organización Política</span>
        </div>
      </template>
      <template #subtitle>
        <span class="text-caption">Ordenado por total de votos obtenidos a nivel escrutado</span>
      </template>
    </VCardItem>

    <VDivider />

    <VCardText class="pa-4">
      <div v-if="loading" class="d-flex justify-center align-center py-12">
        <VProgressCircular indeterminate color="primary" size="48" />
      </div>

      <div v-else-if="!organizations.length" class="text-center py-12 text-medium-emphasis">
        <VIcon icon="ri-inbox-line" size="48" class="mb-2" />
        <p class="text-body-1 mb-0">No se registran votos computados para el filtro seleccionado.</p>
      </div>

      <div v-else class="d-flex flex-column gap-y-4">
        <div
          v-for="(org, index) in organizations"
          :key="org.political_organization_id"
          class="pa-3 rounded border bg-surface"
        >
          <div class="d-flex align-center justify-space-between mb-2 flex-wrap gap-2">
            <!-- Logo y Nombre del Partido -->
            <div class="d-flex align-center gap-x-3">
              <VAvatar
                size="40"
                :color="getColor(index)"
                class="elevation-1 text-white font-weight-bold"
              >
                <VImg v-if="org.logo_url" :src="org.logo_url" :alt="org.short_name" />
                <span v-else>{{ org.short_name?.substring(0, 3) || org.rank }}</span>
              </VAvatar>

              <div>
                <div class="d-flex align-center gap-x-2">
                  <VChip size="x-small" :color="index === 0 ? 'primary' : 'default'" variant="tonal" class="font-weight-bold">
                    #{{ org.rank }}
                  </VChip>
                  <span class="font-weight-bold text-subtitle-1 text-high-emphasis">
                    {{ org.organization_name }}
                  </span>
                </div>
                <span class="text-caption text-medium-emphasis">
                  {{ org.short_name }}
                </span>
              </div>
            </div>

            <!-- Cantidad de Votos y Porcentajes -->
            <div class="text-end">
              <div class="d-flex align-baseline gap-x-2 justify-end">
                <span class="text-h5 font-weight-bold text-high-emphasis">
                  {{ formatNumber(org.votes) }}
                </span>
                <span class="text-caption text-medium-emphasis">votos</span>
              </div>
              <div class="d-flex gap-x-3 text-caption justify-end">
                <span class="text-primary font-weight-bold">
                  {{ org.percentage_valid_votes }}% válidos
                </span>
                <span class="text-medium-emphasis">
                  ({{ org.percentage_total_votes }}% emitidos)
                </span>
              </div>
            </div>
          </div>

          <!-- Barra de Progreso -->
          <VProgressLinear
            :model-value="org.percentage_valid_votes"
            :color="getColor(index)"
            height="12"
            rounded
            striped
          />
        </div>
      </div>
    </VCardText>
  </VCard>
</template>
