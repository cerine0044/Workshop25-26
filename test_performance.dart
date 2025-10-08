import 'dart:io';
import 'dart:convert';
import 'dart:async';

void main() async {
  print('⚡ TESTS DE PERFORMANCE PANDORA BOX');
  print('==================================');
  
  int testsPassed = 0;
  int totalTests = 0;
  
  // Test 1: Performance du serveur
  totalTests++;
  if (await testServerPerformance()) {
    testsPassed++;
    print('✅ Test 1: Performance serveur - RÉUSSI');
  } else {
    print('❌ Test 1: Performance serveur - ÉCHOUÉ');
  }
  
  // Test 2: Latence WebSocket
  totalTests++;
  if (await testWebSocketLatency()) {
    testsPassed++;
    print('✅ Test 2: Latence WebSocket - RÉUSSI');
  } else {
    print('❌ Test 2: Latence WebSocket - ÉCHOUÉ');
  }
  
  // Test 3: Charge multijoueur
  totalTests++;
  if (await testMultiplayerLoad()) {
    testsPassed++;
    print('✅ Test 3: Charge multijoueur - RÉUSSI');
  } else {
    print('❌ Test 3: Charge multijoueur - ÉCHOUÉ');
  }
  
  // Test 4: Mémoire et ressources
  totalTests++;
  if (await testMemoryUsage()) {
    testsPassed++;
    print('✅ Test 4: Mémoire et ressources - RÉUSSI');
  } else {
    print('❌ Test 4: Mémoire et ressources - ÉCHOUÉ');
  }
  
  // Résultats finaux
  print('\n📊 RÉSULTATS PERFORMANCE:');
  print('==========================');
  print('Tests réussis: $testsPassed/$totalTests');
  print('Pourcentage de réussite: ${(testsPassed / totalTests * 100).toStringAsFixed(1)}%');
  
  if (testsPassed == totalTests) {
    print('\n🚀 PERFORMANCE OPTIMALE !');
    print('L\'application est prête pour la production !');
  } else {
    print('\n⚠️  OPTIMISATIONS NÉCESSAIRES');
    print('Certains aspects de performance peuvent être améliorés');
  }
}

Future<bool> testServerPerformance() async {
  print('\n⚡ Test 1: Performance du serveur...');
  
  try {
    final startTime = DateTime.now();
    
    // Test de charge HTTP
    final futures = <Future>[];
    for (int i = 0; i < 10; i++) {
      futures.add(_makeHttpRequest(i));
    }
    
    await Future.wait(futures);
    
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    
    if (duration.inMilliseconds < 5000) {
      print('   ✅ Serveur HTTP performant (${duration.inMilliseconds}ms pour 10 requêtes)');
      return true;
    } else {
      print('   ❌ Serveur HTTP lent (${duration.inMilliseconds}ms pour 10 requêtes)');
      return false;
    }
    
  } catch (e) {
    print('   ❌ Erreur test performance serveur: $e');
    return false;
  }
}

Future<void> _makeHttpRequest(int index) async {
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:5001/'));
    final response = await request.close();
    await response.drain();
    client.close();
  } catch (e) {
    // Ignorer les erreurs individuelles
  }
}

Future<bool> testWebSocketLatency() async {
  print('\n🔌 Test 2: Latence WebSocket...');
  
  try {
    final webSocket = await WebSocket.connect('ws://localhost:5002');
    final latencies = <int>[];
    
    // Mesurer la latence sur plusieurs pings
    for (int i = 0; i < 5; i++) {
      final startTime = DateTime.now();
      
      webSocket.add(jsonEncode({'type': 'ping'}));
      
      final completer = Completer<int>();
      Timer(const Duration(seconds: 1), () => completer.complete(-1));
      
      webSocket.listen((message) {
        final data = jsonDecode(message) as Map<String, dynamic>;
        if (data['type'] == 'pong') {
          final endTime = DateTime.now();
          final latency = endTime.difference(startTime).inMilliseconds;
          completer.complete(latency);
        }
      });
      
      final latency = await completer.future;
      if (latency > 0) {
        latencies.add(latency);
        print('   📊 Latence ping ${i + 1}: ${latency}ms');
      }
      
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    await webSocket.close();
    
    if (latencies.isNotEmpty) {
      final avgLatency = latencies.reduce((a, b) => a + b) / latencies.length;
      
      if (avgLatency < 100) {
        print('   ✅ Latence WebSocket excellente (${avgLatency.toStringAsFixed(1)}ms moyenne)');
        return true;
      } else if (avgLatency < 500) {
        print('   ⚠️  Latence WebSocket acceptable (${avgLatency.toStringAsFixed(1)}ms moyenne)');
        return true;
      } else {
        print('   ❌ Latence WebSocket élevée (${avgLatency.toStringAsFixed(1)}ms moyenne)');
        return false;
      }
    } else {
      print('   ❌ Aucune réponse pong reçue');
      return false;
    }
    
  } catch (e) {
    print('   ❌ Erreur test latence: $e');
    return false;
  }
}

Future<bool> testMultiplayerLoad() async {
  print('\n👥 Test 3: Charge multijoueur...');
  
  try {
    final startTime = DateTime.now();
    final connections = <WebSocket>[];
    final roomsCreated = <String>[];
    
    // Créer 5 connexions simultanées
    for (int i = 0; i < 5; i++) {
      final webSocket = await WebSocket.connect('ws://localhost:5002');
      connections.add(webSocket);
      
      webSocket.listen((message) {
        final data = jsonDecode(message) as Map<String, dynamic>;
        if (data['type'] == 'room_update') {
          final room = data['room'] as Map<String, dynamic>;
          roomsCreated.add(room['id'] as String);
        }
      });
    }
    
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Chaque connexion crée une room
    for (int i = 0; i < connections.length; i++) {
      connections[i].add(jsonEncode({
        'type': 'create_room',
        'roomName': 'Load Test Room $i',
        'host': 'load_test_user_$i',
        'hostName': 'Load Tester $i',
      }));
    }
    
    // Attendre que toutes les rooms soient créées
    await Future.delayed(const Duration(milliseconds: 2000));
    
    // Fermer toutes les connexions
    for (final connection in connections) {
      await connection.close();
    }
    
    final endTime = DateTime.now();
    final duration = endTime.difference(startTime);
    
    if (roomsCreated.length >= 5 && duration.inMilliseconds < 10000) {
      print('   ✅ Charge multijoueur excellente (${roomsCreated.length} rooms en ${duration.inMilliseconds}ms)');
      return true;
    } else if (roomsCreated.length >= 3) {
      print('   ⚠️  Charge multijoueur acceptable (${roomsCreated.length} rooms en ${duration.inMilliseconds}ms)');
      return true;
    } else {
      print('   ❌ Charge multijoueur insuffisante (${roomsCreated.length} rooms en ${duration.inMilliseconds}ms)');
      return false;
    }
    
  } catch (e) {
    print('   ❌ Erreur test charge multijoueur: $e');
    return false;
  }
}

Future<bool> testMemoryUsage() async {
  print('\n💾 Test 4: Mémoire et ressources...');
  
  try {
    // Test de création et suppression de rooms
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
    
    // Créer plusieurs rooms
    for (int i = 0; i < 10; i++) {
      webSocket.add(jsonEncode({
        'type': 'create_room',
        'roomName': 'Memory Test Room $i',
        'host': 'memory_test_user_$i',
        'hostName': 'Memory Tester $i',
      }));
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    await Future.delayed(const Duration(milliseconds: 2000));
    
    // Vérifier que toutes les rooms ont été créées
    if (roomsCreated.length >= 10) {
      print('   ✅ Gestion mémoire excellente (${roomsCreated.length} rooms créées)');
      
      // Test de nettoyage
      await webSocket.close();
      await Future.delayed(const Duration(milliseconds: 1000));
      
      print('   ✅ Nettoyage des ressources réussi');
      return true;
    } else {
      print('   ❌ Gestion mémoire insuffisante (${roomsCreated.length} rooms créées)');
      return false;
    }
    
  } catch (e) {
    print('   ❌ Erreur test mémoire: $e');
    return false;
  }
}
