import 'dart:io';
import 'dart:convert';
import 'dart:async';

void main() async {
  print('🧪 TESTS COMPLETS INTERFACE MODERNE PANDORA BOX');
  print('===============================================');
  
  int testsPassed = 0;
  int totalTests = 0;
  
  // Test 1: Connectivité du serveur
  totalTests++;
  if (await testServerConnectivity()) {
    testsPassed++;
    print('✅ Test 1: Connectivité serveur - RÉUSSI');
  } else {
    print('❌ Test 1: Connectivité serveur - ÉCHOUÉ');
  }
  
  // Test 2: Interface web moderne
  totalTests++;
  if (await testModernWebInterface()) {
    testsPassed++;
    print('✅ Test 2: Interface web moderne - RÉUSSI');
  } else {
    print('❌ Test 2: Interface web moderne - ÉCHOUÉ');
  }
  
  // Test 3: WebSocket temps réel
  totalTests++;
  if (await testWebSocketRealTime()) {
    testsPassed++;
    print('✅ Test 3: WebSocket temps réel - RÉUSSI');
  } else {
    print('❌ Test 3: WebSocket temps réel - ÉCHOUÉ');
  }
  
  // Test 4: Création de salons
  totalTests++;
  if (await testRoomCreation()) {
    testsPassed++;
    print('✅ Test 4: Création de salons - RÉUSSI');
  } else {
    print('❌ Test 4: Création de salons - ÉCHOUÉ');
  }
  
  // Test 5: Synchronisation multijoueur
  totalTests++;
  if (await testMultiplayerSync()) {
    testsPassed++;
    print('✅ Test 5: Synchronisation multijoueur - RÉUSSI');
  } else {
    print('❌ Test 5: Synchronisation multijoueur - ÉCHOUÉ');
  }
  
  // Test 6: Gestion des erreurs
  totalTests++;
  if (await testErrorHandling()) {
    testsPassed++;
    print('✅ Test 6: Gestion des erreurs - RÉUSSI');
  } else {
    print('❌ Test 6: Gestion des erreurs - ÉCHOUÉ');
  }
  
  // Test 7: Performance et animations
  totalTests++;
  if (await testPerformanceAndAnimations()) {
    testsPassed++;
    print('✅ Test 7: Performance et animations - RÉUSSI');
  } else {
    print('❌ Test 7: Performance et animations - ÉCHOUÉ');
  }
  
  // Résultats finaux
  print('\n📊 RÉSULTATS FINAUX:');
  print('===================');
  print('Tests réussis: $testsPassed/$totalTests');
  print('Pourcentage de réussite: ${(testsPassed / totalTests * 100).toStringAsFixed(1)}%');
  
  if (testsPassed == totalTests) {
    print('\n🎉 TOUS LES TESTS SONT PASSÉS !');
    print('L\'interface moderne fonctionne parfaitement !');
  } else {
    print('\n⚠️  CERTAINS TESTS ONT ÉCHOUÉ');
    print('Vérifiez les logs ci-dessus pour plus de détails');
  }
}

Future<bool> testServerConnectivity() async {
  print('\n🔍 Test 1: Connectivité du serveur...');
  
  try {
    // Test HTTP
    final httpResponse = await HttpClient().getUrl(Uri.parse('http://localhost:5001/'));
    final httpRequest = await httpResponse.close();
    
    if (httpRequest.statusCode == 200) {
      print('   ✅ Serveur HTTP accessible (port 5001)');
    } else {
      print('   ❌ Serveur HTTP inaccessible (status: ${httpRequest.statusCode})');
      return false;
    }
    
    // Test WebSocket
    final webSocket = await WebSocket.connect('ws://localhost:5002');
    final completer = Completer<bool>();
    bool completed = false;
    
    Timer(const Duration(seconds: 2), () {
      if (!completed) {
        completed = true;
        completer.complete(false);
      }
    });
    
    webSocket.listen((message) {
      final data = jsonDecode(message) as Map<String, dynamic>;
      if (data['type'] == 'pong' && !completed) {
        completed = true;
        completer.complete(true);
      }
    });
    
    webSocket.add(jsonEncode({'type': 'ping'}));
    
    final result = await completer.future;
    await webSocket.close();
    
    if (result) {
      print('   ✅ Serveur WebSocket accessible (port 5002)');
      return true;
    } else {
      print('   ❌ Serveur WebSocket inaccessible');
      return false;
    }
    
  } catch (e) {
    print('   ❌ Erreur de connectivité: $e');
    return false;
  }
}

Future<bool> testModernWebInterface() async {
  print('\n🎨 Test 2: Interface web moderne...');
  
  try {
    final response = await HttpClient().getUrl(Uri.parse('http://localhost:5001/'));
    final request = await response.close();
    final body = await request.transform(utf8.decoder).join();
    
    // Vérifier les éléments modernes
    final modernElements = [
      'gradient',
      'animation',
      'backdrop-filter',
      'box-shadow',
      'border-radius',
      'WebSocket',
      'modern',
      'responsive'
    ];
    
    int foundElements = 0;
    for (String element in modernElements) {
      if (body.toLowerCase().contains(element.toLowerCase())) {
        foundElements++;
        print('   ✅ Élément moderne trouvé: $element');
      }
    }
    
    if (foundElements >= 5) {
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

Future<bool> testWebSocketRealTime() async {
  print('\n⚡ Test 3: WebSocket temps réel...');
  
  try {
    final webSocket = await WebSocket.connect('ws://localhost:5002');
    final messages = <Map<String, dynamic>>[];
    
    // Écouter les messages
    webSocket.listen((message) {
      final data = jsonDecode(message) as Map<String, dynamic>;
      messages.add(data);
    });
    
    // Attendre la connexion
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Test de ping/pong
    webSocket.add(jsonEncode({'type': 'ping'}));
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Test de création de room
    webSocket.add(jsonEncode({
      'type': 'create_room',
      'roomName': 'Test Temps Réel',
      'host': 'test_user',
      'hostName': 'Testeur',
    }));
    
    await Future.delayed(const Duration(milliseconds: 1000));
    
    await webSocket.close();
    
    // Vérifier les messages reçus
    if (messages.any((msg) => msg['type'] == 'pong')) {
      print('   ✅ Ping/Pong fonctionnel');
    } else {
      print('   ❌ Ping/Pong non fonctionnel');
      return false;
    }
    
    if (messages.any((msg) => msg['type'] == 'room_update')) {
      print('   ✅ Création de room temps réel');
    } else {
      print('   ❌ Création de room non fonctionnelle');
      return false;
    }
    
    print('   ✅ WebSocket temps réel fonctionnel');
    return true;
    
  } catch (e) {
    print('   ❌ Erreur WebSocket: $e');
    return false;
  }
}

Future<bool> testRoomCreation() async {
  print('\n🏠 Test 4: Création de salons...');
  
  try {
    // Test via HTTP
    final httpClient = HttpClient();
    final request = await httpClient.postUrl(Uri.parse('http://localhost:5001/rooms'));
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({
      'name': 'Test Room HTTP',
      'host': 'test_user_http',
      'hostName': 'Testeur HTTP',
    }));
    
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 201) {
      print('   ✅ Création de room HTTP réussie');
    } else {
      print('   ❌ Création de room HTTP échouée (status: ${response.statusCode})');
      return false;
    }
    
    // Test via WebSocket
    final webSocket = await WebSocket.connect('ws://localhost:5002');
    final roomCreated = Completer<bool>();
    
    webSocket.listen((message) {
      final data = jsonDecode(message) as Map<String, dynamic>;
      if (data['type'] == 'room_update') {
        roomCreated.complete(true);
      }
    });
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    webSocket.add(jsonEncode({
      'type': 'create_room',
      'roomName': 'Test Room WebSocket',
      'host': 'test_user_ws',
      'hostName': 'Testeur WebSocket',
    }));
    
    final result = await roomCreated.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () => false,
    );
    
    await webSocket.close();
    
    if (result) {
      print('   ✅ Création de room WebSocket réussie');
      return true;
    } else {
      print('   ❌ Création de room WebSocket échouée');
      return false;
    }
    
  } catch (e) {
    print('   ❌ Erreur création de room: $e');
    return false;
  }
}

Future<bool> testMultiplayerSync() async {
  print('\n👥 Test 5: Synchronisation multijoueur...');
  
  try {
    // Simuler deux clients
    final client1 = await WebSocket.connect('ws://localhost:5002');
    final client2 = await WebSocket.connect('ws://localhost:5002');
    
    final client1Messages = <Map<String, dynamic>>[];
    final client2Messages = <Map<String, dynamic>>[];
    
    client1.listen((message) {
      final data = jsonDecode(message) as Map<String, dynamic>;
      client1Messages.add(data);
    });
    
    client2.listen((message) {
      final data = jsonDecode(message) as Map<String, dynamic>;
      client2Messages.add(data);
    });
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Client 1 crée une room
    client1.add(jsonEncode({
      'type': 'create_room',
      'roomName': 'Test Sync Room',
      'host': 'client1',
      'hostName': 'Client 1',
    }));
    
    await Future.delayed(const Duration(milliseconds: 1000));
    
    // Extraire l'ID de la room
    String? roomId;
    for (var msg in client1Messages) {
      if (msg['type'] == 'room_update') {
        roomId = msg['room']['id'] as String?;
        break;
      }
    }
    
    if (roomId == null) {
      print('   ❌ Impossible de récupérer l\'ID de la room');
      return false;
    }
    
    // Client 2 rejoint la room
    client2.add(jsonEncode({
      'type': 'join_room',
      'roomId': roomId,
      'userId': 'client2',
      'userName': 'Client 2',
    }));
    
    await Future.delayed(const Duration(milliseconds: 2000));
    
    // Vérifier la synchronisation
    bool client1Sees2Players = false;
    bool client2Sees2Players = false;
    
    for (var msg in client1Messages) {
      if (msg['type'] == 'room_update') {
        final room = msg['room'] as Map<String, dynamic>;
        final players = room['players'] as Map<String, dynamic>;
        if (players.length == 2) {
          client1Sees2Players = true;
          break;
        }
      }
    }
    
    for (var msg in client2Messages) {
      if (msg['type'] == 'room_update') {
        final room = msg['room'] as Map<String, dynamic>;
        final players = room['players'] as Map<String, dynamic>;
        if (players.length == 2) {
          client2Sees2Players = true;
          break;
        }
      }
    }
    
    await client1.close();
    await client2.close();
    
    if (client1Sees2Players && client2Sees2Players) {
      print('   ✅ Synchronisation multijoueur réussie');
      return true;
    } else {
      print('   ❌ Synchronisation multijoueur échouée');
      return false;
    }
    
  } catch (e) {
    print('   ❌ Erreur synchronisation: $e');
    return false;
  }
}

Future<bool> testErrorHandling() async {
  print('\n⚠️  Test 6: Gestion des erreurs...');
  
  try {
    // Test avec une room inexistante
    final webSocket = await WebSocket.connect('ws://localhost:5002');
    final errorReceived = Completer<bool>();
    
    webSocket.listen((message) {
      final data = jsonDecode(message) as Map<String, dynamic>;
      if (data['type'] == 'error') {
        errorReceived.complete(true);
      }
    });
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Essayer de rejoindre une room inexistante
    webSocket.add(jsonEncode({
      'type': 'join_room',
      'roomId': 'room_inexistante',
      'userId': 'test_user',
      'userName': 'Testeur',
    }));
    
    final result = await errorReceived.future.timeout(
      const Duration(seconds: 3),
      onTimeout: () => false,
    );
    
    await webSocket.close();
    
    if (result) {
      print('   ✅ Gestion des erreurs fonctionnelle');
      return true;
    } else {
      print('   ❌ Gestion des erreurs non fonctionnelle');
      return false;
    }
    
  } catch (e) {
    print('   ❌ Erreur test gestion d\'erreurs: $e');
    return false;
  }
}

Future<bool> testPerformanceAndAnimations() async {
  print('\n⚡ Test 7: Performance et animations...');
  
  try {
    // Test de performance - créer plusieurs rooms rapidement
    final startTime = DateTime.now();
    
    final webSocket = await WebSocket.connect('ws://localhost:5002');
    final roomsCreated = <String>[];
    
    webSocket.listen((message) {
      final data = jsonDecode(message) as Map<String, dynamic>;
      if (data['type'] == 'room_update') {
        final room = data['room'] as Map<String, dynamic>;
        roomsCreated.add(room['id'] as String);
      }
    });
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Créer 5 rooms rapidement
    for (int i = 0; i < 5; i++) {
      webSocket.add(jsonEncode({
        'type': 'create_room',
        'roomName': 'Test Performance $i',
        'host': 'test_user_$i',
        'hostName': 'Testeur $i',
      }));
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    await Future.delayed(const Duration(milliseconds: 2000));
    
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    
    await webSocket.close();
    
    if (roomsCreated.length >= 5 && duration.inMilliseconds < 5000) {
      print('   ✅ Performance acceptable (${roomsCreated.length} rooms en ${duration.inMilliseconds}ms)');
      return true;
    } else {
      print('   ❌ Performance insuffisante (${roomsCreated.length} rooms en ${duration.inMilliseconds}ms)');
      return false;
    }
    
  } catch (e) {
    print('   ❌ Erreur test performance: $e');
    return false;
  }
}
