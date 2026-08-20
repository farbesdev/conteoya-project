import { defineStore } from 'pinia'
import { authService, type UserData } from '@/api/auth.service'
import { ability } from '@/plugins/casl/ability'

export const useAuthStore = defineStore('auth', () => {
  const user = ref<UserData | null>(useCookie<UserData | null>('userData').value || null)
  const token = ref<string | null>(useCookie<string | null>('accessToken').value || null)
  const loading = ref(false)
  const error = ref<string | null>(null)

  const isAuthenticated = computed(() => !!token.value && !!user.value)
  const isAdmin = computed(() => user.value?.role === 'ADMIN')
  const isDirector = computed(() => user.value?.role === 'DIRECTOR')
  const isPersonero = computed(() => user.value?.role === 'PERSONERO')

  const login = async (loginIdentifier: string, pass: string) => {
    loading.value = true
    error.value = null
    try {
      const response = await authService.login(loginIdentifier, pass)
      token.value = response.access_token
      user.value = response.user

      useCookie<string>('accessToken').value = response.access_token
      useCookie<UserData>('userData').value = response.user

      // Configure default CASL ability rules
      const rules = [
        {
          action: 'manage' as const,
          subject: 'all' as const,
        },
      ]
      useCookie<any[]>('userAbilityRules').value = rules

      try {
        ability.update(rules)
      } catch (e) {
        // Safe fallback
      }

      return response
    } catch (err: any) {
      error.value = err?._data?.message || err?.message || 'Error al iniciar sesión'
      throw err
    } finally {
      loading.value = false
    }
  }

  const logout = async () => {
    try {
      if (token.value) {
        await authService.logout().catch(() => {})
      }
    } finally {
      token.value = null
      user.value = null
      useCookie<string | null>('accessToken').value = null
      useCookie<UserData | null>('userData').value = null
      useCookie<any[] | null>('userAbilityRules').value = null
    }
  }

  const fetchCurrentUser = async () => {
    if (!token.value) return null
    try {
      const res = await authService.me()
      user.value = res.user
      useCookie<UserData>('userData').value = res.user
      return res.user
    } catch (e) {
      await logout()
      return null
    }
  }

  return {
    user,
    token,
    loading,
    error,
    isAuthenticated,
    isAdmin,
    isDirector,
    isPersonero,
    login,
    logout,
    fetchCurrentUser,
  }
})
