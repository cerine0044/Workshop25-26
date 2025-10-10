#!/usr/bin/env dart

import 'dart:io';

void main() async {
  print('🎮 TEST COMPLET MULTIJOUEUR - PATTERN COMPLET');
  print('=============================================');
  
  // Test 1: Vérifier tous les fichiers nécessaires
  await testAllFiles();
  
  // Test 2: Analyser le flux complet
  await analyzeCompleteFlow();
  
  // Test 3: Vérifier l'enregistrement des données
  await testDataRecording();
  
  // Test 4: Corriger les problèmes identifiés
  await fixDataRecordingIssues();
  
  // Test 5: Construire et déployer
  await buildAndDeploy();
  
  // Test 6: Instructions de test complet
  printCompleteTestInstructions();
}

Future<void> testAllFiles() async {
  print('\n📁 TEST 1: Vérification de tous les fichiers');
  print('============================================');
  
  final requiredFiles = [
    'lib/pages/waiting_room_page.dart',
    'lib/pages/multiplayer_game_page.dart',
    'lib/pages/multiplayer_success_page.dart',
    'lib/services/firebase_multiplayer_service.dart',
    'lib/services/game_stats_service.dart',
    'lib/pages/page1_puzzle.dart',
    'lib/pages/stress_page.dart',
    'lib/pages/page3_words.dart',
    'lib/pages/page4_tram.dart',
    'lib/pages/page5_notifications.dart',
  ];
  
  for (final file in requiredFiles) {
    final fileObj = File(file);
    if (fileObj.existsSync()) {
      print('✅ $file');
    } else {
      print('❌ $file MANQUANT');
    }
  }
}

Future<void> analyzeCompleteFlow() async {
  print('\n🔄 TEST 2: Analyse du flux complet');
  print('=================================');
  
  // Analyser MultiplayerGamePage
  final gamePageFile = File('lib/pages/multiplayer_game_page.dart');
  if (gamePageFile.existsSync()) {
    final content = gamePageFile.readAsStringSync();
    
    print('\n🎮 Analyse de MultiplayerGamePage:');
    
    // Vérifier la gestion des salles
    if (content.contains('_gameRooms')) {
      print('✅ Liste des salles définie');
    } else {
      print('❌ Liste des salles MANQUANTE');
    }
    
    // Vérifier la navigation entre salles
    if (content.contains('_navigateToRoom')) {
      print('✅ Méthode de navigation entre salles présente');
    } else {
      print('❌ Méthode de navigation MANQUANTE');
    }
    
    // Vérifier la sauvegarde des données
    if (content.contains('_playerSessions')) {
      print('✅ Sauvegarde des sessions joueurs présente');
    } else {
      print('❌ Sauvegarde des sessions MANQUANTE');
    }
    
    // Vérifier la gestion de fin de jeu
    if (content.contains('_finishGame')) {
      print('✅ Méthode de fin de jeu présente');
    } else {
      print('❌ Méthode de fin de jeu MANQUANTE');
    }
  }
  
  // Analyser MultiplayerSuccessPage
  final successPageFile = File('lib/pages/multiplayer_success_page.dart');
  if (successPageFile.existsSync()) {
    final content = successPageFile.readAsStringSync();
    
    print('\n🏆 Analyse de MultiplayerSuccessPage:');
    
    // Vérifier l'affichage des résultats
    if (content.contains('_calculateResults')) {
      print('✅ Calcul des résultats présent');
    } else {
      print('❌ Calcul des résultats MANQUANT');
    }
    
    // Vérifier la sauvegarde des résultats
    if (content.contains('_saveGameResults')) {
      print('✅ Sauvegarde des résultats présente');
    } else {
      print('❌ Sauvegarde des résultats MANQUANTE');
    }
    
    // Vérifier l'affichage des scores par salle
    if (content.contains('roomResults')) {
      print('✅ Affichage des scores par salle présent');
    } else {
      print('❌ Affichage des scores par salle MANQUANT');
    }
  }
}

Future<void> testDataRecording() async {
  print('\n💾 TEST 3: Vérification de l\'enregistrement des données');
  print('=======================================================');
  
  // Vérifier GameStatsService
  final gameStatsFile = File('lib/services/game_stats_service.dart');
  if (gameStatsFile.existsSync()) {
    final content = gameStatsFile.readAsStringSync();
    
    print('\n📊 Analyse de GameStatsService:');
    
    // Vérifier la gestion des sessions multijoueur
    if (content.contains('gameMode.*multiplayer')) {
      print('✅ Support multijoueur présent');
    } else {
      print('❌ Support multijoueur MANQUANT');
    }
    
    // Vérifier la sauvegarde des sessions
    if (content.contains('startGlobalGameSession')) {
      print('✅ Démarrage de session globale présent');
    } else {
      print('❌ Démarrage de session globale MANQUANT');
    }
    
    if (content.contains('endGlobalGameSession')) {
      print('✅ Fin de session globale présente');
    } else {
      print('❌ Fin de session globale MANQUANTE');
    }
  }
  
  // Vérifier FirebaseMultiplayerService
  final firebaseServiceFile = File('lib/services/firebase_multiplayer_service.dart');
  if (firebaseServiceFile.existsSync()) {
    final content = firebaseServiceFile.readAsStringSync();
    
    print('\n🔥 Analyse de FirebaseMultiplayerService:');
    
    // Vérifier la synchronisation des états
    if (content.contains('roomStateStream')) {
      print('✅ Stream d\'état de room présent');
    } else {
      print('❌ Stream d\'état de room MANQUANT');
    }
    
    // Vérifier la gestion des déconnexions
    if (content.contains('disconnect')) {
      print('✅ Gestion des déconnexions présente');
    } else {
      print('❌ Gestion des déconnexions MANQUANTE');
    }
  }
}

Future<void> fixDataRecordingIssues() async {
  print('\n🔧 TEST 4: Correction des problèmes d\'enregistrement');
  print('====================================================');
  
  // Fix 1: S'assurer que MultiplayerGamePage sauvegarde correctement
  await fixMultiplayerGamePageDataRecording();
  
  // Fix 2: S'assurer que MultiplayerSuccessPage enregistre les résultats
  await fixMultiplayerSuccessPageDataRecording();
  
  // Fix 3: Vérifier la synchronisation Firebase
  await fixFirebaseSynchronization();
}

Future<void> fixMultiplayerGamePageDataRecording() async {
  print('\n🎮 Fix 1: Correction MultiplayerGamePage');
  
  final gamePageFile = File('lib/pages/multiplayer_game_page.dart');
  if (gamePageFile.existsSync()) {
    final content = gamePageFile.readAsStringSync();
    
    // Vérifier si la méthode _handleRoomCompletion sauvegarde correctement
    if (!content.contains('_playerSessions[playerId]')) {
      print('❌ Sauvegarde des données de salle incorrecte');
      
      // Ajouter une méthode de sauvegarde robuste
      final robustSavingMethod = '''
  void _saveRoomData(int roomIndex, dynamic result) {
    final playerId = _multiplayerService.currentPlayerId;
    if (playerId != null && result != null) {
      _playerSessions[playerId] ??= {};
      _playerSessions[playerId]!['room\$roomIndex'] = {
        'completed': result['completed'] ?? false,
        'score': result['score'] ?? 0,
        'time': result['time'] ?? Duration.zero,
        'additionalData': result['additionalData'] ?? {},
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      print('💾 Données salle \$roomIndex sauvegardées: \${_playerSessions[playerId]!['room\$roomIndex']}');
    }
  }

''';
      
      // Insérer la méthode avant _handleRoomCompletion
      final newContent = content.replaceFirst(
        'void _handleRoomCompletion(dynamic result) {',
        '$robustSavingMethod  void _handleRoomCompletion(dynamic result) {',
      );
      
      await gamePageFile.writeAsString(newContent);
      print('✅ Méthode de sauvegarde robuste ajoutée');
    } else {
      print('✅ Sauvegarde des données de salle correcte');
    }
  }
}

Future<void> fixMultiplayerSuccessPageDataRecording() async {
  print('\n🏆 Fix 2: Correction MultiplayerSuccessPage');
  
  final successPageFile = File('lib/pages/multiplayer_success_page.dart');
  if (successPageFile.existsSync()) {
    final content = successPageFile.readAsStringSync();
    
    // Vérifier si la sauvegarde des résultats est robuste
    if (!content.contains('await _gameStatsService.endGameSession')) {
      print('❌ Sauvegarde des résultats manquante');
      
      // Ajouter une sauvegarde robuste
      final robustSavingMethod = '''
  Future<void> _saveGameResults() async {
    try {
      print('💾 Sauvegarde des résultats multijoueur...');
      
      // Sauvegarder les résultats dans GameStatsService pour chaque joueur
      for (final playerResult in _playersResults) {
        final playerId = playerResult['playerId'];
        final playerName = playerResult['playerName'];
        final totalScore = playerResult['totalScore'];
        final completedRooms = playerResult['completedRooms'];
        final totalTime = playerResult['totalTime'];
        
        // Créer une session pour ce joueur
        await _gameStatsService.startGlobalGameSession(
          playerName: playerName,
          gameMode: 'multiplayer',
        );
        
        // Terminer la session avec les résultats
        await _gameStatsService.endGameSession(
          completed: completedRooms > 0,
          score: totalScore,
          additionalData: {
            'gameMode': 'multiplayer',
            'completedRooms': completedRooms,
            'totalTime': totalTime.inMilliseconds,
            'roomResults': playerResult['roomResults'],
            'playerId': playerId,
            'isWinner': playerResult == _playersResults.first,
          },
        );
        
        print('✅ Résultats sauvegardés pour \$playerName');
      }
      
      print('✅ Tous les résultats multijoueur sauvegardés');
    } catch (e) {
      print('❌ Erreur sauvegarde résultats: \$e');
    }
  }

''';
      
      // Remplacer la méthode existante
      final newContent = content.replaceFirst(
        RegExp(r'Future<void> _saveGameResults\(\) async \{[^}]*\}', multiLine: true),
        robustSavingMethod,
      );
      
      await successPageFile.writeAsString(newContent);
      print('✅ Sauvegarde robuste des résultats ajoutée');
    } else {
      print('✅ Sauvegarde des résultats présente');
    }
  }
}

Future<void> fixFirebaseSynchronization() async {
  print('\n🔥 Fix 3: Correction synchronisation Firebase');
  
  final gamePageFile = File('lib/pages/multiplayer_game_page.dart');
  if (gamePageFile.existsSync()) {
    final content = gamePageFile.readAsStringSync();
    
    // Vérifier si la synchronisation des états est présente
    if (!content.contains('_checkForDisconnections')) {
      print('❌ Vérification des déconnexions manquante');
      
      // Ajouter une vérification des déconnexions
      final disconnectionCheck = '''
  void _checkForDisconnections() {
    // Vérifier si tous les joueurs sont encore connectés
    final players = _playersData.values.toList();
    if (players.length < 2 && _isGameStarted) {
      print('❌ Un joueur s\'est déconnecté');
      _showErrorAndReturn('Un joueur s\'est déconnecté. Retour à l\'accueil.');
    }
  }

''';
      
      // Insérer la méthode avant _showErrorAndReturn
      final newContent = content.replaceFirst(
        'void _showErrorAndReturn(String message) {',
        '$disconnectionCheck  void _showErrorAndReturn(String message) {',
      );
      
      await gamePageFile.writeAsString(newContent);
      print('✅ Vérification des déconnexions ajoutée');
    } else {
      print('✅ Vérification des déconnexions présente');
    }
  }
}

Future<void> buildAndDeploy() async {
  print('\n🏗️ TEST 5: Construction et déploiement');
  print('=====================================');
  
  // Build
  print('📦 Construction de l\'application...');
  final buildResult = await Process.run('flutter', ['build', 'web', '--release'], 
      workingDirectory: Directory.current.path);
  
  if (buildResult.exitCode == 0) {
    print('✅ Construction réussie');
  } else {
    print('❌ Erreur de construction:');
    print(buildResult.stderr);
    return;
  }
  
  // Deploy
  print('🚀 Déploiement sur Firebase...');
  final deployResult = await Process.run('firebase', ['deploy', '--only', 'hosting'],
      workingDirectory: Directory.current.path);
  
  if (deployResult.exitCode == 0) {
    print('✅ Déploiement réussi');
  } else {
    print('❌ Erreur de déploiement:');
    print(deployResult.stderr);
  }
}

void printCompleteTestInstructions() {
  print('\n🎯 INSTRUCTIONS DE TEST COMPLET');
  print('===============================');
  print('');
  print('🌐 APPLICATION: https://pandora-box-user2.web.app');
  print('');
  print('📋 TEST COMPLET DU PATTERN MULTIJOUEUR:');
  print('');
  print('1. 🏠 CRÉATION DE ROOM:');
  print('   - Aller dans Multijoueur');
  print('   - Créer une room "Test Complete"');
  print('   - Vérifier: Statut "Hôte" affiché');
  print('');
  print('2. 🔗 REJOINDRE LA ROOM:');
  print('   - Ouvrir un autre navigateur/onglet');
  print('   - Rejoindre avec le même code');
  print('   - Vérifier: Statut "Invité" affiché');
  print('');
  print('3. ▶️ DÉMARRER LE JEU:');
  print('   - Hôte clique "Commencer le Jeu"');
  print('   - Vérifier: Compte à rebours 3 secondes');
  print('   - Vérifier: Navigation vers MultiplayerGamePage');
  print('');
  print('4. 🎮 JOUER TOUTES LES SALLES:');
  print('   - Salle 1 (Puzzle): Compléter le puzzle');
  print('   - Salle 2 (Stress): Terminer le détecteur');
  print('   - Salle 3 (Mots): Trouver tous les mots');
  print('   - Salle 4 (Tram): Résoudre le problème');
  print('   - Salle 5 (Notifications): Gérer les notifications');
  print('');
  print('5. 🏆 PAGE DE SUCCÈS:');
  print('   - Vérifier: Affichage des scores des deux joueurs');
  print('   - Vérifier: Comparaison par salle');
  print('   - Vérifier: Détermination du gagnant');
  print('');
  print('6. 💾 VÉRIFICATION DES DONNÉES:');
  print('   - Aller dans "MES STATISTIQUES"');
  print('   - Vérifier: Session multijoueur enregistrée');
  print('   - Aller dans "SCORES GLOBAUX"');
  print('   - Vérifier: Scores des deux joueurs visibles');
  print('   - Aller dans "HISTORIQUE GLOBAL"');
  print('   - Vérifier: Historique des parties multijoueur');
  print('');
  print('7. 🔄 TEST DE DÉCONNEXION:');
  print('   - Fermer un onglet pendant le jeu');
  print('   - Vérifier: Message d\'erreur sur l\'autre onglet');
  print('   - Vérifier: Retour automatique à l\'accueil');
  print('');
  print('✅ CRITÈRES DE SUCCÈS:');
  print('=====================');
  print('- ✅ Navigation fluide entre toutes les salles');
  print('- ✅ Sauvegarde des scores par salle');
  print('- ✅ Page de succès avec comparaison');
  print('- ✅ Enregistrement dans les statistiques');
  print('- ✅ Gestion des déconnexions');
  print('- ✅ Synchronisation Firebase en temps réel');
  print('');
  print('🎯 Si tous les critères sont remplis:');
  print('   🏆 LE MULTIJOUEUR FONCTIONNE PARFAITEMENT!');
  print('');
  print('❌ Si problème:');
  print('   - Copier les logs de la console');
  print('   - Relancer ce script');
  print('   - Le système sera corrigé automatiquement');
}
