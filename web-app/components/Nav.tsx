'use client'
import { useState, useEffect } from 'react'
import Link from 'next/link'
import { useRouter, usePathname } from 'next/navigation'
import { useTranslations, useLocale } from 'next-intl'
import { supabase } from '@/lib/supabase'
import { useNotifications } from '@/lib/useNotifications'

export default function Nav() {
  const router = useRouter()
  const pathname = usePathname()
  const locale = useLocale()
  const t = useTranslations('nav')
  const [user, setUser] = useState<any>(null)
  const [userId, setUserId] = useState<string | null>(null)
  const [menuOpen, setMenuOpen] = useState(false)
  const [isAdmin, setIsAdmin] = useState(false)
  const notifCount = useNotifications(userId)

  useEffect(() => {
    supabase.auth.getSession().then(async ({ data }) => {
      setUser(data.session?.user ?? null)
      setUserId(data.session?.user?.id ?? null)
      if (data.session?.user?.id) {
        const { data: profile } = await supabase
          .from('profiles')
          .select('is_admin')
          .eq('id', data.session.user.id)
          .single()
        setIsAdmin(profile?.is_admin ?? false)
      }
    })
    const { data: listener } = supabase.auth.onAuthStateChange(async (_, session) => {
      setUser(session?.user ?? null)
      setUserId(session?.user?.id ?? null)
      if (session?.user?.id) {
        const { data: profile } = await supabase
          .from('profiles')
          .select('is_admin')
          .eq('id', session.user.id)
          .single()
        setIsAdmin(profile?.is_admin ?? false)
      } else {
        setIsAdmin(false)
      }
    })
    return () => listener.subscription.unsubscribe()
  }, [])

  async function handleLogout() {
    await supabase.auth.signOut()
    router.push('/')
  }

  function switchLocale(newLocale: string) {
    const segments = pathname.split('/')
    segments[1] = newLocale
    router.push(segments.join('/'))
  }

  const LangToggle = () => (
    <div style={{ display: 'flex', alignItems: 'center', gap: 4, marginLeft: 8 }}>
      <button
        onClick={() => switchLocale('fr')}
        style={{
          background: 'transparent', border: 'none', cursor: 'pointer',
          fontFamily: 'var(--font-sans)', fontSize: 13, fontWeight: 700,
          color: locale === 'fr' ? 'var(--amber)' : 'var(--text-mute)',
          padding: '4px 2px',
        }}
      >FR</button>
      <span style={{ color: 'var(--text-mute)', fontSize: 13 }}>|</span>
      <button
        onClick={() => switchLocale('en')}
        style={{
          background: 'transparent', border: 'none', cursor: 'pointer',
          fontFamily: 'var(--font-sans)', fontSize: 13, fontWeight: 700,
          color: locale === 'en' ? 'var(--amber)' : 'var(--text-mute)',
          padding: '4px 2px',
        }}
      >EN</button>
    </div>
  )

  return (
    <>
      <nav style={{
        position: 'fixed', top: 0, left: 0, right: 0, zIndex: 100,
        borderBottom: '1px solid var(--line)',
        background: 'rgba(8,11,17,0.95)',
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

        {/* Desktop Links */}
        <div className="nav-desktop" style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          {user ? (
            <>
              {isAdmin && (
                <Link href="/admin" style={{
                  padding: '8px 18px',
                  border: '1px solid var(--red)',
                  borderRadius: 8,
                  fontSize: 14,
                  color: 'var(--red)',
                }}>
                  {t('admin')}
                </Link>
              )}
              <Link href="/explore" style={{ padding: '8px 18px', border: '1px solid var(--line-2)', borderRadius: 8, fontSize: 14, color: 'var(--text-dim)' }}>
                {t('explore')}
              </Link>
              <Link href="/dashboard" style={{ padding: '8px 18px', border: '1px solid var(--line-2)', borderRadius: 8, fontSize: 14, color: 'var(--text-dim)', display: 'flex', alignItems: 'center', gap: 6 }}>
                {t('dashboard')}
                {notifCount > 0 && (
                  <span style={{ background: 'var(--red)', color: '#fff', borderRadius: '50%', width: 18, height: 18, fontSize: 11, fontWeight: 700, display: 'grid', placeItems: 'center' }}>{notifCount}</span>
                )}
              </Link>
              <Link href="/conversations" style={{ padding: '8px 18px', border: '1px solid var(--line-2)', borderRadius: 8, fontSize: 14, color: 'var(--text-dim)' }}>
                              {t('messages')}
              </Link>
              <Link href="/invoices" style={{ padding: '8px 18px', border: '1px solid var(--line-2)', borderRadius: 8, fontSize: 14, color: 'var(--text-dim)' }}>
                {t('invoices')}
              </Link>
              <Link href="/profile" style={{ padding: '8px 18px', border: '1px solid var(--line-2)', borderRadius: 8, fontSize: 14, color: 'var(--text-dim)' }}>
                {t('profile')}
              </Link>
              <Link href="/requests/new" style={{ padding: '8px 18px', background: 'var(--amber)', color: '#000', borderRadius: 8, fontWeight: 600, fontSize: 14 }}>
                {t('sos_btn')}
              </Link>
              <button onClick={handleLogout} style={{ padding: '8px 18px', border: '1px solid var(--line-2)', borderRadius: 8, fontSize: 14, color: 'var(--text-mute)', background: 'transparent', cursor: 'pointer', fontFamily: 'var(--font-sans)' }}>
                {t('logout')}
              </button>
            </>
          ) : (
            <>
              <Link href="/requests/new" style={{ padding: '8px 18px', background: 'var(--amber)', color: '#000', borderRadius: 8, fontWeight: 600, fontSize: 14 }}>
                {t('sos_btn')}
              </Link>
              <Link href="/login" style={{ padding: '8px 18px', border: '1px solid var(--line-2)', borderRadius: 8, fontSize: 14, color: 'var(--text-dim)' }}>
                {t('login')}
              </Link>
            </>
          )}
          <LangToggle />
        </div>

        {/* Mobile: bouton hamburger */}
        <button
          className="nav-mobile-btn"
          onClick={() => setMenuOpen(!menuOpen)}
          style={{ display: 'none', background: 'transparent', border: 'none', color: 'var(--text)', cursor: 'pointer', fontSize: 24, padding: 8 }}
        >
          {menuOpen ? '✕' : '☰'}
        </button>
      </nav>

      {/* Mobile menu */}
      {menuOpen && (
        <div className="nav-mobile-menu" style={{
          position: 'fixed', top: 64, left: 0, right: 0, zIndex: 99,
          background: 'var(--bg-2)',
          borderBottom: '1px solid var(--line)',
          padding: '16px 24px',
          display: 'flex', flexDirection: 'column', gap: 10,
        }}>
          {user ? (
            <>
              {isAdmin && (
                <Link href="/admin" onClick={() => setMenuOpen(false)} style={{ padding: '12px 16px', border: '1px solid var(--red)', borderRadius: 8, fontSize: 15, color: 'var(--red)' }}>{t('admin')}</Link>
              )}
              <Link href="/explore" onClick={() => setMenuOpen(false)} style={{ padding: '12px 16px', border: '1px solid var(--line)', borderRadius: 8, fontSize: 15, color: 'var(--text-dim)' }}>{t('explore')}</Link>
              <Link href="/dashboard" onClick={() => setMenuOpen(false)} style={{ padding: '12px 16px', border: '1px solid var(--line)', borderRadius: 8, fontSize: 15, color: 'var(--text-dim)', display: 'flex', alignItems: 'center', gap: 8 }}>
                {t('dashboard')}
                {notifCount > 0 && <span style={{ background: 'var(--red)', color: '#fff', borderRadius: '50%', width: 20, height: 20, fontSize: 11, fontWeight: 700, display: 'grid', placeItems: 'center' }}>{notifCount}</span>}
              </Link>
              <Link href="/conversations" onClick={() => setMenuOpen(false)} style={{ padding: '12px 16px', border: '1px solid var(--line)', borderRadius: 8, fontSize: 15, color: 'var(--text-dim)' }}>{t('messages')}</Link>
              <Link href="/invoices" onClick={() => setMenuOpen(false)} style={{ padding: '12px 16px', border: '1px solid var(--line)', borderRadius: 8, fontSize: 15, color: 'var(--text-dim)' }}>{t('invoices')}</Link>
              <Link href="/profile" onClick={() => setMenuOpen(false)} style={{ padding: '12px 16px', border: '1px solid var(--line)', borderRadius: 8, fontSize: 15, color: 'var(--text-dim)' }}>{t('profile')}</Link>
              <Link href="/requests/new" onClick={() => setMenuOpen(false)} style={{ padding: '12px 16px', background: 'var(--amber)', color: '#000', borderRadius: 8, fontWeight: 600, fontSize: 15, textAlign: 'center' }}>{t('sos_btn')}</Link>
              <button onClick={() => { handleLogout(); setMenuOpen(false) }} style={{ padding: '12px 16px', border: '1px solid var(--line)', borderRadius: 8, fontSize: 15, color: 'var(--text-mute)', background: 'transparent', cursor: 'pointer', fontFamily: 'var(--font-sans)', textAlign: 'left' }}>{t('logout')}</button>
            </>
          ) : (
            <>
              <Link href="/requests/new" onClick={() => setMenuOpen(false)} style={{ padding: '12px 16px', background: 'var(--amber)', color: '#000', borderRadius: 8, fontWeight: 600, fontSize: 15, textAlign: 'center' }}>{t('sos_btn')}</Link>
              <Link href="/login" onClick={() => setMenuOpen(false)} style={{ padding: '12px 16px', border: '1px solid var(--line)', borderRadius: 8, fontSize: 15, color: 'var(--text-dim)' }}>{t('login')}</Link>
            </>
          )}
          <LangToggle />
        </div>
      )}

      <style>{`
        @media (max-width: 640px) {
          .nav-desktop { display: none !important; }
          .nav-mobile-btn { display: block !important; }
        }
      `}</style>
    </>
  )
}