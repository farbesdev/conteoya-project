import { defineStore } from 'pinia'
import { useResultsStore } from './useResultsStore'

export const useRealtimeStore = defineStore('realtime', () => {
  const isConnected = ref(false)
  const lastEvent = ref<any>(null)
  const recentActivities = ref<Array<{ id: string; text: string; time: string; color: string }>>([])
  let pollingInterval: any = null

  const resultsStore = useResultsStore()

  const handleActConfirmed = (eventData: any) => {
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

  const startListening = () => {
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

  const startPolling = (intervalMs = 10000) => {
    if (pollingInterval) return
    pollingInterval = setInterval(() => {
      resultsStore.fetchElectionResults()
    }, intervalMs)
  }

  const stopListening = () => {
    if (pollingInterval) {
      clearInterval(pollingInterval)
      pollingInterval = null
    }
    if (typeof window !== 'undefined' && (window as any).Echo) {
      try {
        (window as any).Echo.leaveChannel('election-results')
      } catch (e) {}
    }
    isConnected.value = false
  }

  return {
    isConnected,
    lastEvent,
    recentActivities,
    handleActConfirmed,
    startListening,
    stopListening,
  }
})
