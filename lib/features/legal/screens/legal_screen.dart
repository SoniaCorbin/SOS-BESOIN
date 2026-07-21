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
CONDITIONS D'UTILISATION
Dernière mise à jour : 23 juin 2026

1. ACCEPTATION DES CONDITIONS
En accédant à la plateforme SOS-BESOIN, exploitée par Corbin Creative Tech Inc. (NEQ : 1182286402), vous acceptez d'être lié par les présentes conditions d'utilisation. Si vous n'acceptez pas ces conditions, veuillez ne pas utiliser nos services.

2. DESCRIPTION DU SERVICE
SOS-BESOIN est une place de marché en ligne qui met en relation des clients ayant des besoins urgents avec des prestataires de services qualifiés. Corbin Creative Tech Inc. agit uniquement en tant qu'intermédiaire et n'est pas partie aux contrats conclus entre les clients et les prestataires.

3. ADMISSIBILITÉ
Pour utiliser SOS-BESOIN, vous devez :
- Avoir au moins 18 ans
- Résider au Canada
- Fournir des informations exactes lors de l'inscription
- Posséder un compte bancaire ou une carte de crédit valide

4. COMPTES UTILISATEURS
Vous êtes responsable de maintenir la confidentialité de vos identifiants de connexion. Vous acceptez de nous notifier immédiatement de toute utilisation non autorisée de votre compte. Corbin Creative Tech Inc. se réserve le droit de suspendre ou de résilier tout compte en cas de violation des présentes conditions.

5. PAIEMENTS ET FRAIS
Les paiements sont traités de manière sécurisée via Stripe. Le montant est séquestré jusqu'à la validation de la mission par le client ou après un délai de 3 jours sans action du client. Corbin Creative Tech Inc. perçoit une commission sur chaque transaction complétée. Les frais applicables sont affichés avant toute confirmation de paiement.

6. OBLIGATIONS DES PRESTATAIRES
Les prestataires s'engagent à :
- Fournir des services conformes à leur description
- Maintenir les licences et certifications requises par la loi
- Traiter les clients avec respect et professionnalisme
- Compléter les missions acceptées dans les délais convenus
- Déclarer leurs revenus conformément aux lois fiscales applicables

7. OBLIGATIONS DES CLIENTS
Les clients s'engagent à :
- Fournir des informations exactes sur leurs besoins
- Être disponibles pour accueillir le prestataire aux heures convenues
- Valider la mission dans les délais impartis
- Ne pas contacter les prestataires en dehors de la plateforme pour éviter les frais

8. CONTENU INTERDIT
Il est strictement interdit d'utiliser SOS-BESOIN pour :
- Des activités illégales ou frauduleuses
- Le harcèlement ou l'intimidation d'autres utilisateurs
- La publication de fausses informations
- La sollicitation de paiements en dehors de la plateforme
- Toute activité portant atteinte aux droits d'autrui

9. LIMITATION DE RESPONSABILITÉ
Corbin Creative Tech Inc. n'est pas responsable des dommages directs, indirects, accessoires ou consécutifs résultant de l'utilisation de la plateforme, de la qualité des services fournis par les prestataires, ou de tout litige entre utilisateurs. La responsabilité maximale de Corbin Creative Tech Inc. est limitée aux frais payés par l'utilisateur au cours des 30 derniers jours.

10. PROPRIÉTÉ INTELLECTUELLE
Tous les droits de propriété intellectuelle relatifs à la plateforme SOS-BESOIN, incluant le logo, le design et le code source, appartiennent à Corbin Creative Tech Inc. Toute reproduction non autorisée est interdite.

11. DROIT APPLICABLE
Les présentes conditions sont régies par les lois de la province de Québec et les lois fédérales du Canada applicables. Tout litige sera soumis à la juridiction exclusive des tribunaux du Québec.

12. MODIFICATIONS
Corbin Creative Tech Inc. se réserve le droit de modifier les présentes conditions à tout moment. Les utilisateurs seront informés des changements importants. L'utilisation continue de la plateforme après notification constitue une acceptation des nouvelles conditions.

13. CONTACT
Corbin Creative Tech Inc.
1231 Rue De La Relève, Saint-Lazare, Québec, J7T 3G2
sosbesoinapp@outlook.com
NEQ : 1182286402
''';

  static const String privacyPolicy = '''
POLITIQUE DE CONFIDENTIALITÉ
Dernière mise à jour : 23 juin 2026

1. RESPONSABLE DU TRAITEMENT
Corbin Creative Tech Inc. (NEQ : 1182286402), ayant son siège au 1231 Rue De La Relève, Saint-Lazare, Québec, J7T 3G2, est responsable du traitement de vos renseignements personnels conformément à la Loi 25 (Loi modernisant des dispositions législatives en matière de protection des renseignements personnels) et à la Loi sur la protection des renseignements personnels et les documents électroniques (LPRPDE).

Pour toute question relative à la protection de vos renseignements personnels, contactez notre responsable : sosbesoinapp@outlook.com

2. RENSEIGNEMENTS COLLECTÉS
Nous collectons les renseignements suivants :
- Informations d'identification : nom complet, adresse courriel, numéro de téléphone
- Informations de localisation : ville, quartier, coordonnées GPS (avec votre consentement explicite)
- Informations de paiement : traitées directement par Stripe — nous ne conservons pas vos données bancaires
- Données d'utilisation : demandes publiées, offres soumises, messages échangés, évaluations
- Données techniques : adresse IP, type d'appareil (pour la sécurité et l'amélioration du service)

3. FINALITÉS DU TRAITEMENT
Vos renseignements sont utilisés pour :
- Créer et gérer votre compte utilisateur
- Mettre en relation clients et prestataires
- Traiter les paiements et émissions de factures
- Assurer la sécurité et prévenir la fraude
- Améliorer nos services et l'expérience utilisateur
- Respecter nos obligations légales
- Vous envoyer des communications relatives à votre compte (avec votre consentement)

4. GÉOLOCALISATION
L'utilisation de votre position GPS est entièrement optionnelle et requiert votre consentement explicite. Elle sert uniquement à :
- Afficher les demandes proches de votre position
- Permettre aux prestataires de définir leur rayon de travail

Vous pouvez retirer votre consentement à tout moment dans les paramètres de votre appareil.

5. PARTAGE DES RENSEIGNEMENTS
Nous ne vendons jamais vos renseignements personnels. Nous les partageons uniquement avec :
- Stripe : traitement sécurisé des paiements
- Firebase : notifications push
- Supabase : hébergement sécurisé des données (serveurs en Amérique du Nord)
- Autorités légales : uniquement si requis par la loi

6. CONSERVATION DES DONNÉES
Vos renseignements sont conservés aussi longtemps que votre compte est actif. Après la fermeture de votre compte :
- Les données de transaction sont conservées 7 ans (obligations fiscales)
- Les autres données personnelles sont supprimées dans les 90 jours
- Les données anonymisées peuvent être conservées à des fins statistiques

7. VOS DROITS (LOI 25)
Conformément à la Loi 25, vous avez le droit de :
- Accès : obtenir une copie de vos renseignements personnels
- Rectification : corriger des renseignements inexacts
- Suppression : demander l'effacement de vos données
- Portabilité : recevoir vos données dans un format structuré
- Retrait du consentement : à tout moment, sans préjudice
- Plainte : auprès de la Commission d'accès à l'information du Québec

Pour exercer vos droits : sosbesoinapp@outlook.com

8. SÉCURITÉ
Nous mettons en œuvre des mesures de sécurité appropriées :
- Chiffrement SSL/TLS de toutes les communications
- Authentification sécurisée via Supabase Auth
- Contrôle d'accès strict aux données (Row Level Security)
- Paiements traités par Stripe (certifié PCI DSS)

En cas d'incident de confidentialité, nous vous en informerons dans les 72 heures si vos droits sont susceptibles d'être affectés, conformément à la Loi 25.

9. TÉMOINS (COOKIES)
L'application mobile n'utilise pas de cookies publicitaires ou de suivi tiers.

10. MODIFICATIONS
Toute modification importante de cette politique sera communiquée par notification dans l'application au moins 30 jours avant son entrée en vigueur, conformément à la Loi 25.

11. CONTACT
Responsable de la protection des renseignements personnels
Corbin Creative Tech Inc.
1231 Rue De La Relève, Saint-Lazare, Québec, J7T 3G2
sosbesoinapp@outlook.com
NEQ : 1182286402
''';

  static const String refundPolicy = '''
POLITIQUE DE REMBOURSEMENT
Dernière mise à jour : 23 juin 2026

1. PRINCIPE DU PAIEMENT SÉQUESTRÉ
SOS-BESOIN utilise un système de paiement séquestré (escrow) pour protéger les deux parties. Lorsqu'un client accepte une offre, le montant est retenu de manière sécurisée via Stripe et n'est libéré au prestataire qu'après la validation de la mission.

2. CAS DE REMBOURSEMENT
Un remboursement complet est accordé dans les situations suivantes :
- Le prestataire n'a pas effectué la mission convenue
- Le prestataire annule après acceptation de l'offre
- La mission n'a pas été complétée dans les délais convenus
- Le service fourni ne correspond pas à la description de l'offre acceptée
- Erreur technique ayant entraîné un double paiement

3. CAS DE NON-REMBOURSEMENT
Aucun remboursement ne sera accordé dans les situations suivantes :
- La mission a été validée par le client (validation manuelle ou automatique après 3 jours)
- Le client a changé d'avis après la complétion de la mission
- Le client n'était pas disponible à l'heure convenue sans préavis
- Insatisfaction subjective non liée à un manquement du prestataire

4. VALIDATION AUTOMATIQUE
Si le client ne valide pas la mission dans les 3 jours suivant la complétion, le paiement est automatiquement libéré au prestataire. Passé ce délai, aucun remboursement ne peut être accordé sauf en cas de fraude avérée.

5. PROCÉDURE DE REMBOURSEMENT
Pour demander un remboursement :
1. Contactez-nous à sosbesoinapp@outlook.com dans les 7 jours suivant l'incident
2. Indiquez votre numéro de demande et une description détaillée du problème
3. Notre équipe examinera votre demande dans un délai de 5 jours ouvrables
4. Si approuvé, le remboursement sera effectué sur votre mode de paiement original dans un délai de 5 à 10 jours ouvrables

6. LITIGES ENTRE UTILISATEURS
En cas de litige entre un client et un prestataire, Corbin Creative Tech Inc. peut intervenir en tant que médiateur. Nous nous réservons le droit de prendre une décision finale concernant le remboursement après examen des preuves fournies par les deux parties.

7. FRAIS DE PLATEFORME
Les frais de service de Corbin Creative Tech Inc. ne sont pas remboursables une fois la mise en relation effectuée, sauf en cas d'erreur technique de notre part.

8. CONTACT
Corbin Creative Tech Inc.
sosbesoinapp@outlook.com
Délai de réponse : 2 jours ouvrables
''';
}