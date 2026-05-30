import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class LegalScreen extends StatelessWidget {
  final String title;
  final String content;

  const LegalScreen({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textDim, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontFamily: 'SpaceGrotesk',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textDim,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Contenu légal ─────────────────────────────────────────
class LegalContent {
  static const String termsOfService = '''
CONDITIONS GÉNÉRALES D'UTILISATION
Dernière mise à jour : mai 2026

1. ACCEPTATION DES CONDITIONS
En utilisant l'application SOS-BESOIN, vous acceptez les présentes conditions générales d'utilisation. Si vous n'acceptez pas ces conditions, veuillez ne pas utiliser l'application.

2. DESCRIPTION DU SERVICE
SOS-BESOIN est une marketplace qui met en relation des clients ayant des besoins urgents avec des prestataires vérifiés. Nous agissons en tant qu'intermédiaire et ne sommes pas responsables de la qualité des services fournis. La vérification KYC confirme l'identité du prestataire uniquement — SOS-BESOIN ne garantit pas les qualifications, compétences ou certifications professionnelles des prestataires.

3. INSCRIPTION ET COMPTE
- Vous devez avoir au moins 18 ans pour utiliser SOS-BESOIN.
- Vous êtes responsable de la confidentialité de votre mot de passe.
- Vous devez fournir des informations exactes lors de l'inscription.
- Un seul compte par personne est autorisé.

4. POUR LES CLIENTS
- Vous pouvez publier des demandes de service urgentes.
- Le paiement est séquestré jusqu'à validation de la mission.
- Vous ne payez que si vous acceptez une offre.
- Vous avez 48h après la mission pour valider ou contester.

5. POUR LES PRESTATAIRES
- Vous devez passer une vérification KYC avant de soumettre des offres.
- Une commission de 10% est retenue sur chaque mission.
- Le paiement est transféré sous 24h après validation.
- Vous fixez vos propres tarifs.

6. PAIEMENT ET REMBOURSEMENT
- Les paiements sont traités par Stripe.
- En cas de litige, consultez notre politique de remboursement.
- La commission de 10% n'est pas remboursable.

7. COMPORTEMENT INTERDIT
- Fraude ou fausses informations
- Harcèlement ou comportement abusif
- Contournement du système de paiement
- Utilisation à des fins illégales

8. RÉSILIATION
SOS-BESOIN se réserve le droit de suspendre ou supprimer tout compte qui viole ces conditions.

9. LIMITATION DE RESPONSABILITÉ
SOS-BESOIN n'est pas responsable des dommages indirects résultant de l'utilisation du service.

10. CONTACT
Pour toute question : support@sosbesoin.app
''';

  static const String privacyPolicy = '''
POLITIQUE DE CONFIDENTIALITÉ
Dernière mise à jour : mai 2026

1. DONNÉES COLLECTÉES
Nous collectons les données suivantes :
- Nom complet et adresse courriel
- Numéro de téléphone (optionnel)
- Informations de paiement (traitées par Stripe)
- Historique des transactions
- Messages échangés via le chat
- Token FCM pour les notifications push

2. UTILISATION DES DONNÉES
Vos données sont utilisées pour :
- Créer et gérer votre compte
- Traiter les paiements
- Envoyer des notifications push
- Améliorer nos services
- Prévenir la fraude

3. PARTAGE DES DONNÉES
Nous ne vendons jamais vos données personnelles. Vos données peuvent être partagées avec :
- Stripe (traitement des paiements)
- Firebase (notifications push)
- Supabase (stockage sécurisé)

4. SÉCURITÉ
- Toutes les données sont chiffrées en transit (HTTPS)
- Les mots de passe sont hashés
- Row Level Security activé sur toutes les tables
- Clés API jamais exposées dans le code

5. VOS DROITS
Vous avez le droit de :
- Accéder à vos données personnelles
- Corriger vos informations
- Supprimer votre compte et vos données
- Retirer votre consentement

6. CONSERVATION DES DONNÉES
Vos données sont conservées tant que votre compte est actif. Après suppression, elles sont effacées sous 30 jours.

7. COOKIES
L'application mobile n'utilise pas de cookies.

8. CONTACT
Pour exercer vos droits : privacy@sosbesoin.app
''';

  static const String refundPolicy = '''
POLITIQUE DE REMBOURSEMENT
Dernière mise à jour : mai 2026

1. PAIEMENT SÉQUESTRÉ
Tous les paiements sur SOS-BESOIN sont séquestrés. Cela signifie que votre argent est retenu de façon sécurisée jusqu'à ce que vous validiez la mission.

2. CONDITIONS DE REMBOURSEMENT

Remboursement complet (100%) :
- Si vous annulez avant d'accepter une offre
- Si le prestataire ne se présente pas
- Si la mission n'a pas été réalisée

Remboursement partiel :
- Si la mission est partiellement réalisée
  (à déterminer au cas par cas)

Aucun remboursement :
- Après validation de la mission
- La commission de 10% n'est jamais remboursée

3. PROCESSUS DE REMBOURSEMENT
1. Contactez le support dans les 48h
2. Décrivez le problème en détail
3. Notre équipe examine la demande sous 24h
4. Le remboursement est traité sous 5-10 jours ouvrables

4. LITIGES
En cas de désaccord entre client et prestataire, SOS-BESOIN peut intervenir comme médiateur. Notre décision est finale.

5. CONTACT
Pour un remboursement : support@sosbesoin.app
''';
}

