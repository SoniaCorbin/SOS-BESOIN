'use client'
import { useState, useEffect } from 'react'
import { Elements, PaymentElement, useStripe, useElements } from '@stripe/react-stripe-js'
import { useTranslations } from 'next-intl'
import { supabase } from '@/lib/supabase'
import { getStripe } from '@/lib/stripe'

type Props = {
  offerId: string
  requestId: string
  price: number
  onClose: () => void
  onSuccess: () => void
}

export default function PaymentModal({ offerId, requestId, price, onClose, onSuccess }: Props) {
  const t = useTranslations('payment')
  const [clientSecret, setClientSecret] = useState<string | null>(null)
  const [totalAmount, setTotalAmount] = useState<number | null>(null)
  const [error, setError] = useState<string | null>(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function createIntent() {
      try {
        const { data, error } = await supabase.functions.invoke('create-payment-intent', {
          body: { offerId, currency: 'cad' },
        })
        if (error || data?.error) {
          setError(data?.error || error?.message || t('error_generic'))
          setLoading(false)
          return
        }
        setClientSecret(data.clientSecret)
        setTotalAmount(data.totalAmount)
        setLoading(false)
      } catch (e: any) {
        setError(e?.message || t('error_generic'))
        setLoading(false)
      }
    }
    createIntent()
  }, [offerId, t])

  return (
    <div
      style={{
        position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)',
        zIndex: 200, display: 'grid', placeItems: 'center', padding: 24,
      }}
      onClick={onClose}
    >
      <div
        style={{
          background: 'var(--bg-2)', border: '1px solid var(--line)',
          borderRadius: 16, padding: 28, maxWidth: 480, width: '100%',
        }}
        onClick={(e) => e.stopPropagation()}
      >
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
          <h2 style={{ fontSize: 18, fontWeight: 700 }}>{t('title')}</h2>
          <button onClick={onClose} style={{ background: 'none', border: 'none', color: 'var(--text-mute)', fontSize: 20, cursor: 'pointer' }}>✕</button>
        </div>

        {loading ? (
          <div style={{ textAlign: 'center', padding: 40, color: 'var(--amber)', fontFamily: 'var(--font-mono)' }}>
            {t('loading')}
          </div>
        ) : error ? (
          <div style={{ color: 'var(--red)', fontSize: 14, padding: 16, textAlign: 'center' }}>
            {error}
          </div>
        ) : clientSecret ? (
          <Elements
            stripe={getStripe()}
            options={{
              clientSecret,
              appearance: {
                theme: 'night',
                variables: {
                  colorPrimary: '#F59E0B',
                  colorBackground: '#111C33',
                  colorText: '#F1F5F9',
                  colorDanger: '#EF4444',
                  borderRadius: '10px',
                },
              },
            }}
          >
            <CheckoutForm
              offerId={offerId}
              requestId={requestId}
              totalAmount={totalAmount ?? price}
              onClose={onClose}
              onSuccess={onSuccess}
            />
          </Elements>
        ) : null}
      </div>
    </div>
  )
}

function CheckoutForm({
  offerId,
  requestId,
  totalAmount,
  onClose,
  onSuccess,
}: {
  offerId: string
  requestId: string
  totalAmount: number
  onClose: () => void
  onSuccess: () => void
}) {
  const t = useTranslations('payment')
  const stripe = useStripe()
  const elements = useElements()
  const [submitting, setSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    if (!stripe || !elements) return

    setSubmitting(true)
    setError(null)

    const { error: confirmError, paymentIntent } = await stripe.confirmPayment({
      elements,
      redirect: 'if_required',
    })

    if (confirmError) {
      setError(confirmError.message || t('error_generic'))
      setSubmitting(false)
      return
    }

    if (
      paymentIntent &&
      (paymentIntent.status === 'requires_capture' || paymentIntent.status === 'succeeded')
    ) {
      const { data, error: captureError } = await supabase.functions.invoke('capture-payment', {
        body: {
          paymentIntentId: paymentIntent.id,
          offerId,
          requestId,
        },
      })

      if (captureError || data?.error) {
        setError(data?.error || captureError?.message || t('error_generic'))
        setSubmitting(false)
        return
      }

      onSuccess()
      onClose()
    } else {
      setError(t('error_generic'))
      setSubmitting(false)
    }
  }

  return (
    <form onSubmit={handleSubmit}>
      <div
        style={{
          display: 'flex', justifyContent: 'space-between',
          padding: '12px 0', marginBottom: 16,
          borderBottom: '1px solid var(--line)',
        }}
      >
        <span style={{ fontSize: 14, color: 'var(--text-dim)' }}>{t('total_label')}</span>
        <span style={{ fontFamily: 'var(--font-mono)', fontSize: 18, fontWeight: 700, color: 'var(--amber)' }}>
          {totalAmount.toFixed(2)}$
        </span>
      </div>

      <PaymentElement />

      {error && (
        <div style={{ color: 'var(--red)', fontSize: 13, marginTop: 12 }}>{error}</div>
      )}

      <div style={{ display: 'flex', gap: 8, marginTop: 20 }}>
        <button
          type="submit"
          disabled={!stripe || submitting}
          style={{
            flex: 1, padding: '12px', background: submitting ? 'var(--bg-3)' : 'var(--amber)',
            color: submitting ? 'var(--text-dim)' : '#000', border: 'none',
            borderRadius: 10, fontWeight: 700, fontSize: 15,
            cursor: submitting ? 'not-allowed' : 'pointer', fontFamily: 'var(--font-sans)',
          }}
        >
          {submitting ? t('processing') : t('pay_btn')}
        </button>
        <button
          type="button"
          onClick={onClose}
          disabled={submitting}
          style={{
            padding: '12px 20px', background: 'none', border: '1px solid var(--line)',
            borderRadius: 10, color: 'var(--text-mute)', fontSize: 14,
            cursor: 'pointer', fontFamily: 'var(--font-sans)',
          }}
        >
          {t('cancel_btn')}
        </button>
      </div>

      <p style={{ fontSize: 11, color: 'var(--text-mute)', marginTop: 14, textAlign: 'center' }}>
        🔒 {t('escrow_note')}
      </p>
    </form>
  )
}