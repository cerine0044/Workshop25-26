# 🎮 Pandora Box - Mode Multijoueur

## 📁 Structure du Projet (Nettoyée)

### 🎯 Fichiers Principaux
- `lib/main.dart` - Point d'entrée de l'application
- `lib/firebase_options.dart` - Configuration Firebase
- `firebase.json` - Configuration Firebase Hosting
- `pubspec.yaml` - Dépendances Flutter

### 🏠 Pages (lib/pages/)
- `eco_stress_home_page.dart` - Page d'accueil avec thème stress
- `working_multiplayer_page.dart` - **Page multijoueur principale**
- `fallback_home_page.dart` - Page d'accueil de secours
- `final_score_page.dart` - Page des scores finaux
- `home_page.dart` - Page d'accueil basique
- `page1_puzzle.dart` - Jeu puzzle
- `page3_crossword.dart` - Mots croisés
- `page4_tram.dart` - Jeu du tram
- `page5_notifications.dart` - Notifications
- `page5_success.dart` - Page de succès
- `stress_page.dart` - Détecteur de stress

### 🔧 Services (lib/services/)
- `firebase_multiplayer_service.dart` - **Service multijoueur Firebase**
- `global_score_service.dart` - Gestion des scores globaux

### 🎨 Widgets (lib/widgets/)
- `score_display_widget.dart` - Affichage des scores

### 📱 Assets
- `assets/images/` - Images des jeux (tram1-5.jpg)
- `assets/sounds/` - Sons (horn.mp3)

### 🌐 Web
- `web/` - Fichiers web (index.html, manifest.json, etc.)

## 🎮 Fonctionnalités Multijoueur

### ✅ Fonctionnalités Disponibles
- **Création de room** avec nom personnalisé
- **Rejoindre par code** (6 caractères)
- **Liste des rooms** disponibles en temps réel
- **Copie de code** depuis la liste
- **Gestion des joueurs** en temps réel
- **Toggle ready/unready** synchronisé
- **Démarrage de jeu** (hôte seulement)
- **Transfert d'hôte** automatique
- **Synchronisation temps réel** via Firebase

### 🔥 Configuration Firebase Requise
Voir `FIREBASE_SETUP_GUIDE.md` pour activer :
- Firebase Authentication (Anonymous)
- Firebase Realtime Database

## 🚀 Déploiement

### Local
```bash
flutter run -d chrome --web-port=3000
```

### Production
```bash
flutter build web --release
firebase deploy --only hosting
```

**URL :** https://pandora-d7a90.web.app

## 📊 Statistiques du Nettoyage

### ❌ Fichiers Supprimés
- **10 services** inutilisés supprimés
- **8 pages** inutilisées supprimées  
- **1 widget** inutilisé supprimé
- **4 fichiers** de test/documentation supprimés
- **2 fichiers** de backup supprimés

### ✅ Fichiers Conservés
- **2 services** essentiels
- **11 pages** fonctionnelles
- **1 widget** utilisé
- **Assets** complets
- **Configuration** Firebase

## 🎯 Objectif

Projet **nettoyé et optimisé** pour le mode multijoueur fonctionnel avec Firebase Realtime Database.

---

**🎮 Mode multijoueur opérationnel et prêt pour la production !**
