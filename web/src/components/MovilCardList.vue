<script setup lang="ts" generic="T extends { id: string | number }">
import { useDisplay } from 'vuetify'
import { computed } from 'vue'

interface Props {
  items: T[]
  itemsLength: number
  itemsPerPage?: number
  loading?: boolean
  loadingText?: string
  noDataText?: string
}

const props = withDefaults(defineProps<Props>(), {
  itemsPerPage: 10,
  loading: false,
  loadingText: 'Cargando...',
  noDataText: 'No se encontraron registros.',
})

const page = defineModel<number>('page', { default: 1 })

const { mdAndUp } = useDisplay()

const totalPages = computed(() => {
  return Math.ceil(props.itemsLength / props.itemsPerPage) || 1
})
</script>

<template>
  <div
    v-if="!mdAndUp"
    class="d-flex flex-column gap-4"
  >
    <!-- Estado de carga -->
    <div
      v-if="loading && items.length === 0"
      class="d-flex justify-center align-center py-8"
    >
      <VProgressCircular
        indeterminate
        color="primary"
      />
      <span class="ms-3 text-body-2 text-secondary">{{ loadingText }}</span>
    </div>

    <!-- Sin datos -->
    <div
      v-else-if="items.length === 0"
      class="text-center py-8 text-secondary"
    >
      {{ noDataText }}
    </div>

    <!-- Lista de tarjetas -->
    <template v-else>
      <VCard
        v-for="(item, index) in items"
        :key="item.id"
        variant="outlined"
        rounded="xl"
        class="pa-4 position-relative hover-card elevation-0"
      >
        <!-- Slot para inyectar los campos y el diseño de la tarjeta -->
        <slot
          name="card"
          :item="item"
          :index="index"
        />
      </VCard>

      <!-- Paginación móvil -->
      <div class="d-flex justify-center align-center mt-2 pb-4 gap-2">
        <VBtn
          icon="ri-arrow-left-s-line"
          variant="tonal"
          size="small"
          :disabled="page <= 1 || loading"
          @click="page--"
        />
        <span class="text-body-2 font-weight-medium">
          Pág. {{ page }} de {{ totalPages }}
        </span>
        <VBtn
          icon="ri-arrow-right-s-line"
          variant="tonal"
          size="small"
          :disabled="page >= totalPages || loading"
          @click="page++"
        />
      </div>
    </template>
  </div>
</template>

<style scoped>
.hover-card {
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.hover-card:hover {
  transform: translateY(-2px);
}
</style>
