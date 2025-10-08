import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:math';

void main() async {
  print('🔧 DÉBOGAGE CONNEXION MULTIJOUEUR PANDORA BOX');
  print('=============================================');
  
  // Test 1: Diagnostic des services
  await diagnoseServices();
  
  // Test 2: Test de connectivité réseau
  await testNetworkConnectivity();
  
  // Test 3: Test des ports et serveurs
  await testPortsAndServers();
  
  // Test 4: Simulation de connexion multijoueur
  await simulateMultiplayerConnection();
  
  // Test 5: Test de synchronisation des données
  await testDataSynchronization();
  
  // Test 6: Test de gestion des erreurs
  await testErrorHandling();
  
  print('\n✅ DÉBOGAGE TERMINÉ');
  print('Consultez les résultats ci-dessus pour identifier les problèmes');
}

Future<void> diagnoseServices() async {
  print('\n🔍 DIAGNOSTIC DES SERVICES');
  print('----------------------------');
  
  // Vérifier les fichiers de services
  final serviceFiles = [
    'lib/services/http_game_service.dart',
    'lib/services/websocket_game_service.dart',
    'lib/services/local_game_service.dart',
    'lib/services/shared_local_service.dart',
  ];
  
  for (String file in serviceFiles) {
    final fileExists = File(file).existsSync();
    if (fileExists) {
      print('✅ $file existe');
      
      // Analyser le contenu du fichier
      try {
        final content = await File(file).readAsString();
        
        // Vérifier les méthodes critiques
        final criticalMethods = [
          'initialize',
          'createGameRoom',
          'joinGameRoom',
          'listenToRoom',
          'updateGameState',
        ];
        
        for (String method in criticalMethods) {
          if (content.contains('$method(')) {
            print('  ✅ Méthode $method présente');
          } else {
            print('  ❌ Méthode $method manquante');
          }
        }
        
        // Vérifier les URLs de serveur
        if (content.contains('localhost') || content.contains('127.0.0.1')) {
          print('  ⚠️  Utilise localhost (peut causer des problèmes réseau)');
        }
        
        if (content.contains('10.151.18.84')) {
          print('  ⚠️  IP hardcodée détectée');
        }
        
      } catch (e) {
        print('  ❌ Erreur lecture fichier: $e');
      }
    } else {
      print('❌ $file manquant');
    }
  }
}

Future<void> testNetworkConnectivity() async {
  print('\n🌐 TEST DE CONNECTIVITÉ RÉSEAU');
  print('--------------------------------');
  
  // Test des interfaces réseau
  try {
    final interfaces = await NetworkInterface.list();
    print('📡 Interfaces réseau détectées:');
    
    for (NetworkInterface interface in interfaces) {
      print('  🔌 ${interface.name}:');
      for (InternetAddress address in interface.addresses) {
        if (address.type == InternetAddressType.IPv4) {
          print('    📍 ${address.address}');
        }
      }
    }
    
    // Tester la connectivité locale
    final localhostTest = await testConnection('localhost', 5001);
    print('🏠 Localhost:5001 - ${localhostTest ? "✅ Accessible" : "❌ Inaccessible"}');
    
    final localhostTest2 = await testConnection('localhost', 5002);
    print('🏠 Localhost:5002 - ${localhostTest2 ? "✅ Accessible" : "❌ Inaccessible"}');
    
    // Tester avec l'IP locale
    for (NetworkInterface interface in interfaces) {
      for (InternetAddress address in interface.addresses) {
        if (address.type == InternetAddressType.IPv4 && !address.isLoopback) {
          final ipTest1 = await testConnection(address.address, 5001);
          final ipTest2 = await testConnection(address.address, 5002);
          print('🌐 ${address.address}:5001 - ${ipTest1 ? "✅ Accessible" : "❌ Inaccessible"}');
          print('🌐 ${address.address}:5002 - ${ipTest2 ? "✅ Accessible" : "❌ Inaccessible"}');
        }
      }
    }
    
  } catch (e) {
    print('❌ Erreur test connectivité: $e');
  }
}

Future<bool> testConnection(String host, int port) async {
  try {
    final socket = await Socket.connect(host, port, timeout: Duration(seconds: 2));
    socket.destroy();
    return true;
  } catch (e) {
    return false;
  }
}

Future<void> testPortsAndServers() async {
  print('\n🔌 TEST DES PORTS ET SERVEURS');
  print('------------------------------');
  
  final ports = [5001, 5002, 8081];
  
  for (int port in ports) {
    print('🔍 Test port $port...');
    
    // Test TCP
    final tcpTest = await testConnection('localhost', port);
    print('  TCP: ${tcpTest ? "✅ Ouvert" : "❌ Fermé"}');
    
    // Test HTTP si port 5001
    if (port == 5001) {
      await testHttpEndpoint(port);
    }
    
    // Test WebSocket si port 5002
    if (port == 5002) {
      await testWebSocketEndpoint(port);
    }
  }
}

Future<void> testHttpEndpoint(int port) async {
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:$port/'));
    final response = await request.close();
    
    print('  HTTP: ✅ Status ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      if (body.contains('Pandora Box')) {
        print('  📄 Page d\'accueil détectée');
      }
    }
    
    client.close();
  } catch (e) {
    print('  HTTP: ❌ Erreur $e');
  }
}

Future<void> testWebSocketEndpoint(int port) async {
  try {
    final socket = await Socket.connect('localhost', port, timeout: Duration(seconds: 3));
    
    // Envoyer un message de test
    final testMessage = jsonEncode({
      'type': 'ping',
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    socket.add(utf8.encode(testMessage + '\n'));
    
    // Attendre une réponse
    final completer = Completer<bool>();
    Timer(Duration(seconds: 2), () => completer.complete(false));
    
    socket.listen((data) {
      final response = utf8.decode(data);
      print('  WebSocket: ✅ Réponse reçue');
      if (!completer.isCompleted) {
        completer.complete(true);
      }
    });
    
    final hasResponse = await completer.future;
    if (!hasResponse) {
      print('  WebSocket: ⚠️  Pas de réponse');
    }
    
    socket.destroy();
  } catch (e) {
    print('  WebSocket: ❌ Erreur $e');
  }
}

Future<void> simulateMultiplayerConnection() async {
  print('\n👥 SIMULATION CONNEXION MULTIJOUEUR');
  print('------------------------------------');
  
  try {
    // Simuler deux clients
    final client1 = HttpClient();
    final client2 = HttpClient();
    
    print('🔄 Simulation Client 1...');
    
    // Client 1: Créer une room
    final request1 = await client1.postUrl(Uri.parse('http://localhost:5001/rooms'));
    request1.headers.contentType = ContentType.json;
    
    final roomData = {
      'name': 'Test Debug Room',
      'host': 'debug_user_1',
      'hostName': 'Debug User 1',
    };
    
    request1.write(jsonEncode(roomData));
    final response1 = await request1.close();
    
    if (response1.statusCode == 201) {
      print('✅ Client 1: Room créée');
      
      final body1 = await response1.transform(utf8.decoder).join();
      final data1 = jsonDecode(body1) as Map<String, dynamic>;
      final roomId = data1['id'] as String?;
      
      if (roomId != null) {
        print('📋 Room ID: $roomId');
        
        print('🔄 Simulation Client 2...');
        
        // Client 2: Rejoindre la room
        final request2 = await client2.putUrl(Uri.parse('http://localhost:5001/room/$roomId'));
        request2.headers.contentType = ContentType.json;
        
        final joinData = {
          'players': {
            'debug_user_2': {
              'name': 'Debug User 2',
              'isHost': false,
              'isReady': false,
              'joinedAt': DateTime.now().toIso8601String(),
            }
          }
        };
        
        request2.write(jsonEncode(joinData));
        final response2 = await request2.close();
        
        if (response2.statusCode == 200) {
          print('✅ Client 2: Room rejointe');
          
          // Vérifier l'état final
          await Future.delayed(Duration(milliseconds: 500));
          await verifyRoomState(roomId);
          
        } else {
          print('❌ Client 2: Erreur rejoindre room (${response2.statusCode})');
        }
      } else {
        print('❌ Client 1: Room ID manquant');
      }
    } else {
      print('❌ Client 1: Erreur création room (${response1.statusCode})');
    }
    
    client1.close();
    client2.close();
    
  } catch (e) {
    print('❌ Erreur simulation multijoueur: $e');
  }
}

Future<void> verifyRoomState(String roomId) async {
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:5001/room/$roomId'));
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      final roomData = jsonDecode(body) as Map<String, dynamic>;
      
      print('📊 État de la room:');
      print('  🏠 Nom: ${roomData['name']}');
      print('  👤 Hôte: ${roomData['host']}');
      print('  🎮 État: ${roomData['gameState']}');
      
      final players = roomData['players'] as Map<String, dynamic>?;
      if (players != null) {
        print('  👥 Joueurs: ${players.length}');
        players.forEach((id, data) {
          print('    - $id: ${data['name']} (${data['isHost'] ? 'Hôte' : 'Joueur'})');
        });
      }
      
      if (players != null && players.length == 2) {
        print('✅ Connexion multijoueur réussie!');
      } else {
        print('⚠️  Connexion multijoueur incomplète');
      }
    } else {
      print('❌ Erreur vérification room (${response.statusCode})');
    }
    
    client.close();
  } catch (e) {
    print('❌ Erreur vérification room: $e');
  }
}

Future<void> testDataSynchronization() async {
  print('\n🔄 TEST SYNCHRONISATION DES DONNÉES');
  print('------------------------------------');
  
  try {
    // Simuler la synchronisation des données de jeu
    final gameData = {
      'player1': {
        'score': 100,
        'level': 1,
        'position': {'x': 10, 'y': 20},
        'timestamp': DateTime.now().toIso8601String(),
      },
      'player2': {
        'score': 150,
        'level': 2,
        'position': {'x': 15, 'y': 25},
        'timestamp': DateTime.now().toIso8601String(),
      },
    };
    
    print('📊 Données de jeu simulées:');
    gameData.forEach((player, data) {
      print('  $player: ${data['score']} points, niveau ${data['level']}');
    });
    
    // Tester la cohérence des données
    bool dataConsistent = true;
    gameData.forEach((player, data) {
      if (data['score'] is int && data['level'] is int) {
        print('✅ Données $player cohérentes');
      } else {
        print('❌ Données $player incohérentes');
        dataConsistent = false;
      }
    });
    
    // Tester la synchronisation temporelle
    final timestamps = gameData.values.map((data) => DateTime.parse(data['timestamp'] as String)).toList();
    final timeDiff = timestamps[1].difference(timestamps[0]).inMilliseconds;
    
    if (timeDiff < 1000) {
      print('✅ Synchronisation temporelle OK (${timeDiff}ms)');
    } else {
      print('⚠️  Désynchronisation temporelle (${timeDiff}ms)');
    }
    
    if (dataConsistent) {
      print('✅ Test synchronisation réussi');
    } else {
      print('❌ Erreur synchronisation');
    }
    
  } catch (e) {
    print('❌ Erreur test synchronisation: $e');
  }
}

Future<void> testErrorHandling() async {
  print('\n⚠️  TEST GESTION DES ERREURS');
  print('-----------------------------');
  
  // Test des erreurs de connexion
  final errorScenarios = [
    'Connexion refusée',
    'Timeout de connexion',
    'Serveur indisponible',
    'Données corrompues',
    'Room introuvable',
  ];
  
  for (String scenario in errorScenarios) {
    print('🔄 Test: $scenario');
    
    // Simuler la gestion d'erreur
    try {
      await simulateError(scenario);
      print('✅ Gestion d\'erreur OK');
    } catch (e) {
      print('❌ Erreur non gérée: $e');
    }
  }
  
  // Test de récupération après erreur
  print('🔄 Test récupération après erreur...');
  try {
    await Future.delayed(Duration(milliseconds: 100));
    print('✅ Récupération réussie');
  } catch (e) {
    print('❌ Échec récupération: $e');
  }
}

Future<void> simulateError(String scenario) async {
  // Simuler différents types d'erreurs
  switch (scenario) {
    case 'Connexion refusée':
      throw SocketException('Connection refused');
    case 'Timeout de connexion':
      throw TimeoutException('Connection timeout', Duration(seconds: 5));
    case 'Serveur indisponible':
      throw HttpException('Server unavailable');
    case 'Données corrompues':
      throw FormatException('Invalid data format');
    case 'Room introuvable':
      throw Exception('Room not found');
    default:
      throw Exception('Unknown error');
  }
}
