# CAHIER DES CHARGES - APPLICATION PANDORA BOX

## 📋 INFORMATIONS GÉNÉRALES

**Nom du projet :** Pandora Box  
**Version :** 1.0  
**Date de création :** Décembre 2024  
**Type d'application :** Jeu multijoueur en ligne avec mode solo  
**Plateforme :** Web (Flutter Web)  
**Déploiement :** Firebase Hosting  

---

## 🎯 OBJECTIFS DU PROJET

### Objectif Principal
Développer une application de jeu multijoueur en temps réel permettant aux joueurs de participer à des sessions de jeu collaboratives et compétitives à travers différentes salles de jeu thématiques.

### Objectifs Secondaires
- Proposer un mode solo pour l'entraînement individuel
- Implémenter un système de statistiques et de classements
- Créer une interface utilisateur moderne et intuitive
- Assurer une synchronisation temps réel entre les joueurs

---

## 🎮 FONCTIONNALITÉS PRINCIPALES

### 1. MODE SOLO
- **Navigation libre** : Le joueur peut naviguer entre les différentes salles à son rythme
- **Chronomètre global** : Temps de jeu total depuis le début de la session
- **Sauvegarde automatique** : Progression sauvegardée localement et sur Firebase
- **Statistiques personnelles** : Historique des performances et scores

### 2. MODE MULTIJOUEUR
- **Création de salles** : Les joueurs peuvent créer des salles de jeu privées
- **Rejoindre une salle** : Système de codes de salle pour rejoindre des parties
- **Synchronisation temps réel** : Tous les joueurs avancent ensemble dans les mêmes salles
- **Chat intégré** : Communication entre joueurs pendant l'attente
- **Classement en temps réel** : Affichage des scores pendant la partie

### 3. SYSTÈME DE SALLES DE JEU

#### Salle 1 - Puzzle
- **Type :** Jeu de puzzle/logique
- **Objectif :** Résoudre des énigmes pour progresser
- **Scoring :** Points basés sur la rapidité et l'exactitude

#### Salle 2 - Stress
- **Type :** Jeu de gestion du stress
- **Objectif :** Maintenir un équilibre sous pression
- **Scoring :** Points basés sur la stabilité et la performance

#### Salle 3 - Mots
- **Type :** Jeu de mots/vocabulaire
- **Objectif :** Trouver 100% des mots pour compléter la salle
- **Scoring :** Points basés sur le nombre de mots trouvés

#### Salle 4 - Tram
- **Type :** Jeu de simulation/stratégie
- **Objectif :** Gérer efficacement un système de transport
- **Scoring :** Points basés sur l'efficacité et la satisfaction

#### Salle 5 - Notifications
- **Type :** Jeu de gestion des notifications
- **Objectif :** Traiter efficacement les notifications
- **Scoring :** Points basés sur la rapidité de traitement

---

## 🏗️ ARCHITECTURE TECHNIQUE

### Technologies Utilisées
- **Frontend :** Flutter Web
- **Backend :** Firebase (Realtime Database, Hosting)
- **Langage :** Dart
- **Gestion d'état :** Provider Pattern
- **Animations :** Flutter Animation Framework

### Structure du Projet
```
lib/
├── main.dart                    # Point d'entrée de l'application
├── firebase_options.dart        # Configuration Firebase
├── pages/                       # Pages de l'application
│   ├── eco_stress_home_page.dart
│   ├── home_page.dart
│   ├── waiting_room_page.dart
│   ├── multiplayer_game_page.dart
│   ├── multiplayer_success_page.dart
│   ├── page1_puzzle.dart
│   ├── stress_page.dart
│   ├── page3_words.dart
│   ├── page4_tram.dart
│   ├── page5_notifications.dart
│   └── ...
├── services/                    # Services métier
│   ├── firebase_multiplayer_service.dart
│   ├── firebase_chat_service.dart
│   ├── firebase_leaderboard_service.dart
│   ├── firebase_history_service.dart
│   ├── game_stats_service.dart
│   └── player_name_service.dart
└── widgets/                     # Composants réutilisables
    ├── score_display_widget.dart
    ├── chat_widget.dart
    └── leaderboard_widget.dart
```

---

## 🔧 SERVICES ET FONCTIONNALITÉS TECHNIQUES

### 1. Firebase Multiplayer Service
- **Gestion des salles** : Création, suppression, mise à jour des salles
- **Gestion des joueurs** : Ajout, suppression, synchronisation des joueurs
- **États de jeu** : Gestion des états (attente, en cours, terminé)
- **Synchronisation temps réel** : Mise à jour automatique des données

### 2. Firebase Chat Service
- **Messages temps réel** : Chat instantané entre joueurs
- **Historique** : Sauvegarde des conversations
- **Modération** : Filtrage des messages inappropriés

### 3. Firebase Leaderboard Service
- **Classements globaux** : Scores de tous les joueurs
- **Classements par salle** : Meilleurs scores par type de jeu
- **Mise à jour temps réel** : Synchronisation automatique des classements

### 4. Firebase History Service
- **Historique global** : Toutes les sessions jouées
- **Historique personnel** : Sessions individuelles
- **Statistiques détaillées** : Temps, scores, progression

### 5. Game Stats Service
- **Statistiques locales** : Sauvegarde des données de jeu
- **Synchronisation Firebase** : Upload des statistiques
- **Calculs de performance** : Moyennes, meilleurs scores, temps

### 6. Player Name Service
- **Gestion des pseudonymes** : Stockage et récupération des noms
- **Persistance** : Sauvegarde locale des préférences
- **Validation** : Vérification des noms d'utilisateur

---

## 🎨 INTERFACE UTILISATEUR

### Design System
- **Couleurs principales :** 
  - Fond : Noir (#0A0A0A)
  - Accent : Violet profond (#6A1B9A)
  - Succès : Vert (#4CAF50)
  - Erreur : Rouge (#F44336)
  - Avertissement : Orange (#FF9800)

### Composants UI
- **Cartes de jeu** : Design moderne avec bordures arrondies
- **Boutons d'action** : Style Material Design avec animations
- **Indicateurs de progression** : Barres de progression animées
- **Messages de feedback** : Notifications toast et modales

### Responsive Design
- **Desktop** : Interface optimisée pour les écrans larges
- **Tablet** : Adaptation pour les tablettes
- **Mobile** : Interface tactile optimisée

---

## 🔄 FLUX DE JEU MULTIJOUEUR

### 1. Création de Salle
1. Le joueur clique sur "Multijoueur"
2. Sélectionne "Créer une salle"
3. Configure les paramètres (nombre de joueurs, etc.)
4. Obtient un code de salle à partager

### 2. Rejoindre une Salle
1. Le joueur clique sur "Multijoueur"
2. Sélectionne "Rejoindre une salle"
3. Saisit le code de salle
4. Rejoint la salle d'attente

### 3. Salle d'Attente
- **Chat intégré** : Communication entre joueurs
- **Liste des joueurs** : Affichage des participants
- **Classement** : Scores des joueurs présents
- **Bouton de démarrage** : Disponible pour l'hôte

### 4. Démarrage du Jeu
1. L'hôte clique sur "Commencer le Jeu"
2. Compte à rebours de 3 secondes
3. Navigation vers la première salle
4. Synchronisation de tous les joueurs

### 5. Progression dans les Salles
- **Navigation synchronisée** : Tous les joueurs avancent ensemble
- **Scores individuels** : Chaque joueur a ses propres résultats
- **Temps de jeu** : Chronomètre individuel par salle

### 6. Fin de Partie
- **Page de succès** : Comparaison des scores
- **Classement final** : Résultats de tous les joueurs
- **Sauvegarde** : Données enregistrées dans les statistiques

---

## 📊 SYSTÈME DE STATISTIQUES

### Statistiques Personnelles
- **Sessions totales** : Nombre de parties jouées
- **Temps de jeu total** : Durée cumulée
- **Meilleurs scores** : Records par salle
- **Progression** : Évolution des performances

### Statistiques Globales
- **Classement général** : Position parmi tous les joueurs
- **Classements par salle** : Meilleurs scores par type de jeu
- **Historique complet** : Toutes les sessions jouées
- **Statistiques temporelles** : Évolution dans le temps

### Données Sauvegardées
- **Nom du joueur** : Pseudonyme utilisé
- **Mode de jeu** : Solo ou multijoueur
- **Salle jouée** : Type de jeu
- **Score obtenu** : Points gagnés
- **Temps de jeu** : Durée de la session
- **Statut de completion** : Salle terminée ou non
- **Données additionnelles** : Informations spécifiques par salle
- **Numéro de run** : Identifiant unique de session

---

## 🐛 FONCTIONNALITÉS DE DEBUG

### Boutons de Debug
- **Dans la salle d'attente** : Passage direct au jeu multijoueur
- **Dans le jeu multijoueur** : Passage direct aux notifications (salle 5)
- **Simulation automatique** : Résultats simulés pour les salles précédentes

### Outils de Test
- **Tests automatisés** : Scripts de validation des fonctionnalités
- **Logs détaillés** : Traçabilité des actions utilisateur
- **Mode développement** : Interface de debug intégrée

---

## 🚀 DÉPLOIEMENT ET MAINTENANCE

### Déploiement
- **Plateforme** : Firebase Hosting
- **URL de production** : https://pandora-box-user2.web.app
- **Processus** : Build Flutter Web → Deploy Firebase
- **Branches Git** : 
  - `AppleDev` : Développement
  - `main` : Production principale
  - `AppleProd` : Production Apple
  - `MultiEtSolo_AppV1` : Version multijoueur et solo

### Maintenance
- **Monitoring** : Surveillance des performances Firebase
- **Mises à jour** : Déploiement continu des nouvelles fonctionnalités
- **Sauvegarde** : Données sauvegardées sur Firebase
- **Support** : Gestion des erreurs et des retours utilisateur

---

## 📈 MÉTRIQUES ET KPIs

### Métriques Techniques
- **Temps de chargement** : < 3 secondes
- **Temps de réponse** : < 500ms pour les actions
- **Disponibilité** : > 99.9%
- **Synchronisation** : < 100ms entre joueurs

### Métriques Utilisateur
- **Sessions actives** : Nombre de joueurs simultanés
- **Temps de session** : Durée moyenne des parties
- **Taux de completion** : Pourcentage de salles terminées
- **Engagement** : Fréquence de retour des joueurs

---

## 🔒 SÉCURITÉ ET CONFORMITÉ

### Sécurité des Données
- **Authentification** : Système de noms d'utilisateur
- **Validation** : Vérification des données côté client et serveur
- **Sauvegarde** : Données chiffrées sur Firebase
- **Privacité** : Respect des données personnelles

### Gestion des Erreurs
- **Récupération automatique** : Reconnexion automatique en cas de déconnexion
- **Messages d'erreur** : Feedback clair pour l'utilisateur
- **Logs d'erreur** : Traçabilité des problèmes techniques
- **Fallback** : Modes de secours en cas de problème

---

## 📋 ROADMAP FUTURE

### Version 1.1
- [ ] Amélioration des animations
- [ ] Nouvelles salles de jeu
- [ ] Système de récompenses
- [ ] Mode spectateur

### Version 1.2
- [ ] Application mobile native
- [ ] Système de tournois
- [ ] Intégration réseaux sociaux
- [ ] Mode coopératif avancé

### Version 2.0
- [ ] Intelligence artificielle
- [ ] Génération procédurale de contenu
- [ ] Réalité augmentée
- [ ] Plateforme de création de contenu

---

## 📞 CONTACT ET SUPPORT

**Développeur :** Assistant IA Claude  
**Plateforme :** Cursor IDE  
**Repository :** https://github.com/cerine0044/Workshop.git  
**Application :** https://pandora-box-user2.web.app  

---

*Document généré automatiquement - Décembre 2024*
