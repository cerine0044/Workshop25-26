# 🎮 Pandora Box - Guide d'Utilisation

## 🚀 Démarrage Rapide

### Une Seule Commande
```bash
dart run lancer_complet.dart
```

### URLs à Partager
- **Application Flutter** : `http://192.0.0.2:8084`
- **API Backend** : `http://192.0.0.2:5002`

## 📱 Instructions pour l'Autre PC

1. **Connectez-vous au même WiFi**
2. **Ouvrez un navigateur**
3. **Allez à** : `http://192.0.0.2:8084`
4. **Les rooms seront partagées entre tous les PC !** 🎉

## 🛠️ Commandes Utiles

### Démarrage
```bash
# Lancer l'application complète (serveur + app)
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

### Développement
```bash
# Hot reload (quand l'app est lancée)
r

# Hot restart (quand l'app est lancée)
R

# Quitter l'application
q
```

## 🔧 Dépannage

### Problème : "Address already in use"
```bash
# Trouver et arrêter les processus qui utilisent les ports
lsof -ti:8084 | xargs kill -9
lsof -ti:5002 | xargs kill -9
```

### Problème : "Connexion refusée"
- Vérifiez que les deux PC sont sur le même réseau WiFi
- Vérifiez que le firewall n'bloque pas les ports 8084 et 5002
- Essayez de désactiver temporairement le firewall

### Problème : "Page ne se charge pas"
- Vérifiez l'IP avec `ifconfig` sur Mac/Linux ou `ipconfig` sur Windows
- Assurez-vous que l'IP affichée correspond bien à votre réseau

### Problème : "Application Flutter ne démarre pas"
- Vérifiez que Flutter est installé : `flutter doctor`
- Vérifiez que les dépendances sont installées : `flutter pub get`

## 📋 Fonctionnalités

### Gestion des Rooms
- ✅ **Créer une room** : Saisissez un nom et cliquez sur "Créer la room"
- ✅ **Rejoindre une room** : Saisissez l'ID de la room et cliquez sur "Rejoindre"
- ✅ **Voir les rooms disponibles** : Liste mise à jour en temps réel
- ✅ **Rooms partagées** : Tous les PC voient les mêmes rooms

### Synchronisation
- ✅ **Temps réel** : Les rooms se mettent à jour toutes les 2 secondes
- ✅ **Multi-PC** : Plusieurs PC peuvent se connecter simultanément
- ✅ **Persistance** : Les rooms restent disponibles tant que le serveur tourne

## 🌐 Architecture

### Serveur Backend (Port 5002)
- **Stockage des rooms** en mémoire
- **API REST** pour créer/rejoindre les rooms
- **CORS activé** pour permettre l'accès depuis Flutter Web

### Application Flutter (Port 8084)
- **Interface utilisateur** moderne et responsive
- **Connexion au serveur backend** via HTTP
- **Mise à jour automatique** des rooms disponibles

## 📞 Support

Si vous rencontrez des problèmes :
1. Vérifiez que les deux PC sont sur le même réseau
2. Testez d'abord l'API backend : `http://192.0.0.2:5002`
3. Vérifiez les logs dans le terminal
4. Essayez de redémarrer les deux PC

## 🎯 Prochaines Étapes

- [ ] Ajouter l'authentification utilisateur
- [ ] Implémenter les jeux multijoueurs
- [ ] Ajouter la persistance des données
- [ ] Optimiser la synchronisation temps réel