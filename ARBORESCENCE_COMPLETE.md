# ARBORESCENCE COMPLÈTE - PANDORA BOX

## Vue d'ensemble
Pandora Box est un jeu de sensibilisation sur le stress numérique, le RGPD, le harcèlement et la désinformation. L'objectif est de libérer l'influenceur du stress en passant par différentes épreuves chronométrées.

## Structure des pages

### 1. Page d'accueil (GameModeSelectionPage)
- **Fichier**: `lib/main.dart`
- **Fonction**: Sélection du mode de jeu (Solo/Multijoueur)
- **Navigation**: Vers StartPage

### 2. Page START (StartPage)
- **Fichier**: `lib/pages/start_page.dart`
- **Fonction**: 
  - Chronomètre global commence dès l'appui sur START
  - Bouton stressant avec effets visuels
  - Avertissement épilepsie
  - Compte à rebours 3-2-1
- **Navigation**: Vers Page1Puzzle

### 3. Page 1 - Boutons cachés (Page1Puzzle)
- **Fichier**: `lib/pages/page1_puzzle.dart`
- **Fonction**:
  - Jeu de mémoire avec 4 boutons à trouver
  - Séquence à reproduire
  - BoutonFinal apparaît après 4/4 boutons trouvés
- **Navigation**: Vers StressPage

### 4. Page 2 - Détecteur de stress (StressPage)
- **Fichier**: `lib/pages/stress_page.dart`
- **Fonction**:
  - Détection de mouvement avec accéléromètre
  - Flash du téléphone réactif
  - Seuil de stress à atteindre (65%)
  - BoutonFinal2 apparaît au seuil atteint
- **Navigation**: Vers Page3Crossword

### 5. Page 3 - Mots fléchés RGPD (Page3Crossword)
- **Fichier**: `lib/pages/page3_crossword.dart`
- **Fonction**:
  - Grille 10x10 avec 10 mots RGPD
  - Interface avec définitions
  - Validation ligne par ligne
  - BoutonFinal3 après complétion
- **Navigation**: Vers Page4Tram

### 6. Page 4 - Dilemme du tramway (Page4Tram)
- **Fichier**: `lib/pages/page4_tram.dart`
- **Fonction**:
  - 20 questions de dilemme moral
  - Timer par question (12 secondes)
  - Images stressantes en overlay
  - Son de corne de bateau
  - BoutonFinal4 après toutes les questions
- **Navigation**: Vers Page5Notifications

### 7. Page 5 - Notifications (Page5Notifications)
- **Fichier**: `lib/pages/page5_notifications.dart`
- **Fonction**:
  - Liste de notifications à décocher
  - Son stressant et fort
  - Flash visuel de couleurs
  - Intensité diminue avec les décoches
- **Navigation**: Vers CalmSuccessPage

### 8. Page de succès (CalmSuccessPage)
- **Fichier**: `lib/pages/page5_success.dart`
- **Fonction**:
  - Page blanche et calme
  - Message de réussite
  - Sensibilisation à la paix numérique

## Fichiers de configuration

### GameConfig (`lib/config/game_config.dart`)
- Configuration centralisée des paramètres
- Messages et textes
- Couleurs du thème
- Sons et images

### GameNavigation (`lib/navigation/game_navigation.dart`)
- Gestion centralisée de la navigation
- Routes nommées
- Méthodes utilitaires

## Fonctionnalités principales

### Chronomètre global
- Démarre dès l'appui sur START
- Suivi du temps total de jeu
- Classement des joueurs par temps

### Mode multijoueur
- Synchronisation en temps réel
- Attente des autres joueurs
- Gestion des salles

### Effets sensoriels
- Flash du téléphone
- Vibrations haptiques
- Sons stressants
- Effets visuels épileptogènes

### Sensibilisation
- RGPD et protection des données
- Harcèlement numérique
- Burnout et stress
- Désinformation

## Navigation entre pages

```
GameModeSelectionPage
    ↓
StartPage (chrono commence)
    ↓
Page1Puzzle (4 boutons)
    ↓
StressPage (détecteur stress)
    ↓
Page3Crossword (10 mots RGPD)
    ↓
Page4Tram (20 questions)
    ↓
Page5Notifications (décocher)
    ↓
CalmSuccessPage (succès)
```

## Technologies utilisées

- **Flutter**: Framework principal
- **Sensors Plus**: Détection de mouvement
- **Torch Light**: Flash du téléphone
- **Audio Players**: Sons et effets
- **WebSocket**: Communication multijoueur
- **Firebase**: Synchronisation (optionnel)

## Avertissements

- ⚠️ **Épilepsie**: Effets lumineux pouvant déclencher des crises
- 🔊 **Son**: Sons forts et stressants
- 📱 **Flash**: Utilisation du flash du téléphone
- ⏱️ **Temps**: Jeu chronométré avec pression temporelle
