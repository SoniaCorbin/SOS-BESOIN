'use client'
import { useState } from 'react'

const FAQ_ITEMS = [
  {
    q: "Combien de temps avant de recevoir une offre ?",
    a: "Les prestataires vérifiés près de vous répondent rapidement. Sur les catégories Tech, Musique et Transport, la majorité des demandes reçoivent au moins 2 offres en moins de 15 minutes en journée."
  },
  {
    q: "Comment fonctionne le paiement séquestré ?",
    a: "Quand vous acceptez une offre, votre carte est débitée mais l'argent reste bloqué chez Stripe. Le prestataire ne reçoit le paiement qu'après votre validation. Si rien ne va, on rembourse."
  },
  {
    q: "Que se passe-t-il si je dois annuler ma demande ?",
    a: "Tant qu'aucune offre n'est acceptée, vous pouvez annuler sans frais. Une fois une offre acceptée, des conditions s'appliquent selon le délai et la catégorie."
  },
  {
    q: "Les prestataires sont-ils vérifiés ?",
    a: "Tous les prestataires passent un KYC (identité + adresse) avant de pouvoir soumettre des offres. Les prestataires notés moins de 3,5/5 après 10 missions sont suspendus automatiquement."
  },
  {
    q: "Quelle est la commission de la plateforme ?",
    a: "10% du montant de la mission, retenue automatiquement sur le paiement du prestataire. Aucun frais caché côté client : le prix affiché par le prestataire est le prix que vous payez."
  },
  {
    q: "Puis-je utiliser un code promo ?",
    a: "Les codes promo arrivent bientôt ! Inscrivez-vous sur la liste d'attente pour être notifié en priorité."
  },
]

export default function FAQ() {
  const [open, setOpen] = useState<number | null>(null)

  return (
    <section style={{ padding: '80px 24px', background: 'var(--bg-2)' }} id="faq">
      <div style={{ maxWidth: 720, margin: '0 auto' }}>
        <div style={{ textAlign: 'center', marginBottom: 48 }}>
          <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--amber)', letterSpacing: '0.1em', textTransform: 'uppercase' }}>·FAQ·</span>
          <h2 style={{ fontSize: 'clamp(28px, 4vw, 48px)', fontWeight: 700, marginTop: 12, letterSpacing: '-0.02em' }}>
            Les choses qu'on<br />nous demande le plus.
          </h2>
        </div>

        <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
          {FAQ_ITEMS.map((item, i) => (
            <div key={i} style={{
              background: 'var(--bg)',
              border: `1px solid ${open === i ? 'var(--amber)' : 'var(--line)'}`,
              borderRadius: 12,
              overflow: 'hidden',
              transition: 'border-color 0.2s',
            }}>
              <button
                onClick={() => setOpen(open === i ? null : i)}
                style={{
                  width: '100%', padding: '18px 20px',
                  display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                  background: 'transparent', border: 'none',
                  cursor: 'pointer', fontFamily: 'var(--font-sans)',
                  textAlign: 'left',
                }}
              >
                <span style={{ fontSize: 15, fontWeight: 500, color: 'var(--text)' }}>{item.q}</span>
                <span style={{ color: 'var(--amber)', fontSize: 20, marginLeft: 16, flexShrink: 0 }}>
                  {open === i ? '−' : '+'}
                </span>
              </button>
              {open === i && (
                <div style={{ padding: '0 20px 18px', fontSize: 14, color: 'var(--text-dim)', lineHeight: 1.7 }}>
                  {item.a}
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}