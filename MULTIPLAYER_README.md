# Mode Multijoueur - Pandora Box

## Description
Le mode multijoueur permet à plusieurs joueurs de se connecter à la même room de jeu via leurs navigateurs web respectifs.

## Fonctionnalités

### Gestion des Rooms
- **Créer une room** : Un joueur peut créer une nouvelle room avec un nom personnalisé
- **Rejoindre une room** : Les autres joueurs peuvent rejoindre une room existante via son ID
- **Liste des rooms** : Affichage en temps réel des rooms disponibles
- **Quitter une room** : Possibilité de quitter la room à tout moment

### Synchronisation en Temps Réel
- **État des joueurs** : Suivi en temps réel de l'état de préparation de chaque joueur
- **Gestion de l'hôte** : Transfert automatique du rôle d'hôte si nécessaire
- **État du jeu** : Synchronisation de l'état du jeu entre tous les joueurs

## Comment Utiliser

### 1. Démarrer l'Application
```bash
flutter run -d web-server --web-port 8080
```

### 2. Accéder à l'Application
Ouvrez votre navigateur et allez à : `http://localhost:8080`

### 3. Mode Multijoueur
1. Cliquez sur "START" sur la page d'accueil
2. Sélectionnez "MODE MULTIJOUEUR"
3. Vous arrivez sur la page de gestion des rooms

### 4. Créer une Room (Joueur 1)
1. Entrez un nom pour votre room dans le champ "Nom de la room"
2. Cliquez sur "Créer la room"
3. Notez l'ID de la room qui s'affiche
4. Partagez cet ID avec les autres joueurs

### 5. Rejoindre une Room (Joueurs 2+)
1. Entrez l'ID de la room dans le champ "ID de la room"
2. Cliquez sur "Rejoindre"
3. Ou sélectionnez une room dans la liste des "Rooms disponibles"

### 6. Gestion de la Room
- **État de préparation** : Cliquez sur "Prêt/Non prêt" pour indiquer votre statut
- **Liste des joueurs** : Voir tous les joueurs connectés et leur état
- **Quitter** : Cliquez sur "Quitter" pour quitter la room

## Architecture Technique

### Services
- **FirebaseService** : Interface principale pour la gestion des rooms
- **LocalGameService** : Service local de simulation pour le développement
- **Mode de développement** : Utilise le service local par défaut

### Structure des Données
```json
{
  "id": "room_id",
  "name": "Nom de la room",
  "host": "user_id",
  "hostName": "Nom du joueur",
  "players": {
    "user_id": {
      "name": "Nom du joueur",
      "isHost": true,
      "isReady": false,
      "joinedAt": "2024-01-01T00:00:00.000Z"
    }
  },
  "gameState": "waiting",
  "createdAt": "2024-01-01T00:00:00.000Z"
}
```

## Développement

### Mode Local (Développement)
Le service utilise un mode local par défaut qui simule Firebase sans nécessiter de configuration réelle.

### Mode Firebase (Production)
Pour utiliser Firebase réel, modifiez dans `firebase_service.dart` :
```dart
static bool _useLocalService = false; // Passer à false pour Firebase réel
```

### Configuration Firebase
1. Créez un projet Firebase
2. Activez Firebase Realtime Database
3. Configurez les règles de sécurité
4. Mettez à jour `firebase_options.dart` avec vos clés

## Limitations Actuelles
- Mode local uniquement (pas de Firebase réel configuré)
- Pas de synchronisation des jeux individuels (puzzle, crossword, etc.)
- Pas de chat intégré
- Pas de gestion des déconnexions inattendues

## Prochaines Étapes
1. Intégrer la synchronisation des jeux individuels
2. Ajouter un système de chat
3. Implémenter la gestion des déconnexions
4. Configurer Firebase réel pour la production
5. Ajouter des animations et effets visuels
