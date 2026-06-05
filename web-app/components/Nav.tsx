'use client'
import { useState, useEffect } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { supabase } from '@/lib/supabase'

export default function Nav() {
  const router = useRouter()
  const [user, setUser] = useState<any>(null)

  useEffect(() => {
    supabase.auth.getSession().then(({ data }) => {
      setUser(data.session?.user ?? null)
    })
    const { data: listener } = supabase.auth.onAuthStateChange((_, session) => {
      setUser(session?.user ?? null)
    })
    return () => listener.subscription.unsubscribe()
  }, [])

  async function handleLogout() {
    await supabase.auth.signOut()
    router.push('/')
  }

  return (
    <nav style={{
      position: 'fixed', top: 0, left: 0, right: 0, zIndex: 100,
      borderBottom: '1px solid var(--line)',
      background: 'rgba(8,11,17,0.85)',
      backdropFilter: 'blur(12px)',
      padding: '0 24px',
      height: 64,
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
    }}>
      {/* Logo */}
      <Link href="/" style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{
          width: 32, height: 32, borderRadius: 8,
          background: 'var(--amber-soft)',
          border: '1px solid var(--amber)',
          display: 'grid', placeItems: 'center',
          color: 'var(--amber)',
        }}>⚠</div>
        <span style={{ fontWeight: 700, fontSize: 16, letterSpacing: '-0.02em' }}>
          SOS<b style={{ color: 'var(--amber)' }}>·BESOIN</b>
        </span>
      </Link>

      {/* Links */}
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        {user ? (
          <>
            <Link href="/dashboard" style={{
              padding: '8px 18px',
              border: '1px solid var(--line-2)',
              borderRadius: 8,
              fontSize: 14,
              color: 'var(--text-dim)',
            }}>
              Dashboard
            </Link>
            <Link href="/requests/new" style={{
              padding: '8px 18px',
              background: 'var(--amber)',
              color: '#000',
              borderRadius: 8,
              fontWeight: 600,
              fontSize: 14,
            }}>
              + Lancer un SOS
            </Link>
            <button onClick={handleLogout} style={{
              padding: '8px 18px',
              border: '1px solid var(--line-2)',
              borderRadius: 8,
              fontSize: 14,
              color: 'var(--text-mute)',
              background: 'transparent',
              cursor: 'pointer',
              fontFamily: 'var(--font-sans)',
            }}>
              Déconnexion
            </button>
          </>
        ) : (
          <>
            <Link href="/requests/new" style={{
              padding: '8px 18px',
              background: 'var(--amber)',
              color: '#000',
              borderRadius: 8,
              fontWeight: 600,
              fontSize: 14,
            }}>
              + Lancer un SOS
            </Link>
            <Link href="/login" style={{
              padding: '8px 18px',
              border: '1px solid var(--line-2)',
              borderRadius: 8,
              fontSize: 14,
              color: 'var(--text-dim)',
            }}>
              Connexion
            </Link>
          </>
        )}
      </div>
    </nav>
  )
}