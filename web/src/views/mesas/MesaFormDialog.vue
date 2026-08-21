<script setup lang="ts">
import { mesasService, type PollingStationItem } from '@/api/mesas.service'

const props = defineProps<{
  modelValue: boolean
  mesa: PollingStationItem | null
}>()

const emit = defineEmits<{
  (e: 'update:modelValue', value: boolean): void
  (e: 'saved'): void
}>()

const isEdit = computed(() => !!props.mesa?.id)

const form = ref({
  code: '',
  location_name: '',
  address: '',
  department_name: '',
  province_name: '',
  district_name: '',
  odpe: '',
  registered_voters: 300,
  status: 'ACTIVE',
})

const saving = ref(false)
const errorMessage = ref<string | null>(null)

watch(
  () => props.mesa,
  (val) => {
    if (val) {
      form.value = {
        code: val.code || '',
        location_name: val.location_name || '',
        address: val.address || '',
        department_name: val.department_name || '',
        province_name: val.province_name || '',
        district_name: val.district_name || '',
        odpe: val.odpe || '',
        registered_voters: val.registered_voters || 300,
        status: val.status || 'ACTIVE',
      }
    } else {
      form.value = {
        code: '',
        location_name: '',
        address: '',
        department_name: '',
        province_name: '',
        district_name: '',
        odpe: '',
        registered_voters: 300,
        status: 'ACTIVE',
      }
    }
    errorMessage.value = null
  },
  { immediate: true }
)

const handleSave = async () => {
  if (!form.value.code || form.value.code.length < 6) {
    errorMessage.value = 'El código de mesa debe tener 6 dígitos numéricos.'
    return
  }

  saving.value = true
  errorMessage.value = null

  try {
    if (isEdit.value && props.mesa) {
      await mesasService.update(props.mesa.id, form.value)
    } else {
      await mesasService.create(form.value)
    }
    emit('saved')
    emit('update:modelValue', false)
  } catch (err: any) {
    errorMessage.value = err?._data?.message || 'Error al guardar los datos de la mesa.'
  } finally {
    saving.value = false
  }
}
</script>

<template>
  <VDialog
    :model-value="modelValue"
    max-width="600"
    @update:model-value="emit('update:modelValue', $event)"
  >
    <VCard>
      <VCardTitle class="d-flex justify-space-between align-center pa-4 border-b">
        <span class="text-h6 font-weight-bold">
          {{ isEdit ? `Editar Mesa Nº ${mesa?.code}` : 'Registrar Nueva Mesa Electoral' }}
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
              v-model="form.code"
              label="Código de Mesa (6 dígitos)"
              placeholder="030390"
              variant="outlined"
              density="comfortable"
              :disabled="isEdit"
              maxlength="6"
            />
          </VCol>
          <VCol cols="12" sm="6">
            <VTextField
              v-model.number="form.registered_voters"
              label="Electores Hábiles"
              type="number"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
          <VCol cols="12">
            <VTextField
              v-model="form.location_name"
              label="Local de Votación (Colegio / IE / Estadio)"
              placeholder="I.E. 1082 Alfonso Ugarte"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
          <VCol cols="12">
            <VTextField
              v-model="form.address"
              label="Dirección del Local"
              placeholder="Av. Paseo de la República 5051"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
          <VCol cols="12" sm="4">
            <VTextField
              v-model="form.department_name"
              label="Departamento / Región"
              placeholder="LIMA"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
          <VCol cols="12" sm="4">
            <VTextField
              v-model="form.province_name"
              label="Provincia"
              placeholder="LIMA"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
          <VCol cols="12" sm="4">
            <VTextField
              v-model="form.district_name"
              label="Distrito"
              placeholder="MIRAFLORES"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
          <VCol cols="12" sm="6">
            <VTextField
              v-model="form.odpe"
              label="ODPE Asignada"
              placeholder="ODPE LIMA CENTRO 1"
              variant="outlined"
              density="comfortable"
            />
          </VCol>
          <VCol cols="12" sm="6">
            <VSelect
              v-model="form.status"
              :items="[
                { title: 'Activa (Habilitada)', value: 'ACTIVE' },
                { title: 'Inactiva / Anulada', value: 'INACTIVE' },
              ]"
              label="Estado de la Mesa"
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
          {{ isEdit ? 'Guardar Cambios' : 'Registrar Mesa' }}
        </VBtn>
      </VCardActions>
    </VCard>
  </VDialog>
</template>
