import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() async {
  print('🧪 Test Automatisé WebSocket - Pandora Box');
  print('==========================================');
  
  // Obtenir l'IP locale
  final interfaces = await NetworkInterface.list();
  String? localIP;
  
  for (var interface in interfaces) {
    for (var addr in interface.addresses) {
      if (addr.type == InternetAddressType.IPv4 && 
          !addr.isLoopback && 
          !addr.address.startsWith('169.254') &&
          !addr.address.startsWith('127.')) {
        localIP = addr.address;
        break;
      }
    }
    if (localIP != null) break;
  }
  
  if (localIP == null) {
    localIP = '192.168.1.20';
  }
  
  print('📱 IP détectée: $localIP');
  print('🌐 URL WebSocket: ws://$localIP:5002');
  print('');
  
  // Test 1: Démarrer le serveur WebSocket
  print('🚀 Test 1: Démarrage du serveur WebSocket');
  final server = await _startWebSocketServer(localIP);
  print('✅ Serveur WebSocket démarré sur le port 5002');
  print('');
  
  // Attendre que le serveur soit prêt
  await Future.delayed(Duration(seconds: 2));
  
  // Test 2: Test de connexion WebSocket
  print('🔌 Test 2: Connexion WebSocket');
  final connectionTest = await _testWebSocketConnection(localIP);
  if (connectionTest) {
    print('✅ Connexion WebSocket réussie');
  } else {
    print('❌ Connexion WebSocket échouée');
  }
  print('');
  
  // Test 3: Test de création de room
  print('🏠 Test 3: Création de room');
  final roomCreationTest = await _testRoomCreation(localIP);
  if (roomCreationTest) {
    print('✅ Création de room réussie');
  } else {
    print('❌ Création de room échouée');
  }
  print('');
  
  // Test 4: Test de connexions multiples
  print('👥 Test 4: Connexions multiples');
  final multipleConnectionsTest = await _testMultipleConnections(localIP);
  if (multipleConnectionsTest) {
    print('✅ Test de connexions multiples réussi');
  } else {
    print('❌ Test de connexions multiples échoué');
  }
  print('');
  
  print('🎉 Tests terminés !');
  print('');
  print('📋 Résumé des tests:');
  print('   Connexion WebSocket: ${connectionTest ? "✅" : "❌"}');
  print('   Création de room: ${roomCreationTest ? "✅" : "❌"}');
  print('   Connexions multiples: ${multipleConnectionsTest ? "✅" : "❌"}');
  print('');
  print('🌐 URLs pour tester sur un autre PC:');
  print('   WebSocket: ws://$localIP:5002');
  print('   Application: http://$localIP:8085');
  print('');
  print('📱 Instructions pour l\'autre PC:');
  print('1. Connectez-vous au même réseau WiFi');
  print('2. Ouvrez un terminal');
  print('3. Naviguez vers ce dossier');
  print('4. Exécutez: dart run test_client_simple.dart');
  print('5. Entrez l\'IP: $localIP');
  print('');
  print('Appuyez sur Ctrl+C pour arrêter le serveur');
  
  // Attendre indéfiniment
  await Future.delayed(Duration(days: 365));
}

Future<HttpServer> _startWebSocketServer(String localIP) async {
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 5002);
  
  // Stockage des rooms et connexions
  final Map<String, Map<String, dynamic>> rooms = {};
  final Map<String, WebSocket> connections = {};
  final Map<String, String> userConnections = {};
  
  server.listen((HttpRequest request) async {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final webSocket = await WebSocketTransformer.upgrade(request);
      final connectionId = DateTime.now().millisecondsSinceEpoch.toString();
      
      connections[connectionId] = webSocket;
      print('🔌 Nouvelle connexion: $connectionId');
      
      webSocket.listen(
        (message) => _handleWebSocketMessage(
          message, 
          connectionId, 
          webSocket, 
          rooms, 
          connections, 
          userConnections
        ),
        onError: (error) {
          print('❌ Erreur WebSocket $connectionId: $error');
          _removeConnection(connectionId, connections, userConnections);
        },
        onDone: () {
          print('🔌 Déconnexion: $connectionId');
          _removeConnection(connectionId, connections, userConnections);
        },
      );
    } else {
      request.response.statusCode = 400;
      request.response.write('WebSocket upgrade required');
      request.response.close();
    }
  });
  
  return server;
}

void _handleWebSocketMessage(
  dynamic message,
  String connectionId,
  WebSocket webSocket,
  Map<String, Map<String, dynamic>> rooms,
  Map<String, WebSocket> connections,
  Map<String, String> userConnections,
) {
  try {
    final data = jsonDecode(message) as Map<String, dynamic>;
    final type = data['type'] as String;
    
    switch (type) {
      case 'connect':
        _handleConnect(data, connectionId, userConnections);
        break;
      case 'create_room':
        _handleCreateRoom(data, connectionId, webSocket, rooms, userConnections);
        break;
      case 'join_room':
        _handleJoinRoom(data, connectionId, webSocket, rooms, userConnections);
        break;
      case 'leave_room':
        _handleLeaveRoom(data, connectionId, webSocket, rooms, userConnections);
        break;
      case 'get_rooms':
        _handleGetRooms(data, connectionId, webSocket, rooms, userConnections);
        break;
      case 'ping':
        _handlePing(data, connectionId, webSocket);
        break;
    }
  } catch (e) {
    print('❌ Erreur traitement message: $e');
  }
}

void _handleConnect(Map<String, dynamic> data, String connectionId, Map<String, String> userConnections) {
  final userId = data['userId'] as String?;
  if (userId != null) {
    userConnections[userId] = connectionId;
    print('👤 Utilisateur connecté: $userId');
  }
}

void _handleCreateRoom(
  Map<String, dynamic> data,
  String connectionId,
  WebSocket webSocket,
  Map<String, Map<String, dynamic>> rooms,
  Map<String, String> userConnections,
) {
  final roomName = data['roomName'] as String? ?? 'Test Room';
  final host = data['host'] as String? ?? 'unknown';
  final hostName = data['hostName'] as String? ?? 'Test User';
  
  final roomId = DateTime.now().millisecondsSinceEpoch.toString();
  final roomData = {
    'id': roomId,
    'name': roomName,
    'host': host,
    'hostName': hostName,
    'players': {
      host: {
        'name': hostName,
        'isHost': true,
        'isReady': false,
        'joinedAt': DateTime.now().toIso8601String(),
      }
    },
    'gameState': 'waiting',
    'createdAt': DateTime.now().toIso8601String(),
  };
  
  rooms[roomId] = roomData;
  
  print('🏠 Room créée: $roomId ($roomName)');
  
  webSocket.add(jsonEncode({
    'type': 'room_update',
    'room': roomData,
  }));
}

void _handleJoinRoom(
  Map<String, dynamic> data,
  String connectionId,
  WebSocket webSocket,
  Map<String, Map<String, dynamic>> rooms,
  Map<String, String> userConnections,
) {
  final roomId = data['roomId'] as String?;
  final userId = data['userId'] as String? ?? 'unknown';
  final userName = data['userName'] as String? ?? 'Test User';
  
  if (roomId == null || !rooms.containsKey(roomId)) {
    return;
  }
  
  final room = rooms[roomId]!;
  final players = Map<String, dynamic>.from(room['players'] ?? {});
  
  if (!players.containsKey(userId)) {
    players[userId] = {
      'name': userName,
      'isHost': false,
      'isReady': false,
      'joinedAt': DateTime.now().toIso8601String(),
    };
    
    room['players'] = players;
    print('👤 Joueur $userName a rejoint la room $roomId');
    
    webSocket.add(jsonEncode({
      'type': 'room_update',
      'room': room,
    }));
  }
}

void _handleLeaveRoom(
  Map<String, dynamic> data,
  String connectionId,
  WebSocket webSocket,
  Map<String, Map<String, dynamic>> rooms,
  Map<String, String> userConnections,
) {
  final roomId = data['roomId'] as String?;
  final userId = data['userId'] as String? ?? 'unknown';
  
  if (roomId == null || !rooms.containsKey(roomId)) {
    return;
  }
  
  final room = rooms[roomId]!;
  final players = Map<String, dynamic>.from(room['players'] ?? {});
  
  if (players.containsKey(userId)) {
    players.remove(userId);
    room['players'] = players;
    print('👤 Joueur $userId a quitté la room $roomId');
    
    webSocket.add(jsonEncode({
      'type': 'room_update',
      'room': room,
    }));
  }
}

void _handleGetRooms(
  Map<String, dynamic> data,
  String connectionId,
  WebSocket webSocket,
  Map<String, Map<String, dynamic>> rooms,
  Map<String, String> userConnections,
) {
  final availableRooms = rooms.values
      .where((room) => room['gameState'] == 'waiting')
      .toList();
  
  webSocket.add(jsonEncode({
    'type': 'rooms_list',
    'rooms': availableRooms,
  }));
}

void _handlePing(Map<String, dynamic> data, String connectionId, WebSocket webSocket) {
  webSocket.add(jsonEncode({
    'type': 'pong',
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  }));
}

void _removeConnection(
  String connectionId,
  Map<String, WebSocket> connections,
  Map<String, String> userConnections,
) {
  connections.remove(connectionId);
  userConnections.removeWhere((userId, connId) => connId == connectionId);
}

Future<bool> _testWebSocketConnection(String localIP) async {
  try {
    final channel = WebSocketChannel.connect(Uri.parse('ws://$localIP:5002'));
    
    final completer = Completer<bool>();
    channel.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message) as Map<String, dynamic>;
          if (data['type'] == 'pong') {
            completer.complete(true);
          }
        } catch (e) {
          completer.complete(false);
        }
      },
      onError: (error) => completer.complete(false),
    );
    
    // Envoyer un ping
    channel.sink.add(jsonEncode({
      'type': 'ping',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    }));
    
    final success = await completer.future.timeout(Duration(seconds: 5));
    await channel.sink.close();
    return success;
  } catch (e) {
    return false;
  }
}

Future<bool> _testRoomCreation(String localIP) async {
  try {
    final channel = WebSocketChannel.connect(Uri.parse('ws://$localIP:5002'));
    
    final completer = Completer<bool>();
    channel.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message) as Map<String, dynamic>;
          if (data['type'] == 'room_update') {
            completer.complete(true);
          }
        } catch (e) {
          completer.complete(false);
        }
      },
      onError: (error) => completer.complete(false),
    );
    
    // Créer une room de test
    channel.sink.add(jsonEncode({
      'type': 'create_room',
      'roomName': 'Test Room Automatique',
      'host': 'test_user_auto',
      'hostName': 'Test User Auto',
    }));
    
    final success = await completer.future.timeout(Duration(seconds: 5));
    await channel.sink.close();
    return success;
  } catch (e) {
    return false;
  }
}

Future<bool> _testMultipleConnections(String localIP) async {
  try {
    final channels = <WebSocketChannel>[];
    
    // Créer 3 connexions
    for (int i = 0; i < 3; i++) {
      final channel = WebSocketChannel.connect(Uri.parse('ws://$localIP:5002'));
      channels.add(channel);
      
      // Se connecter
      channel.sink.add(jsonEncode({
        'type': 'connect',
        'userId': 'test_user_$i',
      }));
    }
    
    await Future.delayed(Duration(seconds: 2));
    
    // Fermer les connexions
    for (final channel in channels) {
      await channel.sink.close();
    }
    
    return true;
  } catch (e) {
    return false;
  }
}
