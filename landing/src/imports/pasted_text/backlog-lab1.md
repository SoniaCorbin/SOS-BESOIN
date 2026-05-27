SOS BESOIN — Backlog complet (Lab 1)
Conventions


•	Priorité : 0 = indispensable (MVP) | 1 = important | 2 = nice-to-have
•	Estimation : S = 2–4h | M = 4–8h | L = 1–2 jours
•	Tag : FE = Front-end | BE = Back-end | FE/BE = Full-stack

________________________________________
Sprint 1 — Base fonctionnelle (Publication + Offres)
US-01 — Accès / Auth
•	User Story : En tant qu’Utilisateur, je veux me connecter afin d’accéder aux fonctionnalités privées.
•	Sprint : 1
•	Priorité : 0
•	Estimation : M
•	Tag : FE/BE
•	Labels : auth, ui
•	Critères d’acceptation :
1.	Un utilisateur non connecté est redirigé vers la page de connexion.
2.	Après connexion, l’utilisateur revient à la page demandée.

________________________________________
US-02 — Profil
•	User Story : En tant qu’Utilisateur, je veux compléter mon profil afin d’afficher mes informations de base.
•	Sprint : 1
•	Priorité : 1
•	Estimation : S
•	Tag : FE/BE
•	Labels : profile, ui, db, validation
•	Critères d’acceptation :
1.	Je peux enregistrer une bio, une ville et un téléphone.
2.	Les modifications sont persistées et visibles après rechargement.

________________________________________
US-03 — Créer une demande
•	User Story : En tant que Client, je veux publier une demande afin de recevoir des offres de prestataires.
•	Sprint : 1
•	Priorité : 0
•	Estimation : M
•	Tag : FE/BE
•	Labels : requests, ui, db, validation
•	Critères d’acceptation :
1.	Champs requis : title, description, neededAt.
2.	Statut initial de la demande = OPEN.
3.	La demande est associée au client (ex. clientId).

________________________________________
US-04 — Associer des catégories à une demande
•	User Story : En tant que Client, je veux choisir une ou plusieurs catégories afin de classifier mon besoin.
•	Sprint : 1
•	Priorité : 0
•	Estimation : M
•	Tag : FE/BE
•	Labels : categories, requests, ui, db, validation
•	Critères d’acceptation :
1.	Au moins 1 catégorie est obligatoire.
2.	Les catégories sont enregistrées via une relation N–N (ex. RequestCategory).
3.	Les catégories sont visibles lors de la consultation de la demande.

________________________________________
US-05 — Lister les demandes ouvertes
•	User Story : En tant que Prestataire, je veux consulter les demandes ouvertes afin de trouver des mandats.
•	Sprint : 1
•	Priorité : 0
•	Estimation : M
•	Tag : FE/BE
•	Labels : requests, ui, db
•	Critères d’acceptation :
1.	La liste affiche uniquement les demandes dont le statut est OPEN.
2.	La liste est triée par date (ex. neededAt croissant ou création récente).

________________________________________
US-06 — Filtrer par catégorie
•	User Story : En tant que Prestataire, je veux filtrer les demandes par catégorie afin de voir celles qui me concernent.
•	Sprint : 1
•	Priorité : 1
•	Estimation : S
•	Tag : FE/BE
•	Labels : categories, requests, ui
•	Critères d’acceptation :
1.	Le filtre par catégorie modifie la liste de demandes de façon cohérente.
2.	Il est possible de réinitialiser le filtre.

________________________________________
US-07 — Soumettre une offre
•	User Story : En tant que Prestataire, je veux soumettre une offre afin de proposer mon prix et ma disponibilité.
•	Sprint : 1
•	Priorité : 0
•	Estimation : M
•	Tag : FE/BE
•	Labels : offers, ui, db, validation
•	Critères d’acceptation :
1.	Les champs price et message sont obligatoires.
2.	Le statut initial de l’offre = PENDING.
3.	Un prestataire ne peut pas soumettre deux offres sur la même demande (unicité requestId + providerId).

________________________________________
Sprint 2 — Réservation + Paiement + règles métier
US-08 — Voir les offres reçues
•	User Story : En tant que Client, je veux consulter les offres reçues afin de choisir la meilleure proposition.
•	Sprint : 2
•	Priorité : 0
•	Estimation : M
•	Tag : FE/BE
•	Labels : offers, requests, ui, db
•	Critères d’acceptation :
1.	Les offres affichent : prix, message, prestataire, date.
2.	Le statut de chaque offre est visible (PENDING, ACCEPTED, REJECTED).

________________________________________
US-09 — Calcul des montants
•	User Story : En tant que Système, je veux calculer le sous total, la commission et le total afin d’afficher un récapitulatif juste et de stocker des montants fiables.
•	Sprint : 2
•	Priorité : 1
•	Estimation : S
•	Tag : BE
•	Labels : booking, payment, validation
•	Critères d’acceptation :
1.	Les montants sont en cents (Int) afin d’éviter les erreurs Float.
2.	total = subtotal + platformFee.
3.	La commission (ex. 10%) est appliquée de manière cohérente.

________________________________________
US-10 — Accepter une offre (transaction)
•	User Story : En tant que Client, je veux accepter une offre afin de réserver le prestataire de manière fiable.
•	Sprint : 2
•	Priorité : 0
•	Estimation : L
•	Tag : FE/BE
•	Labels : booking, offers, requests, transaction, db
•	Critères d’acceptation :
1.	L’acceptation est possible seulement si la demande est OPEN.
2.	Une demande ne peut produire qu’une seule réservation (Booking unique par requestId).
3.	Si la demande est déjà réservée, l’action échoue avec un message clair.

________________________________________
US-11 — Enregistrer le paiement
•	User Story : En tant que Client, je veux payer afin de confirmer la réservation.
•	Sprint : 2
•	Priorité : 0
•	Estimation : L
•	Tag : FE/BE
•	Labels : payment, booking, transaction
•	Critères d’acceptation :
1.	Si le paiement réussit, Payment.status = SUCCEEDED.
2.	La réservation passe à CONFIRMED.
3.	En cas d’échec, aucune réservation confirmée n’est créée (pas d’état incohérent).

________________________________________
US-12 — Statuts des offres après acceptation
•	User Story : En tant que Système, je veux mettre à jour automatiquement le statut des offres après l’acceptation afin d’éviter toute ambiguïté et d’indiquer clairement l’offre retenue.
•	Sprint : 2
•	Priorité : 1
•	Estimation : S
•	Tag : BE (+ FE affichage)
•	Labels : offers, transaction, db
•	Critères d’acceptation :
1.	L’offre acceptée devient ACCEPTED.
2.	Les autres offres PENDING deviennent REJECTED.
3.	Les statuts affichés sont cohérents côté client et prestataires.

________________________________________
US-13 — Annuler une demande
•	User Story : En tant que Client, je veux annuler une demande afin d’arrêter le processus si mon besoin n’est plus актуel.
•	Sprint : 2
•	Priorité : 1
•	Estimation : M
•	Tag : FE/BE
•	Labels : requests, validation, ui, db
•	Critères d’acceptation :
1.	Le statut de la demande devient CANCELLED.
2.	Les prestataires ne peuvent plus soumettre d’offre sur une demande annulée.

________________________________________
Sprint 3 — Administration + qualité
US-14 — Gestion des catégories (admin)
•	User Story : En tant qu’Admin, je veux gérer les catégories afin de maintenir une taxonomie cohérente.
•	Sprint : 3
•	Priorité : 2
•	Estimation : M
•	Tag : FE/BE
•	Labels : admin, categories, ui, db
•	Critères d’acceptation :
1.	CRUD catégorie (création, modification, suppression, liste).
2.	Le champ slug est unique.
3.	Les catégories sont disponibles lors de la création de demande.

________________________________________
US-15 — Modération (admin)
•	User Story : En tant qu’Admin, je veux masquer une demande/offre afin de retirer du contenu abusif.
•	Sprint : 3
•	Priorité : 2
•	Estimation : M
•	Tag : FE/BE
•	Labels : admin, requests, offers, validation
•	Critères d’acceptation :
1.	Une demande/offre masquée n’apparaît plus aux utilisateurs.
2.	La demande masquée est identifiée via un statut HIDDEN (ou équivalent) côté demande.
3.	L’action admin est traçable (ex. AdminAction).
