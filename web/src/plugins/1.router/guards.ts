import type { RouteNamedMap, _RouterTyped } from 'unplugin-vue-router'
import { canNavigate } from '@layouts/plugins/casl'

export const setupGuards = (router: _RouterTyped<RouteNamedMap & { [key: string]: any }>) => {
  // 👉 router.beforeEach
  router.beforeEach(to => {
    /*
     * If it's a public route (or /resultados), continue navigation.
     */
    if (to.meta.public || to.path.startsWith('/resultados'))
      return

    /**
     * Check if user is logged in by checking if token & user data exists in cookies
     */
    const isLoggedIn = !!(useCookie('userData').value && useCookie('accessToken').value)

    /*
      If user is logged in and is trying to access login like page, redirect to admin dashboard
     */
    if (to.meta.unauthenticatedOnly) {
      if (isLoggedIn)
        return '/admin/dashboard'
      else
        return undefined
    }

    // Require auth for admin routes
    if (to.path.startsWith('/admin')) {
      if (!isLoggedIn) {
        return {
          path: '/login',
          query: { to: to.fullPath !== '/' ? to.path : undefined },
        }
      }
      return
    }

    if (!canNavigate(to) && to.matched.length) {
      /* eslint-disable indent */
      return isLoggedIn
        ? { name: 'not-authorized' }
        : {
            name: 'login',
            query: {
              ...to.query,
              to: to.fullPath !== '/' ? to.path : undefined,
            },
          }
      /* eslint-enable indent */
    }
  })
}
