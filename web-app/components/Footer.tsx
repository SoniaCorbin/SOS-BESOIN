import Link from 'next/link'

export default function Footer() {
  return (
    <footer style={{
      borderTop: '1px solid var(--line)',
      padding: '60px 24px 32px',
      background: 'var(--bg)',
    }}>
      <div style={{ maxWidth: 1100, margin: '0 auto' }}>
        <div style={{
          display: 'grid',
          gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
          gap: 40,
          marginBottom: 48,
        }}>
          {/* Brand */}
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 16 }}>
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
            </div>
            <p style={{ fontSize: 13, color: 'var(--text-dim)', lineHeight: 1.6 }}>
              La place de marché pour vos besoins urgents. Prestataires vérifiés. Paiement séquestré.
            </p>
          </div>

          {/* Plateforme */}
          <div>
            <h5 style={{ fontSize: 12, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--text-mute)', marginBottom: 16 }}>Plateforme</h5>
            <ul style={{ listStyle: 'none', display: 'flex', flexDirection: 'column', gap: 10 }}>
              {[
                { label: 'Comment ça marche', href: '#how' },
                { label: 'Catégories', href: '#categories' },
                { label: 'Demandes en direct', href: '#live' },
                { label: 'Devenir prestataire', href: '#pros' },
              ].map((l, i) => (
                <li key={i}><Link href={l.href} style={{ fontSize: 14, color: 'var(--text-dim)' }}>{l.label}</Link></li>
              ))}
            </ul>
          </div>

          {/* Support */}
          <div>
            <h5 style={{ fontSize: 12, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--text-mute)', marginBottom: 16 }}>Support</h5>
            <ul style={{ listStyle: 'none', display: 'flex', flexDirection: 'column', gap: 10 }}>
              {[
                { label: "Centre d'aide", href: '#' },
                { label: 'Contacter le support', href: '#' },
                { label: 'FAQ', href: '#faq' },
              ].map((l, i) => (
                <li key={i}><Link href={l.href} style={{ fontSize: 14, color: 'var(--text-dim)' }}>{l.label}</Link></li>
              ))}
            </ul>
          </div>

          {/* Légal */}
          <div>
            <h5 style={{ fontSize: 12, fontWeight: 600, letterSpacing: '0.08em', textTransform: 'uppercase', color: 'var(--text-mute)', marginBottom: 16 }}>Légal</h5>
            <ul style={{ listStyle: 'none', display: 'flex', flexDirection: 'column', gap: 10 }}>
              {[
                { label: "Conditions générales", href: '/terms' },
                { label: 'Politique de confidentialité', href: '/privacy' },
                { label: 'Politique de remboursement', href: '/refund' },
              ].map((l, i) => (
                <li key={i}><Link href={l.href} style={{ fontSize: 14, color: 'var(--text-dim)' }}>{l.label}</Link></li>
              ))}
            </ul>
          </div>
        </div>

        {/* Bottom */}
        <div style={{
          borderTop: '1px solid var(--line)',
          paddingTop: 24,
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          flexWrap: 'wrap',
          gap: 12,
        }}>
          <span style={{ fontSize: 12, color: 'var(--text-mute)' }}>© 2026 SOS-BESOIN · Tous droits réservés</span>
          <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--text-mute)' }}>
            status: ALL SYSTEMS OK
          </span>
        </div>
      </div>
    </footer>
  )
}