<script setup lang="ts" generic="T extends { id: string | number }">
import { useDisplay } from 'vuetify'

interface Props {
  items: T[]
  itemsLength: number
  headers: Array<{ title: string; key: string; sortable?: boolean; align?: 'start' | 'center' | 'end' }>
  loading?: boolean
  loadingText?: string
  noDataText?: string
}

const props = withDefaults(defineProps<Props>(), {
  loading: false,
  loadingText: 'Cargando registros...',
  noDataText: 'No se encontraron registros.',
})

const page = defineModel<number>('page', { default: 1 })
const itemsPerPage = defineModel<number>('itemsPerPage', { default: 10 })

const { mdAndUp } = useDisplay()
</script>

<template>
  <VCard
    v-if="mdAndUp"
    rounded="lg"
    variant="outlined"
    class="elevation-0"
  >
    <VDataTableServer
      v-model:items-per-page="itemsPerPage"
      v-model:page="page"
      :items="items"
      :items-length="itemsLength"
      :headers="headers"
      :loading="loading"
      :loading-text="loadingText"
      :no-data-text="noDataText"
      class="text-no-wrap rounded-0"
    >
      <!-- Re-exponer todos los slots del VDataTableServer para que se puedan personalizar desde el padre -->
      <template
        v-for="(_, name) in $slots"
        #[name]="slotData"
      >
        <slot
          :name="name"
          v-bind="slotData"
        />
      </template>

      <!-- Slot predeterminado para el índice/numeración si no se define uno custom -->
      <template
        v-if="!$slots['item.index']"
        #item.index="{ index }"
      >
        {{ page > 1 ? (page - 1) * itemsPerPage + index + 1 : index + 1 }}
      </template>
    </VDataTableServer>
  </VCard>
</template>
