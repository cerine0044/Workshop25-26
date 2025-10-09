# 🎮 Pandora Box - Application Web

## 📁 Structure du projet

```
Utilisateur2/
├── assets/           # Images et sons du jeu
├── build/web/        # Application web compilée (pour déploiement)
├── lib/              # Code source Flutter
├── web/              # Configuration web
├── firebase.json     # Configuration Firebase Hosting
└── pubspec.yaml      # Dépendances Flutter
```

## 🚀 Déploiement

L'application est déployée sur Firebase Hosting :
- **URL** : https://pandora-d7a90.web.app
- **Console** : https://console.firebase.google.com/project/pandora-d7a90

## 🔧 Commandes utiles

```bash
# Installer les dépendances
flutter pub get

# Construire pour le web
flutter build web --release

# Déployer sur Firebase
firebase deploy --only hosting
```

## 📱 Fonctionnalités

- Interface moderne et responsive
- Support Firebase (authentification, base de données)
- Jeux multijoueurs
- Synchronisation temps réel
- Compatible avec tous les navigateurs modernes