export default function HowItWorks() {
  const steps = [
    {
      number: '01',
      title: 'Décrivez votre besoin',
      desc: 'Prenez 90 secondes pour décrire ce qu\'il vous faut, votre budget et votre délai.',
      color: 'var(--amber)',
    },
    {
      number: '02',
      title: 'Recevez des offres',
      desc: 'Les prestataires vérifiés vous envoient leur prix et leur dispo en direct.',
      color: 'var(--cyan)',
    },
    {
      number: '03',
      title: 'Acceptez et payez',
      desc: 'Choisissez l\'offre qui vous convient. Le paiement est séquestré — vous ne payez qu\'à la validation.',
      color: 'var(--violet)',
    },
    {
      number: '04',
      title: 'Mission accomplie',
      desc: 'Validez la mission terminée. Le prestataire est payé dans les 24h. Laissez un avis.',
      color: 'var(--green)',
    },
  ]

  return (
    <section style={{ padding: '80px 24px' }} id="how">
      <div style={{ maxWidth: 1100, margin: '0 auto' }}>
        <div style={{ textAlign: 'center', marginBottom: 64 }}>
          <span style={{
            fontFamily: 'var(--font-mono)',
            fontSize: 11,
            color: 'var(--violet)',
            letterSpacing: '0.1em',
            textTransform: 'uppercase',
          }}>·COMMENT_ÇA_MARCHE·</span>
          <h2 style={{
            fontSize: 'clamp(28px, 4vw, 48px)',
            fontWeight: 700,
            marginTop: 12,
            letterSpacing: '-0.02em',
          }}>Simple. Rapide. <span style={{ color: 'var(--violet)' }}>Sécurisé.</span></h2>
        </div>

        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))',
          gap: 24,
        }}>
          {steps.map((step, i) => (
            <div key={i} style={{
              background: 'var(--bg-2)',
              border: '1px solid var(--line)',
              borderRadius: 16,
              padding: '28px 24px',
              position: 'relative',
            }}>
              <div style={{
                fontFamily: 'var(--font-mono)',
                fontSize: 36,
                fontWeight: 700,
                color: step.color,
                opacity: 0.3,
                lineHeight: 1,
                marginBottom: 16,
              }}>{step.number}</div>
              <h3 style={{ fontSize: 16, fontWeight: 600, marginBottom: 10 }}>{step.title}</h3>
              <p style={{ fontSize: 14, color: 'var(--text-dim)', lineHeight: 1.6 }}>{step.desc}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}