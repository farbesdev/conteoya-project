import { defineStore } from 'pinia'
import { useResultsStore } from './useResultsStore'

export const useRealtimeStore = defineStore('realtime', () => {
  // Leer configuración desde .env
  const isRealtimeConfigured = import.meta.env.VITE_ENABLE_REALTIME === 'true' || import.meta.env.VITE_ENABLE_REALTIME === true
  const defaultPollingInterval = Number(import.meta.env.VITE_REALTIME_POLLING_INTERVAL) || 30000

  const isPaused = ref(!isRealtimeConfigured)
  const isConnected = ref(false)
  const lastEvent = ref<any>(null)
  const recentActivities = ref<Array<{ id: string; text: string; time: string; color: string }>>([])
  let pollingInterval: any = null

  const resultsStore = useResultsStore()

  const handleActConfirmed = (eventData: any) => {
    if (isPaused.value) return

    lastEvent.value = eventData
    recentActivities.value.unshift({
      id: `${eventData.act_id}-${Date.now()}`,
      text: `Mesa ${eventData.polling_station || 'N/A'} confirmada (${eventData.district_name || ''} - ${eventData.total_votes || 0} votos)`,
      time: new Date().toLocaleTimeString(),
      color: 'success',
    })
    if (recentActivities.value.length > 20) {
      recentActivities.value.pop()
    }
    // Refresh election results
    resultsStore.fetchElectionResults()
  }

  const startPolling = (intervalMs = defaultPollingInterval) => {
    if (pollingInterval) return
    pollingInterval = setInterval(() => {
      if (!isPaused.value) {
        resultsStore.fetchElectionResults()
      }
    }, intervalMs)
  }

  const stopPolling = () => {
    if (pollingInterval) {
      clearInterval(pollingInterval)
      pollingInterval = null
    }
  }

  const startListening = () => {
    if (isPaused.value) {
      stopListening()
      return
    }

    // Si Echo / Reverb está disponible en window, suscribirse
    if (typeof window !== 'undefined' && (window as any).Echo) {
      try {
        (window as any).Echo.channel('election-results')
          .listen('.act.confirmed', (e: any) => {
            isConnected.value = true
            handleActConfirmed(e)
          })
        isConnected.value = true
      } catch (err) {
        console.warn('Reverb WebSocket fallback to polling:', err)
        startPolling()
      }
    } else {
      startPolling()
    }
  }

  const stopListening = () => {
    stopPolling()
    if (typeof window !== 'undefined' && (window as any).Echo) {
      try {
        (window as any).Echo.leaveChannel('election-results')
      } catch (e) {}
    }
    isConnected.value = false
  }

  const pause = () => {
    isPaused.value = true
    stopListening()
  }

  const resume = () => {
    isPaused.value = false
    startListening()
    // Forzar una actualización inmediata al reanudar
    resultsStore.fetchElectionResults()
  }

  const togglePause = () => {
    if (isPaused.value) {
      resume()
    } else {
      pause()
    }
  }

  return {
    isPaused,
    isConnected,
    lastEvent,
    recentActivities,
    handleActConfirmed,
    startListening,
    stopListening,
    pause,
    resume,
    togglePause,
  }
})

