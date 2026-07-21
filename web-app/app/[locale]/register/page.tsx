'use client'
import { useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { useTranslations } from 'next-intl'
import { supabase } from '@/lib/supabase'

export default function RegisterPage() {
  const router = useRouter()
  const t = useTranslations('register')
  const [form, setForm] = useState({ full_name: '', email: '', password: '', role: 'client' })
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  async function handleRegister() {
    setLoading(true)
    setError('')
    setSuccess('')

    const { data, error: signUpError } = await supabase.auth.signUp({
      email: form.email,
      password: form.password,
      options: { data: { full_name: form.full_name } },
    })

    if (signUpError) {
      setError(t('error_generic'))
      setLoading(false)
      return
    }

    if (data.user) {
      await supabase.from('profiles').upsert({
        id: data.user.id,
        full_name: form.full_name,
        email: form.email,
        role: form.role,
      })
    }

    setSuccess(t('success'))
    setLoading(false)
    setTimeout(() => router.push('/login'), 2000)
  }

  return (
    <div style={{
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      padding: '24px',
      background: 'var(--bg)',
    }}>
      <div style={{ width: '100%', maxWidth: 420 }}>
        <Link href="/" style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 40, justifyContent: 'center' }}>
          <div style={{
            width: 32, height: 32, borderRadius: 8,
            background: 'var(--amber-soft)',
            border: '1px solid var(--amber)',
            display: 'grid', placeItems: 'center',
            color: 'var(--amber)',
          }}>⚠</div>
          <span style={{ fontWeight: 700, fontSize: 16 }}>
            SOS<b style={{ color: 'var(--amber)' }}>·BESOIN</b>
          </span>
        </Link>

        <div style={{
          background: 'var(--bg-2)',
          border: '1px solid var(--line)',
          borderRadius: 16,
          padding: '32px',
        }}>
          <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 8, letterSpacing: '-0.02em' }}>{t('title')}</h1>
          <p style={{ fontSize: 14, color: 'var(--text-dim)', marginBottom: 28 }}>
            {t('have_account')} <Link href="/login" style={{ color: 'var(--amber)' }}>{t('login_link')}</Link>
          </p>

          {error && (
            <div style={{ background: 'rgba(239,68,68,0.1)', border: '1px solid var(--red)', borderRadius: 8, padding: '10px 14px', fontSize: 13, color: 'var(--red)', marginBottom: 20 }}>{error}</div>
          )}
          {success && (
            <div style={{ background: 'var(--green-soft)', border: '1px solid var(--green)', borderRadius: 8, padding: '10px 14px', fontSize: 13, color: 'var(--green)', marginBottom: 20 }}>{success}</div>
          )}

          <div style={{ marginBottom: 16 }}>
            <label style={{ fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 6 }}>{t('name_label')}</label>
            <input
              type="text"
              value={form.full_name}
              onChange={e => setForm(f => ({ ...f, full_name: e.target.value }))}
              placeholder={t('name_placeholder')}
              style={{ width: '100%', padding: '10px 14px', background: 'var(--bg-3)', border: '1px solid var(--line-2)', borderRadius: 8, color: 'var(--text)', fontSize: 14, outline: 'none' }}
            />
          </div>

          <div style={{ marginBottom: 16 }}>
            <label style={{ fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 6 }}>{t('email_label')}</label>
            <input
              type="email"
              value={form.email}
              onChange={e => setForm(f => ({ ...f, email: e.target.value }))}
              placeholder={t('email_placeholder')}
              style={{ width: '100%', padding: '10px 14px', background: 'var(--bg-3)', border: '1px solid var(--line-2)', borderRadius: 8, color: 'var(--text)', fontSize: 14, outline: 'none' }}
            />
          </div>

          <div style={{ marginBottom: 16 }}>
            <label style={{ fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 6 }}>{t('password_label')}</label>
            <input
              type="password"
              value={form.password}
              onChange={e => setForm(f => ({ ...f, password: e.target.value }))}
              placeholder="••••••••"
              style={{ width: '100%', padding: '10px 14px', background: 'var(--bg-3)', border: '1px solid var(--line-2)', borderRadius: 8, color: 'var(--text)', fontSize: 14, outline: 'none' }}
            />
          </div>

          <div style={{ marginBottom: 24 }}>
            <label style={{ fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 10 }}>{t('role_label')}</label>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
              {(['client', 'provider'] as const).map(role => (
                <button
                  key={role}
                  onClick={() => setForm(f => ({ ...f, role }))}
                  style={{
                    padding: '12px 16px',
                    background: form.role === role ? (role === 'provider' ? 'var(--cyan-soft)' : 'var(--amber-soft)') : 'var(--bg-3)',
                    border: `1px solid ${form.role === role ? (role === 'provider' ? 'var(--cyan)' : 'var(--amber)') : 'var(--line-2)'}`,
                    borderRadius: 8,
                    color: form.role === role ? (role === 'provider' ? 'var(--cyan)' : 'var(--amber)') : 'var(--text-dim)',
                    fontSize: 14, fontWeight: form.role === role ? 600 : 400,
                    cursor: 'pointer', textAlign: 'left',
                    fontFamily: 'var(--font-sans)',
                  }}
                >
                  {role === 'client' ? t('role_client') : t('role_provider')}
                </button>
              ))}
            </div>
          </div>

          <button
            onClick={handleRegister}
            disabled={loading}
            style={{
              width: '100%', padding: '12px',
              background: loading ? 'var(--bg-3)' : 'var(--amber)',
              color: loading ? 'var(--text-dim)' : '#000',
              border: 'none', borderRadius: 8,
              fontSize: 15, fontWeight: 600,
              cursor: loading ? 'not-allowed' : 'pointer',
              fontFamily: 'var(--font-sans)',
            }}
          >
            {loading ? t('loading') : t('submit')}
          </button>
        </div>
      </div>
    </div>
  )
}