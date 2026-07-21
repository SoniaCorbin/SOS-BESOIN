'use client'
import { useState } from 'react'
import { useTranslations } from 'next-intl'
import { supabase } from '@/lib/supabase'

type Props = {
  requestId: string
  offerId: string
  clientId: string
  providerId: string
  onRated: () => void
}

export default function RatingForm({ requestId, offerId, clientId, providerId, onRated }: Props) {
  const t = useTranslations('rating')
  const [rating, setRating] = useState(0)
  const [hover, setHover] = useState(0)
  const [comment, setComment] = useState('')
  const [loading, setLoading] = useState(false)
  const [done, setDone] = useState(false)

  async function handleSubmit() {
    if (rating === 0) return
    setLoading(true)

    await supabase.from('ratings').insert({
      request_id:  requestId,
      offer_id:    offerId,
      client_id:   clientId,
      provider_id: providerId,
      rating,
      comment,
    })

    const { data: ratings } = await supabase
      .from('ratings')
      .select('rating')
      .eq('provider_id', providerId)

    if (ratings && ratings.length > 0) {
      const avg = ratings.reduce((sum, r) => sum + r.rating, 0) / ratings.length
      await supabase.from('profiles').update({
        rating:         Math.round(avg * 10) / 10,
        total_missions: ratings.length,
      }).eq('id', providerId)
    }

    setLoading(false)
    setDone(true)
    onRated()
  }

  if (done) return (
    <div style={{
      background: 'rgba(132,204,22,0.1)',
      border: '1px solid var(--green)',
      borderRadius: 12, padding: '16px 20px',
      fontSize: 14, color: 'var(--green)',
      textAlign: 'center',
    }}>
      {t('success')}
    </div>
  )

  return (
    <div style={{
      background: 'var(--bg-2)',
      border: '1px solid var(--amber)',
      borderRadius: 12, padding: '20px',
      marginTop: 12,
    }}>
      <h4 style={{ fontSize: 15, fontWeight: 600, marginBottom: 16 }}>
        {t('title')}
      </h4>

      <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
        {[1, 2, 3, 4, 5].map(star => (
          <button
            key={star}
            onClick={() => setRating(star)}
            onMouseEnter={() => setHover(star)}
            onMouseLeave={() => setHover(0)}
            style={{
              fontSize: 28,
              background: 'transparent',
              border: 'none',
              cursor: 'pointer',
              color: star <= (hover || rating) ? 'var(--amber)' : 'var(--line-2)',
              transition: 'color 0.15s',
            }}
          >★</button>
        ))}
      </div>

      <textarea
        value={comment}
        onChange={e => setComment(e.target.value)}
        placeholder={t('comment_placeholder')}
        rows={3}
        style={{
          width: '100%', padding: '10px 14px',
          background: 'var(--bg-3)', border: '1px solid var(--line-2)',
          borderRadius: 8, color: 'var(--text)', fontSize: 14,
          outline: 'none', fontFamily: 'var(--font-sans)',
          resize: 'vertical', marginBottom: 12,
        }}
      />

      <button
        onClick={handleSubmit}
        disabled={loading || rating === 0}
        style={{
          width: '100%', padding: '10px',
          background: rating === 0 ? 'var(--bg-3)' : 'var(--amber)',
          color: rating === 0 ? 'var(--text-mute)' : '#000',
          border: 'none', borderRadius: 8,
          fontWeight: 600, fontSize: 14,
          cursor: rating === 0 ? 'not-allowed' : 'pointer',
          fontFamily: 'var(--font-sans)',
        }}
      >
        {loading ? t('submitting') : t('submit_btn')}
      </button>
    </div>
  )
}