# 📋 DOCUMENTATION TECHNIQUE - PANDORA BOX
## Application Flutter Web Multijoueur

---

## 📊 INFORMATIONS GÉNÉRALES

**Nom du projet :** Pandora Box  
**Version :** 1.0.0+1  
**Framework :** Flutter Web  
**Déploiement :** Firebase Hosting  
**URL de production :** https://pandora-box-user2.web.app  
**Date de création :** Workshop25-26  

---

## 🏗️ ARCHITECTURE TECHNIQUE

### **Stack Technologique**
- **Frontend :** Flutter Web (SDK ^3.6.0)
- **Backend :** Firebase Realtime Database
- **Authentification :** Firebase Auth
- **Hébergement :** Firebase Hosting
- **Langage :** Dart

### **Dépendances Principales**
```yaml
dependencies:
  flutter: sdk
  cupertino_icons: ^1.0.8
  sensors_plus: (capteurs mobiles)
  torch_light: (flash mobile)
  audioplayers: ^6.1.0
  shared_preferences: ^2.2.2
  firebase_core: ^3.15.2
  firebase_database: ^11.3.10
  firebase_auth: ^5.7.0
```

---

## 📁 STRUCTURE DU PROJET

```
Utilisateur2/
├── lib/                           # Code source principal
│   ├── main.dart                  # Point d'entrée
│   ├── firebase_options.dart      # Configuration Firebase
│   ├── pages/                     # Pages de l'application
│   │   ├── home_page.dart         # Page d'accueil
│   │   ├── page1_puzzle.dart      # Jeu puzzle interactif
│   │   ├── stress_page.dart       # Détecteur de stress
│   │   ├── page3_words.dart       # Jeu de mots croisés
│   │   ├── page4_tram.dart        # Dilemme du tramway
│   │   ├── page5_notifications.dart # Gestion notifications
│   │   ├── game_stats_page.dart   # Page statistiques
│   │   ├── firebase_admin_panel.dart # Panel admin
│   │   └── working_multiplayer_page.dart # Mode multijoueur
│   ├── services/                  # Services métier
│   │   ├── game_stats_service.dart # Gestion statistiques
│   │   ├── firebase_multiplayer_service.dart # Multijoueur
│   │   └── firebase_database_manager.dart # Gestion BDD
│   └── widgets/                   # Widgets réutilisables
│       ├── game_timer_widget.dart # Chronomètre global
│       └── score_display_widget.dart # Affichage scores
├── assets/                        # Ressources (images, sons)
├── web/                          # Configuration web
├── build/                        # Build de production
├── firebase.json                 # Configuration Firebase
└── pubspec.yaml                 # Dépendances Flutter
```

---

## 🎮 FONCTIONNALITÉS PRINCIPALES

### **1. Système de Chronomètre Global**
- **Service :** `GameStatsService`
- **Widget :** `GameTimerWidget`
- **Fonctionnalités :**
  - Chronomètre continu à travers toutes les salles
  - Enregistrement automatique des sessions
  - Statistiques détaillées par jeu
  - Persistance des données avec `shared_preferences`

### **2. Mode Multijoueur Firebase**
- **Service :** `FirebaseMultiplayerService`
- **Fonctionnalités :**
  - Création de rooms avec codes uniques (6 caractères)
  - Connexion en temps réel entre joueurs
  - Synchronisation des scores et états
  - Gestion des déconnexions intelligente
  - Mode fallback local en cas d'erreur

### **3. Jeux Disponibles**

#### **Page 1 - Puzzle Interactif**
- Jeu "Es-tu stressé ?" avec bouton mobile "NON"
- Système de bouton leurre et bouton caché
- Intégration complète du chronomètre global

#### **Page 2 - Détecteur de Stress**
- Utilisation des capteurs mobiles (`sensors_plus`)
- Flash mobile réactif (`torch_light`)
- Jauge de stress en temps réel
- Seuil de déclenchement configurable

#### **Page 3 - Mots Croisés**
- Jeu d'association de mots avec drag-and-drop
- Système de stress progressif
- Conseils personnalisés par mot trouvé
- Mode association et mode liste

#### **Page 4 - Dilemme du Tramway**
- 20 questions de dilemmes moraux
- Système de progression avec cercles visuels
- Effets sonores et visuels immersifs
- Comptage des décisions par type

#### **Page 5 - Gestion des Notifications**
- Popups de notifications stressantes
- Système d'intensité sonore progressive
- Fermeture des notifications pour réduire le stress
- Sons d'ambiance multicouches

---

## 🔥 CONFIGURATION FIREBASE

### **Projet Firebase**
- **Nom :** pandora-box-user2
- **Console :** https://console.firebase.google.com/project/pandora-box-user2/overview
- **Database URL :** https://pandora-box-user2-default-rtdb.firebaseio.com

### **Structure de la Base de Données**
```json
{
  "rooms": {
    "roomId": {
      "name": "Nom de la room",
      "code": "ABC123",
      "host": "userId",
      "players": {
        "playerId": {
          "name": "Nom du joueur",
          "ready": false,
          "score": 0
        }
      },
      "status": "waiting|playing|finished"
    }
  },
  "players": {
    "playerId": {
      "name": "Nom du joueur",
      "roomId": "roomId",
      "lastSeen": "timestamp"
    }
  }
}
```

---

## 🛠️ OUTILS D'ADMINISTRATION

### **1. Panel d'Administration In-App**
- Accès via bouton "Admin Firebase" sur la page d'accueil
- Gestion des rooms et joueurs en temps réel
- Suppression de données avec confirmation
- Monitoring de l'activité

### **2. Scripts CLI de Maintenance**
- `firebase_rest_cli.dart` - Gestion complète via REST API
- `test_multijoueur.dart` - Tests de connectivité
- `test_interface.dart` - Validation de l'interface déployée
- `deploy_firebase.sh` - Déploiement automatisé

### **3. Commandes de Maintenance**
```bash
# Analyser la base de données
dart firebase_rest_cli.dart analyze

# Nettoyer les données inactives
dart firebase_rest_cli.dart cleanup --rooms 24 --players 7

# Créer une sauvegarde
dart firebase_rest_cli.dart backup

# Voir les statistiques
dart firebase_rest_cli.dart stats
```

---

## 📊 SYSTÈME DE STATISTIQUES

### **Données Collectées**
- **Nom du joueur** et **salle de jeu**
- **Temps de début et fin** de session
- **Durée totale** de jeu
- **Statut de completion** (réussi/échoué)
- **Score obtenu**
- **Données additionnelles** spécifiques à chaque jeu

### **Persistance**
- Stockage local avec `shared_preferences`
- Sauvegarde automatique à la fin de chaque session
- Chargement automatique au démarrage de l'application

### **Page de Statistiques**
- Affichage des sessions complétées
- Statistiques agrégées par salle
- Temps moyen et meilleur temps
- Taux de réussite global

---

## 🚀 DÉPLOIEMENT ET BUILD

### **Commandes de Build**
```bash
# Build de production
flutter build web --release

# Build avec optimisations
flutter build web --release --no-tree-shake-icons

# Analyse du code
flutter analyze

# Tests
flutter test
```

### **Déploiement Firebase**
```bash
# Déploiement complet
firebase deploy

# Déploiement hosting uniquement
firebase deploy --only hosting

# Script automatisé
./deploy_firebase.sh
```

---

## 🔧 RÉSOLUTION DE PROBLÈMES

### **Problèmes Courants**

#### **Ports Occupés**
```bash
# Solution 1: Utiliser un port libre
flutter run -d chrome --web-port=8087

# Solution 2: Tuer les processus existants
lsof -ti:8080 | xargs kill -9
```

#### **Erreurs Firebase**
- L'application bascule automatiquement en mode local
- Vérifier la configuration Firebase
- Consulter les logs de la console Firebase

#### **Problèmes de Synchronisation**
- Vérifier la connexion internet
- Rafraîchir la page
- Vérifier que tous les joueurs sont connectés

---

## 📱 COMPATIBILITÉ

### **Navigateurs Supportés**
- ✅ Chrome (recommandé)
- ✅ Firefox
- ✅ Safari
- ✅ Edge

### **Appareils Supportés**
- ✅ Ordinateurs (Windows, macOS, Linux)
- ✅ Tablettes (iPad, Android)
- ✅ Smartphones (iOS, Android)

---

## 🔒 SÉCURITÉ

### **Authentification**
- Firebase Auth pour la gestion des utilisateurs
- Codes de room à 6 caractères pour l'accès
- Gestion des sessions et déconnexions

### **Données**
- Chiffrement automatique Firebase
- Pas de données sensibles stockées localement
- Nettoyage automatique des données inactives

---

## 📈 PERFORMANCE

### **Métriques Actuelles**
- **Temps de réponse :** ~30-35ms
- **Taille du build :** Optimisé avec tree-shaking
- **Chargement initial :** < 3 secondes
- **Synchronisation temps réel :** < 100ms

### **Optimisations Appliquées**
- Tree-shaking des icônes (99% de réduction)
- Compression des assets
- Lazy loading des composants
- Cache Firebase optimisé

---

## 🎯 ROADMAP FUTURE

### **Améliorations Prévues**
- [ ] Système de chat en temps réel
- [ ] Plus de jeux interactifs
- [ ] Système de récompenses
- [ ] Mode compétition
- [ ] API REST pour intégrations externes

### **Maintenance**
- [ ] Monitoring automatique des performances
- [ ] Sauvegardes automatiques quotidiennes
- [ ] Alertes de santé système
- [ ] Documentation utilisateur étendue

---

## 📞 SUPPORT ET CONTACT

### **Documentation**
- Guide d'utilisation : `GUIDE_UTILISATION.md`
- Guide de test UX : `GUIDE_TEST_UX.md`
- Guide Firebase : `FIREBASE_MANAGEMENT.md`

### **Outils de Debug**
- Panel d'administration intégré
- Scripts de diagnostic
- Logs Firebase en temps réel
- Tests automatisés

---

**Document généré le :** $(date)  
**Version de l'application :** 1.0.0+1  
**Dernière mise à jour :** Intégration du système de chronomètre global
