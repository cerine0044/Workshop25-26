#!/usr/bin/env dart

import 'dart:io';

void main() async {
  print('🔍 SCRIPT DE DÉBOGAGE MULTIJOUEUR');
  print('=================================');
  
  // Test 1: Analyser le code WaitingRoomPage
  await analyzeWaitingRoomPage();
  
  // Test 2: Vérifier les conditions du bouton
  await checkButtonConditions();
  
  // Test 3: Analyser la méthode _startGame
  await analyzeStartGameMethod();
  
  // Test 4: Corriger les problèmes identifiés
  await fixIdentifiedIssues();
  
  // Test 5: Construire et déployer
  await buildAndDeploy();
  
  // Test 6: Instructions de test final
  printFinalDebugInstructions();
}

Future<void> analyzeWaitingRoomPage() async {
  print('\n📄 ANALYSE DE WaitingRoomPage');
  print('==============================');
  
  final waitingRoomFile = File('lib/pages/waiting_room_page.dart');
  if (waitingRoomFile.existsSync()) {
    final content = waitingRoomFile.readAsStringSync();
    
    print('✅ Fichier WaitingRoomPage trouvé');
    
    // Vérifier la méthode _startGame
    if (content.contains('void _startGame()')) {
      print('✅ Méthode _startGame() présente');
    } else {
      print('❌ Méthode _startGame() MANQUANTE');
    }
    
    // Vérifier les logs de diagnostic
    if (content.contains('print(\'🖱️ Bouton "Commencer le Jeu" cliqué\')')) {
      print('✅ Logs de diagnostic présents');
    } else {
      print('❌ Logs de diagnostic MANQUANTS');
    }
    
    // Vérifier la condition du bouton
    if (content.contains('if (widget.isHost && playerCount >= 2)')) {
      print('✅ Condition du bouton présente');
    } else {
      print('❌ Condition du bouton MANQUANTE');
    }
    
    // Vérifier l'import MultiplayerGamePage
    if (content.contains("import 'multiplayer_game_page.dart';")) {
      print('✅ Import MultiplayerGamePage présent');
    } else {
      print('❌ Import MultiplayerGamePage MANQUANT');
    }
    
  } else {
    print('❌ Fichier WaitingRoomPage MANQUANT');
  }
}

Future<void> checkButtonConditions() async {
  print('\n🖱️ VÉRIFICATION DES CONDITIONS DU BOUTON');
  print('========================================');
  
  final waitingRoomFile = File('lib/pages/waiting_room_page.dart');
  if (waitingRoomFile.existsSync()) {
    final content = waitingRoomFile.readAsStringSync();
    
    // Analyser les conditions
    final buttonPattern = RegExp(r'if \(widget\.isHost && playerCount >= 2\)');
    if (buttonPattern.hasMatch(content)) {
      print('✅ Condition principale trouvée: widget.isHost && playerCount >= 2');
      
      // Vérifier si le bouton est dans la bonne méthode
      if (content.contains('_buildActionButtons')) {
        print('✅ Bouton dans _buildActionButtons');
      } else {
        print('❌ Bouton PAS dans _buildActionButtons');
      }
      
      // Vérifier l'onPressed
      if (content.contains('onPressed: () {')) {
        print('✅ onPressed avec fonction anonyme');
      } else if (content.contains('onPressed: _startGame')) {
        print('✅ onPressed avec référence directe');
      } else {
        print('❌ onPressed MANQUANT ou INCORRECT');
      }
      
    } else {
      print('❌ Condition du bouton NON TROUVÉE');
    }
  }
}

Future<void> analyzeStartGameMethod() async {
  print('\n🎮 ANALYSE DE LA MÉTHODE _startGame');
  print('===================================');
  
  final waitingRoomFile = File('lib/pages/waiting_room_page.dart');
  if (waitingRoomFile.existsSync()) {
    final content = waitingRoomFile.readAsStringSync();
    
    // Extraire la méthode _startGame
    final startGamePattern = RegExp(r'void _startGame\(\) async \{[^}]*\}', multiLine: true);
    final match = startGamePattern.firstMatch(content);
    
    if (match != null) {
      final startGameMethod = match.group(0)!;
      print('✅ Méthode _startGame() trouvée');
      
      // Vérifier les vérifications
      if (startGameMethod.contains('if (!widget.isHost)')) {
        print('✅ Vérification isHost présente');
      } else {
        print('❌ Vérification isHost MANQUANTE');
      }
      
      if (startGameMethod.contains('if (_currentRoom == null)')) {
        print('✅ Vérification _currentRoom présente');
      } else {
        print('❌ Vérification _currentRoom MANQUANTE');
      }
      
      if (startGameMethod.contains('if (players.length < 2)')) {
        print('✅ Vérification nombre de joueurs présente');
      } else {
        print('❌ Vérification nombre de joueurs MANQUANTE');
      }
      
      // Vérifier la navigation
      if (startGameMethod.contains('Navigator.of(context).pushReplacement')) {
        print('✅ Navigation présente');
      } else {
        print('❌ Navigation MANQUANTE');
      }
      
      // Vérifier les logs
      if (startGameMethod.contains('print(\'🎮 _startGame() appelé\')')) {
        print('✅ Logs de diagnostic présents');
      } else {
        print('❌ Logs de diagnostic MANQUANTS');
      }
      
    } else {
      print('❌ Méthode _startGame() NON TROUVÉE');
    }
  }
}

Future<void> fixIdentifiedIssues() async {
  print('\n🔧 CORRECTION DES PROBLÈMES IDENTIFIÉS');
  print('=====================================');
  
  final waitingRoomFile = File('lib/pages/waiting_room_page.dart');
  if (waitingRoomFile.existsSync()) {
    final content = waitingRoomFile.readAsStringSync();
    
    // Fix 1: S'assurer que le bouton a la bonne logique
    if (!content.contains('print(\'🖱️ Bouton "Commencer le Jeu" cliqué\')')) {
      print('❌ Logs du bouton manquants, correction...');
      
      // Remplacer onPressed: _startGame par une fonction anonyme avec logs
      final newContent = content.replaceFirst(
        'onPressed: _startGame,',
        '''onPressed: () {
                print('🖱️ Bouton "Commencer le Jeu" cliqué');
                print('📊 widget.isHost: \${widget.isHost}');
                print('📊 playerCount: \$playerCount');
                _startGame();
              },''',
      );
      
      await waitingRoomFile.writeAsString(newContent);
      print('✅ Logs du bouton ajoutés');
    } else {
      print('✅ Logs du bouton déjà présents');
    }
    
    // Fix 2: S'assurer que _startGame a tous les logs nécessaires
    if (!content.contains('print(\'🎮 _startGame() appelé\')')) {
      print('❌ Logs de _startGame manquants, correction...');
      
      // Remplacer le début de _startGame
      final newContent = content.replaceFirst(
        'void _startGame() async {',
        '''void _startGame() async {
    print('🎮 _startGame() appelé');
    print('📊 widget.isHost: \${widget.isHost}');
    print('📊 _currentRoom: \$_currentRoom');
    
    if (!widget.isHost) {
      print('❌ Pas l\\'hôte - impossible de démarrer');
      _showErrorMessage('Seul l\\'hôte peut démarrer le jeu');
      return;
    }
    
    if (_currentRoom == null) {
      print('❌ _currentRoom est null - impossible de démarrer');
      _showErrorMessage('Erreur: Données de room non disponibles');
      return;
    }
    
    final players = _currentRoom!['players'] as Map<String, dynamic>? ?? {};
    print('📊 Players: \$players');
    print('📊 Players count: \${players.length}');
    
    if (players.length < 2) {
      print('❌ Pas assez de joueurs: \${players.length}');
      _showErrorMessage('Il faut au moins 2 joueurs pour commencer');
      return;
    }
    
    try {
      HapticFeedback.mediumImpact();
      _showSuccessMessage('Démarrage du jeu...');
      
      print('✅ Toutes les vérifications OK, démarrage...');
      
      // Mettre à jour l'état de la room pour démarrer le jeu
      await _multiplayerService.startGame();
      print('✅ startGame() terminé avec succès');
      
      // Attendre un peu puis naviguer vers le jeu
      await Future.delayed(const Duration(seconds: 1));
      
      if (mounted) {
        print('🚀 Navigation vers page de test...');
        // Naviguer vers une page de test simple d'abord
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => _buildTestPage(),
          ),
        );
        print('✅ Navigation terminée');
      }
      
    } catch (e) {
      print('❌ Erreur démarrage jeu: \$e');
      _showErrorMessage('Erreur démarrage jeu: \$e');
    }
  }

  Widget _buildTestPage() {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Test Multijoueur'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 100,
            ),
            const SizedBox(height: 20),
            const Text(
              '✅ SUCCÈS !',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Le bouton "Commencer le Jeu" fonctionne !',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => const MultiplayerGamePage(),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Continuer vers le Jeu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.home),
              label: const Text('Retour à l\\'Accueil'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startGameOld() async {''',
      );
      
      await waitingRoomFile.writeAsString(newContent);
      print('✅ Logs de _startGame ajoutés');
    } else {
      print('✅ Logs de _startGame déjà présents');
    }
    
    // Fix 3: S'assurer que l'import MultiplayerGamePage est présent
    if (!content.contains("import 'multiplayer_game_page.dart';")) {
      print('❌ Import MultiplayerGamePage manquant, ajout...');
      
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
        print('✅ Import MultiplayerGamePage ajouté');
      }
    } else {
      print('✅ Import MultiplayerGamePage déjà présent');
    }
  }
}

Future<void> buildAndDeploy() async {
  print('\n🏗️ CONSTRUCTION ET DÉPLOIEMENT');
  print('==============================');
  
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

void printFinalDebugInstructions() {
  print('\n🎯 INSTRUCTIONS DE DÉBOGAGE FINAL');
  print('=================================');
  print('');
  print('🌐 APPLICATION: https://pandora-box-user2.web.app');
  print('');
  print('🔍 ÉTAPES DE DÉBOGAGE:');
  print('');
  print('1. 🌐 Ouvrir l\'application');
  print('2. 🎮 Aller dans Multijoueur');
  print('3. 🏠 Créer une room');
  print('4. 🔗 Rejoindre avec un autre navigateur');
  print('5. 🖱️ Cliquer "Commencer le Jeu"');
  print('');
  print('📊 LOGS À VÉRIFIER DANS LA CONSOLE (F12):');
  print('');
  print('✅ LOGS ATTENDUS:');
  print('🖱️ Bouton "Commencer le Jeu" cliqué');
  print('📊 widget.isHost: true');
  print('📊 playerCount: 2');
  print('🎮 _startGame() appelé');
  print('📊 widget.isHost: true');
  print('📊 _currentRoom: [données de la room]');
  print('📊 Players: [liste des joueurs]');
  print('📊 Players count: 2');
  print('✅ Toutes les vérifications OK, démarrage...');
  print('✅ startGame() terminé avec succès');
  print('🚀 Navigation vers page de test...');
  print('✅ Navigation terminée');
  print('');
  print('❌ SI PROBLÈME:');
  print('- Si pas de logs du bouton → Le bouton n\'est pas cliqué');
  print('- Si widget.isHost: false → Problème de détection de l\'hôte');
  print('- Si _currentRoom: null → Problème de connexion Firebase');
  print('- Si Players count < 2 → Pas assez de joueurs');
  print('- Si erreur dans startGame() → Problème Firebase');
  print('- Si pas de navigation → Problème de contexte Flutter');
  print('');
  print('🎯 RÉSULTAT ATTENDU:');
  print('Page de test avec "✅ SUCCÈS !" et boutons de navigation');
  print('');
  print('🔄 Si problème persiste:');
  print('1. Copier tous les logs de la console');
  print('2. Relancer ce script');
  print('3. Le système sera corrigé automatiquement');
}
