import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

void main() async {
  print('🧪 Test de Bout en Bout - WebSocket Pandora Box');
  print('===============================================');
  
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
    localIP = '10.151.18.84';
  }
  
  print('📱 IP détectée: $localIP');
  print('🌐 URL WebSocket: ws://$localIP:5002');
  print('');
  
  // Démarrer le serveur WebSocket
  print('🚀 Démarrage du serveur WebSocket...');
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 5002);
  print('✅ Serveur WebSocket démarré sur le port 5002');
  
  // Stockage des rooms et connexions
  final Map<String, Map<String, dynamic>> rooms = {};
  final Map<String, WebSocket> connections = {};
  final Map<String, String> userConnections = {};
  
  // Gérer les connexions WebSocket
  server.listen((HttpRequest request) async {
    if (WebSocketTransformer.isUpgradeRequest(request)) {
      final webSocket = await WebSocketTransformer.upgrade(request);
      final connectionId = DateTime.now().millisecondsSinceEpoch.toString();
      
      connections[connectionId] = webSocket;
      print('🔌 Nouvelle connexion WebSocket: $connectionId');
      
      // Écouter les messages
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
          print('🔌 Déconnexion WebSocket: $connectionId');
          _removeConnection(connectionId, connections, userConnections);
        },
      );
    } else {
      request.response.statusCode = 400;
      request.response.write('WebSocket upgrade required');
      request.response.close();
    }
  });
  
  print('');
  print('🎮 Instructions pour tester:');
  print('1. Sur un autre PC, ouvrez un navigateur');
  print('2. Allez à: http://$localIP:8085');
  print('3. Ou utilisez le client de test: dart run test_client.dart');
  print('');
  print('📋 URLs importantes:');
  print('   WebSocket: ws://$localIP:5002');
  print('   Application: http://$localIP:8085');
  print('');
  print('Appuyez sur Ctrl+C pour arrêter');
  
  // Attendre indéfiniment
  await Future.delayed(Duration(days: 365));
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
    
    print('📨 Message reçu ($connectionId): $type');
    
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
      case 'update_player_ready':
        _handleUpdatePlayerReady(data, connectionId, webSocket, rooms, userConnections);
        break;
      case 'update_game_state':
        _handleUpdateGameState(data, connectionId, webSocket, rooms, userConnections);
        break;
      case 'get_rooms':
        _handleGetRooms(data, connectionId, webSocket, rooms, userConnections);
        break;
      case 'ping':
        _handlePing(data, connectionId, webSocket);
        break;
      default:
        print('⚠️ Message non reconnu: $type');
        _sendError(webSocket, 'Type de message non reconnu: $type');
    }
  } catch (e) {
    print('❌ Erreur lors du traitement du message: $e');
    _sendError(webSocket, 'Erreur de traitement: $e');
  }
}

void _handleConnect(Map<String, dynamic> data, String connectionId, Map<String, String> userConnections) {
  final userId = data['userId'] as String?;
  if (userId != null) {
    userConnections[userId] = connectionId;
    print('👤 Utilisateur connecté: $userId -> $connectionId');
  }
}

void _handleCreateRoom(
  Map<String, dynamic> data,
  String connectionId,
  WebSocket webSocket,
  Map<String, Map<String, dynamic>> rooms,
  Map<String, String> userConnections,
) {
  final roomName = data['roomName'] as String? ?? 'Room';
  final host = data['host'] as String? ?? 'unknown';
  final hostName = data['hostName'] as String? ?? 'Joueur';
  
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
    'lastUpdated': DateTime.now().toIso8601String(),
  };
  
  rooms[roomId] = roomData;
  
  print('🏠 Room créée: $roomId ($roomName) par $hostName');
  
  // Envoyer la confirmation
  webSocket.add(jsonEncode({
    'type': 'room_update',
    'room': roomData,
  }));
  
  // Notifier tous les autres clients
  _broadcastRoomsList(rooms, connections, userConnections);
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
  final userName = data['userName'] as String? ?? 'Joueur';
  
  if (roomId == null || !rooms.containsKey(roomId)) {
    _sendError(webSocket, 'Room introuvable');
    return;
  }
  
  final room = rooms[roomId]!;
  final players = Map<String, dynamic>.from(room['players'] ?? {});
  
  // Vérifier si le joueur n'est pas déjà dans la room
  if (players.containsKey(userId)) {
    print('👤 Joueur $userName déjà dans la room $roomId');
    webSocket.add(jsonEncode({
      'type': 'room_update',
      'room': room,
    }));
    return;
  }
  
  // Ajouter le joueur à la room
  players[userId] = {
    'name': userName,
    'isHost': false,
    'isReady': false,
    'joinedAt': DateTime.now().toIso8601String(),
  };
  
  room['players'] = players;
  room['lastUpdated'] = DateTime.now().toIso8601String();
  
  print('👤 Joueur $userName a rejoint la room $roomId');
  
  // Envoyer la mise à jour
  webSocket.add(jsonEncode({
    'type': 'room_update',
    'room': room,
  }));
  
  // Notifier tous les autres clients
  _broadcastRoomUpdate(room, connections, userConnections);
  _broadcastRoomsList(rooms, connections, userConnections);
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
    final playerName = players[userId]['name'] ?? 'Joueur';
    players.remove(userId);
    
    // Si c'était l'hôte qui partait, transférer l'hôte ou supprimer la room
    if (room['host'] == userId) {
      if (players.isNotEmpty) {
        // Transférer l'hôte au premier joueur restant
        final newHostId = players.keys.first;
        players[newHostId]['isHost'] = true;
        room['host'] = newHostId;
        room['players'] = players;
        print('👑 Hôte transféré à ${players[newHostId]['name']} dans la room $roomId');
      } else {
        // Supprimer la room si plus personne
        rooms.remove(roomId);
        print('🗑️ Room $roomId supprimée (plus de joueurs)');
        _broadcastRoomsList(rooms, connections, userConnections);
        return;
      }
    } else {
      room['players'] = players;
    }
    
    room['lastUpdated'] = DateTime.now().toIso8601String();
    
    print('👤 Joueur $playerName a quitté la room $roomId');
    
    // Notifier tous les autres clients
    _broadcastRoomUpdate(room, connections, userConnections);
    _broadcastRoomsList(rooms, connections, userConnections);
  }
}

void _handleUpdatePlayerReady(
  Map<String, dynamic> data,
  String connectionId,
  WebSocket webSocket,
  Map<String, Map<String, dynamic>> rooms,
  Map<String, String> userConnections,
) {
  final roomId = data['roomId'] as String?;
  final userId = data['userId'] as String? ?? 'unknown';
  final isReady = data['isReady'] as bool? ?? false;
  
  if (roomId == null || !rooms.containsKey(roomId)) {
    _sendError(webSocket, 'Room introuvable');
    return;
  }
  
  final room = rooms[roomId]!;
  final players = Map<String, dynamic>.from(room['players'] ?? {});
  
  if (players.containsKey(userId)) {
    players[userId]['isReady'] = isReady;
    room['players'] = players;
    room['lastUpdated'] = DateTime.now().toIso8601String();
    
    final playerName = players[userId]['name'] ?? 'Joueur';
    print('✅ Joueur $playerName est ${isReady ? 'prêt' : 'non prêt'} dans la room $roomId');
    
    // Notifier tous les autres clients
    _broadcastRoomUpdate(room, connections, userConnections);
  }
}

void _handleUpdateGameState(
  Map<String, dynamic> data,
  String connectionId,
  WebSocket webSocket,
  Map<String, Map<String, dynamic>> rooms,
  Map<String, String> userConnections,
) {
  final roomId = data['roomId'] as String?;
  final gameState = data['gameState'] as String? ?? 'waiting';
  final gameData = data['gameData'] as Map<String, dynamic>?;
  
  if (roomId == null || !rooms.containsKey(roomId)) {
    _sendError(webSocket, 'Room introuvable');
    return;
  }
  
  final room = rooms[roomId]!;
  room['gameState'] = gameState;
  room['lastUpdated'] = DateTime.now().toIso8601String();
  
  if (gameData != null) {
    room['gameData'] = gameData;
  }
  
  print('🎮 État du jeu mis à jour pour la room $roomId: $gameState');
  
  // Notifier tous les autres clients
  _broadcastRoomUpdate(room, connections, userConnections);
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
  
  print('📋 Envoi de ${availableRooms.length} rooms disponibles');
  
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

void _broadcastRoomUpdate(
  Map<String, dynamic> room,
  Map<String, WebSocket> connections,
  Map<String, String> userConnections,
) {
  final message = jsonEncode({
    'type': 'room_update',
    'room': room,
  });
  
  for (final connection in connections.values) {
    try {
      connection.add(message);
    } catch (e) {
      print('❌ Erreur lors de l\'envoi de la mise à jour: $e');
    }
  }
}

void _broadcastRoomsList(
  Map<String, Map<String, dynamic>> rooms,
  Map<String, WebSocket> connections,
  Map<String, String> userConnections,
) {
  final availableRooms = rooms.values
      .where((room) => room['gameState'] == 'waiting')
      .toList();
  
  final message = jsonEncode({
    'type': 'rooms_list',
    'rooms': availableRooms,
  });
  
  for (final connection in connections.values) {
    try {
      connection.add(message);
    } catch (e) {
      print('❌ Erreur lors de l\'envoi de la liste: $e');
    }
  }
}

void _sendError(WebSocket webSocket, String message) {
  try {
    webSocket.add(jsonEncode({
      'type': 'error',
      'message': message,
    }));
  } catch (e) {
    print('❌ Erreur lors de l\'envoi d\'erreur: $e');
  }
}

void _removeConnection(
  String connectionId,
  Map<String, WebSocket> connections,
  Map<String, String> userConnections,
) {
  connections.remove(connectionId);
  
  // Nettoyer les références utilisateur
  userConnections.removeWhere((userId, connId) => connId == connectionId);
  
  print('🧹 Connexion $connectionId nettoyée');
}
