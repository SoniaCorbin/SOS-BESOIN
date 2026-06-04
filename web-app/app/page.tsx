import Nav from '@/components/Nav'
import Stats from '@/components/Stats'

export default function Home() {
  return (
    <>
      <Nav />
      <main style={{ paddingTop: 64 }}>
        <section style={{
          minHeight: '100vh',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          textAlign: 'center',
          padding: '0 24px',
        }}>
          <div>
            <span style={{
              fontFamily: 'var(--font-mono)',
              fontSize: 11,
              color: 'var(--amber)',
              letterSpacing: '0.1em',
              textTransform: 'uppercase',
            }}>·SOS_BESOIN·</span>
            <h1 style={{
              fontSize: 'clamp(40px, 6vw, 80px)',
              fontWeight: 700,
              lineHeight: 1.1,
              letterSpacing: '-0.03em',
              marginTop: 16,
            }}>
              Un pro disponible,<br />
              <span style={{ color: 'var(--amber)' }}>quand c'est urgent.</span>
            </h1>
            <p style={{
              marginTop: 24,
              fontSize: 18,
              color: 'var(--text-dim)',
              maxWidth: 480,
              margin: '24px auto 0',
            }}>
              Décrivez ce qu'il vous faut. Un prestataire vérifié répond en moins de 30 minutes.
            </p>
          </div>
        </section>
        <Stats />
      </main>
    </>
  )
}