'use client'
import { useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { supabase } from '@/lib/supabase'

export default function LoginPage() {
  const router = useRouter()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  async function handleLogin() {
    setLoading(true)
    setError('')
    const { error } = await supabase.auth.signInWithPassword({ email, password })
    if (error) {
      setError('Courriel ou mot de passe incorrect.')
      setLoading(false)
    } else {
      router.push('/dashboard')
    }
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
        {/* Logo */}
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

        {/* Card */}
        <div style={{
          background: 'var(--bg-2)',
          border: '1px solid var(--line)',
          borderRadius: 16,
          padding: '32px',
        }}>
          <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 8, letterSpacing: '-0.02em' }}>Connexion</h1>
          <p style={{ fontSize: 14, color: 'var(--text-dim)', marginBottom: 28 }}>
            Pas encore de compte? <Link href="/register" style={{ color: 'var(--amber)' }}>S'inscrire</Link>
          </p>

          {error && (
            <div style={{
              background: 'rgba(239,68,68,0.1)',
              border: '1px solid var(--red)',
              borderRadius: 8,
              padding: '10px 14px',
              fontSize: 13,
              color: 'var(--red)',
              marginBottom: 20,
            }}>{error}</div>
          )}

          {/* Email */}
          <div style={{ marginBottom: 16 }}>
            <label style={{ fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 6 }}>Courriel</label>
            <input
              type="email"
              value={email}
              onChange={e => setEmail(e.target.value)}
              placeholder="vous@exemple.com"
              style={{
                width: '100%',
                padding: '10px 14px',
                background: 'var(--bg-3)',
                border: '1px solid var(--line-2)',
                borderRadius: 8,
                color: 'var(--text)',
                fontSize: 14,
                outline: 'none',
              }}
            />
          </div>

          {/* Mot de passe */}
          <div style={{ marginBottom: 24 }}>
            <label style={{ fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 6 }}>Mot de passe</label>
            <input
              type="password"
              value={password}
              onChange={e => setPassword(e.target.value)}
              placeholder="••••••••"
              onKeyDown={e => e.key === 'Enter' && handleLogin()}
              style={{
                width: '100%',
                padding: '10px 14px',
                background: 'var(--bg-3)',
                border: '1px solid var(--line-2)',
                borderRadius: 8,
                color: 'var(--text)',
                fontSize: 14,
                outline: 'none',
              }}
            />
          </div>

          {/* Bouton */}
          <button
            onClick={handleLogin}
            disabled={loading}
            style={{
              width: '100%',
              padding: '12px',
              background: loading ? 'var(--bg-3)' : 'var(--amber)',
              color: loading ? 'var(--text-dim)' : '#000',
              border: 'none',
              borderRadius: 8,
              fontSize: 15,
              fontWeight: 600,
              cursor: loading ? 'not-allowed' : 'pointer',
              fontFamily: 'var(--font-sans)',
            }}
          >
            {loading ? 'Connexion...' : 'Se connecter'}
          </button>
        </div>
      </div>
    </div>
  )
}