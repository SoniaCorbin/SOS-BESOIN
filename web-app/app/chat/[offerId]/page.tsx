'use client'
import { useState, useEffect, useRef } from 'react'
import { useRouter, useParams } from 'next/navigation'
import Link from 'next/link'
import { supabase } from '@/lib/supabase'
import Nav from '@/components/Nav'

export default function ChatPage() {
  const router = useRouter()
  const { offerId } = useParams<{ offerId: string }>()
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

    // Temps réel
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
      .select('*, profiles(full_name)')
      .eq('offer_id', offerId)
      .order('created_at', { ascending: true })
    setMessages(data ?? [])
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
      <div style={{ color: 'var(--amber)', fontFamily: 'var(--font-mono)' }}>Chargement...</div>
    </div>
  )

  return (
    <>
      <Nav />
      <main style={{ paddingTop: 64, height: '100vh', display: 'flex', flexDirection: 'column', background: 'var(--bg)' }}>
        {/* Header */}
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
              En direct
            </div>
          </div>
        </div>

        {/* Messages */}
        <div style={{ flex: 1, overflow: 'auto', padding: '20px 24px', display: 'flex', flexDirection: 'column', gap: 12 }}>
          {messages.length === 0 ? (
            <div style={{ textAlign: 'center', color: 'var(--text-mute)', marginTop: 40, fontFamily: 'var(--font-mono)', fontSize: 13 }}>
              Aucun message pour l'instant. Commencez la conversation!
            </div>
          ) : messages.map(msg => {
            const isMe = msg.sender_id === userId
            const name = msg.profiles?.full_name ?? 'Utilisateur'
            const time = new Date(msg.created_at).toLocaleTimeString('fr-CA', { hour: '2-digit', minute: '2-digit' })

            return (
              <div key={msg.id} style={{
                display: 'flex',
                flexDirection: 'column',
                alignItems: isMe ? 'flex-end' : 'flex-start',
              }}>
                {!isMe && (
                  <div style={{ fontSize: 11, color: 'var(--text-mute)', marginBottom: 4, paddingLeft: 4 }}>{name}</div>
                )}
                <div style={{
                  maxWidth: '70%',
                  padding: '10px 14px',
                  borderRadius: isMe ? '16px 16px 4px 16px' : '16px 16px 16px 4px',
                  background: isMe ? 'var(--amber)' : 'var(--bg-2)',
                  border: isMe ? 'none' : '1px solid var(--line)',
                  color: isMe ? '#000' : 'var(--text)',
                  fontSize: 14,
                  lineHeight: 1.5,
                }}>
                  {msg.content}
                </div>
                <div style={{ fontSize: 10, color: 'var(--text-mute)', marginTop: 4, paddingLeft: 4, paddingRight: 4 }}>
                  {time}
                </div>
              </div>
            )
          })}
          <div ref={bottomRef} />
        </div>

        {/* Input */}
        <div style={{
          padding: '16px 24px',
          borderTop: '1px solid var(--line)',
          background: 'var(--bg-2)',
          display: 'flex', gap: 10,
        }}>
          <input
            type="text"
            value={text}
            onChange={e => setText(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && sendMessage()}
            placeholder="Écrivez un message..."
            style={{
              flex: 1, padding: '10px 16px',
              background: 'var(--bg-3)', border: '1px solid var(--line-2)',
              borderRadius: 24, color: 'var(--text)', fontSize: 14,
              outline: 'none', fontFamily: 'var(--font-sans)',
            }}
          />
          <button
            onClick={sendMessage}
            disabled={sending || !text.trim()}
            style={{
              padding: '10px 20px',
              background: text.trim() ? 'var(--amber)' : 'var(--bg-3)',
              color: text.trim() ? '#000' : 'var(--text-mute)',
              border: 'none', borderRadius: 24,
              fontWeight: 600, fontSize: 14,
              cursor: text.trim() ? 'pointer' : 'not-allowed',
              fontFamily: 'var(--font-sans)',
            }}
          >
            Envoyer
          </button>
        </div>
      </main>
    </>
  )
}