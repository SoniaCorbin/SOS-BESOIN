'use client'
import { useState } from 'react'
import Link from 'next/link'
import { useRouter } from 'next/navigation'
import { supabase } from '@/lib/supabase'

export default function RegisterPage() {
  const router = useRouter()
  const [fullName, setFullName] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [role, setRole] = useState<'client' | 'provider'>('client')
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState('')

  async function handleRegister() {
    if (!fullName || !email || !password) {
      setError('Remplissez tous les champs.')
      return
    }
    setLoading(true)
    setError('')

    const { data, error: signUpError } = await supabase.auth.signUp({
      email,
      password,
      options: { data: { full_name: fullName } }
    })

    if (signUpError) {
      setError(signUpError.message)
      setLoading(false)
      return
    }

    if (data.user) {
      await supabase.from('profiles').insert({
        id: data.user.id,
        full_name: fullName,
        email,
        role,
      })
      router.push('/dashboard')
    }
    setLoading(false)
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
          <h1 style={{ fontSize: 24, fontWeight: 700, marginBottom: 8, letterSpacing: '-0.02em' }}>Créer un compte</h1>
          <p style={{ fontSize: 14, color: 'var(--text-dim)', marginBottom: 28 }}>
            Déjà un compte? <Link href="/login" style={{ color: 'var(--amber)' }}>Se connecter</Link>
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

          {/* Nom */}
          <div style={{ marginBottom: 16 }}>
            <label style={{ fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 6 }}>Nom complet</label>
            <input
              type="text"
              value={fullName}
              onChange={e => setFullName(e.target.value)}
              placeholder="Marie Tremblay"
              style={{
                width: '100%', padding: '10px 14px',
                background: 'var(--bg-3)', border: '1px solid var(--line-2)',
                borderRadius: 8, color: 'var(--text)', fontSize: 14, outline: 'none',
              }}
            />
          </div>

          {/* Email */}
          <div style={{ marginBottom: 16 }}>
            <label style={{ fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 6 }}>Courriel</label>
            <input
              type="email"
              value={email}
              onChange={e => setEmail(e.target.value)}
              placeholder="vous@exemple.com"
              style={{
                width: '100%', padding: '10px 14px',
                background: 'var(--bg-3)', border: '1px solid var(--line-2)',
                borderRadius: 8, color: 'var(--text)', fontSize: 14, outline: 'none',
              }}
            />
          </div>

          {/* Mot de passe */}
          <div style={{ marginBottom: 20 }}>
            <label style={{ fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 6 }}>Mot de passe</label>
            <input
              type="password"
              value={password}
              onChange={e => setPassword(e.target.value)}
              placeholder="••••••••"
              style={{
                width: '100%', padding: '10px 14px',
                background: 'var(--bg-3)', border: '1px solid var(--line-2)',
                borderRadius: 8, color: 'var(--text)', fontSize: 14, outline: 'none',
              }}
            />
          </div>

          {/* Rôle */}
          <div style={{ marginBottom: 24 }}>
            <label style={{ fontSize: 13, color: 'var(--text-dim)', display: 'block', marginBottom: 10 }}>Je suis...</label>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
              {[
                { value: 'client', label: '🙋 Un client', desc: 'Je cherche un service' },
                { value: 'provider', label: '🔧 Un prestataire', desc: 'Je propose mes services' },
              ].map((r) => (
                <button
                  key={r.value}
                  onClick={() => setRole(r.value as 'client' | 'provider')}
                  style={{
                    padding: '12px',
                    background: role === r.value ? 'var(--amber-soft)' : 'var(--bg-3)',
                    border: `1px solid ${role === r.value ? 'var(--amber)' : 'var(--line-2)'}`,
                    borderRadius: 8,
                    cursor: 'pointer',
                    textAlign: 'left',
                    fontFamily: 'var(--font-sans)',
                  }}
                >
                  <div style={{ fontSize: 13, fontWeight: 600, color: 'var(--text)', marginBottom: 2 }}>{r.label}</div>
                  <div style={{ fontSize: 11, color: 'var(--text-mute)' }}>{r.desc}</div>
                </button>
              ))}
            </div>
          </div>

          {/* Bouton */}
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
            {loading ? 'Création...' : 'Créer mon compte'}
          </button>
        </div>
      </div>
    </div>
  )
}