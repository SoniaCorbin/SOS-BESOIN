'use client'
import { useState, useEffect, useRef } from 'react'
import { useRouter, useParams } from 'next/navigation'
import Link from 'next/link'
import { useTranslations } from 'next-intl'
import { supabase } from '@/lib/supabase'
import Nav from '@/components/Nav'

export default function ChatPage() {
  const router = useRouter()
  const { offerId } = useParams<{ offerId: string }>()
  const t = useTranslations('chat')
  const [messages, setMessages] = useState<any[]>([])
  const [userId, setUserId] = useState<string | null>(null)
  const [text, setText] = useState('')
  const [loading, setLoading] = useState(true)
  const [sending, setSending] = useState(false)
  const bottomRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    async function load() {
      const { data: { session } } = await supabase.auth.getSession()
      if (!session) { router.push('/login'); return }
      setUserId(session.user.id)
      await fetchMessages()
      setLoading(false)
    }
    load()

    const channel = supabase.channel(`chat-${offerId}`)
      .on('postgres_changes', {
        event: 'INSERT',
        schema: 'public',
        table: 'messages',
        filter: `offer_id=eq.${offerId}`,
      }, (payload) => {
        setMessages(prev => [...prev, payload.new])
        setTimeout(() => bottomRef.current?.scrollIntoView({ behavior: 'smooth' }), 100)
      })
      .subscribe()

    return () => { supabase.removeChannel(channel) }
  }, [offerId])

  async function fetchMessages() {
    const { data } = await supabase
          .from('messages')
          .select('*')
          .eq('offer_id', offerId)
          .order('created_at', { ascending: true })

        // Enrich with sender names (FK points to auth.users, not profiles)
        const enriched = []
        for (const msg of data ?? []) {
          try {
            const { data: profile } = await supabase
              .from('profiles')
              .select('full_name')
              .eq('id', msg.sender_id)
              .single()
            enriched.push({ ...msg, profiles: profile })
          } catch {
            enriched.push({ ...msg, profiles: null })
          }
        }
        setMessages(enriched)
    setTimeout(() => bottomRef.current?.scrollIntoView({ behavior: 'smooth' }), 100)
  }

  async function sendMessage() {
    if (!text.trim() || sending) return
    setSending(true)
    await supabase.from('messages').insert({
      offer_id: offerId,
      sender_id: userId,
      content: text.trim(),
      is_read: false,
    })
    setText('')
    setSending(false)
  }

  if (loading) return (
    <div style={{ minHeight: '100vh', display: 'grid', placeItems: 'center', background: 'var(--bg)' }}>
      <div style={{ color: 'var(--amber)', fontFamily: 'var(--font-mono)' }}>{t('loading')}</div>
    </div>
  )

  return (
    <>
      <Nav />
      <main style={{ paddingTop: 64, height: '100vh', display: 'flex', flexDirection: 'column', background: 'var(--bg)' }}>
        <div style={{ maxWidth: 700, width: '100%', margin: '0 auto', flex: 1, display: 'flex', flexDirection: 'column', height: '100%' }}>
          <div style={{
            padding: '16px 24px',
            borderBottom: '1px solid var(--line)',
            display: 'flex', alignItems: 'center', gap: 12,
            background: 'var(--bg-2)',
          }}>
            <Link href="/dashboard" style={{ color: 'var(--text-mute)', fontSize: 20 }}>←</Link>
            <div>
              <div style={{ fontWeight: 600, fontSize: 15 }}>Chat</div>
              <div style={{ fontSize: 12, color: 'var(--cyan)', fontFamily: 'var(--font-mono)' }}>
                <span style={{ width: 6, height: 6, borderRadius: '50%', background: 'var(--cyan)', display: 'inline-block', marginRight: 6 }} />
                {t('live')}
              </div>
            </div>
          </div>

          <div style={{ flex: 1, overflow: 'auto', padding: '20px 24px', display: 'flex', flexDirection: 'column', gap: 12 }}>
            {messages.length === 0 ? (
              <div style={{
                flex: 1,
                display: 'flex', flexDirection: 'column',
                alignItems: 'center', justifyContent: 'center',
                gap: 12, textAlign: 'center',
              }}>
                <div style={{ fontSize: 40 }}>💬</div>
                <div style={{ color: 'var(--text-dim)', fontSize: 15, fontWeight: 500 }}>
                  {t('start_conversation')}
                </div>
                <div style={{ color: 'var(--text-mute)', fontSize: 13, fontFamily: 'var(--font-mono)', display: 'flex', alignItems: 'center', gap: 6 }}>
                  {t('write_below')}
                </div>
              </div>
            ) : messages.map(msg => {
              const isMe = msg.sender_id === userId
              const name = msg.profiles?.full_name ?? t('unknown_user')
              const time = new Date(msg.created_at).toLocaleTimeString('fr-CA', { hour: '2-digit', minute: '2-digit' })

              return (
                <div key={msg.id} style={{ display: 'flex', flexDirection: 'column', alignItems: isMe ? 'flex-end' : 'flex-start' }}>
                  {!isMe && <div style={{ fontSize: 11, color: 'var(--text-mute)', marginBottom: 4, paddingLeft: 4 }}>{name}</div>}
                  <div style={{
                    maxWidth: '70%', padding: '10px 14px',
                    borderRadius: isMe ? '16px 16px 4px 16px' : '16px 16px 16px 4px',
                    background: isMe ? 'var(--amber)' : 'var(--bg-2)',
                    border: isMe ? 'none' : '1px solid var(--line)',
                    color: isMe ? '#000' : 'var(--text)',
                    fontSize: 14, lineHeight: 1.5,
                  }}>{msg.content}</div>
                  <div style={{ fontSize: 10, color: 'var(--text-mute)', marginTop: 4, paddingLeft: 4, paddingRight: 4 }}>{time}</div>
                </div>
              )
            })}
            <div ref={bottomRef} />
          </div>

          <div style={{
            padding: '16px 24px',
            borderTop: '1px solid var(--line)',
            borderBottom: '1px solid var(--line)',
            background: 'var(--bg-2)',
            display: 'flex', gap: 10,
            position: 'sticky', bottom: 0,
          }}>
            <input
              type="text"
              value={text}
              onChange={e => setText(e.target.value)}
              onKeyDown={e => e.key === 'Enter' && sendMessage()}
              placeholder={t('placeholder')}
              autoFocus
              style={{
                flex: 1, padding: '12px 16px',
                background: 'var(--bg-3)', border: '1px solid var(--amber-soft)',
                borderRadius: 24, color: 'var(--text)', fontSize: 14,
                outline: 'none', fontFamily: 'var(--font-sans)',
              }}
            />
            <button
              onClick={sendMessage}
              disabled={sending || !text.trim()}
              style={{
                padding: '12px 24px',
                background: text.trim() ? 'var(--amber)' : 'var(--bg-3)',
                color: text.trim() ? '#000' : 'var(--text-mute)',
                border: 'none', borderRadius: 24,
                fontWeight: 600, fontSize: 14,
                cursor: text.trim() ? 'pointer' : 'not-allowed',
                fontFamily: 'var(--font-sans)',
              }}
            >
              {t('send')}
            </button>
          </div>
        </div>
      </main>
    </>
  )
}