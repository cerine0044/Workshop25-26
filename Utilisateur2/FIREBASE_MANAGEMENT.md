# 🔥 Gestion Complète de la Base de Données Firebase

Ce document décrit tous les outils disponibles pour gérer votre base de données Firebase Realtime Database.

## 📋 Table des Matières

- [Vue d'ensemble](#vue-densemble)
- [Outils disponibles](#outils-disponibles)
- [Interface d'administration](#interface-dadministration)
- [Scripts de ligne de commande](#scripts-de-ligne-de-commande)
- [Maintenance automatique](#maintenance-automatique)
- [Sauvegarde et restauration](#sauvegarde-et-restauration)
- [Monitoring](#monitoring)
- [Configuration](#configuration)

## 🎯 Vue d'ensemble

Votre système de gestion Firebase comprend :

- **Interface d'administration** : Panneau web pour gérer la BDD
- **Scripts CLI** : Commandes terminal pour automatiser les tâches
- **Maintenance automatique** : Nettoyage et surveillance automatiques
- **Sauvegarde/Restauration** : Protection des données
- **Monitoring temps réel** : Surveillance des changements

## 🛠️ Outils Disponibles

### 1. Interface d'Administration Web

**Accès** : Depuis l'application → Bouton "Admin Firebase"

**Fonctionnalités** :
- 📊 Statistiques en temps réel
- 🧹 Nettoyage des données inactives
- 💾 Sauvegarde manuelle
- ⚠️ Détection des problèmes
- 👁️ Monitoring en direct
- 📋 Génération de rapports

### 2. Script de Ligne de Commande

**Fichier** : `firebase_cli.dart`

**Usage** :
```bash
dart firebase_cli.dart [command] [options]
```

**Commandes disponibles** :
- `analyze` - Analyser la structure de la BDD
- `cleanup` - Nettoyer les données inactives
- `backup` - Créer une sauvegarde
- `restore` - Restaurer depuis une sauvegarde
- `clear` - Supprimer toutes les données
- `monitor` - Surveiller en temps réel
- `stats` - Afficher les statistiques

**Exemples** :
```bash
# Analyser la base de données
dart firebase_cli.dart analyze

# Nettoyer les rooms inactives depuis 24h et joueurs depuis 7 jours
dart firebase_cli.dart cleanup --rooms 24 --players 7

# Créer une sauvegarde
dart firebase_cli.dart backup

# Restaurer depuis une sauvegarde
dart firebase_cli.dart restore backup_1234567890.json

# Surveiller en temps réel
dart firebase_cli.dart monitor
```

### 3. Script de Déploiement

**Fichier** : `deploy_firebase.sh`

**Usage** :
```bash
./deploy_firebase.sh [command]
```

**Commandes disponibles** :
- `setup` - Configuration initiale Firebase
- `deploy` - Déployer l'application
- `rules` - Déployer les règles de sécurité
- `backup` - Créer une sauvegarde
- `restore` - Restaurer depuis une sauvegarde
- `cleanup` - Nettoyer la base de données
- `monitor` - Surveiller la base de données
- `status` - Afficher le statut
- `logs` - Afficher les logs
- `maintenance` - Démarrer la maintenance automatique

**Exemples** :
```bash
# Configuration initiale
./deploy_firebase.sh setup

# Déployer l'application
./deploy_firebase.sh deploy

# Nettoyer la base de données
./deploy_firebase.sh cleanup

# Créer une sauvegarde
./deploy_firebase.sh backup
```

## 🎛️ Interface d'Administration

### Accès
1. Lancez l'application Flutter
2. Cliquez sur le bouton "Admin Firebase" dans le menu de debug

### Fonctionnalités

#### 📊 Statistiques
- Nombre total de rooms
- Rooms actives/inactives
- Nombre total de joueurs
- Moyenne de joueurs par room

#### 🧹 Actions de Nettoyage
- **Nettoyer Rooms** : Supprime les rooms inactives
- **Nettoyer Joueurs** : Supprime les joueurs inactifs
- **Sauvegarder** : Crée une sauvegarde complète
- **Rapport** : Génère un rapport détaillé
- **Tout Supprimer** : ⚠️ Supprime toutes les données

#### ⚠️ Détection de Problèmes
- Rooms vides sans joueurs
- Rooms inactives depuis trop longtemps
- Joueurs hors ligne depuis trop longtemps
- Dates invalides
- Suggestions de correction

#### 👁️ Monitoring Temps Réel
- Surveillance des changements en direct
- Historique des événements
- Alertes automatiques

## 🔧 Maintenance Automatique

### Configuration
Le service de maintenance automatique peut être configuré dans `firebase_config.json` :

```json
{
  "maintenance": {
    "enabled": true,
    "interval_hours": 6,
    "cleanup": {
      "rooms": {
        "enabled": true,
        "max_hours_inactive": 24
      },
      "players": {
        "enabled": true,
        "max_days_inactive": 7
      }
    },
    "backup": {
      "enabled": true,
      "max_backups": 10
    }
  }
}
```

### Démarrage
```bash
# Démarrer la maintenance automatique
./deploy_firebase.sh maintenance

# Ou manuellement avec le script CLI
dart firebase_cli.dart cleanup --rooms 24 --players 7 --force
```

### Tâches Automatiques
- **Nettoyage des rooms** : Supprime les rooms inactives depuis 24h
- **Nettoyage des joueurs** : Supprime les joueurs hors ligne depuis 7 jours
- **Sauvegarde** : Crée une sauvegarde avant le nettoyage
- **Rapport** : Génère un rapport de maintenance

## 💾 Sauvegarde et Restauration

### Création de Sauvegarde
```bash
# Via le script CLI
dart firebase_cli.dart backup

# Via le script de déploiement
./deploy_firebase.sh backup

# Via l'interface web
# Cliquez sur "Sauvegarder" dans le panneau d'administration
```

### Restauration
```bash
# Via le script CLI
dart firebase_cli.dart restore backup_1234567890.json

# Via le script de déploiement
./deploy_firebase.sh restore backup_1234567890.json
```

### Format des Sauvegardes
Les sauvegardes sont créées au format JSON avec :
- Timestamp de création
- Version du format
- Données complètes des rooms et joueurs

## 👁️ Monitoring

### Surveillance Temps Réel
```bash
# Via le script CLI
dart firebase_cli.dart monitor

# Via le script de déploiement
./deploy_firebase.sh monitor
```

### Alertes Automatiques
- Rooms inactives depuis trop longtemps
- Trop de joueurs hors ligne
- Problèmes de performance
- Erreurs de connexion

## ⚙️ Configuration

### Règles de Sécurité
Fichier : `database.rules.json`
```json
{
  "rules": {
    "rooms": {
      ".read": true,
      ".write": true,
      ".indexOn": ["code", "hostId"]
    },
    "players": {
      ".read": true,
      ".write": true
    }
  }
}
```

### Configuration Firebase
Fichier : `firebase_config.json`
- Paramètres de maintenance
- Seuils d'alerte
- Configuration de sécurité
- Paramètres de logging

## 🚀 Déploiement

### Déploiement Complet
```bash
# Configuration initiale
./deploy_firebase.sh setup

# Déploiement de l'application
./deploy_firebase.sh deploy

# Déploiement des règles de sécurité
./deploy_firebase.sh rules
```

### Déploiement Manuel
```bash
# Build Flutter
flutter build web --release

# Déployer sur Firebase Hosting
firebase deploy --only hosting

# Déployer les règles de sécurité
firebase deploy --only database
```

## 📊 Rapports et Statistiques

### Génération de Rapports
```bash
# Via l'interface web
# Cliquez sur "Rapport" dans le panneau d'administration

# Le rapport est automatiquement copié dans le presse-papiers
```

### Contenu des Rapports
- Statistiques générales
- Détails des rooms et joueurs
- Problèmes détectés
- Recommandations
- Historique des actions

## 🔒 Sécurité

### Bonnes Pratiques
- Sauvegardes régulières
- Monitoring continu
- Nettoyage automatique
- Règles de sécurité strictes
- Authentification appropriée

### Alertes de Sécurité
- Tentatives d'accès non autorisées
- Modifications suspectes
- Volume de données anormal
- Erreurs de connexion répétées

## 🆘 Dépannage

### Problèmes Courants

#### Erreur de Connexion Firebase
```bash
# Vérifier la configuration
firebase projects:list

# Reconfigurer si nécessaire
firebase login
firebase use pandora-box-user2
```

#### Base de Données Corrompue
```bash
# Restaurer depuis une sauvegarde
./deploy_firebase.sh restore backup_1234567890.json

# Ou nettoyer complètement
dart firebase_cli.dart clear
```

#### Problèmes de Performance
```bash
# Analyser la base de données
dart firebase_cli.dart analyze

# Nettoyer les données inactives
./deploy_firebase.sh cleanup
```

### Logs et Debug
```bash
# Afficher les logs Firebase
./deploy_firebase.sh logs

# Surveiller en temps réel
./deploy_firebase.sh monitor
```

## 📞 Support

Pour toute question ou problème :
1. Consultez les logs via `./deploy_firebase.sh logs`
2. Analysez la base de données via `dart firebase_cli.dart analyze`
3. Vérifiez le statut via `./deploy_firebase.sh status`
4. Consultez l'interface d'administration web

---

**Note** : Ce système de gestion Firebase est conçu pour être robuste et automatisé. Les sauvegardes régulières et la maintenance automatique garantissent la stabilité de votre base de données.
