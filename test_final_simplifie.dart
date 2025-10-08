import 'dart:io';
import 'dart:convert';
import 'dart:async';

void main() async {
  print('🎯 TEST FINAL SIMPLIFIÉ PANDORA BOX');
  print('===================================');
  
  int testsPassed = 0;
  int totalTests = 0;
  
  // Test 1: Serveur accessible
  totalTests++;
  if (await testServerAccessible()) {
    testsPassed++;
    print('✅ Test 1: Serveur accessible - RÉUSSI');
  } else {
    print('❌ Test 1: Serveur accessible - ÉCHOUÉ');
  }
  
  // Test 2: WebSocket fonctionnel
  totalTests++;
  if (await testWebSocketWorking()) {
    testsPassed++;
    print('✅ Test 2: WebSocket fonctionnel - RÉUSSI');
  } else {
    print('❌ Test 2: WebSocket fonctionnel - ÉCHOUÉ');
  }
  
  // Test 3: Création de room
  totalTests++;
  if (await testRoomCreation()) {
    testsPassed++;
    print('✅ Test 3: Création de room - RÉUSSI');
  } else {
    print('❌ Test 3: Création de room - ÉCHOUÉ');
  }
  
  // Test 4: Interface moderne présente
  totalTests++;
  if (await testModernInterface()) {
    testsPassed++;
    print('✅ Test 4: Interface moderne - RÉUSSI');
  } else {
    print('❌ Test 4: Interface moderne - ÉCHOUÉ');
  }
  
  // Résultats finaux
  print('\n📊 RÉSULTATS FINAUX:');
  print('====================');
  print('Tests réussis: $testsPassed/$totalTests');
  print('Pourcentage de réussite: ${(testsPassed / totalTests * 100).toStringAsFixed(1)}%');
  
  if (testsPassed == totalTests) {
    print('\n🎉 TOUS LES TESTS SONT PASSÉS !');
    print('L\'interface moderne Pandora Box fonctionne parfaitement !');
    print('\n🚀 PRÊT POUR L\'UTILISATION !');
    print('📱 Application Flutter: http://localhost:8080');
    print('🖥️  Interface Web: http://localhost:5001');
    print('🔌 Serveur WebSocket: ws://localhost:5002');
  } else {
    print('\n⚠️  CERTAINS TESTS ONT ÉCHOUÉ');
    print('Vérifiez les logs ci-dessus pour plus de détails');
  }
}

Future<bool> testServerAccessible() async {
  print('\n🌐 Test 1: Serveur accessible...');
  
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:5001/'));
    final response = await request.close();
    
    if (response.statusCode == 200) {
      print('   ✅ Serveur HTTP accessible (port 5001)');
      return true;
    } else {
      print('   ❌ Serveur HTTP inaccessible (status: ${response.statusCode})');
      return false;
    }
  } catch (e) {
    print('   ❌ Erreur serveur HTTP: $e');
    return false;
  }
}

Future<bool> testWebSocketWorking() async {
  print('\n🔌 Test 2: WebSocket fonctionnel...');
  
  try {
    final webSocket = await WebSocket.connect('ws://localhost:5002');
    
    // Envoyer un ping
    webSocket.add(jsonEncode({'type': 'ping'}));
    
    // Attendre une réponse
    final completer = Completer<bool>();
    Timer(const Duration(seconds: 2), () => completer.complete(false));
    
    webSocket.listen((message) {
      final data = jsonDecode(message) as Map<String, dynamic>;
      if (data['type'] == 'pong') {
        completer.complete(true);
      }
    });
    
    final result = await completer.future;
    await webSocket.close();
    
    if (result) {
      print('   ✅ WebSocket fonctionnel (ping/pong)');
      return true;
    } else {
      print('   ❌ WebSocket non fonctionnel');
      return false;
    }
  } catch (e) {
    print('   ❌ Erreur WebSocket: $e');
    return false;
  }
}

Future<bool> testRoomCreation() async {
  print('\n🏠 Test 3: Création de room...');
  
  try {
    final webSocket = await WebSocket.connect('ws://localhost:5002');
    final roomCreated = Completer<bool>();
    
    webSocket.listen((message) {
      final data = jsonDecode(message) as Map<String, dynamic>;
      if (data['type'] == 'room_update') {
        roomCreated.complete(true);
      }
    });
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Créer une room
    webSocket.add(jsonEncode({
      'type': 'create_room',
      'roomName': 'Test Final Room',
      'host': 'test_final_user',
      'hostName': 'Testeur Final',
    }));
    
    final result = await roomCreated.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () => false,
    );
    
    await webSocket.close();
    
    if (result) {
      print('   ✅ Création de room réussie');
      return true;
    } else {
      print('   ❌ Création de room échouée');
      return false;
    }
  } catch (e) {
    print('   ❌ Erreur création de room: $e');
    return false;
  }
}

Future<bool> testModernInterface() async {
  print('\n🎨 Test 4: Interface moderne...');
  
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:5001/'));
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    
    // Vérifier les éléments modernes
    final modernElements = [
      'gradient',
      'animation',
      'backdrop-filter',
      'box-shadow',
      'border-radius',
      'WebSocket',
    ];
    
    int foundElements = 0;
    for (String element in modernElements) {
      if (body.toLowerCase().contains(element.toLowerCase())) {
        foundElements++;
      }
    }
    
    if (foundElements >= 3) {
      print('   ✅ Interface moderne détectée ($foundElements éléments)');
      return true;
    } else {
      print('   ❌ Interface basique détectée ($foundElements éléments)');
      return false;
    }
  } catch (e) {
    print('   ❌ Erreur test interface: $e');
    return false;
  }
}
