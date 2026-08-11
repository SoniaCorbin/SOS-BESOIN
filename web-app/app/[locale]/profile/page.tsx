'use client'
import { useState, useEffect, useCallback } from 'react'
import { useRouter } from 'next/navigation'
import Link from 'next/link'
import { useTranslations } from 'next-intl'
import { supabase } from '@/lib/supabase'
import Nav from '@/components/Nav'
import { getCurrentPosition } from '@/lib/geolocation'

type CategoryRow = { id: string; slug: string; label: string; emoji: string; is_custom: boolean }

export default function ProfilePage() {
  const router = useRouter()
  const t = useTranslations('profile')
  const [profile, setProfile] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [editing, setEditing] = useState(false)
  const [saving, setSaving] = useState(false)
  const [saved, setSaved] = useState(false)
  const [locating, setLocating] = useState(false)
  const [locationSaved, setLocationSaved] = useState(false)
  const [categories, setCategories] = useState<CategoryRow[]>([])
  const [form, setForm] = useState({
    full_name: '',
    phone: '',
    latitude: null as number | null,
    longitude: null as number | null,
    max_distance_km: 50,
    provider_categories: [] as string[],
  })

  useEffect(() => {
    async function load() {
      const { data: { session } } = await supabase.auth.getSession()
      if (!session) { router.push('/login'); return }
      const { data } = await supabase.from('profiles').select('*').eq('id', session.user.id).single()
      setProfile(data)
      setForm({
        full_name: data?.full_name ?? '',
        phone: data?.phone ?? '',
        latitude: data?.latitude ?? null,
        longitude: data?.longitude ?? null,
        max_distance_km: data?.max_distance_km ?? 50,
        provider_categories: data?.provider_categories ?? [],
      })

      // Fetch categories
      const { data: cats } = await supabase
        .from('categories')
        .select('id, slug, label, emoji, is_custom')
        .eq('is_active', true)
        .order('sort_order')
      setCategories(cats ?? [])

      setLoading(false)
    }
    load()
  }, [router])

  async function handleLocation() {
    setLocating(true)
    try {
      const pos = await getCurrentPosition()
      setForm(f => ({ ...f, latitude: pos.lat, longitude: pos.lng }))
      setLocationSaved(true)
    } catch (e) {}
    setLocating(false)
  }

  function toggleCategory(slug: string) {
    setForm(f => {
      const current = f.provider_categories
      if (current.includes(slug)) {
        return { ...f, provider_categories: current.filter(s => s !== slug) }
      } else {
        return { ...f, provider_categories: [...current, slug] }
      }
    })
  }

  async function handleSave() {
    setSaving(true)
    const { data: { session } } = await supabase.auth.getSession()
    if (!session) return
    await supabase.from('profiles').update({
      full_name: form.full_name,
      phone: form.phone,
      latitude: form.latitude,
      longitude: form.longitude,
      max_distance_km: form.max_distance_km,
      provider_categories: form.provider_categories.length > 0 ? form.provider_categories : null,
    }).eq('id', session.user.id)
    setSaving(false)
    setSaved(true)
    setEditing(false)
    setTimeout(() => setSaved(false), 3000)
  }

  async function handleLogout() {
    await supabase.auth.signOut()
    router.push('/')
  }

  if (loading) return (
    <div style={{ minHeight: '100vh', display: 'grid', placeItems: 'center', background: 'var(--bg)' }}>
      <div style={{ color: 'var(--amber)', fontFamily: 'var(--font-mono)' }}>{t('loading')}</div>
    </div>
  )

  const isProvider = profile?.role === 'provider'
  const inputStyle = { width: '100%', padding: '10px 14px', background: 'var(--bg-3)', border: '1px solid var(--line-2)', borderRadius: 8, color: 'var(--text)', fontSize: 14, outline: 'none', fontFamily: 'var(--font-sans)' }

  return (
    <>
      <Nav />
      <main style={{ paddingTop: 64, minHeight: '100vh', background: 'var(--bg)' }}>
        <div style={{ maxWidth: 700, margin: '0 auto', padding: '40px 24px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 32 }}>
            <div>
              <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--amber)', letterSpacing: '0.1em', textTransform: 'uppercase' }}>{t('tag')}</span>
              <h1 style={{ fontSize: 32, fontWeight: 700, marginTop: 8, letterSpacing: '-0.02em' }}>{t('title')}</h1>
            </div>
            <button
              onClick={() => editing ? handleSave() : setEditing(true)}
              disabled={saving}
              style={{
                padding: '10px 20px',
                background: editing ? 'var(--amber)' : 'var(--bg-2)',
                color: editing ? '#000' : 'var(--text-dim)',
                border: `1px solid ${editing ? 'var(--amber)' : 'var(--line)'}`,
                borderRadius: 8, fontSize: 14, fontWeight: 600,
                cursor: 'pointer', fontFamily: 'var(--font-sans)',
              }}
            >
              {saving ? '...' : editing ? t('save_btn') : t('edit_btn')}
            </button>
          </div>

          {saved && (
            <div style={{ background: 'var(--green-soft)', border: '1px solid var(--green)', borderRadius: 8, padding: '10px 14px', fontSize: 13, color: 'var(--green)', marginBottom: 20 }}>
              {t('saved')}
            </div>
          )}

          {/* Avatar + infos de base */}
          <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 16, padding: '28px', marginBottom: 20 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 20, marginBottom: 24 }}>
              <div style={{
                width: 72, height: 72, borderRadius: '50%',
                background: isProvider ? 'var(--cyan-soft)' : 'var(--amber-soft)',
                border: `2px solid ${isProvider ? 'var(--cyan)' : 'var(--amber)'}`,
                display: 'grid', placeItems: 'center',
                fontSize: 28, fontWeight: 700, color: isProvider ? 'var(--cyan)' : 'var(--amber)',
              }}>
                {profile?.full_name?.[0]?.toUpperCase() ?? '?'}
              </div>
              <div>
                <div style={{ fontWeight: 600, fontSize: 18 }}>{profile?.full_name}</div>
                <div style={{ fontSize: 13, color: 'var(--text-mute)', marginTop: 2 }}>{profile?.email}</div>
                <div style={{ fontSize: 12, marginTop: 6, color: isProvider ? 'var(--cyan)' : 'var(--amber)' }}>
                  {isProvider ? `🔧 ${t('role_provider')}` : `🙋 ${t('role_client')}`}
                </div>
              </div>
              <div style={{ marginLeft: 'auto', display: 'flex', gap: 16 }}>
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontFamily: 'var(--font-mono)', fontSize: 20, fontWeight: 700, color: 'var(--amber)' }}>
                    {profile?.rating ? `${profile.rating.toFixed(1)} ★` : '—'}
                  </div>
                  <div style={{ fontSize: 11, color: 'var(--text-mute)', textTransform: 'uppercase', letterSpacing: '0.08em' }}>{t('stat_rating')}</div>
                </div>
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontFamily: 'var(--font-mono)', fontSize: 20, fontWeight: 700, color: 'var(--cyan)' }}>
                    {profile?.total_missions ?? 0}
                  </div>
                  <div style={{ fontSize: 11, color: 'var(--text-mute)', textTransform: 'uppercase', letterSpacing: '0.08em' }}>{t('stat_missions')}</div>
                </div>
              </div>
            </div>
            <div style={{ fontSize: 12, color: profile?.is_kyc_verified ? 'var(--green)' : 'var(--text-mute)', fontFamily: 'var(--font-mono)' }}>
              {profile?.is_kyc_verified ? t('kyc_verified') : t('kyc_pending')}
            </div>
          </div>

          {/* Infos modifiables */}
          <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 16, padding: '28px', marginBottom: 20 }}>
            <div style={{ marginBottom: 16 }}>
              <label style={{ fontSize: 12, color: 'var(--text-mute)', display: 'block', marginBottom: 6, textTransform: 'uppercase', letterSpacing: '0.08em' }}>{t('name_label')}</label>
              {editing ? (
                <input value={form.full_name} onChange={e => setForm(f => ({ ...f, full_name: e.target.value }))}
                  style={{ ...inputStyle, borderColor: 'var(--amber)' }} />
              ) : (
                <div style={{ fontSize: 15, color: 'var(--text)' }}>{profile?.full_name}</div>
              )}
            </div>
            <div style={{ marginBottom: 16 }}>
              <label style={{ fontSize: 12, color: 'var(--text-mute)', display: 'block', marginBottom: 6, textTransform: 'uppercase', letterSpacing: '0.08em' }}>{t('phone_label')}</label>
              {editing ? (
                <input value={form.phone} onChange={e => setForm(f => ({ ...f, phone: e.target.value }))}
                  placeholder="+1 (514) 000-0000" style={inputStyle} />
              ) : (
                <div style={{ fontSize: 15, color: profile?.phone ? 'var(--text)' : 'var(--text-mute)' }}>{profile?.phone || '—'}</div>
              )}
            </div>

            {editing && (
              <>
                <button onClick={handleLocation} disabled={locating} style={{
                  padding: '10px 16px', background: locationSaved ? 'var(--green-soft)' : 'var(--bg-3)',
                  border: `1px solid ${locationSaved ? 'var(--green)' : 'var(--line-2)'}`,
                  borderRadius: 8, fontSize: 13, color: locationSaved ? 'var(--green)' : 'var(--text-dim)',
                  cursor: 'pointer', fontFamily: 'var(--font-sans)', marginBottom: 16,
                }}>
                  {locating ? t('locating') : locationSaved ? t('location_saved') : t('location_btn')}
                </button>

                {isProvider && (
                  <>
                    {/* Distance slider */}
                    <div style={{ marginBottom: 20 }}>
                      <label style={{ fontSize: 12, color: 'var(--text-mute)', display: 'block', marginBottom: 8, textTransform: 'uppercase', letterSpacing: '0.08em' }}>
                        {t('radius_label')}: <span style={{ color: 'var(--cyan)' }}>{form.max_distance_km >= 500 ? t('radius_unlimited') : `${form.max_distance_km} km`}</span>
                      </label>
                      <input type="range" min={5} max={500} value={form.max_distance_km}
                        onChange={e => setForm(f => ({ ...f, max_distance_km: Number(e.target.value) }))}
                        style={{ width: '100%', accentColor: 'var(--cyan)' }} />
                    </div>

                    {/* Category filter */}
                    <div>
                      <label style={{ fontSize: 12, color: 'var(--text-mute)', display: 'block', marginBottom: 8, textTransform: 'uppercase', letterSpacing: '0.08em' }}>
                        {t('categories_label')}
                      </label>
                      <p style={{ fontSize: 12, color: 'var(--text-mute)', marginBottom: 12 }}>
                        {t('categories_hint')}
                      </p>
                      <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
                        {categories.filter(c => !c.is_custom).map(cat => {
                          const isSelected = form.provider_categories.includes(cat.slug)
                          return (
                            <button key={cat.slug} onClick={() => toggleCategory(cat.slug)} style={{
                              padding: '8px 14px', borderRadius: 20,
                              background: isSelected ? 'var(--amber-soft)' : 'var(--bg-3)',
                              border: `1px solid ${isSelected ? 'var(--amber)' : 'var(--line-2)'}`,
                              color: isSelected ? 'var(--amber)' : 'var(--text-dim)',
                              fontSize: 13, fontWeight: isSelected ? 600 : 400,
                              cursor: 'pointer', fontFamily: 'var(--font-sans)',
                              transition: 'all 0.15s',
                            }}>
                              {cat.emoji} {cat.label}
                            </button>
                          )
                        })}
                      </div>
                    </div>
                  </>
                )}
              </>
            )}

            {/* Show selected categories when not editing */}
            {!editing && isProvider && (
              <div style={{ marginTop: 16 }}>
                <label style={{ fontSize: 12, color: 'var(--text-mute)', display: 'block', marginBottom: 8, textTransform: 'uppercase', letterSpacing: '0.08em' }}>
                  {t('categories_label')}
                </label>
                {(profile?.provider_categories ?? []).length === 0 ? (
                  <div style={{ fontSize: 13, color: 'var(--text-mute)' }}>{t('categories_all')}</div>
                ) : (
                  <div style={{ display: 'flex', flexWrap: 'wrap', gap: 6 }}>
                    {(profile?.provider_categories ?? []).map((slug: string) => {
                      const cat = categories.find(c => c.slug === slug)
                      return (
                        <span key={slug} style={{
                          padding: '5px 10px', borderRadius: 16,
                          background: 'var(--amber-soft)', border: '1px solid var(--amber)',
                          color: 'var(--amber)', fontSize: 12, fontWeight: 600,
                        }}>
                          {cat ? `${cat.emoji} ${cat.label}` : slug}
                        </span>
                      )
                    })}
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Stripe */}
          {isProvider && (
            <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 16, padding: '20px', marginBottom: 20 }}>
              <a href="https://connect.stripe.com/setup/c/acct_xxx" target="_blank" rel="noopener noreferrer"
                style={{ display: 'block', textAlign: 'center', padding: '12px', background: 'var(--amber)', color: '#000', borderRadius: 8, fontWeight: 600, fontSize: 14 }}>
                {t('stripe_btn')}
              </a>
            </div>
          )}

          {/* Légal */}
          <div style={{ background: 'var(--bg-2)', border: '1px solid var(--line)', borderRadius: 16, padding: '20px', marginBottom: 20 }}>
            <div style={{ fontSize: 12, color: 'var(--text-mute)', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 12 }}>{t('legal_title')}</div>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              <Link href="/terms" style={{ fontSize: 14, color: 'var(--text-dim)' }}>{t('link_terms')} →</Link>
              <Link href="/privacy" style={{ fontSize: 14, color: 'var(--text-dim)' }}>{t('link_privacy')} →</Link>
              <Link href="/refund" style={{ fontSize: 14, color: 'var(--text-dim)' }}>{t('link_refund')} →</Link>
            </div>
          </div>

          {/* Déconnexion */}
          <button onClick={handleLogout} style={{
            width: '100%', padding: '12px', background: 'transparent',
            border: '1px solid var(--red)', borderRadius: 8, color: 'var(--red)',
            fontSize: 14, fontWeight: 600, cursor: 'pointer', fontFamily: 'var(--font-sans)',
          }}>
            {t('logout_btn')}
          </button>
        </div>
      </main>
    </>
  )
}