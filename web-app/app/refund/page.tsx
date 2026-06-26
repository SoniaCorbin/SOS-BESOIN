'use client'
import Nav from '@/components/Nav'
import Link from 'next/link'

export default function RefundPage() {
  return (
    <>
      <Nav />
      <main style={{ paddingTop: 64, minHeight: '100vh', background: 'var(--bg)' }}>
        <div style={{ maxWidth: 800, margin: '0 auto', padding: '40px 24px' }}>
          <div style={{ marginBottom: 32 }}>
            <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--amber)', letterSpacing: '0.1em', textTransform: 'uppercase' }}>·LÉGAL·</span>
            <h1 style={{ fontSize: 32, fontWeight: 700, marginTop: 8, letterSpacing: '-0.02em' }}>Politique de remboursement</h1>
            <p style={{ fontSize: 13, color: 'var(--text-mute)', marginTop: 8 }}>Dernière mise à jour : 23 juin 2026</p>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 32, fontSize: 14, color: 'var(--text-dim)', lineHeight: 1.8 }}>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>1. Principe du paiement séquestré</h2>
              <p>SOS-BESOIN utilise un système de paiement séquestré (escrow) pour protéger les deux parties. Lorsqu'un client accepte une offre, le montant est retenu de manière sécurisée via Stripe et n'est libéré au prestataire qu'après la validation de la mission.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>2. Cas de remboursement</h2>
              <p>Un remboursement complet est accordé dans les situations suivantes :</p>
              <ul style={{ marginTop: 8, paddingLeft: 20, display: 'flex', flexDirection: 'column', gap: 6 }}>
                <li>Le prestataire n'a pas effectué la mission convenue</li>
                <li>Le prestataire annule après acceptation de l'offre</li>
                <li>La mission n'a pas été complétée dans les délais convenus</li>
                <li>Le service fourni ne correspond pas à la description de l'offre acceptée</li>
                <li>Erreur technique ayant entraîné un double paiement</li>
              </ul>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>3. Cas de non-remboursement</h2>
              <p>Aucun remboursement ne sera accordé dans les situations suivantes :</p>
              <ul style={{ marginTop: 8, paddingLeft: 20, display: 'flex', flexDirection: 'column', gap: 6 }}>
                <li>La mission a été validée par le client (validation manuelle ou automatique après 3 jours)</li>
                <li>Le client a changé d'avis après la complétion de la mission</li>
                <li>Le client n'était pas disponible à l'heure convenue sans préavis</li>
                <li>Insatisfaction subjective non liée à un manquement du prestataire</li>
              </ul>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>4. Validation automatique</h2>
              <p>Si le client ne valide pas la mission dans les <strong style={{ color: 'var(--text)' }}>3 jours suivant la complétion</strong>, le paiement est automatiquement libéré au prestataire. Passé ce délai, aucun remboursement ne peut être accordé sauf en cas de fraude avérée.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>5. Procédure de remboursement</h2>
              <p>Pour demander un remboursement :</p>
              <ul style={{ marginTop: 8, paddingLeft: 20, display: 'flex', flexDirection: 'column', gap: 6 }}>
                <li>Contactez-nous à <a href="mailto:support@sosbesoin.ca" style={{ color: 'var(--amber)' }}>support@sosbesoin.ca</a> dans les 7 jours suivant l'incident</li>
                <li>Indiquez votre numéro de demande et une description détaillée du problème</li>
                <li>Notre équipe examinera votre demande dans un délai de 5 jours ouvrables</li>
                <li>Si approuvé, le remboursement sera effectué sur votre mode de paiement original dans un délai de 5 à 10 jours ouvrables</li>
              </ul>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>6. Litiges entre utilisateurs</h2>
              <p>En cas de litige entre un client et un prestataire, Corbin Creative Tech Inc. peut intervenir en tant que médiateur. Nous nous réservons le droit de prendre une décision finale concernant le remboursement après examen des preuves fournies par les deux parties (messages, photos, descriptions).</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>7. Frais de plateforme</h2>
              <p>Les frais de service de Corbin Creative Tech Inc. ne sont pas remboursables une fois la mise en relation effectuée, sauf en cas d'erreur technique de notre part.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>8. Contact</h2>
              <p>Pour toute question concernant un remboursement :</p>
              <p style={{ marginTop: 8 }}>
                <strong style={{ color: 'var(--text)' }}>Corbin Creative Tech Inc.</strong><br />
                <a href="mailto:support@sosbesoin.ca" style={{ color: 'var(--amber)' }}>support@sosbesoin.ca</a><br />
                Délai de réponse : 2 jours ouvrables
              </p>
            </section>

            <div style={{ borderTop: '1px solid var(--line)', paddingTop: 24, display: 'flex', gap: 16 }}>
              <Link href="/terms" style={{ color: 'var(--cyan)', fontSize: 13 }}>Conditions d'utilisation →</Link>
              <Link href="/privacy" style={{ color: 'var(--cyan)', fontSize: 13 }}>Politique de confidentialité →</Link>
            </div>
          </div>
        </div>
      </main>
    </>
  )
}