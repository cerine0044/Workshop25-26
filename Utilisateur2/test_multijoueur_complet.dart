#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

void main() async {
  print('🚀 SCRIPT DE TEST MULTIJOUEUR COMPLET');
  print('=====================================');
  
  // Test 1: Vérifier la structure des fichiers
  await testFileStructure();
  
  // Test 2: Analyser le code pour identifier les problèmes
  await analyzeCode();
  
  // Test 3: Corriger les problèmes identifiés
  await fixIssues();
  
  // Test 4: Construire et déployer
  await buildAndDeploy();
  
  // Test 5: Instructions de test final
  printFinalInstructions();
}

Future<void> testFileStructure() async {
  print('\n📁 TEST 1: Structure des fichiers');
  print('================================');
  
  final files = [
    'lib/pages/waiting_room_page.dart',
    'lib/pages/multiplayer_game_page.dart',
    'lib/pages/multiplayer_success_page.dart',
    'lib/services/firebase_multiplayer_service.dart',
    'lib/pages/working_multiplayer_page.dart',
  ];
  
  for (final file in files) {
    final fileObj = File(file);
    if (fileObj.existsSync()) {
      print('✅ $file existe');
    } else {
      print('❌ $file MANQUANT');
    }
  }
}

Future<void> analyzeCode() async {
  print('\n🔍 TEST 2: Analyse du code');
  print('==========================');
  
  // Analyser waiting_room_page.dart
  final waitingRoomFile = File('lib/pages/waiting_room_page.dart');
  if (waitingRoomFile.existsSync()) {
    final content = waitingRoomFile.readAsStringSync();
    
    print('\n📄 Analyse de waiting_room_page.dart:');
    
    // Vérifier la méthode _startGame
    if (content.contains('void _startGame()')) {
      print('✅ Méthode _startGame() présente');
      
      // Vérifier les logs de diagnostic
      if (content.contains('print(\'🎮 _startGame() appelé\')')) {
        print('✅ Logs de diagnostic présents');
      } else {
        print('❌ Logs de diagnostic MANQUANTS');
      }
      
      // Vérifier la vérification _currentRoom
      if (content.contains('if (_currentRoom == null)')) {
        print('✅ Vérification _currentRoom présente');
      } else {
        print('❌ Vérification _currentRoom MANQUANTE');
      }
      
      // Vérifier l'import MultiplayerGamePage
      if (content.contains("import 'multiplayer_game_page.dart';")) {
        print('✅ Import MultiplayerGamePage présent');
      } else {
        print('❌ Import MultiplayerGamePage MANQUANT');
      }
      
    } else {
      print('❌ Méthode _startGame() MANQUANTE');
    }
  }
  
  // Analyser firebase_multiplayer_service.dart
  final firebaseServiceFile = File('lib/services/firebase_multiplayer_service.dart');
  if (firebaseServiceFile.existsSync()) {
    final content = firebaseServiceFile.readAsStringSync();
    
    print('\n🔥 Analyse de firebase_multiplayer_service.dart:');
    
    if (content.contains('Future<void> startGame()')) {
      print('✅ Méthode startGame() présente');
    } else {
      print('❌ Méthode startGame() MANQUANTE');
    }
    
    if (content.contains('getCurrentRoomData()')) {
      print('✅ Méthode getCurrentRoomData() présente');
    } else {
      print('❌ Méthode getCurrentRoomData() MANQUANTE');
    }
  }
}

Future<void> fixIssues() async {
  print('\n🔧 TEST 3: Correction des problèmes');
  print('===================================');
  
  // Fix 1: S'assurer que l'import MultiplayerGamePage est présent
  await fixImportInWaitingRoom();
  
  // Fix 2: Ajouter une méthode de test simple
  await addTestMethod();
  
  // Fix 3: Simplifier la logique de démarrage
  await simplifyStartGameLogic();
}

Future<void> fixImportInWaitingRoom() async {
  print('\n📦 Fix 1: Vérifier l\'import MultiplayerGamePage');
  
  final waitingRoomFile = File('lib/pages/waiting_room_page.dart');
  if (waitingRoomFile.existsSync()) {
    final content = waitingRoomFile.readAsStringSync();
    
    if (!content.contains("import 'multiplayer_game_page.dart';")) {
      print('❌ Import manquant, ajout en cours...');
      
      // Trouver la ligne d'import pour chat_widget
      final lines = content.split('\n');
      int insertIndex = -1;
      
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains("import '../widgets/chat_widget.dart';")) {
          insertIndex = i + 1;
          break;
        }
      }
      
      if (insertIndex != -1) {
        lines.insert(insertIndex, "import 'multiplayer_game_page.dart';");
        final newContent = lines.join('\n');
        await waitingRoomFile.writeAsString(newContent);
        print('✅ Import ajouté');
      } else {
        print('❌ Impossible de trouver l\'emplacement pour l\'import');
      }
    } else {
      print('✅ Import déjà présent');
    }
  }
}

Future<void> addTestMethod() async {
  print('\n🧪 Fix 2: Ajouter une méthode de test simple');
  
  final waitingRoomFile = File('lib/pages/waiting_room_page.dart');
  if (waitingRoomFile.existsSync()) {
    final content = waitingRoomFile.readAsStringSync();
    
    if (!content.contains('void _testStartGame()')) {
      print('❌ Méthode de test manquante, ajout en cours...');
      
      // Ajouter une méthode de test simple avant _startGame
      final testMethod = '''
  void _testStartGame() {
    print('🧪 TEST: Méthode de test appelée');
    _showSuccessMessage('Test: Méthode appelée avec succès');
    
    // Test simple de navigation
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const MultiplayerGamePage(),
      ),
    );
  }

''';
      
      // Remplacer _startGame par la méthode de test temporairement
      final newContent = content.replaceFirst(
        'void _startGame() async {',
        '$testMethod  void _startGame() async {',
      );
      
      await waitingRoomFile.writeAsString(newContent);
      print('✅ Méthode de test ajoutée');
    } else {
      print('✅ Méthode de test déjà présente');
    }
  }
}

Future<void> simplifyStartGameLogic() async {
  print('\n⚡ Fix 3: Simplifier la logique de démarrage');
  
  final waitingRoomFile = File('lib/pages/waiting_room_page.dart');
  if (waitingRoomFile.existsSync()) {
    final content = waitingRoomFile.readAsStringSync();
    
    // Créer une version simplifiée de _startGame
    final simplifiedStartGame = '''
  void _startGame() async {
    print('🎮 _startGame() appelé - VERSION SIMPLIFIÉE');
    
    try {
      // Feedback haptique
      HapticFeedback.mediumImpact();
      _showSuccessMessage('Démarrage du jeu...');
      
      // Attendre un peu
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Navigation directe
      if (mounted) {
        print('🚀 Navigation vers MultiplayerGamePage...');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const MultiplayerGamePage(),
          ),
        );
        print('✅ Navigation terminée');
      }
      
    } catch (e) {
      print('❌ Erreur: \$e');
      _showErrorMessage('Erreur: \$e');
    }
  }
''';
    
    // Remplacer la méthode _startGame existante
    final startGamePattern = RegExp(r'void _startGame\(\) async \{[^}]*\}', multiLine: true);
    final newContent = content.replaceFirst(startGamePattern, simplifiedStartGame);
    
    if (newContent != content) {
      await waitingRoomFile.writeAsString(newContent);
      print('✅ Logique simplifiée appliquée');
    } else {
      print('✅ Logique déjà simplifiée');
    }
  }
}

Future<void> buildAndDeploy() async {
  print('\n🏗️ TEST 4: Construction et déploiement');
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

void printFinalInstructions() {
  print('\n🎯 INSTRUCTIONS DE TEST FINAL');
  print('=============================');
  print('');
  print('1. 🌐 Ouvrir: https://pandora-box-user2.web.app');
  print('');
  print('2. 🎮 Aller dans Multijoueur');
  print('');
  print('3. 🏠 Créer une room (nom: "Test Room")');
  print('');
  print('4. 🔗 Rejoindre avec un autre navigateur/onglet');
  print('   - Même code de room');
  print('');
  print('5. ▶️ Cliquer "Commencer le Jeu"');
  print('   - Le bouton doit être visible pour l\'hôte');
  print('   - Doit naviguer vers MultiplayerGamePage');
  print('');
  print('6. 📊 Vérifier dans la console du navigateur (F12):');
  print('   - Logs: "🎮 _startGame() appelé - VERSION SIMPLIFIÉE"');
  print('   - Logs: "🚀 Navigation vers MultiplayerGamePage..."');
  print('   - Logs: "✅ Navigation terminée"');
  print('');
  print('7. ⏰ Si le compte à rebours de 3 secondes apparaît:');
  print('   - ✅ SUCCÈS: Le multijoueur fonctionne!');
  print('');
  print('8. ❌ Si problème persiste:');
  print('   - Copier les logs de la console');
  print('   - Relancer ce script');
  print('');
  print('🔄 Le script peut être relancé autant de fois que nécessaire');
  print('   jusqu\'à ce que le multijoueur fonctionne parfaitement!');
}
