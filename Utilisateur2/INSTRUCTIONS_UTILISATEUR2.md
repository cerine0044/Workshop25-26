# 🎮 Pandora Box - Instructions pour l'Utilisateur 2

## 🚀 Installation Rapide

### Prérequis
- **Flutter SDK** installé sur votre PC
- **Dart SDK** (inclus avec Flutter)
- **Navigateur web** moderne (Chrome, Firefox, Safari, Edge)

### Vérification de l'installation
```bash
# Vérifier que Flutter est installé
flutter doctor

# Vérifier que Dart est installé
dart --version
```

## 📦 Installation du Projet

### 1. Extraire le dossier
- Décompressez le fichier `Utilisateur2.zip` dans un dossier de votre choix
- Ouvrez un terminal dans ce dossier

### 2. Installer les dépendances
```bash
# Installer les packages Flutter
flutter pub get

# Vérifier que tout est installé correctement
flutter doctor
```

## 🌐 Connexion au Jeu Multijoueur

### Étape 1 : Obtenir l'IP du PC Principal
Demandez à l'utilisateur du PC principal de vous donner :
- **L'adresse IP** de son PC (ex: `192.168.1.100`)
- **Le port de l'application** (généralement `8084`)

### Étape 2 : Se connecter
1. **Ouvrez votre navigateur web**
2. **Allez à l'adresse** : `http://[IP_DU_PC_PRINCIPAL]:8084`
   - Exemple : `http://192.168.1.100:8084`
3. **L'application devrait se charger automatiquement !**

## 🎯 Utilisation de l'Application

### Fonctionnalités Disponibles
- ✅ **Créer une room** : Saisissez un nom et cliquez sur "Créer la room"
- ✅ **Rejoindre une room** : Saisissez l'ID de la room et cliquez sur "Rejoindre"
- ✅ **Voir les rooms disponibles** : Liste mise à jour en temps réel
- ✅ **Jeux multijoueurs** : Participez aux jeux avec d'autres joueurs

### Navigation
- **Page d'accueil** : Gestion des rooms et navigation
- **Salle 1** : Puzzle et énigmes
- **Salle 2** : Jeu de stress et défis
- **Salle 3** : Mots croisés collaboratifs
- **Salle 4** : Jeu du tramway
- **Salle 5** : Notifications et succès

## 🔧 Dépannage

### Problème : "Page ne se charge pas"
1. **Vérifiez la connexion réseau** : Les deux PC doivent être sur le même WiFi
2. **Vérifiez l'adresse IP** : Demandez à nouveau l'IP du PC principal
3. **Vérifiez le port** : Assurez-vous que le port est correct (généralement 8084)
4. **Testez l'API** : Essayez `http://[IP]:5002` pour vérifier le serveur backend

### Problème : "Connexion refusée"
1. **Firewall** : Vérifiez que votre firewall n'bloque pas les connexions
2. **Antivirus** : Certains antivirus bloquent les connexions réseau
3. **Réseau d'entreprise** : Certains réseaux d'entreprise bloquent les connexions entre PC

### Problème : "Application Flutter ne démarre pas"
1. **Flutter non installé** : Installez Flutter depuis [flutter.dev](https://flutter.dev)
2. **Dépendances manquantes** : Exécutez `flutter pub get`
3. **Version incompatible** : Vérifiez que vous avez Flutter 3.6.0 ou plus récent

### Problème : "Rooms ne se synchronisent pas"
1. **Vérifiez la connexion** : Les deux PC doivent être connectés au même réseau
2. **Actualisez la page** : Appuyez sur F5 ou Ctrl+R
3. **Redémarrez** : Fermez et rouvrez le navigateur

## 📱 Fonctionnalités Avancées

### Synchronisation Temps Réel
- Les rooms se mettent à jour automatiquement toutes les 2 secondes
- Les changements sont visibles instantanément sur tous les PC connectés
- Aucune action requise de votre part

### Multi-Plateforme
- Fonctionne sur **Windows**, **macOS**, **Linux**
- Compatible avec tous les navigateurs modernes
- Interface responsive qui s'adapte à votre écran

## 🆘 Support

### En cas de problème
1. **Vérifiez d'abord** que les deux PC sont sur le même réseau WiFi
2. **Testez l'API backend** : `http://[IP]:5002`
3. **Vérifiez les logs** dans le terminal du PC principal
4. **Redémarrez** les deux PC si nécessaire

### Informations utiles à fournir
- **Votre système d'exploitation** (Windows/macOS/Linux)
- **Votre navigateur** et sa version
- **Le message d'erreur exact** si il y en a un
- **L'adresse IP** que vous essayez d'utiliser

## 🎉 Amusez-vous bien !

L'application Pandora Box est conçue pour être utilisée en multijoueur. Profitez des jeux collaboratifs et des défis partagés !

---
*Dernière mise à jour : Octobre 2024*
