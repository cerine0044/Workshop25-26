# Connexion entre PC - Guide Rapide

## 🚀 Solution la Plus Simple

### Étape 1 : Démarrer le serveur sur le PC principal
```bash
dart run start_multiplayer.dart
```

### Étape 2 : Noter l'adresse IP
L'application affichera quelque chose comme :
```
📱 Adresse de cette machine: http://192.168.1.100:8080
```

### Étape 3 : Se connecter depuis l'autre PC
Sur le deuxième PC, ouvrez le navigateur et allez à :
```
http://192.168.1.100:8080
```
(Remplacez par l'IP affichée)

## 🔧 Solutions Alternatives

### Option A : Firebase Réel
1. Suivez le guide `FIREBASE_SETUP.md`
2. Configurez Firebase avec vos vraies clés
3. Les deux PC pourront se connecter via Firebase

### Option B : Mode Local Partagé
1. Modifiez `firebase_service.dart` :
   ```dart
   static bool _useLocalService = true; // Retour au mode local
   ```
2. Utilisez le même réseau local
3. Accédez via l'IP locale du PC principal

## 🌐 Dépannage

### Problème : "Connexion refusée"
- Vérifiez que les deux PC sont sur le même réseau WiFi
- Vérifiez que le port 8080 n'est pas bloqué par le firewall
- Essayez de désactiver temporairement l'antivirus

### Problème : "Page non trouvée"
- Vérifiez que l'IP est correcte
- Essayez `http://localhost:8080` si vous testez sur la même machine
- Vérifiez que l'application Flutter est bien démarrée

### Problème : "Rooms non synchronisées"
- Vérifiez que Firebase est configuré (si vous utilisez Firebase)
- Redémarrez l'application sur les deux PC
- Vérifiez la console du navigateur pour les erreurs

## 📱 Test Rapide

1. **PC 1** : Démarrez l'app et créez une room
2. **PC 2** : Ouvrez l'IP du PC 1 et rejoignez la room
3. **Vérification** : Les deux PC devraient voir les mêmes joueurs

## 🔄 Redémarrage

Si ça ne marche pas :
```bash
# Arrêter l'application (Ctrl+C)
# Puis redémarrer
dart run start_multiplayer.dart
```
