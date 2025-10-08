# 🎮 Pandora Box - Application Multijoueur

## 🚀 Démarrage Rapide

### Une Seule Commande
```bash
dart run lancer_complet.dart
```

### URLs Disponibles
- **Application** : http://localhost:8085
- **API Backend** : http://localhost:5002

## 📱 Processus d'Utilisation

### Pour le Joueur 1 (Hôte)
1. **Lancez l'application** : `dart run lancer_complet.dart`
2. **Ouvrez** http://localhost:8085
3. **Cliquez sur "Créer un salon"**
4. **Entrez un nom** de salon
5. **Cliquez sur "Créer"**
6. **Partagez l'ID généré** avec le Joueur 2

### Pour le Joueur 2
1. **Connectez-vous au même WiFi**
2. **Ouvrez** http://192.168.1.20:8085
3. **Cliquez sur "Rejoindre"**
4. **Entrez l'ID** reçu du Joueur 1
5. **Cliquez sur "Rejoindre"**
6. **Vous êtes connectés !** 🎉

## 🛠️ Commandes Utiles

### Démarrage
```bash
# Lancer l'application complète
dart run lancer_complet.dart

# Installer les dépendances
flutter pub get

# Vérifier l'état de Flutter
flutter doctor
```

### Arrêt
```bash
# Arrêter tous les processus
pkill -f "dart run"
pkill -f "flutter run"

# Ou utiliser Ctrl+C dans le terminal
```

### Dépannage
```bash
# Problème de port occupé
lsof -ti:8085 | xargs kill -9
lsof -ti:5002 | xargs kill -9

# Redémarrage propre
flutter clean
flutter pub get
dart run lancer_complet.dart
```

## 📋 Fonctionnalités

- ✅ **Création de rooms** multijoueurs
- ✅ **Rejoindre des rooms** existantes  
- ✅ **Synchronisation temps réel** (toutes les 2 secondes)
- ✅ **Interface moderne** et responsive
- ✅ **Multi-plateforme** (Windows, macOS, Web)

## 🌐 Architecture

- **Frontend** : Flutter Web
- **Backend** : Dart HTTP Server  
- **Communication** : HTTP REST API
- **Synchronisation** : Polling (2 secondes)

## 🎯 Plateformes Supportées

- ✅ **Windows** - Application native
- ✅ **macOS** - Application native
- ✅ **Web** - Application web

## 📞 Support

Si vous rencontrez des problèmes :
1. Vérifiez que les deux PC sont sur le même réseau WiFi
2. Testez l'API backend : http://192.168.1.20:5002
3. Vérifiez les logs dans le terminal
4. Redémarrez l'application si nécessaire