# 🎮 Pandora Box - Guide Simplifié

## 🚀 Démarrage Rapide

### 1. Lancer l'application
```bash
dart run lancer_complet.dart
```

### 2. URLs disponibles
- **Application** : http://localhost:8085
- **API Backend** : http://localhost:5002

### 3. Pour l'autre PC
- **Application** : http://192.168.1.20:8085
- **API Backend** : http://192.168.1.20:5002

## 📱 Comment utiliser

### Créer une room
1. Ouvrez http://localhost:8085
2. Cliquez sur "Créer un salon"
3. Entrez un nom de salon
4. Cliquez sur "Créer"
5. Partagez l'ID généré avec l'autre joueur

### Rejoindre une room
1. Ouvrez http://192.168.1.20:8085 (sur l'autre PC)
2. Cliquez sur "Rejoindre"
3. Entrez l'ID de la room
4. Cliquez sur "Rejoindre"

## 🔧 Dépannage

### Arrêter l'application
```bash
# Dans le terminal où l'app tourne
Ctrl+C

# Ou forcer l'arrêt
pkill -f "dart run"
pkill -f "flutter run"
```

### Problème de port occupé
```bash
lsof -ti:8085 | xargs kill -9
lsof -ti:5002 | xargs kill -9
```

### Redémarrer proprement
```bash
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

## 🎯 Plateformes supportées

- ✅ **Windows** - Application native
- ✅ **macOS** - Application native
- ✅ **Web** - Application web

## 📞 Support

Si vous rencontrez des problèmes :
1. Vérifiez que les deux PC sont sur le même réseau WiFi
2. Testez l'API backend : http://192.168.1.20:5002
3. Vérifiez les logs dans le terminal
4. Redémarrez l'application si nécessaire
