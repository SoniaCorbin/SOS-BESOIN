import { useEffect } from 'react'
import { getMessaging, getToken, onMessage, isSupported } from 'firebase/messaging'
import { firebaseApp } from './firebase'
import { supabase } from './supabase'

export function useFcmToken(userId: string | null) {
  useEffect(() => {
    if (!userId) return

    let unsubscribe: (() => void) | undefined

    async function register() {
      if (!(await isSupported())) return
      if (typeof window === 'undefined' || !('Notification' in window)) return

      try {
        const permission = Notification.permission === 'default'
          ? await Notification.requestPermission()
          : Notification.permission

        if (permission !== 'granted') return

        const registration = await navigator.serviceWorker.register('/firebase-messaging-sw.js')
        const messaging = getMessaging(firebaseApp)

        const token = await getToken(messaging, {
          vapidKey: process.env.NEXT_PUBLIC_FIREBASE_VAPID_KEY,
          serviceWorkerRegistration: registration,
        })

        if (token) {
          await supabase.from('profiles').update({ fcm_token: token }).eq('id', userId)
        }

        unsubscribe = onMessage(messaging, (payload) => {
          const { title, body } = payload.notification || {}
          if (title) new Notification(title, { body })
        })
      } catch (e) {
        console.error('FCM registration failed:', e)
      }
    }

    register()
    return () => { unsubscribe?.() }
  }, [userId])
}
