# SOS-BESOIN 🚨

> La marketplace d'urgence qui connecte clients et prestataires vérifiés en moins de 30 minutes.

**COMING SOON on GOOGLE PLAY**
Contact: soniacorbin4@gmail.com

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Supabase](https://img.shields.io/badge/Supabase-Backend-green?logo=supabase)
![Stripe](https://img.shields.io/badge/Stripe-Paiement-purple?logo=stripe)
![Firebase](https://img.shields.io/badge/Firebase-Notifications-orange?logo=firebase)

## 📱 À propos

**SOS-BESOIN** est une application mobile Flutter qui met en relation des clients ayant des besoins urgents avec des prestataires professionnels vérifiés.

- 🔴 Publiez une demande en moins de 90 secondes
- 💼 Recevez des offres de pros vérifiés
- 💳 Paiement séquestré — vous ne payez qu'après validation
- 💬 Chat en temps réel avec le prestataire
- 🧾 Factures générées automatiquement

## 🏗️ Stack technique

| Couche | Technologie |
|--------|------------|
| Mobile | Flutter 3.x (Android) |
| Backend | Supabase (PostgreSQL + Auth + Realtime) |
| Paiement | Stripe (Payment Intent + séquestre) |
| Notifications | Firebase Cloud Messaging |
| State management | Riverpod |
| Navigation | go_router |

## 🚀 Lancer le projet

### Prérequis
- Flutter 3.x
- Android Studio
- Compte Supabase
- Compte Stripe (mode test)
- Compte Firebase

### Installation

\`\`\`bash
git clone https://github.com/SoniaCorbin/SOS-BESOIN.git
cd SOS-BESOIN
flutter pub get
\`\`\`

### Configuration

Crée un fichier run.sh à la racine :

\`\`\`bash
flutter run --dart-define=SUPABASE_URL=https://TONPROJET.supabase.co --dart-define=SUPABASE_ANON_KEY=TON_ANON_KEY --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_...
\`\`\`

## 📄 Licence

Projet privé — © 2026 SOS-BESOIN. Tous droits réservés.
