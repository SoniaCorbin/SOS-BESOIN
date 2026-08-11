'use client'
import { useState, useEffect, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { useTranslations } from 'next-intl'
import { supabase } from '@/lib/supabase'
import Nav from '@/components/Nav'

export default function ConversationsPage() {
  const router = useRouter()
  const t = useTranslations('conversations')
  const [conversations, setConversations] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [userId, setUserId] = useState<string | null>(null)
  const [userRole, setUserRole] = useState<string>('client')
  const [showArchived, setShowArchived] = useState(false)

  const load = useCallback(async () => {
    const { data: { session } } = await supabase.auth.getSession()
    if (!session) { router.push('/login'); return }
    setUserId(session.user.id)

    const { data: profile } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', session.user.id)
      .single()
    const role = profile?.role ?? 'client'
    setUserRole(role)

    const archiveColumn = role === 'provider' ? 'archived_by_provider' : 'archived_by_client'
    const { data } = await supabase
      .from('conversations')
      .select('*')
      .eq(archiveColumn, showArchived)
      .order('last_message_at', { ascending: false, nullsFirst: false })

    setConversations(data ?? [])
    setLoading(false)
  }, [showArchived, router])

  useEffect(() => {
    load()

    const channel = supabase.channel('conversations-list')
      .on('postgres_changes', { event: '*', schema: 'public', table: 'messages' }, load)
      .subscribe()

    const handleVisibility = () => {
      if (document.visibilityState === 'visible') load()
    }
    document.addEventListener('visibilitychange', handleVisibility)

    return () => {
      supabase.removeChannel(channel)
      document.removeEventListener('visibilitychange', handleVisibility)
    }
  }, [load])

  async function archiveConversation(offerId: string) {
    const column = userRole === 'provider' ? 'archived_by_provider' : 'archived_by_client'
    await supabase.from('offers').update({ [column]: !showArchived }).eq('id', offerId)
    load()
  }

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

  const isProvider = userRole === 'provider'

  return (
    <>
      <Nav />
      <main style={{ paddingTop: 64, minHeight: '100vh', background: 'var(--bg)' }}>
        <div style={{ maxWidth: 700, margin: '0 auto', padding: '40px 24px' }}>

          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 32 }}>
            <div>
              <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--amber)', letterSpacing: '0.1em', textTransform: 'uppercase' }}>{t('tag')}</span>
              <h1 style={{ fontSize: 32, fontWeight: 700, marginTop: 8, letterSpacing: '-0.02em' }}>{t('title')}</h1>
            </div>
            {/* Archive toggle */}
            <div style={{
              display: 'inline-flex', background: 'var(--bg-2)',
              border: '1px solid var(--line)', borderRadius: 20, padding: 3,
            }}>
              {[false, true].map(val => (
                <button key={String(val)} onClick={() => setShowArchived(val)} style={{
                  padding: '6px 12px', borderRadius: 16, border: 'none',
                  background: showArchived === val ? 'var(--amber)' : 'transparent',
                  color: showArchived === val ? '#000' : 'var(--text-mute)',
                  fontWeight: 700, fontSize: 11, cursor: 'pointer',
                  fontFamily: 'var(--font-sans)', transition: 'all 0.2s',
                }}>
                  {val ? t('toggle_archived') : t('toggle_active')}
                </button>
              ))}
            </div>
          </div>

          {conversations.length === 0 ? (
            <div style={{
              background: 'var(--bg-2)', border: '1px solid var(--line)',
              borderRadius: 16, padding: '60px 24px', textAlign: 'center',
            }}>
              <div style={{ fontSize: 40, marginBottom: 16 }}>
                {showArchived ? '📦' : '💬'}
              </div>
              <div style={{ fontSize: 16, fontWeight: 600, color: 'var(--text-dim)', marginBottom: 8 }}>
                {showArchived ? t('no_archived') : t('empty_title')}
              </div>
              {!showArchived && (
                <div style={{ fontSize: 13, color: 'var(--text-mute)' }}>
                  {isProvider ? t('empty_provider') : t('empty_client')}
                </div>
              )}
            </div>
          ) : (
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              {conversations.map(conv => {
                const isClient = conv.client_id === userId
                const otherName = isClient
                  ? (conv.provider_name ?? t('default_provider'))
                  : (conv.client_name ?? t('default_client'))
                const initials = otherName.split(' ').length >= 2
                  ? `${otherName.split(' ')[0][0]}${otherName.split(' ')[1][0]}`.toUpperCase()
                  : otherName.substring(0, 2).toUpperCase()
                const unread = conv.unread_count ?? 0
                const hasUnread = unread > 0

                return (
                  <div key={conv.offer_id} style={{
                    display: 'flex', alignItems: 'center', gap: 14,
                    background: 'var(--bg-2)',
                    border: `1px solid ${hasUnread ? (isProvider ? 'var(--cyan)' : 'var(--amber)') : 'var(--line)'}`,
                    borderRadius: 14, padding: '14px 18px',
                  }}>
                    {/* Avatar */}
                    <Link href={`/chat/${conv.offer_id}`} style={{
                      width: 48, height: 48, borderRadius: '50%', flexShrink: 0,
                      background: isProvider
                        ? 'linear-gradient(135deg, var(--amber), var(--amber-2))'
                        : 'linear-gradient(135deg, var(--cyan), var(--cyan-2))',
                      display: 'grid', placeItems: 'center',
                      fontSize: 16, fontWeight: 700, color: '#000',
                    }}>
                      {initials}
                    </Link>

                    {/* Content */}
                    <Link href={`/chat/${conv.offer_id}`} style={{ flex: 1, minWidth: 0 }}>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                        <span style={{
                          fontWeight: hasUnread ? 700 : 600, fontSize: 15,
                          color: 'var(--text)',
                        }}>
                          {otherName}
                        </span>
                        {conv.last_message_at && (
                          <span style={{ fontSize: 11, color: 'var(--text-mute)' }}>
                            {timeAgo(conv.last_message_at)}
                          </span>
                        )}
                      </div>
                      <div style={{
                        fontSize: 12, color: 'var(--text-dim)', fontWeight: 500,
                        marginTop: 2, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                      }}>
                        {conv.request_title}
                      </div>
                      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginTop: 2 }}>
                        <span style={{
                          fontSize: 13,
                          color: hasUnread ? 'var(--text)' : 'var(--text-mute)',
                          fontWeight: hasUnread ? 500 : 400,
                          overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap',
                          maxWidth: '80%',
                        }}>
                          {conv.last_message ?? t('start_conv')}
                        </span>
                        {hasUnread && (
                          <span style={{
                            background: isProvider ? 'var(--cyan)' : 'var(--amber)',
                            color: '#000', fontWeight: 700, fontSize: 11,
                            padding: '2px 7px', borderRadius: 10,
                          }}>
                            {unread}
                          </span>
                        )}
                      </div>
                    </Link>

                    {/* Archive button */}
                    <button
                      onClick={() => archiveConversation(conv.offer_id)}
                      title={showArchived ? t('unarchive') : t('archive')}
                      style={{
                        background: 'none', border: 'none', cursor: 'pointer',
                        color: 'var(--text-mute)', fontSize: 16, flexShrink: 0,
                      }}
                    >
                      {showArchived ? '📤' : '📥'}
                    </button>
                  </div>
                )
              })}
            </div>
          )}
        </div>
      </main>
    </>
  )
}