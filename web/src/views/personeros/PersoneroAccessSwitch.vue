<script setup lang="ts">
import { personerosService, type PersoneroItem } from '@/api/personeros.service'

const props = defineProps<{
  personero: PersoneroItem
}>()

const emit = defineEmits<{
  (e: 'updated', is_active: boolean): void
}>()

const loading = ref(false)
const isActive = ref(props.personero.is_active ?? true)

watch(() => props.personero.is_active, (val) => {
  isActive.value = val ?? true
})

const handleToggle = async () => {
  loading.value = true
  try {
    const res = await personerosService.toggleAccess(props.personero.id)
    isActive.value = res.is_active
    emit('updated', res.is_active)
  } catch (error) {
    console.error('Error toggling personero access:', error)
    // Revert state on failure
    isActive.value = !isActive.value
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="d-inline-flex align-center">
    <VSwitch
      :model-value="isActive"
      :loading="loading"
      :color="isActive ? 'success' : 'secondary'"
      density="compact"
      hide-details
      @update:model-value="handleToggle"
    />
  </div>
</template>
