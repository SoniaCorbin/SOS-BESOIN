const TESTIMONIALS = [
  {
    quote: "Mon DJ a annulé 4h avant le mariage. J'ai posté à 14h, accepté une offre à 14h32, le prestataire était là à 17h. Ça a sauvé la soirée.",
    name: "Élodie L.", role: "Cliente · Mariage", initials: "EL", color: "var(--amber)",
  },
  {
    quote: "En tant que technicien à mon compte, j'avais des trous dans mon agenda. SOS-BESOIN me remplit les créneaux libres avec des missions claires et payantes.",
    name: "Karim B.", role: "Prestataire · Tech", initials: "KB", color: "var(--cyan)",
  },
  {
    quote: "Lave-vaisselle qui inonde la cuisine un dimanche soir. Trois offres reçues en 15 min. Réparé le lendemain matin. Payé seulement après vérif.",
    name: "Sophie M.", role: "Cliente · Réparation", initials: "SM", color: "var(--violet)",
  },
]

export default function Testimonials() {
  return (
    <section style={{ padding: '80px 24px' }}>
      <div style={{ maxWidth: 1100, margin: '0 auto' }}>
        <div style={{ textAlign: 'center', marginBottom: 48 }}>
          <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--amber)', letterSpacing: '0.1em', textTransform: 'uppercase' }}>·TÉMOIGNAGES·</span>
          <h2 style={{ fontSize: 'clamp(28px, 4vw, 48px)', fontWeight: 700, marginTop: 12, letterSpacing: '-0.02em' }}>
            Quand <span style={{ color: 'var(--amber)' }}>chaque minute compte</span>,<br />les gens reviennent.
          </h2>
        </div>

        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: 20 }}>
          {TESTIMONIALS.map((t, i) => (
            <div key={i} style={{
              background: 'var(--bg-2)', border: '1px solid var(--line)',
              borderRadius: 16, padding: '28px',
              display: 'flex', flexDirection: 'column', gap: 16,
            }}>
              <div style={{ display: 'flex', gap: 4 }}>
                {[0,1,2,3,4].map(s => (
                  <span key={s} style={{ color: 'var(--amber)', fontSize: 14 }}>★</span>
                ))}
              </div>
              <p style={{ fontSize: 14, color: 'var(--text-dim)', lineHeight: 1.7, flex: 1 }}>
                « {t.quote} »
              </p>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <div style={{
                  width: 40, height: 40, borderRadius: '50%',
                  background: t.color, opacity: 0.8,
                  display: 'grid', placeItems: 'center',
                  fontWeight: 700, fontSize: 13, color: '#000',
                }}>{t.initials}</div>
                <div>
                  <div style={{ fontWeight: 600, fontSize: 14 }}>{t.name}</div>
                  <div style={{ fontSize: 12, color: 'var(--text-mute)' }}>{t.role}</div>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}