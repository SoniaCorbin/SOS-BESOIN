'use client'
import Nav from '@/components/Nav'
import Link from 'next/link'

export default function TermsPage() {
  return (
    <>
      <Nav />
      <main style={{ paddingTop: 64, minHeight: '100vh', background: 'var(--bg)' }}>
        <div style={{ maxWidth: 800, margin: '0 auto', padding: '40px 24px' }}>
          <div style={{ marginBottom: 32 }}>
            <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--amber)', letterSpacing: '0.1em', textTransform: 'uppercase' }}>·LÉGAL·</span>
            <h1 style={{ fontSize: 32, fontWeight: 700, marginTop: 8, letterSpacing: '-0.02em' }}>Conditions d'utilisation</h1>
            <p style={{ fontSize: 13, color: 'var(--text-mute)', marginTop: 8 }}>Dernière mise à jour : 23 juin 2026</p>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 32, fontSize: 14, color: 'var(--text-dim)', lineHeight: 1.8 }}>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>1. Acceptation des conditions</h2>
              <p>En accédant à la plateforme SOS-BESOIN, exploitée par Corbin Creative Tech Inc. (NEQ : 1182286402), vous acceptez d'être lié par les présentes conditions d'utilisation. Si vous n'acceptez pas ces conditions, veuillez ne pas utiliser nos services.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>2. Description du service</h2>
              <p>SOS-BESOIN est une place de marché en ligne qui met en relation des clients ayant des besoins urgents avec des prestataires de services qualifiés. Corbin Creative Tech Inc. agit uniquement en tant qu'intermédiaire et n'est pas partie aux contrats conclus entre les clients et les prestataires.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>3. Admissibilité</h2>
              <p>Pour utiliser SOS-BESOIN, vous devez :</p>
              <ul style={{ marginTop: 8, paddingLeft: 20, display: 'flex', flexDirection: 'column', gap: 6 }}>
                <li>Avoir au moins 18 ans</li>
                <li>Résider au Canada</li>
                <li>Fournir des informations exactes lors de l'inscription</li>
                <li>Posséder un compte bancaire ou une carte de crédit valide</li>
              </ul>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>4. Comptes utilisateurs</h2>
              <p>Vous êtes responsable de maintenir la confidentialité de vos identifiants de connexion. Vous acceptez de nous notifier immédiatement de toute utilisation non autorisée de votre compte. Corbin Creative Tech Inc. se réserve le droit de suspendre ou de résilier tout compte en cas de violation des présentes conditions.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>5. Paiements et frais</h2>
              <p>Les paiements sont traités de manière sécurisée via Stripe. Le montant est séquestré jusqu'à la validation de la mission par le client ou après un délai de 3 jours sans action du client. Corbin Creative Tech Inc. perçoit une commission sur chaque transaction complétée. Les frais applicables sont affichés avant toute confirmation de paiement.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>6. Obligations des prestataires</h2>
              <p>Les prestataires s'engagent à :</p>
              <ul style={{ marginTop: 8, paddingLeft: 20, display: 'flex', flexDirection: 'column', gap: 6 }}>
                <li>Fournir des services conformes à leur description</li>
                <li>Maintenir les licences et certifications requises par la loi</li>
                <li>Traiter les clients avec respect et professionnalisme</li>
                <li>Compléter les missions acceptées dans les délais convenus</li>
                <li>Déclarer leurs revenus conformément aux lois fiscales applicables</li>
              </ul>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>7. Obligations des clients</h2>
              <p>Les clients s'engagent à :</p>
              <ul style={{ marginTop: 8, paddingLeft: 20, display: 'flex', flexDirection: 'column', gap: 6 }}>
                <li>Fournir des informations exactes sur leurs besoins</li>
                <li>Être disponibles pour accueillir le prestataire aux heures convenues</li>
                <li>Valider la mission dans les délais impartis</li>
                <li>Ne pas contacter les prestataires en dehors de la plateforme pour éviter les frais</li>
              </ul>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>8. Contenu interdit</h2>
              <p>Il est strictement interdit d'utiliser SOS-BESOIN pour :</p>
              <ul style={{ marginTop: 8, paddingLeft: 20, display: 'flex', flexDirection: 'column', gap: 6 }}>
                <li>Des activités illégales ou frauduleuses</li>
                <li>Le harcèlement ou l'intimidation d'autres utilisateurs</li>
                <li>La publication de fausses informations</li>
                <li>La sollicitation de paiements en dehors de la plateforme</li>
                <li>Toute activité portant atteinte aux droits d'autrui</li>
              </ul>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>9. Limitation de responsabilité</h2>
              <p>Corbin Creative Tech Inc. n'est pas responsable des dommages directs, indirects, accessoires ou consécutifs résultant de l'utilisation de la plateforme, de la qualité des services fournis par les prestataires, ou de tout litige entre utilisateurs. La responsabilité maximale de Corbin Creative Tech Inc. est limitée aux frais payés par l'utilisateur au cours des 30 derniers jours.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>10. Propriété intellectuelle</h2>
              <p>Tous les droits de propriété intellectuelle relatifs à la plateforme SOS-BESOIN, incluant le logo, le design et le code source, appartiennent à Corbin Creative Tech Inc. Toute reproduction non autorisée est interdite.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>11. Droit applicable</h2>
              <p>Les présentes conditions sont régies par les lois de la province de Québec et les lois fédérales du Canada applicables. Tout litige sera soumis à la juridiction exclusive des tribunaux du Québec.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>12. Modifications</h2>
              <p>Corbin Creative Tech Inc. se réserve le droit de modifier les présentes conditions à tout moment. Les utilisateurs seront informés des changements importants. L'utilisation continue de la plateforme après notification constitue une acceptation des nouvelles conditions.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>13. Contact</h2>
              <p>Pour toute question concernant ces conditions, contactez-nous à :</p>
              <p style={{ marginTop: 8 }}>
                <strong style={{ color: 'var(--text)' }}>Corbin Creative Tech Inc.</strong><br />
                1231 Rue De La Relève, Saint-Lazare, Québec, J7T 3G2<br />
                <a href="mailto:support@sosbesoin.ca" style={{ color: 'var(--amber)' }}>support@sosbesoin.ca</a><br />
                NEQ : 1182286402
              </p>
            </section>

            <div style={{ borderTop: '1px solid var(--line)', paddingTop: 24, display: 'flex', gap: 16 }}>
              <Link href="/privacy" style={{ color: 'var(--cyan)', fontSize: 13 }}>Politique de confidentialité →</Link>
              <Link href="/refund" style={{ color: 'var(--cyan)', fontSize: 13 }}>Politique de remboursement →</Link>
            </div>
          </div>
        </div>
      </main>
    </>
  )
}