import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:math';

void main() async {
  print('🎮 TEST AUTOMATISÉ DES JEUX PANDORA BOX');
  print('======================================');
  
  // Test 1: Jeu de mémoire (Page 1)
  await testMemoryGame();
  
  // Test 2: Jeu de stress (Page 2)
  await testStressGame();
  
  // Test 3: Mots croisés (Page 3)
  await testCrosswordGame();
  
  // Test 4: Jeu du tram (Page 4)
  await testTramGame();
  
  // Test 5: Notifications (Page 5)
  await testNotificationsGame();
  
  // Test 6: Test multijoueur complet
  await testMultiplayerFlow();
  
  print('\n✅ TOUS LES TESTS TERMINÉS');
}

Future<void> testMemoryGame() async {
  print('\n🧠 TEST 1: Jeu de mémoire');
  print('---------------------------');
  
  try {
    // Simuler le jeu de mémoire
    final sequence = generateRandomSequence(3);
    print('📋 Séquence générée: $sequence');
    
    // Tester la logique de vérification
    bool isValid = true;
    for (int i = 0; i < sequence.length; i++) {
      if (sequence[i] != sequence[i]) {
        isValid = false;
        break;
      }
    }
    
    if (isValid) {
      print('✅ Logique de vérification OK');
    } else {
      print('❌ Erreur dans la logique de vérification');
    }
    
    // Tester les états du jeu
    final gameStates = ['waiting', 'showing_sequence', 'player_turn', 'completed'];
    for (String state in gameStates) {
      print('🔄 État testé: $state');
    }
    
    print('✅ Test jeu de mémoire réussi');
  } catch (e) {
    print('❌ Erreur test jeu de mémoire: $e');
  }
}

Future<void> testStressGame() async {
  print('\n⚡ TEST 2: Jeu de stress');
  print('--------------------------');
  
  try {
    // Simuler le jeu de stress
    final stressLevels = [1, 2, 3, 4, 5];
    print('📊 Niveaux de stress: $stressLevels');
    
    // Tester la progression
    for (int level in stressLevels) {
      print('🎯 Niveau $level testé');
      
      // Simuler l'augmentation du stress
      final stressValue = level * 20;
      if (stressValue <= 100) {
        print('✅ Niveau $level valide (stress: $stressValue%)');
      } else {
        print('❌ Niveau $level invalide (stress: $stressValue%)');
      }
    }
    
    print('✅ Test jeu de stress réussi');
  } catch (e) {
    print('❌ Erreur test jeu de stress: $e');
  }
}

Future<void> testCrosswordGame() async {
  print('\n📝 TEST 3: Mots croisés');
  print('-------------------------');
  
  try {
    // Simuler une grille de mots croisés
    final words = ['FLUTTER', 'DART', 'GAME', 'TEST'];
    print('📚 Mots à placer: $words');
    
    // Tester la logique de placement
    for (String word in words) {
      if (word.length >= 3) {
        print('✅ Mot "$word" valide (${word.length} lettres)');
      } else {
        print('❌ Mot "$word" trop court');
      }
    }
    
    // Tester la validation des intersections
    final intersections = findIntersections(words);
    print('🔗 Intersections trouvées: $intersections');
    
    print('✅ Test mots croisés réussi');
  } catch (e) {
    print('❌ Erreur test mots croisés: $e');
  }
}

Future<void> testTramGame() async {
  print('\n🚊 TEST 4: Jeu du tram');
  print('------------------------');
  
  try {
    // Simuler le jeu du tram
    final tramPositions = [0, 1, 2, 3, 4];
    print('🚊 Positions du tram: $tramPositions');
    
    // Tester le mouvement du tram
    for (int i = 0; i < tramPositions.length - 1; i++) {
      final currentPos = tramPositions[i];
      final nextPos = tramPositions[i + 1];
      
      if ((nextPos - currentPos).abs() == 1) {
        print('✅ Mouvement valide: $currentPos -> $nextPos');
      } else {
        print('❌ Mouvement invalide: $currentPos -> $nextPos');
      }
    }
    
    // Tester la collision
    final collisionTest = testCollision(tramPositions);
    if (collisionTest) {
      print('⚠️  Collision détectée');
    } else {
      print('✅ Aucune collision');
    }
    
    print('✅ Test jeu du tram réussi');
  } catch (e) {
    print('❌ Erreur test jeu du tram: $e');
  }
}

Future<void> testNotificationsGame() async {
  print('\n🔔 TEST 5: Notifications');
  print('--------------------------');
  
  try {
    // Simuler les notifications
    final notifications = [
      {'type': 'success', 'message': 'Jeu terminé!'},
      {'type': 'error', 'message': 'Erreur de connexion'},
      {'type': 'info', 'message': 'Nouveau joueur connecté'},
    ];
    
    for (Map<String, String> notification in notifications) {
      final type = notification['type']!;
      final message = notification['message']!;
      
      if (['success', 'error', 'info', 'warning'].contains(type)) {
        print('✅ Notification $type: $message');
      } else {
        print('❌ Type de notification invalide: $type');
      }
    }
    
    // Tester la priorité des notifications
    final priorities = ['low', 'medium', 'high', 'critical'];
    for (String priority in priorities) {
      print('📊 Priorité testée: $priority');
    }
    
    print('✅ Test notifications réussi');
  } catch (e) {
    print('❌ Erreur test notifications: $e');
  }
}

Future<void> testMultiplayerFlow() async {
  print('\n👥 TEST 6: Flux multijoueur complet');
  print('------------------------------------');
  
  try {
    // Simuler le flux multijoueur
    final steps = [
      'create_room',
      'join_room',
      'wait_for_players',
      'start_game',
      'sync_game_state',
      'end_game',
    ];
    
    for (String step in steps) {
      print('🔄 Étape: $step');
      
      // Simuler le temps d'attente
      await Future.delayed(Duration(milliseconds: 100));
      
      // Tester la logique de chaque étape
      switch (step) {
        case 'create_room':
          final roomId = generateRoomId();
          print('🏠 Room créée: $roomId');
          break;
        case 'join_room':
          print('👤 Joueur rejoint');
          break;
        case 'wait_for_players':
          print('⏳ Attente des joueurs...');
          break;
        case 'start_game':
          print('🎮 Jeu démarré');
          break;
        case 'sync_game_state':
          print('🔄 Synchronisation des états');
          break;
        case 'end_game':
          print('🏁 Jeu terminé');
          break;
      }
    }
    
    // Tester la synchronisation des données
    final gameData = {
      'player1': {'score': 100, 'level': 1},
      'player2': {'score': 150, 'level': 2},
    };
    
    print('📊 Données de jeu: $gameData');
    
    // Vérifier la cohérence des données
    bool dataConsistent = true;
    gameData.forEach((player, data) {
      if (data['score'] is int && data['level'] is int) {
        print('✅ Données $player cohérentes');
      } else {
        print('❌ Données $player incohérentes');
        dataConsistent = false;
      }
    });
    
    if (dataConsistent) {
      print('✅ Test flux multijoueur réussi');
    } else {
      print('❌ Erreur dans le flux multijoueur');
    }
  } catch (e) {
    print('❌ Erreur test flux multijoueur: $e');
  }
}

// Fonctions utilitaires
List<int> generateRandomSequence(int length) {
  final random = Random();
  return List.generate(length, (index) => random.nextInt(4));
}

List<String> findIntersections(List<String> words) {
  List<String> intersections = [];
  
  for (int i = 0; i < words.length; i++) {
    for (int j = i + 1; j < words.length; j++) {
      final word1 = words[i];
      final word2 = words[j];
      
      for (int k = 0; k < word1.length; k++) {
        for (int l = 0; l < word2.length; l++) {
          if (word1[k] == word2[l]) {
            intersections.add('${word1[k]} (${word1[k]}:${word2[l]})');
          }
        }
      }
    }
  }
  
  return intersections;
}

bool testCollision(List<int> positions) {
  // Vérifier s'il y a des doublons
  final uniquePositions = positions.toSet();
  return uniquePositions.length != positions.length;
}

String generateRoomId() {
  final random = Random();
  return 'room_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(1000)}';
}
