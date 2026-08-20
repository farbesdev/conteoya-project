<script setup lang="ts">
import { VForm } from 'vuetify/components/VForm'
import { themeConfig } from '@themeConfig'
import { useAuthStore } from '@/stores/useAuthStore'
import { VNodeRenderer } from '@layouts/components/VNodeRenderer'

import authV2LoginIllustrationBorderedDark from '@images/pages/auth-v2-login-illustration-bordered-dark.png'
import authV2LoginIllustrationBorderedLight from '@images/pages/auth-v2-login-illustration-bordered-light.png'
import authV2LoginIllustrationDark from '@images/pages/auth-v2-login-illustration-dark.png'
import authV2LoginIllustrationLight from '@images/pages/auth-v2-login-illustration-light.png'
import authV2LoginMaskDark from '@images/pages/auth-v2-login-mask-dark.png'
import authV2LoginMaskLight from '@images/pages/auth-v2-login-mask-light.png'

const authThemeImg = useGenerateImageVariant(
  authV2LoginIllustrationLight,
  authV2LoginIllustrationDark,
  authV2LoginIllustrationBorderedLight,
  authV2LoginIllustrationBorderedDark,
  true)

const authThemeMask = useGenerateImageVariant(authV2LoginMaskLight, authV2LoginMaskDark)

definePage({
  meta: {
    layout: 'blank',
    unauthenticatedOnly: true,
  },
})

const isPasswordVisible = ref(false)
const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()

const errorMessage = ref<string | null>(null)
const refVForm = ref<VForm>()

const credentials = ref({
  login: 'admin@conteoya.pe',
  password: 'Admin123!',
})

const rememberMe = ref(false)

const login = async () => {
  errorMessage.value = null
  try {
    await authStore.login(credentials.value.login, credentials.value.password)

    await nextTick(() => {
      const target = (route.query.to ? String(route.query.to) : '/admin/dashboard')
      router.replace(target)
    })
  }
  catch (err: any) {
    errorMessage.value = err?._data?.message || err?.message || 'Credenciales inválidas.'
  }
}

const onSubmit = () => {
  refVForm.value?.validate()
    .then(({ valid: isValid }) => {
      if (isValid)
        login()
    })
}
</script>

<template>
  <RouterLink to="/">
    <div class="auth-logo app-logo">
      <VNodeRenderer :nodes="themeConfig.app.logo" />
      <h1 class="app-logo-title">
        {{ themeConfig.app.title }}
      </h1>
    </div>
  </RouterLink>

  <VRow
    no-gutters
    class="auth-wrapper"
  >
    <VCol
      md="8"
      class="d-none d-md-flex align-center justify-center position-relative"
    >
      <div class="d-flex align-center justify-center pa-10">
        <img
          :src="authThemeImg"
          class="auth-illustration w-100"
          alt="auth-illustration"
        >
      </div>
      <VImg
        :src="authThemeMask"
        class="d-none d-md-flex auth-footer-mask"
        alt="auth-mask"
      />
    </VCol>

    <VCol
      cols="12"
      md="4"
      class="auth-card-v2 d-flex align-center justify-center"
      style="background-color: rgb(var(--v-theme-surface));"
    >
      <VCard
        flat
        :max-width="500"
        class="mt-12 mt-sm-0 pa-5 pa-lg-7"
      >
        <VCardText>
          <h4 class="text-h4 mb-1">
            Bienvenido a <span class="text-capitalize text-primary">ConteoYA</span> 👋🏻
          </h4>
          <p class="mb-0 text-medium-emphasis">
            Ingreso de Administradores, Directores y Personeros
          </p>
        </VCardText>

        <VCardText>
          <VAlert
            v-if="errorMessage"
            color="error"
            variant="tonal"
            class="mb-4"
            closable
          >
            {{ errorMessage }}
          </VAlert>

          <VAlert
            color="primary"
            variant="tonal"
          >
            <p class="text-caption mb-1 text-primary">
              <strong>Admin:</strong> admin@conteoya.pe / Pass: <strong>Admin123!</strong>
            </p>
            <p class="text-caption mb-0 text-primary">
              <strong>Director:</strong> director@conteoya.pe / Pass: <strong>Director123!</strong>
            </p>
          </VAlert>
        </VCardText>

        <VCardText>
          <VForm
            ref="refVForm"
            @submit.prevent="onSubmit"
          >
            <VRow>
              <!-- login (email or DNI) -->
              <VCol cols="12">
                <VTextField
                  v-model="credentials.login"
                  label="Email o DNI"
                  placeholder="admin@conteoya.pe o 44556677"
                  type="text"
                  autofocus
                  :rules="[requiredValidator]"
                />
              </VCol>

              <!-- password -->
              <VCol cols="12">
                <VTextField
                  v-model="credentials.password"
                  label="Contraseña"
                  placeholder="············"
                  :rules="[requiredValidator]"
                  :type="isPasswordVisible ? 'text' : 'password'"
                  autocomplete="current-password"
                  :append-inner-icon="isPasswordVisible ? 'ri-eye-off-line' : 'ri-eye-line'"
                  @click:append-inner="isPasswordVisible = !isPasswordVisible"
                />

                <div class="d-flex align-center flex-wrap justify-space-between my-4 gap-x-2">
                  <VCheckbox
                    v-model="rememberMe"
                    label="Recordarme"
                    density="compact"
                  />
                  <RouterLink
                    class="text-primary text-caption"
                    to="/resultados"
                  >
                    Ver Resultados Públicos
                  </RouterLink>
                </div>

                <VBtn
                  block
                  type="submit"
                  :loading="authStore.loading"
                >
                  Iniciar Sesión
                </VBtn>
              </VCol>
            </VRow>
          </VForm>
        </VCardText>
      </VCard>
    </VCol>
  </VRow>
</template>

<style lang="scss">
@use "@core/scss/template/pages/page-auth";
</style>
