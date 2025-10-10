import 'package:flutter/material.dart';
import '../services/firebase_multiplayer_service.dart';
import '../services/player_name_service.dart';
import '../services/game_stats_service.dart';

/// Test direct pour vérifier les corrections du pseudo multijoueur
class DirectTestRunner {
  static Future<void> runAllTests() async {
    print('🧪 DÉBUT DES TESTS DIRECTS');
    print('');

    // Test 1: PlayerNameService
    await _testPlayerNameService();
    
    // Test 2: FirebaseMultiplayerService
    await _testFirebaseMultiplayerService();
    
    // Test 3: GameStatsService
    await _testGameStatsService();
    
    print('');
    print('🎉 TOUS LES TESTS TERMINÉS');
  }

  static Future<void> _testPlayerNameService() async {
    print('🧪 Test 1: PlayerNameService');
    
    try {
      final playerNameService = PlayerNameService();
      await playerNameService.initialize();
      
      final playerName = playerNameService.getPlayerNameOrDefault();
      print('ℹ️ Nom du joueur: $playerName');
      print('ℹ️ Nom défini: ${playerNameService.hasPlayerName}');
      
      // Tester la définition d'un nom
      final testName = 'TestPlayer${DateTime.now().millisecondsSinceEpoch}';
      final success = await playerNameService.setPlayerName(testName);
      
      if (success) {
        print('✅ Définition du nom réussie: $testName');
        final newName = playerNameService.getPlayerNameOrDefault();
        print('ℹ️ Nouveau nom: $newName');
      } else {
        print('❌ Échec de la définition du nom');
      }
      
    } catch (e) {
      print('❌ Erreur PlayerNameService: $e');
    }
    print('');
  }

  static Future<void> _testFirebaseMultiplayerService() async {
    print('🧪 Test 2: FirebaseMultiplayerService');
    
    try {
      final multiplayerService = FirebaseMultiplayerService();
      await multiplayerService.initialize();
      
      print('ℹ️ Player ID: ${multiplayerService.currentPlayerId}');
      print('ℹ️ Player Name: ${multiplayerService.currentPlayerName}');
      
      // Tester la mise à jour du nom
      await multiplayerService.updateCurrentPlayerName();
      print('ℹ️ Nom après mise à jour: ${multiplayerService.currentPlayerName}');
      
      print('✅ FirebaseMultiplayerService fonctionne');
      
    } catch (e) {
      print('❌ Erreur FirebaseMultiplayerService: $e');
    }
    print('');
  }

  static Future<void> _testGameStatsService() async {
    print('🧪 Test 3: GameStatsService');
    
    try {
      final gameStatsService = GameStatsService();
      
      // Tester une session de jeu
      gameStatsService.startGlobalGameSession(
        playerName: 'TestPlayer',
        gameMode: 'solo',
      );
      
      print('ℹ️ Session démarrée');
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      await gameStatsService.endGameSession(
        completed: true,
        score: 100,
        additionalData: {'test': true},
      );
      
      await gameStatsService.endGlobalGameSession();
      
      print('ℹ️ Session terminée');
      
      final completedSessions = gameStatsService.completedSessions;
      print('ℹ️ Sessions complétées: ${completedSessions.length}');
      
      if (completedSessions.isNotEmpty) {
        final lastSession = completedSessions.last;
        print('ℹ️ Dernière session: ${lastSession.playerName} - ${lastSession.gameRoom}');
        print('✅ GameStatsService fonctionne');
      } else {
        print('⚠️ Aucune session sauvegardée');
      }
      
    } catch (e) {
      print('❌ Erreur GameStatsService: $e');
    }
    print('');
  }
}
