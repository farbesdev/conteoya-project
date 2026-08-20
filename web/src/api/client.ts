import { ofetch } from 'ofetch'

export const apiClient = ofetch.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || 'http://127.0.0.1:8000/api/v1',
  headers: {
    Accept: 'application/json',
  },
  async onRequest({ options }) {
    const token = useCookie<string | null>('accessToken').value
    if (token) {
      const headers = new Headers(options.headers)
      headers.set('Authorization', `Bearer ${token}`)
      options.headers = headers
    }
  },
  async onResponseError({ response }) {
    if (response.status === 401) {
      useCookie('accessToken').value = null
      useCookie('userData').value = null
      if (typeof window !== 'undefined' && !window.location.pathname.startsWith('/resultados')) {
        window.location.href = '/login'
      }
    }
  },
})
