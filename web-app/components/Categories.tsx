'use client'

const CATEGORIES = [
  { icon: '💻', label: 'Tech & Informatique' },
  { icon: '🔧', label: 'Réparation & Bricolage' },
  { icon: '🎵', label: 'Musique & Événements' },
  { icon: '🚗', label: 'Transport & Livraison' },
  { icon: '📚', label: 'Cours & Tutoriels' },
  { icon: '✍️', label: 'Rédaction & Graphisme' },
  { icon: '🌐', label: 'Web & Développement' },
  { icon: '⚖️', label: 'Juridique & Admin' },
  { icon: '❤️', label: 'Santé & Bien-être' },
]

export default function Categories() {
  return (
    <section style={{ padding: '80px 24px' }}>
      <div style={{ maxWidth: 1100, margin: '0 auto' }}>
        <div style={{ textAlign: 'center', marginBottom: 48 }}>
          <span style={{
            fontFamily: 'var(--font-mono)',
            fontSize: 11,
            color: 'var(--amber)',
            letterSpacing: '0.1em',
            textTransform: 'uppercase',
          }}>·CATÉGORIES·</span>
          <h2 style={{
            fontSize: 'clamp(28px, 4vw, 48px)',
            fontWeight: 700,
            marginTop: 12,
            letterSpacing: '-0.02em',
          }}>Ce qu'on règle <span style={{ color: 'var(--amber)' }}>pour vous.</span></h2>
        </div>

        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))',
          gap: 12,
        }}>
          {CATEGORIES.map((cat, i) => (
            <div key={i} style={{
              background: 'var(--bg-2)',
              border: '1px solid var(--line)',
              borderRadius: 12,
              padding: '20px 16px',
              display: 'flex',
              alignItems: 'center',
              gap: 12,
              cursor: 'pointer',
              transition: 'border-color 0.2s',
            }}
            onMouseEnter={e => (e.currentTarget.style.borderColor = 'var(--amber)')}
            onMouseLeave={e => (e.currentTarget.style.borderColor = 'var(--line)')}
            >
              <span style={{ fontSize: 24 }}>{cat.icon}</span>
              <span style={{ fontSize: 14, fontWeight: 500 }}>{cat.label}</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
