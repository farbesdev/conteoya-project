<script setup lang="ts">
import { actsService, type ActItem } from '@/api/acts.service'

const props = defineProps<{
  modelValue: boolean
  act: ActItem | null
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
  (e: 'saved'): void
}>()

const form = ref({
  act_code: '',
  status: 'DRAFT' as 'DRAFT' | 'CONFIRMED' | 'SYNCED' | 'OBSERVED',
  totals: {
    total_votes: 0,
    voters_who_voted: 0,
    blank_votes: 0,
    null_votes: 0,
    challenged_votes: 0,
  },
})

const saving = ref(false)
const errorMessage = ref<string | null>(null)

watch(
  () => props.act,
  (val) => {
    if (val) {
      form.value = {
        act_code: val.act_code || '',
        status: val.status || 'DRAFT',
        totals: {
          total_votes: val.totals?.total_votes || 0,
          voters_who_voted: val.totals?.voters_who_voted || 0,
          blank_votes: val.totals?.blank_votes || 0,
          null_votes: val.totals?.null_votes || 0,
          challenged_votes: val.totals?.challenged_votes || 0,
        },
      }
    }
    errorMessage.value = null
  },
  { immediate: true }
)

const handleSave = async () => {
  if (!props.act) return

  saving.value = true
  errorMessage.value = null

  try {
    await actsService.update(props.act.id, {
      act_code: form.value.act_code,
      status: form.value.status,
      totals: form.value.totals,
    })

    emit('saved')
    emit('update:modelValue', false)
  } catch (err: any) {
    errorMessage.value = err?._data?.message || 'Error al actualizar el acta.'
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <VDialog
    :model-value="modelValue"
    max-width="560"
    @update:model-value="emit('update:modelValue', $event)"
  >
    <VCard v-if="act">
      <VCardTitle class="d-flex justify-space-between align-center pa-4 border-b">
        <span class="text-h6 font-weight-bold">
          Editar Acta Nº {{ act.act_code || `#${act.id}` }}
        </span>
        <VBtn icon="ri-close-line" variant="text" density="compact" @click="emit('update:modelValue', false)" />
      </VCardTitle>

      <VCardText class="pa-4">
        <VAlert v-if="errorMessage" color="error" variant="tonal" class="mb-4">
          {{ errorMessage }}
        </VAlert>

        <VRow dense>
          <VCol cols="12" sm="6">
            <VTextField
              v-model="form.act_code"
              label="Código de Acta"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
          <VCol cols="12" sm="6">
            <VSelect
              v-model="form.status"
              :items="[
                { title: 'CONFIRMED (Confirmada)', value: 'CONFIRMED' },
                { title: 'DRAFT (Borrador)', value: 'DRAFT' },
                { title: 'SYNCED (Sincronizada)', value: 'SYNCED' },
                { title: 'OBSERVED (Observada)', value: 'OBSERVED' },
              ]"
              label="Estado del Acta"
              variant="outlined"
              density="comfortable"
            />
          </VCol>

          <VCol cols="12" class="mt-2">
            <h4 class="text-subtitle-2 font-weight-bold text-primary mb-2">
              Totales Registrados
            </h4>
          </VCol>

          <VCol cols="12" sm="6">
            <VTextField
              v-model.number="form.totals.total_votes"
              label="Total Votos Emitidos"
              type="number"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
          <VCol cols="12" sm="6">
            <VTextField
              v-model.number="form.totals.voters_who_voted"
              label="Ciudadanos que Votaron"
              type="number"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
          <VCol cols="12" sm="4">
            <VTextField
              v-model.number="form.totals.blank_votes"
              label="Votos Blancos"
              type="number"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
          <VCol cols="12" sm="4">
            <VTextField
              v-model.number="form.totals.null_votes"
              label="Votos Nulos"
              type="number"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
          <VCol cols="12" sm="4">
            <VTextField
              v-model.number="form.totals.challenged_votes"
              label="Votos Impugnados"
              type="number"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
        </VRow>
      </VCardText>

      <VCardActions class="pa-4 border-t d-flex justify-end gap-2">
        <VBtn variant="outlined" color="secondary" :disabled="saving" @click="emit('update:modelValue', false)">
          Cancelar
        </VBtn>
        <VBtn variant="flat" color="primary" :loading="saving" @click="handleSave">
          Guardar Cambios
        </VBtn>
      </VCardActions>
    </VCard>
  </VDialog>
</template>
