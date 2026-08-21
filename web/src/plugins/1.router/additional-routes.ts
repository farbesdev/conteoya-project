import type { RouteRecordRaw } from 'vue-router/auto'

// 👉 Redirects
export const redirects: RouteRecordRaw[] = [
  {
    path: '/',
    name: 'index',
    redirect: () => {
      const userData = useCookie<Record<string, unknown> | null | undefined>('userData')
      const token = useCookie<string | null | undefined>('accessToken')

      if (userData.value && token.value)
        return { path: '/admin/dashboard' }

      return { path: '/resultados' }
    },
  },
]

export const routes: RouteRecordRaw[] = []

