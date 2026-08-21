<script setup lang="ts">
import type { CandidateItem } from '@/api/candidates.service'

const props = defineProps<{
  modelValue: boolean
  candidate: CandidateItem | null
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
}>()
</script>

<template>
  <VDialog
    :model-value="modelValue"
    max-width="600"
    @update:model-value="emit('update:modelValue', $event)"
  >
    <VCard v-if="candidate">
      <VCardTitle class="d-flex justify-space-between align-center pa-4 border-b">
        <div class="d-flex align-center gap-x-2">
          <VIcon icon="ri-user-star-line" color="primary" />
          <span class="text-h6 font-weight-bold">Ficha Oficial de Candidato</span>
        </div>
        <VBtn icon="ri-close-line" variant="text" density="compact" @click="emit('update:modelValue', false)" />
      </VCardTitle>

      <VCardText class="pa-4">
        <!-- Foto y Cabecera -->
        <div class="d-flex align-center gap-x-4 mb-4">
          <VAvatar size="80" rounded="lg" color="primary" variant="tonal">
            <VImg
              v-if="candidate.photo_url"
              :src="candidate.photo_url"
              cover
            />
            <span v-else class="text-h4 font-weight-bold">
              {{ candidate.full_name ? candidate.full_name[0] : 'C' }}
            </span>
          </VAvatar>
          <div>
            <h3 class="text-h6 font-weight-bold mb-1">{{ candidate.full_name }}</h3>
            <div class="d-flex align-center gap-2 flex-wrap">
              <VChip size="small" color="primary" variant="tonal" class="font-weight-bold">
                DNI: {{ candidate.document_number }}
              </VChip>
              <VChip size="small" color="secondary" variant="outlined">
                {{ candidate.position || 'Candidato Oficial' }}
              </VChip>
            </div>
          </div>
        </div>

        <VDivider class="my-3" />

        <!-- Información Electoral -->
        <h4 class="text-subtitle-2 font-weight-bold text-primary mb-2 d-flex align-center gap-1">
          <VIcon icon="ri-government-line" size="16" /> Postulación Electoral
        </h4>

        <VRow dense>
          <VCol cols="12" sm="6">
            <span class="text-caption text-medium-emphasis d-block">Organización Política:</span>
            <div class="d-flex align-center gap-x-2 mt-1">
              <VAvatar size="26" class="elevation-1 border" color="surface">
                <VImg
                  v-if="candidate.political_org_logo"
                  :src="candidate.political_org_logo"
                  cover
                />
                <VIcon v-else icon="ri-flag-2-fill" size="14" color="primary" />
              </VAvatar>
              <span class="text-body-2 font-weight-medium">{{ candidate.political_org_name || 'Lista Oficial' }}</span>
            </div>
          </VCol>
          <VCol cols="12" sm="6">
            <span class="text-caption text-medium-emphasis d-block">Estado de Candidatura:</span>
            <VChip
              size="small"
              :color="(candidate.status || '').includes('ADMIT') || (candidate.status || '').includes('INSCRIT') ? 'success' : 'primary'"
              variant="tonal"
              class="font-weight-bold mt-1"
            >
              {{ candidate.status || 'INSCRITO' }}
            </VChip>
          </VCol>
          <VCol cols="12" sm="6" class="mt-2">
            <span class="text-caption text-medium-emphasis d-block">Circunscripción / Ubigeo:</span>
            <span class="text-body-2">
              {{ [candidate.district_name, candidate.province_name, candidate.department_name].filter(Boolean).join(' / ') || 'Ámbito Regional / Municipal' }}
            </span>
          </VCol>
          <VCol cols="12" sm="6" class="mt-2">
            <span class="text-caption text-medium-emphasis d-block">ID Hoja de Vida JNE:</span>
            <div class="d-flex align-center gap-2 mt-1">
              <span class="text-body-2 font-weight-bold text-primary">{{ candidate.id_hoja_vida || 'Declarada en JEE' }}</span>
              <VBtn
                v-if="candidate.id_hoja_vida"
                size="x-small"
                variant="tonal"
                color="primary"
                prepend-icon="ri-external-link-line"
                :href="candidate.cv_url || `https://declara.jne.gob.pe/HojaVida/HojaVida?idHojaVida=${candidate.id_hoja_vida}`"
                target="_blank"
              >
                Ver Hoja de Vida JNE
              </VBtn>
            </div>
          </VCol>
        </VRow>
      </VCardText>

      <VCardActions class="pa-4 border-t d-flex justify-space-between align-center">
        <div>
          <VBtn
            v-if="candidate.id_hoja_vida"
            variant="text"
            color="info"
            size="small"
            prepend-icon="ri-file-user-line"
            :href="candidate.voto_informado_url || `https://votoinformado.jne.gob.pe/voto/hoja-de-vida/${candidate.id_hoja_vida}`"
            target="_blank"
          >
            Portal Voto Informado
          </VBtn>
        </div>
        <VBtn variant="outlined" color="secondary" @click="emit('update:modelValue', false)">
          Cerrar
        </VBtn>
      </VCardActions>
    </VCard>
  </VDialog>
</template>
