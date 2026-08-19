'use client'
import { useState, useEffect } from 'react'
import { useParams, useRouter } from 'next/navigation'
import Link from 'next/link'
import { useTranslations } from 'next-intl'
import { supabase } from '@/lib/supabase'
import Nav from '@/components/Nav'
import { downloadInvoicePdf } from '@/lib/invoicePdf'

export default function InvoiceDetailPage() {
  const { id } = useParams<{ id: string }>()
  const router = useRouter()
  const t = useTranslations('invoices')
  const [invoice, setInvoice] = useState<any>(null)
  const [requestTitle, setRequestTitle] = useState('—')
  const [clientName, setClientName] = useState('—')
  const [providerName, setProviderName] = useState('—')
  const [loading, setLoading] = useState(true)
  const [userId, setUserId] = useState<string | null>(null)

  useEffect(() => {
    async function load() {
      const { data: { session } } = await supabase.auth.getSession()
      if (!session) { router.push('/login'); return }
      setUserId(session.user.id)

      const { data: inv } = await supabase.from('invoices').select('*').eq('id', id).single()
      setInvoice(inv)

      if (inv?.request_id) {
        try {
          const { data: req } = await supabase.from('requests').select('title').eq('id', inv.request_id).single()
          setRequestTitle(req?.title ?? '—')
        } catch {}
      }
      if (inv?.client_id) {
        try {
          const { data: p } = await supabase.from('public_profiles').select('full_name').eq('id', inv.client_id).single()
          setClientName(p?.full_name ?? '—')
        } catch {}
      }
      if (inv?.provider_id) {
        try {
          const { data: p } = await supabase.from('public_profiles').select('full_name').eq('id', inv.provider_id).single()
          setProviderName(p?.full_name ?? '—')
        } catch {}
      }
      setLoading(false)
    }
    load()
  }, [id, router])

  if (loading) return (
    <div style={{ minHeight: '100vh', display: 'grid', placeItems: 'center', background: 'var(--bg)' }}>
      <div style={{ color: 'var(--amber)', fontFamily: 'var(--font-mono)' }}>{t('loading')}</div>
    </div>
  )

  if (!invoice) return (
    <div style={{ minHeight: '100vh', display: 'grid', placeItems: 'center', background: 'var(--bg)' }}>
      <div style={{ color: 'var(--text-mute)' }}>{t('not_found')}</div>
    </div>
  )

  const isClient = invoice.client_id === userId
  const statusColor = invoice.status === 'paid' ? 'var(--green)' : 'var(--amber)'
  const rowStyle = { display: 'flex', justifyContent: 'space-between', padding: '12px 0', borderBottom: '1px solid var(--line)' }
  const labelStyle = { fontSize: 13, color: 'var(--text-mute)' }
  const valueStyle = { fontSize: 14, fontWeight: 600 as const, color: 'var(--text)', textAlign: 'right' as const }

  return (
    <>
      <Nav />
      <main style={{ paddingTop: 64, minHeight: '100vh', background: 'var(--bg)' }}>
        <div style={{ maxWidth: 600, margin: '0 auto', padding: '40px 24px' }}>

          <Link href="/invoices" style={{ fontSize: 13, color: 'var(--text-mute)', display: 'inline-block', marginBottom: 24 }}>
            ← {t('back')}
          </Link>

          <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 16, padding: '28px' }}>
            {/* Header */}
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 24 }}>
              <div>
                <div style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--text-mute)', letterSpacing: '0.1em', textTransform: 'uppercase' }}>{t('invoice_label')}</div>
                <div style={{ fontFamily: 'var(--font-mono)', fontSize: 24, fontWeight: 700, color: 'var(--amber)', marginTop: 4 }}>#{invoice.invoice_number}</div>
              </div>
              <span style={{ fontFamily: 'var(--font-mono)', fontSize: 12, padding: '4px 12px', borderRadius: 8, border: `1px solid ${statusColor}`, color: statusColor }}>
                {invoice.status === 'paid' ? t('status_paid') : t('status_pending')}
              </span>
            </div>

            {/* Details */}
            <div style={rowStyle}>
              <span style={labelStyle}>{t('detail_sos')}</span>
              <Link href={`/requests/${invoice.request_id}`} style={{ ...valueStyle, color: 'var(--amber)' }}>{requestTitle} →</Link>
            </div>
            <div style={rowStyle}>
              <span style={labelStyle}>{t('detail_client')}</span>
              <span style={valueStyle}>{clientName}</span>
            </div>
            <div style={rowStyle}>
              <span style={labelStyle}>{t('detail_provider')}</span>
              <span style={valueStyle}>{providerName}</span>
            </div>
            <div style={rowStyle}>
              <span style={labelStyle}>{t('detail_amount')}</span>
              <span style={{ ...valueStyle, fontFamily: 'var(--font-mono)', fontSize: 18, color: 'var(--green)' }}>{invoice.amount}$</span>
            </div>
            <div style={rowStyle}>
              <span style={labelStyle}>{t('detail_provider_amount')}</span>
              <span style={{ ...valueStyle, color: 'var(--cyan)' }}>{invoice.provider_amount}$</span>
            </div>
            {invoice.paid_at && (
              <div style={rowStyle}>
                <span style={labelStyle}>{t('detail_paid_at')}</span>
                <span style={valueStyle}>{new Date(invoice.paid_at).toLocaleDateString('fr-CA')}</span>
              </div>
            )}

            <button
              onClick={() => downloadInvoicePdf({
                invoiceNumber: invoice.invoice_number,
                status: invoice.status,
                clientName,
                providerName,
                requestTitle,
                requestCategory: invoice.request_category ?? '',
                createdAt: invoice.created_at,
                amount: invoice.amount,
                platformFee: invoice.platform_fee,
                providerAmount: invoice.provider_amount,
              })}
              style={{
                marginTop: 20, width: '100%', padding: '12px',
                background: 'var(--amber)', color: '#000', border: 'none',
                borderRadius: 10, fontWeight: 700, fontSize: 14,
                cursor: 'pointer', fontFamily: 'var(--font-sans)',
              }}
            >
              ⬇ {t('download_pdf')}
            </button>
          </div>
        </div>
      </main>
    </>
  )
}