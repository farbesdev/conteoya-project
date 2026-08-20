<script setup lang="ts">
import { actsService } from '@/api/acts.service'
import { catalogsService, type PoliticalOrgItem } from '@/api/catalogs.service'
import { mesasService } from '@/api/mesas.service'

const props = defineProps<{
  modelValue: boolean
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
  (e: 'saved'): void
}>()

// Pasos: 1: Tipo y Mesa, 2: Votos, 3: Validación y Confirmación
const currentStep = ref(1)

const pollingStationCode = ref('')
const mesaLocationName = ref('')
const actCode = ref('')
const electionId = ref(1)
const electoralLevelId = ref(1) // 1: Regional, 2: Municipal

const organizations = ref<PoliticalOrgItem[]>([])
const votes = ref<Record<number, number>>({})

const blankVotes = ref(0)
const nullVotes = ref(0)
const challengedVotes = ref(0)
const registeredVoters = ref(300)
const votersWhoVoted = ref(280)

const loadingCatalogs = ref(false)
const loadingMesa = ref(false)
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

const onMesaCodeChange = async () => {
  if (pollingStationCode.value.length === 6) {
    loadingMesa.value = true
    try {
      const res = await mesasService.list({ search: pollingStationCode.value, per_page: 1 })
      if (res.data && res.data.length > 0) {
        const m = res.data[0]
        mesaLocationName.value = `${m.location_name} - ${m.district_name}, ${m.department_name}`
        registeredVoters.value = m.registered_voters || 300
        votersWhoVoted.value = m.registered_voters ? Math.round(m.registered_voters * 0.85) : 280
      } else {
        mesaLocationName.value = 'Mesa habilitada'
      }
    } catch {
      mesaLocationName.value = 'Mesa habilitada'
    } finally {
      loadingMesa.value = false
    }
  } else {
    mesaLocationName.value = ''
  }
}

const totalListVotes = computed(() => {
  return Object.values(votes.value).reduce((acc, v) => acc + (Number(v) || 0), 0)
})

const totalVotes = computed(() => {
  return totalListVotes.value + (Number(blankVotes.value) || 0) + (Number(nullVotes.value) || 0) + (Number(challengedVotes.value) || 0)
})

const isConsistent = computed(() => {
  return totalVotes.value <= registeredVoters.value
})

const handleSave = async () => {
  if (!pollingStationCode.value || pollingStationCode.value.length < 6) {
    errorMessage.value = 'Ingrese un código de mesa válido de 6 dígitos.'
    currentStep.value = 1
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
      act_code: actCode.value || `ACT-${pollingStationCode.value}-${electoralLevelId.value === 1 ? 'REG' : 'MUN'}`,
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
    currentStep.value = 1
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
    max-width="850"
    @update:model-value="emit('update:modelValue', $event)"
  >
    <VCard>
      <!-- Header con Indicador de Tipo -->
      <VCardTitle class="d-flex justify-space-between align-center pa-4 border-b">
        <div class="d-flex align-center gap-x-2">
          <VAvatar color="primary" variant="tonal" size="38">
            <VIcon icon="ri-how-to-vote-fill" size="22" />
          </VAvatar>
          <div>
            <span class="text-h6 font-weight-bold d-block">Registro de Acta Electoral</span>
            <span class="text-caption text-medium-emphasis">
              {{ electoralLevelId === 1 ? '🏛 Elección Regional (Gobernador y Vicegobernador)' : '🏙 Elección Municipal (Alcalde y Regidores)' }}
            </span>
          </div>
        </div>
        <VBtn icon="ri-close-line" variant="text" density="compact" @click="emit('update:modelValue', false)" />
      </VCardTitle>

      <VCardText class="pa-4">
        <VAlert v-if="errorMessage" color="error" variant="tonal" class="mb-4">
          {{ errorMessage }}
        </VAlert>

        <!-- Selección de Tipo de Acta (Similar al modal móvil) -->
        <div class="mb-4">
          <span class="text-subtitle-2 font-weight-bold d-block mb-2">Seleccione el Tipo de Proceso Electoral:</span>
          <VRow dense>
            <VCol cols="12" sm="6">
              <VCard
                :variant="electoralLevelId === 1 ? 'flat' : 'outlined'"
                :color="electoralLevelId === 1 ? 'primary' : undefined"
                class="pa-3 cursor-pointer border hover-card"
                @click="electoralLevelId = 1"
              >
                <div class="d-flex align-center gap-x-3">
                  <VAvatar :color="electoralLevelId === 1 ? 'white' : 'primary'" :variant="electoralLevelId === 1 ? 'flat' : 'tonal'" size="36">
                    <VIcon icon="ri-government-line" :color="electoralLevelId === 1 ? 'primary' : undefined" />
                  </VAvatar>
                  <div>
                    <div class="font-weight-bold text-body-1">🏛 Acta Regional</div>
                    <div class="text-caption opacity-80">Gobernador y Vicegobernador</div>
                  </div>
                </div>
              </VCard>
            </VCol>

            <VCol cols="12" sm="6">
              <VCard
                :variant="electoralLevelId === 2 ? 'flat' : 'outlined'"
                :color="electoralLevelId === 2 ? 'primary' : undefined"
                class="pa-3 cursor-pointer border hover-card"
                @click="electoralLevelId = 2"
              >
                <div class="d-flex align-center gap-x-3">
                  <VAvatar :color="electoralLevelId === 2 ? 'white' : 'primary'" :variant="electoralLevelId === 2 ? 'flat' : 'tonal'" size="36">
                    <VIcon icon="ri-community-line" :color="electoralLevelId === 2 ? 'primary' : undefined" />
                  </VAvatar>
                  <div>
                    <div class="font-weight-bold text-body-1">🏙 Acta Municipal</div>
                    <div class="text-caption opacity-80">Alcalde y Regidores Provinciales/Distritales</div>
                  </div>
                </div>
              </VCard>
            </VCol>
          </VRow>
        </div>

        <!-- Identificación de la Mesa -->
        <VRow dense class="mb-3">
          <VCol cols="12" sm="6">
            <VTextField
              v-model="pollingStationCode"
              label="Código de Mesa de Sufragio"
              placeholder="030390"
              variant="outlined"
              density="comfortable"
              maxlength="6"
              :loading="loadingMesa"
              @update:model-value="onMesaCodeChange"
            />
            <span v-if="mesaLocationName" class="text-caption text-primary font-weight-medium d-block mt-1">
              📍 {{ mesaLocationName }} (Padrón: {{ registeredVoters }} electores)
            </span>
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

        <!-- Desglose de Votos por Partido Político -->
        <div class="mb-3">
          <div class="d-flex justify-space-between align-center mb-2">
            <span class="text-subtitle-2 font-weight-bold text-primary d-flex align-center gap-1">
              <VIcon icon="ri-bar-chart-2-line" size="16" /> Votación por Organización Política
            </span>
            <VChip size="x-small" color="primary" variant="tonal" class="font-weight-bold">
              Subtotal Listas: {{ totalListVotes }} votos
            </VChip>
          </div>

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
              <div class="d-flex align-center gap-2 pa-2 border rounded bg-background mb-1">
                <VAvatar size="32" color="primary" variant="tonal">
                  <VIcon icon="ri-flag-2-fill" size="16" />
                </VAvatar>
                <div class="flex-grow-1 text-truncate">
                  <div class="font-weight-medium text-caption text-truncate">{{ org.name }}</div>
                  <div class="text-disabled text-caption">{{ org.short_name || 'Lista Oficial' }}</div>
                </div>
                <VTextField
                  v-model.number="votes[org.id]"
                  type="number"
                  min="0"
                  density="compact"
                  variant="outlined"
                  hide-details
                  style="max-width: 90px;"
                />
              </div>
            </VCol>
          </VRow>
        </div>

        <VDivider class="my-3" />

        <!-- Votos Especiales y Resumen de Consistencia -->
        <h4 class="text-subtitle-2 font-weight-bold text-primary mb-2 d-flex align-center gap-1">
          <VIcon icon="ri-calculator-line" size="16" /> Votos Especiales y Totales de la Mesa
        </h4>

        <VRow dense>
          <VCol cols="12" sm="4">
            <VTextField
              v-model.number="blankVotes"
              label="Votos Blancos"
              type="number"
              min="0"
              variant="outlined"
              density="compact"
            />
          </VCol>
          <VCol cols="12" sm="4">
            <VTextField
              v-model.number="nullVotes"
              label="Votos Nulos"
              type="number"
              min="0"
              variant="outlined"
              density="compact"
            />
          </VCol>
          <VCol cols="12" sm="4">
            <VTextField
              v-model.number="challengedVotes"
              label="Votos Impugnados"
              type="number"
              min="0"
              variant="outlined"
              density="compact"
            />
          </VCol>

          <!-- Tarjeta de Consistencia -->
          <VCol cols="12" class="mt-2">
            <div
              :class="isConsistent ? 'bg-primary-subtle border-primary' : 'bg-warning-subtle border-warning'"
              class="pa-3 rounded border d-flex justify-space-between align-center flex-wrap gap-2"
            >
              <div>
                <div class="font-weight-bold text-body-2">
                  Total de Votos Emitidos en Acta: {{ totalVotes }}
                </div>
                <div class="text-caption text-medium-emphasis">
                  Electores en padrón: {{ registeredVoters }} • Ciudadanos que sufragaron: {{ votersWhoVoted }}
                </div>
              </div>
              <VChip
                :color="isConsistent ? 'success' : 'warning'"
                variant="flat"
                size="small"
                class="font-weight-bold"
              >
                {{ isConsistent ? 'TOTAL VÁLIDO' : 'OBSERVACIÓN DE TOTALES' }}
              </VChip>
            </div>
          </VCol>
        </VRow>
      </VCardText>

      <VCardActions class="pa-4 border-t d-flex justify-end gap-2">
        <VBtn variant="outlined" color="secondary" :disabled="saving" @click="emit('update:modelValue', false)">
          Cancelar
        </VBtn>
        <VBtn variant="flat" color="primary" :loading="saving" @click="handleSave">
          Registrar y Confirmar Acta
        </VBtn>
      </VCardActions>
    </VCard>
  </VDialog>
</template>

<style scoped>
.hover-card {
  transition: all 0.2s ease-in-out;
}
.hover-card:hover {
  transform: translateY(-2px);
}
</style>
