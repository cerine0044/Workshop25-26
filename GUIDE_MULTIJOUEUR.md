# Guide Multijoueur - Pandora Box

## Nouvelles Fonctionnalités Implémentées

### 1. Détection des Joueurs dans le Salon
- **Fonctionnalité** : Le système détecte automatiquement le nombre de joueurs présents dans une room
- **Affichage** : Compteur "Joueurs: X/2" avec indicateur visuel
- **États** :
  - 🟠 "En attente..." quand moins de 2 joueurs
  - 🟢 "Prêt !" quand 2 joueurs sont présents

### 2. Redirection Automatique
- **Déclenchement** : Dès que 2 joueurs rejoignent une room
- **Action** : Affichage d'un dialogue de confirmation pour démarrer le jeu
- **Options** :
  - "Attendre" : Continuer à attendre
  - "DÉMARRER" : Lancer le compte à rebours

### 3. Chrono de Démarrage
- **Durée** : 3 secondes de compte à rebours
- **Interface** : Écran plein avec animation circulaire
- **Synchronisation** : Mise à jour de l'état du jeu sur le serveur

### 4. Redirection vers Salle 1
- **Déclenchement** : À la fin du compte à rebours
- **Destination** : Page1Puzzle en mode multijoueur
- **Paramètres** : Passage de `isMultiplayer: true` et `roomId`

## Flux de Jeu Multijoueur

```
1. Créer/Rejoindre une Room
   ↓
2. Attendre le 2ème joueur
   ↓
3. Dialogue de démarrage automatique
   ↓
4. Compte à rebours (3 secondes)
   ↓
5. Redirection vers Salle 1 (Page1Puzzle)
   ↓
6. Démarrage automatique du jeu de mémoire
```

## Interface Utilisateur

### Room Management Page
- **Compteur de joueurs** : Affichage en temps réel du nombre de joueurs
- **Indicateur d'état** : Icônes visuelles pour l'état d'attente/prêt
- **Bouton de démarrage** : Apparaît quand 2 joueurs sont présents
- **Écran de compte à rebours** : Interface immersive pour le démarrage

### Page1Puzzle (Mode Multijoueur)
- **Démarrage automatique** : Le jeu commence immédiatement
- **Paramètres multijoueur** : Support des rooms et synchronisation

## États du Jeu

- `waiting` : En attente de joueurs
- `starting` : Compte à rebours en cours
- `playing` : Jeu en cours

## Synchronisation Serveur

- Mise à jour automatique de l'état du jeu
- Synchronisation des joueurs en temps réel
- Gestion des déconnexions et reconnexions

## Utilisation

1. **Créer une room** : Entrer un nom et cliquer "Créer la room"
2. **Rejoindre une room** : Entrer l'ID de room ou cliquer sur une room disponible
3. **Attendre** : Le système détecte automatiquement le 2ème joueur
4. **Démarrer** : Confirmer le démarrage dans le dialogue
5. **Jouer** : Le jeu commence automatiquement après le compte à rebours

## Notes Techniques

- Utilisation de `Timer` pour le compte à rebours
- Gestion des états avec `setState()`
- Navigation avec `pushReplacement` pour éviter le retour
- Synchronisation via `HttpGameService`
- Support des paramètres multijoueur dans `Page1Puzzle`
