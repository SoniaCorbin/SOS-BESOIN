'use client'
import Nav from '@/components/Nav'
import Link from 'next/link'
import { useTranslations } from 'next-intl'

export default function RefundPage() {
  const t = useTranslations('legal')

  return (
    <>
      <Nav />
      <main style={{ paddingTop: 64, minHeight: '100vh', background: 'var(--bg)' }}>
        <div style={{ maxWidth: 800, margin: '0 auto', padding: '40px 24px' }}>
          <div style={{ marginBottom: 32 }}>
            <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--amber)', letterSpacing: '0.1em', textTransform: 'uppercase' }}>{t('tag')}</span>
            <h1 style={{ fontSize: 32, fontWeight: 700, marginTop: 8, letterSpacing: '-0.02em' }}>{t('refund_title')}</h1>
            <p style={{ fontSize: 13, color: 'var(--text-mute)', marginTop: 8 }}>{t('updated')}</p>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 32, fontSize: 14, color: 'var(--text-dim)', lineHeight: 1.8 }}>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>1. Principe du paiement séquestré</h2>
              <p>SOS-BESOIN utilise un système de paiement séquestré (escrow). Lorsque vous acceptez une offre, votre paiement est retenu de manière sécurisée par Stripe et n'est libéré au prestataire qu'après votre validation explicite de la mission.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>2. Remboursement avant validation</h2>
              <p>Si vous n'avez pas encore validé la mission, vous pouvez demander un remboursement complet dans les cas suivants :</p>
              <ul style={{ marginTop: 8, paddingLeft: 20, display: 'flex', flexDirection: 'column', gap: 6 }}>
                <li>Le prestataire ne s'est pas présenté ou ne répond plus</li>
                <li>Le prestataire a annulé la mission</li>
                <li>La mission n'a pas été complétée conformément à ce qui était convenu</li>
              </ul>
              <p style={{ marginTop: 8 }}>Dans ces cas, contactez notre support dans les <strong style={{ color: 'var(--text)' }}>48 heures</strong> suivant la date prévue de la mission.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>3. Après validation de la mission</h2>
              <p>Une fois que vous avez validé la mission et que le paiement a été libéré au prestataire, les remboursements ne sont généralement plus possibles. Exceptions :</p>
              <ul style={{ marginTop: 8, paddingLeft: 20, display: 'flex', flexDirection: 'column', gap: 6 }}>
                <li>Fraude avérée de la part du prestataire</li>
                <li>Erreur technique de traitement double paiement</li>
              </ul>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>4. Commission de la plateforme</h2>
              <p>La commission de 10% prélevée par SOS-BESOIN n'est pas remboursable, sauf en cas d'erreur technique de notre part.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>5. Délais de remboursement</h2>
              <p>Les remboursements approuvés sont traités dans un délai de <strong style={{ color: 'var(--text)' }}>5 à 10 jours ouvrables</strong> selon votre institution financière.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>6. Comment demander un remboursement</h2>
              <p>Contactez notre support à <a href="mailto:sosbesoinapp@outlook.com" style={{ color: 'var(--amber)' }}>sosbesoinapp@outlook.com</a> en indiquant :</p>
              <ul style={{ marginTop: 8, paddingLeft: 20, display: 'flex', flexDirection: 'column', gap: 6 }}>
                <li>Votre numéro de demande</li>
                <li>La raison de votre demande de remboursement</li>
                <li>Tout élément justificatif (captures d'écran, messages, etc.)</li>
              </ul>
            </section>

            <div style={{ borderTop: '1px solid var(--line)', paddingTop: 24, display: 'flex', gap: 16 }}>
              <Link href="/terms" style={{ color: 'var(--cyan)', fontSize: 13 }}>{t('link_terms')}</Link>
              <Link href="/privacy" style={{ color: 'var(--cyan)', fontSize: 13 }}>{t('link_privacy')}</Link>
            </div>
          </div>
        </div>
      </main>
    </>
  )
}