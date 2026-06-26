'use client'
import Nav from '@/components/Nav'
import Link from 'next/link'

export default function PrivacyPage() {
  return (
    <>
      <Nav />
      <main style={{ paddingTop: 64, minHeight: '100vh', background: 'var(--bg)' }}>
        <div style={{ maxWidth: 800, margin: '0 auto', padding: '40px 24px' }}>
          <div style={{ marginBottom: 32 }}>
            <span style={{ fontFamily: 'var(--font-mono)', fontSize: 11, color: 'var(--amber)', letterSpacing: '0.1em', textTransform: 'uppercase' }}>·LÉGAL·</span>
            <h1 style={{ fontSize: 32, fontWeight: 700, marginTop: 8, letterSpacing: '-0.02em' }}>Politique de confidentialité</h1>
            <p style={{ fontSize: 13, color: 'var(--text-mute)', marginTop: 8 }}>Dernière mise à jour : 23 juin 2026</p>
          </div>

          <div style={{ display: 'flex', flexDirection: 'column', gap: 32, fontSize: 14, color: 'var(--text-dim)', lineHeight: 1.8 }}>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>1. Responsable du traitement</h2>
              <p>Corbin Creative Tech Inc. (NEQ : 1182286402), ayant son siège au 1231 Rue De La Relève, Saint-Lazare, Québec, J7T 3G2, est responsable du traitement de vos renseignements personnels conformément à la <strong style={{ color: 'var(--text)' }}>Loi 25</strong> (Loi modernisant des dispositions législatives en matière de protection des renseignements personnels) et à la Loi sur la protection des renseignements personnels et les documents électroniques (LPRPDE).</p>
              <p style={{ marginTop: 8 }}>Pour toute question relative à la protection de vos renseignements personnels, contactez notre responsable de la protection des renseignements personnels : <a href="mailto:support@sosbesoin.ca" style={{ color: 'var(--amber)' }}>support@sosbesoin.ca</a></p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>2. Renseignements collectés</h2>
              <p>Nous collectons les renseignements suivants :</p>
              <ul style={{ marginTop: 8, paddingLeft: 20, display: 'flex', flexDirection: 'column', gap: 6 }}>
                <li><strong style={{ color: 'var(--text)' }}>Informations d'identification :</strong> nom complet, adresse courriel, numéro de téléphone</li>
                <li><strong style={{ color: 'var(--text)' }}>Informations de localisation :</strong> ville, quartier, coordonnées GPS (avec votre consentement explicite)</li>
                <li><strong style={{ color: 'var(--text)' }}>Informations de paiement :</strong> traitées directement par Stripe — nous ne conservons pas vos données bancaires</li>
                <li><strong style={{ color: 'var(--text)' }}>Données d'utilisation :</strong> demandes publiées, offres soumises, messages échangés, évaluations</li>
                <li><strong style={{ color: 'var(--text)' }}>Données techniques :</strong> adresse IP, type d'appareil, navigateur (pour la sécurité et l'amélioration du service)</li>
              </ul>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>3. Finalités du traitement</h2>
              <p>Vos renseignements sont utilisés pour :</p>
              <ul style={{ marginTop: 8, paddingLeft: 20, display: 'flex', flexDirection: 'column', gap: 6 }}>
                <li>Créer et gérer votre compte utilisateur</li>
                <li>Mettre en relation clients et prestataires</li>
                <li>Traiter les paiements et émissions de factures</li>
                <li>Assurer la sécurité et prévenir la fraude</li>
                <li>Améliorer nos services et l'expérience utilisateur</li>
                <li>Respecter nos obligations légales</li>
                <li>Vous envoyer des communications relatives à votre compte (avec votre consentement)</li>
              </ul>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>4. Géolocalisation</h2>
              <p>L'utilisation de votre position GPS est <strong style={{ color: 'var(--text)' }}>entièrement optionnelle</strong> et requiert votre consentement explicite. Elle sert uniquement à :</p>
              <ul style={{ marginTop: 8, paddingLeft: 20, display: 'flex', flexDirection: 'column', gap: 6 }}>
                <li>Afficher les demandes proches de votre position</li>
                <li>Permettre aux prestataires de définir leur rayon de travail</li>
              </ul>
              <p style={{ marginTop: 8 }}>Vous pouvez retirer votre consentement à tout moment dans les paramètres de votre appareil ou de votre navigateur.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>5. Partage des renseignements</h2>
              <p>Nous ne vendons jamais vos renseignements personnels. Nous les partageons uniquement avec :</p>
              <ul style={{ marginTop: 8, paddingLeft: 20, display: 'flex', flexDirection: 'column', gap: 6 }}>
                <li><strong style={{ color: 'var(--text)' }}>Stripe :</strong> traitement sécurisé des paiements</li>
                <li><strong style={{ color: 'var(--text)' }}>Supabase :</strong> hébergement sécurisé des données (serveurs en Amérique du Nord)</li>
                <li><strong style={{ color: 'var(--text)' }}>Autorités légales :</strong> uniquement si requis par la loi</li>
              </ul>
              <p style={{ marginTop: 8 }}>Les informations visibles sur votre profil public (nom, note, nombre de missions) sont accessibles aux autres utilisateurs de la plateforme.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>6. Conservation des données</h2>
              <p>Vos renseignements sont conservés aussi longtemps que votre compte est actif. Après la fermeture de votre compte :</p>
              <ul style={{ marginTop: 8, paddingLeft: 20, display: 'flex', flexDirection: 'column', gap: 6 }}>
                <li>Les données de transaction sont conservées 7 ans (obligations fiscales)</li>
                <li>Les autres données personnelles sont supprimées dans les 90 jours</li>
                <li>Les données anonymisées peuvent être conservées à des fins statistiques</li>
              </ul>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>7. Vos droits (Loi 25)</h2>
              <p>Conformément à la Loi 25, vous avez le droit de :</p>
              <ul style={{ marginTop: 8, paddingLeft: 20, display: 'flex', flexDirection: 'column', gap: 6 }}>
                <li><strong style={{ color: 'var(--text)' }}>Accès :</strong> obtenir une copie de vos renseignements personnels</li>
                <li><strong style={{ color: 'var(--text)' }}>Rectification :</strong> corriger des renseignements inexacts</li>
                <li><strong style={{ color: 'var(--text)' }}>Suppression :</strong> demander l'effacement de vos données</li>
                <li><strong style={{ color: 'var(--text)' }}>Portabilité :</strong> recevoir vos données dans un format structuré</li>
                <li><strong style={{ color: 'var(--text)' }}>Retrait du consentement :</strong> à tout moment, sans préjudice</li>
                <li><strong style={{ color: 'var(--text)' }}>Plainte :</strong> auprès de la Commission d'accès à l'information du Québec</li>
              </ul>
              <p style={{ marginTop: 8 }}>Pour exercer vos droits : <a href="mailto:support@sosbesoin.ca" style={{ color: 'var(--amber)' }}>support@sosbesoin.ca</a></p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>8. Sécurité</h2>
              <p>Nous mettons en œuvre des mesures de sécurité appropriées pour protéger vos renseignements, notamment :</p>
              <ul style={{ marginTop: 8, paddingLeft: 20, display: 'flex', flexDirection: 'column', gap: 6 }}>
                <li>Chiffrement SSL/TLS de toutes les communications</li>
                <li>Authentification sécurisée via Supabase Auth</li>
                <li>Contrôle d'accès strict aux données (Row Level Security)</li>
                <li>Paiements traités par Stripe (certifié PCI DSS)</li>
              </ul>
              <p style={{ marginTop: 8 }}>En cas d'incident de confidentialité, nous vous en informerons dans les 72 heures si vos droits et libertés sont susceptibles d'être affectés, conformément à la Loi 25.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>9. Témoins (Cookies)</h2>
              <p>Notre plateforme utilise des témoins essentiels au fonctionnement du service (authentification, préférences). Nous n'utilisons pas de témoins publicitaires ou de suivi tiers.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>10. Modifications</h2>
              <p>Toute modification importante de cette politique sera communiquée par courriel ou par notification dans l'application au moins 30 jours avant son entrée en vigueur, conformément à la Loi 25.</p>
            </section>

            <section>
              <h2 style={{ fontSize: 18, fontWeight: 600, color: 'var(--text)', marginBottom: 12 }}>11. Contact</h2>
              <p>
                <strong style={{ color: 'var(--text)' }}>Responsable de la protection des renseignements personnels</strong><br />
                Corbin Creative Tech Inc.<br />
                1231 Rue De La Relève, Saint-Lazare, Québec, J7T 3G2<br />
                <a href="mailto:support@sosbesoin.ca" style={{ color: 'var(--amber)' }}>support@sosbesoin.ca</a><br />
                NEQ : 1182286402
              </p>
            </section>

            <div style={{ borderTop: '1px solid var(--line)', paddingTop: 24, display: 'flex', gap: 16 }}>
              <Link href="/terms" style={{ color: 'var(--cyan)', fontSize: 13 }}>Conditions d'utilisation →</Link>
              <Link href="/refund" style={{ color: 'var(--cyan)', fontSize: 13 }}>Politique de remboursement →</Link>
            </div>
          </div>
        </div>
      </main>
    </>
  )
}