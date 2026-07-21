'use client'
import Nav from '@/components/Nav'
import Link from 'next/link'
import { useTranslations } from 'next-intl'

export default function TermsPage() {
  const t = useTranslations('legal')

  return (
    <>
      <Nav />
      <main style={{ paddingTop: 64, minHeight: '100vh', background: 'var(--bg)' }}>
        <div style={{ maxWidth: 800, margin: '0 auto', padding: '40px 24px' }}>
          <div style={{ marginBottom: 32 }}>
            <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--amber)', letterSpacing: '0.1em', textTransform: 'uppercase' }}>{t('tag')}</span>
            <h1 style={{ fontSize: 32, fontWeight: 700, marginTop: 8, letterSpacing: '-0.02em' }}>{t('terms_title')}</h1>
            <p style={{ fontSize: 13, color: 'var(--text-mute)', marginTop: 8 }}>{t('updated')}</p>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 32, fontSize: 14, color: 'var(--text-dim)', lineHeight: 1.8 }}>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>1. Objet</h2>
              <p>Les présentes conditions générales d'utilisation régissent l'accès et l'utilisation de la plateforme SOS-BESOIN, exploitée par Corbin Creative Tech Inc. (NEQ : 1182286402), ci-après dénommée « la Plateforme ».</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>2. Acceptation des conditions</h2>
              <p>En créant un compte ou en utilisant la Plateforme, vous acceptez sans réserve les présentes conditions. Si vous n'acceptez pas ces conditions, vous ne devez pas utiliser la Plateforme.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>3. Description du service</h2>
              <p>SOS-BESOIN est une place de marché qui met en relation des clients ayant des besoins urgents de services avec des prestataires qualifiés et vérifiés. La Plateforme facilite la mise en contact, la communication et le paiement sécurisé entre les parties.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>4. Inscription et compte</h2>
              <ul style={{ paddingLeft: 20, display: 'flex', flexDirection: 'column', gap: 6 }}>
                <li>Vous devez avoir au moins 18 ans pour créer un compte</li>
                <li>Les informations fournies doivent être exactes et à jour</li>
                <li>Vous êtes responsable de la confidentialité de vos identifiants</li>
                <li>Un seul compte par personne est autorisé</li>
              </ul>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>5. Obligations des utilisateurs</h2>
              <p>Vous vous engagez à :</p>
              <ul style={{ marginTop: 8, paddingLeft: 20, display: 'flex', flexDirection: 'column', gap: 6 }}>
                <li>Utiliser la Plateforme de manière licite et éthique</li>
                <li>Ne pas publier de contenu faux, trompeur ou offensant</li>
                <li>Respecter les autres utilisateurs</li>
                <li>Ne pas tenter de contourner les systèmes de paiement de la Plateforme</li>
                <li>Signaler tout comportement suspect ou frauduleux</li>
              </ul>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>6. Paiements et commission</h2>
              <ul style={{ paddingLeft: 20, display: 'flex', flexDirection: 'column', gap: 6 }}>
                <li>Tous les paiements sont traités par Stripe (certifié PCI DSS)</li>
                <li>SOS-BESOIN prélève une commission de <strong style={{ color: 'var(--text)' }}>10%</strong> sur chaque transaction</li>
                <li>Le paiement est séquestré jusqu'à la validation de la mission par le client</li>
                <li>Les prestataires reçoivent 90% du montant convenu après validation</li>
              </ul>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>7. Vérification d'identité (KYC)</h2>
              <p>Les prestataires doivent compléter une vérification d'identité avant de pouvoir soumettre des offres. Cette vérification est effectuée via Stripe Identity et est obligatoire pour garantir la sécurité de la Plateforme.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>8. Propriété intellectuelle</h2>
              <p>Tous les contenus de la Plateforme (logo, design, code, textes) sont la propriété exclusive de Corbin Creative Tech Inc. et sont protégés par les lois sur la propriété intellectuelle. Toute reproduction sans autorisation est interdite.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>9. Limitation de responsabilité</h2>
              <p>SOS-BESOIN agit en tant qu'intermédiaire et n'est pas partie aux contrats entre clients et prestataires. La Plateforme ne peut être tenue responsable de la qualité des services fournis, des dommages directs ou indirects résultant de l'utilisation de la Plateforme, ou des interruptions de service.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>10. Suspension et résiliation</h2>
              <p>Corbin Creative Tech Inc. se réserve le droit de suspendre ou de résilier tout compte qui viole les présentes conditions, sans préavis ni remboursement.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>11. Droit applicable</h2>
              <p>Les présentes conditions sont régies par les lois de la province de Québec et les lois fédérales du Canada applicables. Tout litige sera soumis à la juridiction exclusive des tribunaux du Québec.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>12. Contact</h2>
              <p>
                <strong style={{ color: 'var(--text)' }}>Corbin Creative Tech Inc.</strong><br />
                1231 Rue De La Relève, Saint-Lazare, Québec, J7T 3G2<br />
                <a href="mailto:sosbesoinapp@outlook.com" style={{ color: 'var(--amber)' }}>sosbesoinapp@outlook.com</a><br />
                NEQ : 1182286402
              </p>
            </section>

            <div style={{ borderTop: '1px solid var(--line)', paddingTop: 24, display: 'flex', gap: 16 }}>
              <Link href="/privacy" style={{ color: 'var(--cyan)', fontSize: 13 }}>{t('link_privacy')}</Link>
              <Link href="/refund" style={{ color: 'var(--cyan)', fontSize: 13 }}>{t('link_refund')}</Link>
            </div>
          </div>
        </div>
      </main>
    </>
  )
}