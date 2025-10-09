# 🎮 Pandora Box - Projet Workshop25-26

## 📁 Structure du Projet (Nettoyée)

### 🎯 **Projet Principal : Utilisateur2**

Le dossier `Utilisateur2/` contient l'application Flutter web déployée et fonctionnelle.

**🌐 Application Déployée :** https://pandora-d7a90.web.app

### 📂 **Contenu du Dossier Utilisateur2**

```
Utilisateur2/
├── lib/                    # Code source Flutter
│   ├── main.dart          # Point d'entrée
│   ├── firebase_options.dart # Configuration Firebase
│   ├── pages/             # Pages de l'application
│   │   ├── eco_stress_home_page.dart    # Page d'accueil
│   │   ├── working_multiplayer_page.dart # Mode multijoueur
│   │   ├── page1_puzzle.dart           # Jeu puzzle
│   │   ├── page3_crossword.dart        # Mots croisés
│   │   ├── page4_tram.dart             # Jeu du tram
│   │   └── ... (autres pages de jeux)
│   ├── services/          # Services
│   │   ├── firebase_multiplayer_service.dart # Service multijoueur
│   │   └── global_score_service.dart   # Gestion des scores
│   └── widgets/           # Widgets réutilisables
│       └── score_display_widget.dart
├── assets/                # Ressources (images, sons)
├── web/                   # Fichiers web
├── build/                 # Build de production
├── firebase.json          # Configuration Firebase Hosting
├── pubspec.yaml           # Dépendances Flutter
├── README.md              # Documentation du projet
├── FIREBASE_SETUP_GUIDE.md # Guide de configuration Firebase
└── CLEANUP_SUMMARY.md     # Résumé du nettoyage
```

## 🎮 **Fonctionnalités**

### ✅ **Mode Multijoueur**
- Création de rooms avec codes
- Rejoindre par code
- Synchronisation temps réel via Firebase
- Gestion des joueurs
- Toggle ready/unready
- Démarrage de jeu

### 🎯 **Jeux Disponibles**
- **Puzzle** : Énigmes complexes
- **Mots Croisés** : Code secret
- **Jeu du Tram** : Équilibre du système
- **Détecteur de Stress** : Mesure du stress
- **Notifications** : Gestion des alertes

### 🏆 **Système de Scores**
- Score global
- Chronomètre
- Page de résultats finaux

## 🚀 **Déploiement**

### Local
```bash
cd Utilisateur2
flutter run -d chrome --web-port=3000
```

### Production
```bash
cd Utilisateur2
flutter build web --release
firebase deploy --only hosting
```

## 🔥 **Configuration Firebase**

Pour activer le mode multijoueur, voir `Utilisateur2/FIREBASE_SETUP_GUIDE.md`

## 📊 **Statistiques du Nettoyage**

### ❌ **Fichiers Supprimés**
- **25+ fichiers de test** supprimés
- **8 fichiers serveur** supprimés
- **10+ scripts shell** supprimés
- **6 dossiers de plateforme** supprimés (android, ios, macos, linux, windows)
- **Dossiers de build/cache** supprimés
- **Documentation inutile** supprimée

### ✅ **Fichiers Conservés**
- **Dossier Utilisateur2** complet et fonctionnel
- **README.md** principal
- **Configuration Git** (.git/)

## 🎯 **Objectif**

Projet **nettoyé et optimisé** contenant uniquement l'application déployée et fonctionnelle.

---

**🎮 Application prête pour la production !**

**🌐 URL :** https://pandora-d7a90.web.app