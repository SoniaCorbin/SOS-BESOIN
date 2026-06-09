export default function Providers() {
  const bullets = [
    { title: '10% de commission, tout inclus.', desc: 'Paiement transféré 24h après validation par le client.' },
    { title: 'Notifications ciblées.', desc: 'Recevez uniquement les demandes dans vos catégories.' },
    { title: 'Argent sécurisé.', desc: 'Le client a déjà déposé les fonds — vous êtes payé.' },
    { title: 'Statut KYC vérifié.', desc: 'Une fois validé, badge visible sur toutes vos offres.' },
  ]

  return (
    <section style={{ padding: '80px 24px', background: 'var(--bg-2)' }} id="pros">
      <div style={{ maxWidth: 1100, margin: '0 auto' }}>
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(300px, 1fr))',
          gap: 32,
          alignItems: 'center',
        }}>
          {/* Texte */}
          <div>
            <span style={{
              fontFamily: 'var(--font-mono)',
              fontSize: 11,
              color: 'var(--green)',
              letterSpacing: '0.1em',
              textTransform: 'uppercase',
            }}>·POUR_LES_PRESTATAIRES·</span>
            <h2 style={{
              fontSize: 'clamp(28px, 4vw, 48px)',
              fontWeight: 700,
              marginTop: 12,
              marginBottom: 24,
              letterSpacing: '-0.02em',
              lineHeight: 1.1,
            }}>
              De l'urgence,<br />
              <span style={{ color: 'var(--green)' }}>du revenu prévisible.</span>
            </h2>
            <p style={{ fontSize: 15, color: 'var(--text-dim)', lineHeight: 1.7, marginBottom: 32 }}>
              Rejoignez le réseau de prestataires qui captent les meilleures missions urgentes près de chez eux. Vous fixez vos prix. Vous choisissez ce que vous prenez.
            </p>
            <ul style={{ listStyle: 'none', display: 'flex', flexDirection: 'column', gap: 16, marginBottom: 36 }}>
              {bullets.map((b, i) => (
                <li key={i} style={{ display: 'flex', gap: 12 }}>
                  <span style={{
                    width: 20, height: 20, borderRadius: '50%',
                    background: 'var(--green)',
                    display: 'grid', placeItems: 'center',
                    flexShrink: 0, marginTop: 2,
                    fontSize: 11, color: '#000', fontWeight: 700,
                  }}>✓</span>
                  <span style={{ fontSize: 14, color: 'var(--text-dim)', lineHeight: 1.6 }}>
                    <b style={{ color: 'var(--text)' }}>{b.title}</b> {b.desc}
                  </span>
                </li>
              ))}
            </ul>
            <a href="/register" style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: 8,
              padding: '12px 24px',
              border: '1px solid var(--green)',
              borderRadius: 10,
              color: 'var(--green)',
              fontSize: 14,
              fontWeight: 600,
            }}>
              Postuler comme prestataire →
            </a>
          </div>

          {/* Carte prestataire */}
          <div style={{
            background: 'var(--bg)',
            border: '1px solid var(--line-2)',
            borderRadius: 16,
            padding: 24,
          }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 20 }}>
              <div style={{
                width: 44, height: 44, borderRadius: '50%',
                background: 'var(--bg-3)',
                border: '1px solid var(--line-2)',
                display: 'grid', placeItems: 'center',
                fontWeight: 700, fontSize: 14,
              }}>MD</div>
              <div style={{ flex: 1 }}>
                <div style={{ fontWeight: 600, fontSize: 15 }}>
                  Maxime D.
                  <span style={{ color: 'var(--cyan)', fontSize: 12, marginLeft: 8 }}>● vérifié</span>
                </div>
                <div style={{ fontSize: 12, color: 'var(--text-mute)' }}>Tech · Réseau · Mac/PC</div>
              </div>
              <div style={{ fontFamily: 'var(--font-mono)', fontSize: 13, color: 'var(--amber)' }}>★ 4.9</div>
            </div>

            <div style={{
              display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)',
              gap: 12, marginBottom: 20,
              padding: '16px 0',
              borderTop: '1px solid var(--line)',
              borderBottom: '1px solid var(--line)',
            }}>
              {[
                { v: '147', l: 'Missions' },
                { v: '12 min', l: 'Réponse moy.' },
                { v: '8 420$', l: 'Ce mois-ci' },
              ].map((s, i) => (
                <div key={i} style={{ textAlign: 'center' }}>
                  <div style={{ fontFamily: 'var(--font-mono)', fontSize: 18, fontWeight: 700, color: 'var(--amber)' }}>{s.v}</div>
                  <div style={{ fontSize: 11, color: 'var(--text-mute)', marginTop: 4 }}>{s.l}</div>
                </div>
              ))}
            </div>

            <div style={{ fontSize: 11, color: 'var(--text-mute)', fontFamily: 'var(--font-mono)', textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 12 }}>
              Missions récentes
            </div>
            {[
              { title: 'Récupérer données SSD endommagé', time: 'il y a 2h · Plateau', price: '180$', done: true },
              { title: 'Configuration NAS Synology + Plex', time: 'hier · Outremont', price: '220$', done: true },
              { title: 'Migration boîte mail entreprise', time: 'en cours · Mile End', price: '340$', done: false },
            ].map((j, i) => (
              <div key={i} style={{
                display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                padding: '10px 0',
                borderBottom: i < 2 ? '1px solid var(--line)' : 'none',
              }}>
                <div>
                  <div style={{ fontSize: 13, fontWeight: 500 }}>{j.title}</div>
                  <div style={{ fontSize: 11, color: 'var(--text-mute)', marginTop: 2 }}>{j.time}</div>
                </div>
                <span style={{
                  fontFamily: 'var(--font-mono)',
                  fontSize: 11,
                  padding: '3px 8px',
                  borderRadius: 6,
                  border: `1px solid ${j.done ? 'var(--green)' : 'var(--amber)'}`,
                  color: j.done ? 'var(--green)' : 'var(--amber)',
                  whiteSpace: 'nowrap',
                  marginLeft: 12,
                }}>{j.done ? `Validée · ${j.price}` : `En cours · ${j.price}`}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </section>
  )
}