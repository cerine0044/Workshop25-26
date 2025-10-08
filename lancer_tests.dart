#!/usr/bin/env dart

import 'dart:io';

void main() async {
  print('🧪 Lanceur de Tests - Pandora Box WebSocket');
  print('============================================');
  print('');
  print('Choisissez un test à exécuter:');
  print('');
  print('1. Test de connectivité réseau');
  print('2. Serveur WebSocket complet');
  print('3. Client de test interactif');
  print('4. Test de bout en bout complet');
  print('5. Quitter');
  print('');
  stdout.write('Votre choix (1-5): ');
  
  final choice = stdin.readLineSync()?.trim();
  
  switch (choice) {
    case '1':
      print('🔍 Lancement du test de connectivité...');
      await Process.start('dart', ['run', 'test_connectivite.dart'], mode: ProcessStartMode.inheritStdio);
      break;
    case '2':
      print('🚀 Lancement du serveur WebSocket...');
      await Process.start('dart', ['run', 'test_websocket_complet.dart'], mode: ProcessStartMode.inheritStdio);
      break;
    case '3':
      print('🧪 Lancement du client de test...');
      await Process.start('dart', ['run', 'test_client.dart'], mode: ProcessStartMode.inheritStdio);
      break;
    case '4':
      print('🎯 Lancement du test de bout en bout...');
      await Process.start('dart', ['run', 'test_bout_en_bout.dart'], mode: ProcessStartMode.inheritStdio);
      break;
    case '5':
      print('👋 Au revoir !');
      break;
    default:
      print('❌ Choix invalide');
  }
}
