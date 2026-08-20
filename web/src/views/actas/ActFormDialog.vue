<script setup lang="ts">
import { actsService } from '@/api/acts.service'
import { catalogsService, type PoliticalOrgItem } from '@/api/catalogs.service'

const props = defineProps<{
  modelValue: boolean
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
  (e: 'saved'): void
}>()

const pollingStationCode = ref('')
const actCode = ref('')
const electionId = ref(1)
const electoralLevelId = ref(1)

const organizations = ref<PoliticalOrgItem[]>([])
const votes = ref<Record<number, number>>({})

const blankVotes = ref(0)
const nullVotes = ref(0)
const challengedVotes = ref(0)
const votersWhoVoted = ref(0)

const loadingCatalogs = ref(false)
const saving = ref(false)
const errorMessage = ref<string | null>(null)

onMounted(async () => {
  loadingCatalogs.value = true
  try {
    const res = await catalogsService.getPoliticalOrganizations()
    organizations.value = res.data || []
    organizations.value.forEach(org => {
      votes.value[org.id] = 0
    })
  } catch (e) {
    console.error('Error cargando partidos:', e)
  } finally {
    loadingCatalogs.value = false
  }
})

const totalListVotes = computed(() => {
  return Object.values(votes.value).reduce((acc, v) => acc + (Number(v) || 0), 0)
})

const totalVotes = computed(() => {
  return totalListVotes.value + (Number(blankVotes.value) || 0) + (Number(nullVotes.value) || 0) + (Number(challengedVotes.value) || 0)
})

const handleSave = async () => {
  if (!pollingStationCode.value || pollingStationCode.value.length < 6) {
    errorMessage.value = 'Ingrese un código de mesa válido de 6 dígitos.'
    return
  }

  saving.value = true
  errorMessage.value = null

  try {
    const resultsPayload = organizations.value.map(org => ({
      political_organization_id: org.id,
      votes: Number(votes.value[org.id]) || 0,
      source: 'MANUAL',
    }))

    await actsService.create({
      election_id: electionId.value,
      electoral_level_id: electoralLevelId.value,
      polling_station_code: pollingStationCode.value,
      act_code: actCode.value || undefined,
      totals: {
        total_votes: totalVotes.value,
        voters_who_voted: votersWhoVoted.value || totalVotes.value,
        blank_votes: Number(blankVotes.value) || 0,
        null_votes: Number(nullVotes.value) || 0,
        challenged_votes: Number(challengedVotes.value) || 0,
      },
      results: resultsPayload,
      status: 'CONFIRMED',
    })

    emit('saved')
    emit('update:modelValue', false)
  } catch (err: any) {
    errorMessage.value = err?._data?.message || 'Error al registrar el acta.'
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <VDialog
    :model-value="modelValue"
    max-width="800"
    @update:model-value="emit('update:modelValue', $event)"
  >
    <VCard>
      <VCardTitle class="d-flex justify-space-between align-center pa-4 border-b">
        <div class="d-flex align-center gap-x-2">
          <VIcon icon="ri-file-add-line" color="primary" />
          <span class="text-h6 font-weight-bold">Registro Manual de Acta Electoral</span>
        </div>
        <VBtn icon="ri-close-line" variant="text" density="compact" @click="emit('update:modelValue', false)" />
      </VCardTitle>

      <VCardText class="pa-4">
        <VAlert v-if="errorMessage" color="error" variant="tonal" class="mb-4">
          {{ errorMessage }}
        </VAlert>

        <!-- Datos Cabecera -->
        <VRow dense class="mb-3">
          <VCol cols="12" sm="6">
            <VTextField
              v-model="pollingStationCode"
              label="Código de Mesa (6 dígitos)"
              placeholder="030390"
              variant="outlined"
              density="comfortable"
              maxlength="6"
            />
          </VCol>
          <VCol cols="12" sm="6">
            <VTextField
              v-model="actCode"
              label="Código de Acta (Opcional)"
              placeholder="ACT-030390-ERM"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
        </VRow>

        <VDivider class="my-3" />

        <!-- Votos por Organización Política -->
        <h4 class="text-subtitle-2 font-weight-bold text-primary mb-3 d-flex align-center gap-1">
          <VIcon icon="ri-bar-chart-2-line" size="16" /> Votos por Organización Política
        </h4>

        <div v-if="loadingCatalogs" class="text-center py-6">
          <VProgressCircular indeterminate color="primary" />
        </div>

        <VRow v-else dense>
          <VCol
            v-for="org in organizations"
            :key="org.id"
            cols="12"
            sm="6"
          >
            <VTextField
              v-model.number="votes[org.id]"
              :label="org.name"
              type="number"
              min="0"
              variant="outlined"
              density="compact"
              class="mb-1"
            />
          </VCol>
        </VRow>

        <VDivider class="my-3" />

        <!-- Totales y Votos Especiales -->
        <h4 class="text-subtitle-2 font-weight-bold text-primary mb-3 d-flex align-center gap-1">
          <VIcon icon="ri-calculator-line" size="16" /> Votos Especiales y Resumen de Mesa
        </h4>

        <VRow dense>
          <VCol cols="12" sm="4">
            <VTextField
              v-model.number="blankVotes"
              label="Votos Blancos"
              type="number"
              min="0"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
          <VCol cols="12" sm="4">
            <VTextField
              v-model.number="nullVotes"
              label="Votos Nulos"
              type="number"
              min="0"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
          <VCol cols="12" sm="4">
            <VTextField
              v-model.number="challengedVotes"
              label="Votos Impugnados"
              type="number"
              min="0"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
          <VCol cols="12" sm="6" class="mt-2">
            <VTextField
              v-model.number="votersWhoVoted"
              label="Total Ciudadanos que Votaron"
              type="number"
              min="0"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
          <VCol cols="12" sm="6" class="mt-2 d-flex align-center">
            <div class="pa-3 rounded bg-surface border w-100 d-flex justify-space-between align-center">
              <span class="text-caption text-medium-emphasis">Total Votos Emitidos:</span>
              <span class="text-h6 font-weight-black text-primary">{{ totalVotes }}</span>
            </div>
          </VCol>
        </VRow>
      </VCardText>

      <VCardActions class="pa-4 border-t d-flex justify-end gap-2">
        <VBtn variant="outlined" color="secondary" :disabled="saving" @click="emit('update:modelValue', false)">
          Cancelar
        </VBtn>
        <VBtn variant="flat" color="primary" :loading="saving" @click="handleSave">
          Registrar y Procesar Acta
        </VBtn>
      </VCardActions>
    </VCard>
  </VDialog>
</template>
