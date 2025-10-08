import 'dart:io';
import 'dart:convert';
import 'dart:async';

void main() async {
  print('🔍 DIAGNOSTIC COMPLET DE CONNECTIVITÉ PANDORA BOX');
  print('================================================');
  
  // Test 1: Vérification des ports
  await testPorts();
  
  // Test 2: Test du serveur WebSocket
  await testWebSocketServer();
  
  // Test 3: Test du serveur HTTP
  await testHttpServer();
  
  // Test 4: Test de création de room
  await testRoomCreation();
  
  // Test 5: Test de connexion multijoueur
  await testMultiplayerConnection();
  
  print('\n✅ DIAGNOSTIC TERMINÉ');
}

Future<void> testPorts() async {
  print('\n📡 TEST 1: Vérification des ports');
  print('----------------------------------');
  
  final ports = [5001, 5002, 8081];
  
  for (int port in ports) {
    try {
      final socket = await Socket.connect('localhost', port, timeout: Duration(seconds: 3));
      print('✅ Port $port: OUVERT');
      socket.destroy();
    } catch (e) {
      print('❌ Port $port: FERMÉ ($e)');
    }
  }
}

Future<void> testWebSocketServer() async {
  print('\n🔌 TEST 2: Serveur WebSocket');
  print('-----------------------------');
  
  try {
    final socket = await Socket.connect('localhost', 5002, timeout: Duration(seconds: 5));
    print('✅ Connexion WebSocket établie');
    
    // Envoyer un message de test
    final testMessage = jsonEncode({
      'type': 'ping',
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    socket.add(utf8.encode(testMessage + '\n'));
    
    // Attendre une réponse
    final completer = Completer<String>();
    Timer(Duration(seconds: 2), () => completer.complete('timeout'));
    
    socket.listen((data) {
      final response = utf8.decode(data);
      print('📨 Réponse serveur: $response');
      if (!completer.isCompleted) {
        completer.complete(response);
      }
    });
    
    final result = await completer.future;
    if (result == 'timeout') {
      print('⚠️  Pas de réponse du serveur WebSocket');
    } else {
      print('✅ Serveur WebSocket répond');
    }
    
    socket.destroy();
  } catch (e) {
    print('❌ Erreur WebSocket: $e');
  }
}

Future<void> testHttpServer() async {
  print('\n🌐 TEST 3: Serveur HTTP');
  print('------------------------');
  
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:5001/'));
    final response = await request.close();
    
    print('✅ Serveur HTTP accessible (Status: ${response.statusCode})');
    
    final body = await response.transform(utf8.decoder).join();
    if (body.contains('Pandora Box')) {
      print('✅ Page d\'accueil chargée correctement');
    } else {
      print('⚠️  Page d\'accueil inattendue');
    }
    
    client.close();
  } catch (e) {
    print('❌ Erreur HTTP: $e');
  }
}

Future<void> testRoomCreation() async {
  print('\n🏠 TEST 4: Création de room');
  print('-----------------------------');
  
  try {
    final client = HttpClient();
    final request = await client.postUrl(Uri.parse('http://localhost:5001/rooms'));
    request.headers.contentType = ContentType.json;
    
    final roomData = {
      'name': 'Test Room ${DateTime.now().millisecondsSinceEpoch}',
      'host': 'test_user',
      'hostName': 'Test User',
    };
    
    request.write(jsonEncode(roomData));
    final response = await request.close();
    
    if (response.statusCode == 201) {
      print('✅ Room créée avec succès');
      
      final body = await response.transform(utf8.decoder).join();
      final data = jsonDecode(body) as Map<String, dynamic>;
      final roomId = data['id'] as String?;
      
      if (roomId != null) {
        print('📋 ID de room: $roomId');
        
        // Tester la récupération de la room
        await testRoomRetrieval(roomId);
      }
    } else {
      print('❌ Erreur création room (Status: ${response.statusCode})');
    }
    
    client.close();
  } catch (e) {
    print('❌ Erreur création room: $e');
  }
}

Future<void> testRoomRetrieval(String roomId) async {
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://localhost:5001/room/$roomId'));
    final response = await request.close();
    
    if (response.statusCode == 200) {
      print('✅ Room récupérée avec succès');
      
      final body = await response.transform(utf8.decoder).join();
      final roomData = jsonDecode(body) as Map<String, dynamic>;
      
      print('📊 Données room:');
      print('   - Nom: ${roomData['name']}');
      print('   - Hôte: ${roomData['host']}');
      print('   - État: ${roomData['gameState']}');
      print('   - Joueurs: ${(roomData['players'] as Map?)?.length ?? 0}');
    } else {
      print('❌ Erreur récupération room (Status: ${response.statusCode})');
    }
    
    client.close();
  } catch (e) {
    print('❌ Erreur récupération room: $e');
  }
}

Future<void> testMultiplayerConnection() async {
  print('\n👥 TEST 5: Connexion multijoueur');
  print('----------------------------------');
  
  try {
    // Simuler deux connexions simultanées
    final client1 = HttpClient();
    final client2 = HttpClient();
    
    // Créer une room avec le premier client
    final request1 = await client1.postUrl(Uri.parse('http://localhost:5001/rooms'));
    request1.headers.contentType = ContentType.json;
    
    final roomData = {
      'name': 'Multiplayer Test Room',
      'host': 'player1',
      'hostName': 'Player 1',
    };
    
    request1.write(jsonEncode(roomData));
    final response1 = await request1.close();
    
    if (response1.statusCode == 201) {
      final body1 = await response1.transform(utf8.decoder).join();
      final data1 = jsonDecode(body1) as Map<String, dynamic>;
      final roomId = data1['id'] as String?;
      
      if (roomId != null) {
        print('✅ Room créée par Player 1');
        
        // Rejoindre avec le deuxième client
        final request2 = await client2.putUrl(Uri.parse('http://localhost:5001/room/$roomId'));
        request2.headers.contentType = ContentType.json;
        
        final joinData = {
          'players': {
            'player2': {
              'name': 'Player 2',
              'isHost': false,
              'isReady': false,
              'joinedAt': DateTime.now().toIso8601String(),
            }
          }
        };
        
        request2.write(jsonEncode(joinData));
        final response2 = await request2.close();
        
        if (response2.statusCode == 200) {
          print('✅ Player 2 a rejoint la room');
          
          // Vérifier l'état final de la room
          await Future.delayed(Duration(milliseconds: 500));
          await testRoomRetrieval(roomId);
          
          print('✅ Test multijoueur réussi');
        } else {
          print('❌ Erreur rejoindre room (Status: ${response2.statusCode})');
        }
      }
    } else {
      print('❌ Erreur création room multijoueur (Status: ${response1.statusCode})');
    }
    
    client1.close();
    client2.close();
  } catch (e) {
    print('❌ Erreur test multijoueur: $e');
  }
}
