#!/usr/bin/env dart

import 'dart:io';

void main() {
  print('🔍 DIAGNOSTIC MULTIJOUEUR');
  print('========================');
  
  // Test 1: Vérifier la structure des fichiers
  print('\n📁 Test 1: Structure des fichiers');
  final waitingRoomFile = File('lib/pages/waiting_room_page.dart');
  if (waitingRoomFile.existsSync()) {
    print('✅ waiting_room_page.dart existe');
    
    final content = waitingRoomFile.readAsStringSync();
    
    // Vérifier la méthode _startGame
    if (content.contains('void _startGame()')) {
      print('✅ Méthode _startGame() trouvée');
    } else {
      print('❌ Méthode _startGame() NON trouvée');
    }
    
    // Vérifier les logs de diagnostic
    if (content.contains('print(\'🎮 _startGame() appelé\')')) {
      print('✅ Logs de diagnostic trouvés');
    } else {
      print('❌ Logs de diagnostic NON trouvés');
    }
    
    // Vérifier la vérification _currentRoom
    if (content.contains('if (_currentRoom == null)')) {
      print('✅ Vérification _currentRoom trouvée');
    } else {
      print('❌ Vérification _currentRoom NON trouvée');
    }
    
  } else {
    print('❌ waiting_room_page.dart n\'existe pas');
  }
  
  // Test 2: Vérifier FirebaseMultiplayerService
  print('\n🔥 Test 2: FirebaseMultiplayerService');
  final firebaseServiceFile = File('lib/services/firebase_multiplayer_service.dart');
  if (firebaseServiceFile.existsSync()) {
    print('✅ firebase_multiplayer_service.dart existe');
    
    final content = firebaseServiceFile.readAsStringSync();
    
    // Vérifier la méthode startGame
    if (content.contains('Future<void> startGame()')) {
      print('✅ Méthode startGame() trouvée');
    } else {
      print('❌ Méthode startGame() NON trouvée');
    }
    
    // Vérifier la méthode getCurrentRoomData
    if (content.contains('getCurrentRoomData()')) {
      print('✅ Méthode getCurrentRoomData() trouvée');
    } else {
      print('❌ Méthode getCurrentRoomData() NON trouvée');
    }
    
  } else {
    print('❌ firebase_multiplayer_service.dart n\'existe pas');
  }
  
  // Test 3: Vérifier MultiplayerGamePage
  print('\n🎮 Test 3: MultiplayerGamePage');
  final gamePageFile = File('lib/pages/multiplayer_game_page.dart');
  if (gamePageFile.existsSync()) {
    print('✅ multiplayer_game_page.dart existe');
  } else {
    print('❌ multiplayer_game_page.dart n\'existe pas');
  }
  
  // Test 4: Vérifier les imports
  print('\n📦 Test 4: Imports dans waiting_room_page.dart');
  final waitingRoomContent = waitingRoomFile.readAsStringSync();
  
  if (waitingRoomContent.contains("import 'multiplayer_game_page.dart';")) {
    print('✅ Import MultiplayerGamePage trouvé');
  } else {
    print('❌ Import MultiplayerGamePage NON trouvé');
  }
  
  // Test 5: Analyser la logique du bouton
  print('\n🖱️ Test 5: Logique du bouton');
  final buttonPattern = RegExp(r'if \(widget\.isHost && playerCount >= 2\)');
  if (buttonPattern.hasMatch(waitingRoomContent)) {
    print('✅ Condition d\'affichage du bouton trouvée');
  } else {
    print('❌ Condition d\'affichage du bouton NON trouvée');
  }
  
  // Test 6: Vérifier la navigation
  print('\n🚀 Test 6: Navigation');
  final navigationPattern = RegExp(r'Navigator\.of\(context\)\.pushReplacement');
  if (navigationPattern.hasMatch(waitingRoomContent)) {
    print('✅ Navigation pushReplacement trouvée');
  } else {
    print('❌ Navigation pushReplacement NON trouvée');
  }
  
  print('\n🎯 RÉSUMÉ DU DIAGNOSTIC');
  print('=======================');
  print('Si tous les tests sont ✅, le problème pourrait être:');
  print('1. _currentRoom est null au moment du clic');
  print('2. Firebase n\'est pas correctement initialisé');
  print('3. Les données de room ne sont pas synchronisées');
  print('4. Problème de contexte Flutter (mounted = false)');
  print('\n💡 SOLUTION: Vérifier les logs dans la console du navigateur');
}
