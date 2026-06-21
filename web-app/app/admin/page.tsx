'use client'
import { useState, useEffect } from 'react'
import { useRouter } from 'next/navigation'
import { supabase } from '@/lib/supabase'
import Nav from '@/components/Nav'
import Link from 'next/link'

export default function AdminPage() {
  const router = useRouter()
  const [loading, setLoading] = useState(true)
  const [activeTab, setActiveTab] = useState<'stats' | 'users' | 'requests'>('stats')
  const [stats, setStats] = useState({ users: 0, providers: 0, requests: 0, completed: 0, revenue: 0 })
  const [users, setUsers] = useState<any[]>([])
  const [requests, setRequests] = useState<any[]>([])

  useEffect(() => {
    async function load() {
      const { data: { session } } = await supabase.auth.getSession()
      if (!session) { router.push('/login'); return }

      // Vérifier si admin
      const { data: profile } = await supabase
        .from('profiles')
        .select('is_admin')
        .eq('id', session.user.id)
        .single()

      if (!profile?.is_admin) { router.push('/dashboard'); return }

      await Promise.all([fetchStats(), fetchUsers(), fetchRequests()])
      setLoading(false)
    }
    load()
  }, [])

  async function fetchStats() {
    const [
      { count: users },
      { count: providers },
      { count: requests },
      { count: completed },
    ] = await Promise.all([
      supabase.from('profiles').select('*', { count: 'exact', head: true }),
      supabase.from('profiles').select('*', { count: 'exact', head: true }).eq('role', 'provider'),
      supabase.from('requests').select('*', { count: 'exact', head: true }),
      supabase.from('requests').select('*', { count: 'exact', head: true }).eq('status', 'completed'),
    ])
    setStats({ users: users ?? 0, providers: providers ?? 0, requests: requests ?? 0, completed: completed ?? 0, revenue: 0 })
  }

  async function fetchUsers() {
    const { data } = await supabase
      .from('profiles')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(50)
    setUsers(data ?? [])
  }

  async function fetchRequests() {
    const { data } = await supabase
      .from('requests')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(50)
    setRequests(data ?? [])
  }

  async function toggleSuspend(userId: string, isSuspended: boolean) {
    await supabase.from('profiles').update({ is_suspended: !isSuspended }).eq('id', userId)
    await fetchUsers()
  }

  if (loading) return (
    <div style={{ minHeight: '100vh', display: 'grid', placeItems: 'center', background: 'var(--bg)' }}>
      <div style={{ color: 'var(--amber)', fontFamily: 'var(--font-mono)' }}>Chargement...</div>
    </div>
  )

  const tabStyle = (tab: string) => ({
    padding: '8px 20px',
    borderRadius: 8,
    border: 'none',
    background: activeTab === tab ? 'var(--amber)' : 'transparent',
    color: activeTab === tab ? '#000' : 'var(--text-dim)',
    fontWeight: activeTab === tab ? 600 : 400,
    fontSize: 14,
    cursor: 'pointer',
    fontFamily: 'var(--font-sans)',
  })

  return (
    <>
      <Nav />
      <main style={{ paddingTop: 64, minHeight: '100vh', background: 'var(--bg)' }}>
        <div style={{ maxWidth: 1200, margin: '0 auto', padding: '40px 24px' }}>

          {/* Header */}
          <div style={{ marginBottom: 32 }}>
            <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--red)', letterSpacing: '0.1em', textTransform: 'uppercase' }}>·ADMIN·</span>
            <h1 style={{ fontSize: 32, fontWeight: 700, marginTop: 8, letterSpacing: '-0.02em' }}>Panel Admin</h1>
          </div>

          {/* Tabs */}
          <div style={{ display: 'flex', gap: 4, background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 10, padding: 4, marginBottom: 32, width: 'fit-content' }}>
            <button style={tabStyle('stats')} onClick={() => setActiveTab('stats')}>📊 Statistiques</button>
            <button style={tabStyle('users')} onClick={() => setActiveTab('users')}>👥 Utilisateurs</button>
            <button style={tabStyle('requests')} onClick={() => setActiveTab('requests')}>📋 Demandes</button>
          </div>

          {/* Stats */}
          {activeTab === 'stats' && (
            <div>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(200px, 1fr))', gap: 16, marginBottom: 32 }}>
                {[
                  { label: 'Utilisateurs total', value: stats.users, color: 'var(--amber)' },
                  { label: 'Prestataires', value: stats.providers, color: 'var(--cyan)' },
                  { label: 'Demandes total', value: stats.requests, color: 'var(--violet)' },
                  { label: 'Missions complétées', value: stats.completed, color: 'var(--green)' },
                ].map((s, i) => (
                  <div key={i} style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 12, padding: '24px' }}>
                    <div style={{ fontFamily: 'var(--font-mono)', fontSize: 36, fontWeight: 700, color: s.color }}>{s.value}</div>
                    <div style={{ fontSize: 12, color: 'var(--text-mute)', marginTop: 4, textTransform: 'uppercase', letterSpacing: '0.08em' }}>{s.label}</div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Users */}
          {activeTab === 'users' && (
            <div>
              <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 16, overflow: 'hidden' }}>
                <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--line)', display: 'flex', justifyContent: 'space-between' }}>
                  <span style={{ fontWeight: 600 }}>Utilisateurs ({users.length})</span>
                </div>
                {users.map((user, i) => (
                  <div key={user.id} style={{
                    display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                    padding: '14px 20px',
                    borderBottom: i < users.length - 1 ? '1px solid var(--line)' : 'none',
                    opacity: user.is_suspended ? 0.5 : 1,
                  }}>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontWeight: 500, fontSize: 14 }}>
                        {user.full_name}
                        {user.is_admin && <span style={{ marginLeft: 8, fontSize: 11, color: 'var(--red)', border: '1px solid var(--red)', borderRadius: 4, padding: '1px 6px' }}>ADMIN</span>}
                        {user.is_kyc_verified && <span style={{ marginLeft: 8, fontSize: 11, color: 'var(--cyan)', border: '1px solid var(--cyan)', borderRadius: 4, padding: '1px 6px' }}>KYC</span>}
                      </div>
                      <div style={{ fontSize: 12, color: 'var(--text-mute)', marginTop: 2 }}>{user.email} · {user.role} · ★ {user.rating?.toFixed(1) ?? '—'}</div>
                    </div>
                    <button
                      onClick={() => toggleSuspend(user.id, user.is_suspended)}
                      style={{
                        padding: '6px 14px',
                        background: user.is_suspended ? 'var(--green-soft)' : 'rgba(239,68,68,0.1)',
                        border: `1px solid ${user.is_suspended ? 'var(--green)' : 'var(--red)'}`,
                        borderRadius: 6,
                        color: user.is_suspended ? 'var(--green)' : 'var(--red)',
                        fontSize: 12, cursor: 'pointer',
                        fontFamily: 'var(--font-sans)',
                      }}
                    >
                      {user.is_suspended ? 'Réactiver' : 'Suspendre'}
                    </button>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Requests */}
          {activeTab === 'requests' && (
            <div>
              <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 16, overflow: 'hidden' }}>
                <div style={{ padding: '16px 20px', borderBottom: '1px solid var(--line)' }}>
                  <span style={{ fontWeight: 600 }}>Demandes ({requests.length})</span>
                </div>
                {requests.map((req, i) => (
                  <Link key={req.id} href={`/requests/${req.id}`} style={{
                    display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                    padding: '14px 20px',
                    borderBottom: i < requests.length - 1 ? '1px solid var(--line)' : 'none',
                  }}>
                    <div style={{ flex: 1 }}>
                      <div style={{ fontWeight: 500, fontSize: 14 }}>{req.title}</div>
                      <div style={{ fontSize: 12, color: 'var(--text-mute)', marginTop: 2 }}>{req.category} · {req.location}</div>
                    </div>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                      {req.budget && <span style={{ fontFamily: 'var(--font-mono)', fontSize: 13, color: 'var(--amber)' }}>{req.budget}$</span>}
                      <span style={{
                        fontFamily: 'var(--font-mono)', fontSize: 11,
                        padding: '3px 8px', borderRadius: 6,
                        background: req.status === 'open' ? 'var(--amber-soft)' : req.status === 'completed' ? 'var(--green-soft)' : 'var(--bg-3)',
                        color: req.status === 'open' ? 'var(--amber)' : req.status === 'completed' ? 'var(--green)' : 'var(--text-dim)',
                      }}>{req.status}</span>
                    </div>
                  </Link>
                ))}
              </div>
            </div>
          )}
        </div>
      </main>
    </>
  )
}