# 🎮 Guide d'Utilisation - Pandora Box Multijoueur

## 🌐 Accès à l'Application

**URL principale :** https://pandora-box-user2.web.app

## 🚀 Démarrage Rapide

### Pour les Joueurs
1. **Ouvrir l'application** dans votre navigateur
2. **Cliquer sur "Multijoueur"** sur la page d'accueil
3. **Choisir votre mode :**
   - **Créer une room** : Donner un nom et cliquer "Créer"
   - **Rejoindre une room** : Entrer le code de la room

### Pour l'Hôte de la Room
1. Créer une room avec un nom descriptif
2. Partager le **code à 6 caractères** avec les autres joueurs
3. Attendre que les joueurs rejoignent
4. Cliquer "Commencer le jeu" quand tout le monde est prêt

## 🎯 Fonctionnalités Disponibles

### Mode Multijoueur Firebase
- ✅ **Création de rooms** avec codes uniques
- ✅ **Connexion en temps réel** entre joueurs
- ✅ **Synchronisation des scores** automatique
- ✅ **Gestion des déconnexions** intelligente
- ✅ **Chat en temps réel** (si implémenté)

### Mode Local (Fallback)
- ✅ **Fonctionnement hors ligne** si Firebase est indisponible
- ✅ **Interface de secours** automatique
- ✅ **Gestion d'erreurs** transparente

## 🛠️ Administration

### Panel d'Administration In-App
1. Aller sur la page d'accueil
2. Cliquer sur le bouton **"Admin Firebase"**
3. Gérer les rooms et joueurs actifs
4. Supprimer des données si nécessaire

### Scripts de Maintenance
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

## 🔧 Résolution de Problèmes

### Problème : L'application ne se charge pas
**Solution :**
- Vérifier la connexion internet
- Rafraîchir la page (F5)
- Vider le cache du navigateur

### Problème : Impossible de rejoindre une room
**Solutions :**
- Vérifier que le code est correct (6 caractères)
- S'assurer que la room existe encore
- Essayer de créer une nouvelle room

### Problème : Connexion Firebase échoue
**Solutions :**
- L'application bascule automatiquement en mode local
- Les fonctionnalités de base restent disponibles
- Réessayer plus tard

### Problème : Scores ne se synchronisent pas
**Solutions :**
- Vérifier la connexion internet
- Rafraîchir la page
- Vérifier que tous les joueurs sont connectés

## 📱 Compatibilité

### Navigateurs Supportés
- ✅ **Chrome** (recommandé)
- ✅ **Firefox**
- ✅ **Safari**
- ✅ **Edge**

### Appareils Supportés
- ✅ **Ordinateurs** (Windows, macOS, Linux)
- ✅ **Tablettes** (iPad, Android)
- ✅ **Smartphones** (iOS, Android)

## 🎮 Pages de Jeu Disponibles

### Page 3 - Words (Nouvelle)
- **Fonctionnalités :** Association de mots, timer, jauge de stress
- **Multijoueur :** Scores synchronisés en temps réel
- **Conseils :** Personnalisés selon le niveau de stress

### Autres Pages
- **Page 4 :** Tram (si implémentée)
- **Page 5 :** Notifications et succès

## 🔥 Firebase Console

**URL :** https://console.firebase.google.com/project/pandora-box-user2/overview

### Données Surveillées
- **Rooms actives** et leur état
- **Joueurs connectés** et leurs scores
- **Activité en temps réel** de la base de données

## 📊 Monitoring et Statistiques

### Métriques Disponibles
- Nombre de rooms actives
- Nombre de joueurs connectés
- Taux d'activité des rooms
- Performance de l'application

### Outils de Surveillance
- Panel d'administration in-app
- Scripts CLI de monitoring
- Console Firebase en temps réel

## 🆘 Support

### En Cas de Problème
1. **Vérifier** ce guide de résolution
2. **Utiliser** les outils d'administration
3. **Consulter** les logs Firebase
4. **Tester** avec les scripts fournis

### Informations Techniques
- **Base de données :** Firebase Realtime Database
- **Hébergement :** Firebase Hosting
- **Framework :** Flutter Web
- **Langage :** Dart

---

**🎉 L'application Pandora Box est maintenant pleinement opérationnelle !**

**Bonne partie et amusez-vous bien ! 🎮**
