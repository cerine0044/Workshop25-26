# Guide Multijoueur Mis à Jour - Pandora Box

## Nouveau Flux de Jeu

### 1. Page d'Accueil
- **Affichage direct** : Choix de mode (Solo/Multijoueur)
- **Mode Solo** → Page Start → Chrono → Salle 1, etc.
- **Mode Multijoueur** → Gestion des Rooms → Page Start → Synchronisation

### 2. Mode Solo
```
Page d'accueil → Mode Solo → Page Start → Chrono (3s) → Salle 1 → Jeu automatique
```

### 3. Mode Multijoueur
```
Page d'accueil → Mode Multijoueur → Room Management → 
Créer/Rejoindre Room → Attente 2 joueurs → Page Start → 
Synchronisation → Chrono → Salle 1 → Jeu synchronisé
```

## Fonctionnalités Implémentées

### ✅ Page Start Commune
- **Interface unifiée** : Même design pour solo et multijoueur
- **Chrono automatique** : Se déclenche dès le bouton START cliqué
- **Synchronisation multijoueur** : Attente des 2 joueurs avant démarrage
- **États visuels** : Indicateurs d'attente et de démarrage

### ✅ Synchronisation des Salles
- **Interfaces séparées** : Chaque joueur a sa propre interface
- **Progrès partagés** : Affichage des scores de l'autre joueur
- **Attente mutuelle** : Le joueur qui termine attend l'autre
- **Ordre des salles** : Même séquence pour tous les joueurs

### ✅ Gestion des États
- `waiting` : En attente de joueurs
- `ready_to_start` : Prêt à aller à la page Start
- `starting` : Compte à rebours en cours
- `playing` : Jeu en cours avec synchronisation

## Détails Techniques

### Page Start (`start_page.dart`)
```dart
class StartPage extends StatefulWidget {
  final bool isMultiplayer;
  final String? roomId;
}
```

**Fonctionnalités :**
- Chrono de 3 secondes avec animation
- Synchronisation multijoueur via WebSocket/HTTP
- Redirection automatique vers Page1Puzzle
- Gestion des états d'attente

### Page1Puzzle Multijoueur
**Nouvelles fonctionnalités :**
- `_listenToRoom()` : Écoute les changements de room
- `_updateMyProgress()` : Met à jour les progrès du joueur
- `_checkOtherPlayerProgress()` : Vérifie les progrès de l'autre joueur
- `_checkIfCanContinue()` : Vérifie si on peut passer à la salle suivante

**Interface utilisateur :**
- Indicateur des progrès de l'autre joueur
- Dialogue d'attente quand l'autre joueur n'a pas terminé
- Synchronisation automatique des transitions

### Room Management
**Modifications :**
- Redirection vers Page Start au lieu de démarrer directement
- État `ready_to_start` au lieu de `starting`
- Bouton "ALLER À START" au lieu de "DÉMARRER LE JEU"

## Flux Détaillé Multijoueur

### 1. Création/Rejoindre Room
- Créer une room ou rejoindre une existante
- Attendre le 2ème joueur (indicateur visuel)

### 2. Page Start Synchronisée
- Les 2 joueurs arrivent sur la page Start
- Un joueur clique START → Attente de l'autre joueur
- Quand les 2 sont prêts → Chrono synchronisé (3 secondes)

### 3. Salle 1 (Jeu de Mémoire)
- Chaque joueur joue de son côté
- Affichage des progrès de l'autre joueur
- Synchronisation des scores en temps réel

### 4. Transition vers Salle 2
- Le joueur qui termine attend l'autre
- Dialogue d'attente si nécessaire
- Transition synchronisée vers StressPage

## États de Synchronisation

### En Mode Multijoueur
- **Progrès partagés** : Score, étape actuelle, état du jeu
- **Attente mutuelle** : Pas de progression sans l'autre joueur
- **Interface commune** : Même visuel mais données séparées

### En Mode Solo
- **Progression libre** : Pas d'attente
- **Interface standard** : Pas de synchronisation

## Utilisation

### Mode Solo
1. Page d'accueil → "MODE SOLO"
2. Page Start → Cliquer "START"
3. Chrono → Redirection automatique
4. Jeu normal sans synchronisation

### Mode Multijoueur
1. Page d'accueil → "MODE MULTIJOUEUR"
2. Room Management → Créer/Rejoindre
3. Attendre 2 joueurs → "ALLER À START"
4. Page Start → Synchronisation → Chrono
5. Jeu avec synchronisation des progrès

## Avantages du Nouveau Système

- **Flexibilité** : Même interface pour solo et multijoueur
- **Synchronisation** : Progrès partagés en temps réel
- **Attente intelligente** : Pas de progression prématurée
- **Interface claire** : Indicateurs visuels pour l'état du jeu
- **Expérience fluide** : Transitions automatiques entre les salles
