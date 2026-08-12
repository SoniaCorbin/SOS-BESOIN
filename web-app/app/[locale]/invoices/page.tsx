'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { useTranslations } from 'next-intl'
import { supabase } from '@/lib/supabase'
import Nav from '@/components/Nav'

export default function InvoicesPage() {
  const router = useRouter()
  const t = useTranslations('invoices')
  const [invoices, setInvoices] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [userId, setUserId] = useState<string | null>(null)

  useEffect(() => {
    async function load() {
      const { data: { session } } = await supabase.auth.getSession()
      if (!session) { router.push('/login'); return }
      setUserId(session.user.id)

      const { data } = await supabase
        .from('invoices')
        .select('*')
        .or(`client_id.eq.${session.user.id},provider_id.eq.${session.user.id}`)
        .order('created_at', { ascending: false })

      // Enrich with request title
      const enriched = []
      for (const inv of data ?? []) {
        let requestTitle = '—'
        if (inv.request_id) {
          try {
            const { data: req } = await supabase
              .from('requests')
              .select('title')
              .eq('id', inv.request_id)
              .single()
            requestTitle = req?.title ?? '—'
          } catch {}
        }
        enriched.push({ ...inv, request_title: requestTitle })
      }
      setInvoices(enriched)
      setLoading(false)
    }
    load()
  }, [router])

  const timeAgo = (dateStr: string) => {
    const diff = Date.now() - new Date(dateStr).getTime()
    const mins = Math.floor(diff / 60000)
    if (mins < 60) return `${mins} min`
    const hours = Math.floor(mins / 60)
    if (hours < 24) return `${hours}h`
    return `${Math.floor(hours / 24)}j`
  }

  if (loading) return (
    <div style={{ minHeight: '100vh', display: 'grid', placeItems: 'center', background: 'var(--bg)' }}>
      <div style={{ color: 'var(--amber)', fontFamily: 'var(--font-mono)' }}>{t('loading')}</div>
    </div>
  )

  return (
    <>
      <Nav />
      <main style={{ paddingTop: 64, minHeight: '100vh', background: 'var(--bg)' }}>
        <div style={{ maxWidth: 800, margin: '0 auto', padding: '40px 24px' }}>
          <div style={{ marginBottom: 32 }}>
            <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--amber)', letterSpacing: '0.1em', textTransform: 'uppercase' }}>{t('tag')}</span>
            <h1 style={{ fontSize: 32, fontWeight: 700, marginTop: 8, letterSpacing: '-0.02em' }}>{t('title')}</h1>
          </div>

          {invoices.length === 0 ? (
            <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 16, padding: '60px 24px', textAlign: 'center' }}>
              <div style={{ fontSize: 40, marginBottom: 16 }}>📄</div>
              <div style={{ fontSize: 16, fontWeight: 600, color: 'var(--text-dim)' }}>{t('empty')}</div>
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {invoices.map(inv => {
                const isClient = inv.client_id === userId
                const statusColor = inv.status === 'paid' ? 'var(--green)' : 'var(--amber)'

                return (
                  <Link key={inv.id} href={`/invoices/${inv.id}`} style={{
                    display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                    background: 'var(--bg-2)', border: '1px solid var(--line)',
                    borderRadius: 12, padding: '16px 20px',
                  }}>
                    <div style={{ flex: 1 }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 4 }}>
                        <span style={{ fontFamily: 'var(--font-mono)', fontSize: 13, color: 'var(--amber)', fontWeight: 600 }}>
                          #{inv.invoice_number}
                        </span>
                        <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, padding: '2px 8px', borderRadius: 6, border: `1px solid ${statusColor}`, color: statusColor }}>
                          {inv.status === 'paid' ? t('status_paid') : t('status_pending')}
                        </span>
                      </div>
                      <div style={{ fontSize: 14, fontWeight: 500, marginBottom: 2 }}>{inv.request_title}</div>
                      <div style={{ fontSize: 12, color: 'var(--text-mute)' }}>
                        {isClient ? t('role_client') : t('role_provider')} · {inv.created_at ? timeAgo(inv.created_at) : ''}
                      </div>
                    </div>
                    <div style={{ textAlign: 'right' }}>
                      <div style={{ fontFamily: 'var(--font-mono)', fontSize: 20, fontWeight: 700, color: 'var(--green)' }}>
                        {isClient ? `${inv.amount}$` : `${inv.provider_amount}$`}
                      </div>
                      {isClient && inv.client_fee > 0 && (
                        <div style={{ fontSize: 11, color: 'var(--text-mute)' }}>
                          {t('fee')}: {inv.client_fee}$
                        </div>
                      )}
                    </div>
                  </Link>
                )
              })}
            </div>
          )}
        </div>
      </main>
    </>
  )
}