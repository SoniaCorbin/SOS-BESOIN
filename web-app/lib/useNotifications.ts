import { useEffect, useState } from 'react'
import { supabase } from './supabase'

export function useNotifications(userId: string | null) {
  const [count, setCount] = useState(0)

  useEffect(() => {
    if (!userId) return

    async function fetchCount() {
      // Nouvelles offres sur les demandes du client
      const { count: offerCount } = await supabase
        .from('offers')
        .select('*', { count: 'exact', head: true })
        .eq('status', 'pending')
        .in('request_id',
          (await supabase
            .from('requests')
            .select('id')
            .eq('client_id', userId)
            .eq('status', 'open')
          ).data?.map(r => r.id) ?? []
        )

      setCount(offerCount ?? 0)
    }

    fetchCount()

    const channel = supabase.channel('notifications')
      .on('postgres_changes', { event: 'INSERT', schema: 'public', table: 'offers' }, fetchCount)
      .subscribe()

    return () => { supabase.removeChannel(channel) }
  }, [userId])

  return count
}