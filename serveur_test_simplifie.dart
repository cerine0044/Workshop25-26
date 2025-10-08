import 'dart:io';
import 'dart:convert';
import 'dart:async';

void main() async {
  print('🚀 SERVEUR DE TEST PANDORA BOX');
  print('==============================');
  
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
    localIP = '127.0.0.1';
  }
  
  print('📱 IP détectée: $localIP');
  print('🌐 URL HTTP: http://$localIP:5001');
  print('🔌 URL WebSocket: ws://$localIP:5002');
  print('');
  
  // Stockage des rooms
  final Map<String, Map<String, dynamic>> rooms = {};
  
  try {
    // Démarrer le serveur HTTP
    final httpServer = await HttpServer.bind(InternetAddress.anyIPv4, 5001);
    print('✅ Serveur HTTP démarré sur le port 5001');
    
    // Démarrer le serveur WebSocket
    final wsServer = await HttpServer.bind(InternetAddress.anyIPv4, 5002);
    print('✅ Serveur WebSocket démarré sur le port 5002');
    print('');
    print('🎮 Instructions:');
    print('1. Ouvrez http://$localIP:5001 sur l\'autre PC');
    print('2. Créez une room et testez la connectivité');
    print('3. Utilisez ws://$localIP:5002 pour WebSocket');
    print('');
    print('Appuyez sur Ctrl+C pour arrêter');
    
    // Gérer les connexions HTTP
    httpServer.listen((HttpRequest request) async {
      await _handleHttpRequest(request, rooms, localIP!);
    });
    
    // Gérer les connexions WebSocket
    wsServer.listen((HttpRequest request) async {
      if (WebSocketTransformer.isUpgradeRequest(request)) {
        final webSocket = await WebSocketTransformer.upgrade(request);
        final connectionId = DateTime.now().millisecondsSinceEpoch.toString();
        
        print('🔌 Nouvelle connexion WebSocket: $connectionId');
        
        // Écouter les messages
        webSocket.listen(
          (message) => _handleWebSocketMessage(message, connectionId, webSocket, rooms),
          onError: (error) {
            print('❌ Erreur WebSocket $connectionId: $error');
          },
          onDone: () {
            print('🔌 Déconnexion WebSocket: $connectionId');
          },
        );
      } else {
        request.response.statusCode = 400;
        request.response.write('WebSocket upgrade required');
        request.response.close();
      }
    });
    
  } catch (e) {
    print('❌ Erreur démarrage serveur: $e');
    exit(1);
  }
}

// Gérer les requêtes HTTP
Future<void> _handleHttpRequest(HttpRequest request, Map<String, Map<String, dynamic>> rooms, String localIP) async {
  // Headers CORS
  request.response.headers.add('Access-Control-Allow-Origin', '*');
  request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');
  
  if (request.method == 'OPTIONS') {
    request.response.statusCode = 200;
    request.response.close();
    return;
  }
  
  final uri = request.uri;
  final path = uri.path;
  
  try {
    if (path == '/') {
      // Page d'accueil
      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.html;
      request.response.write(_getHomePage(localIP));
      request.response.close();
    } else if (path == '/rooms') {
      // API des rooms
      if (request.method == 'GET') {
        // Récupérer toutes les rooms
        final roomsList = rooms.values.toList();
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(roomsList));
        request.response.close();
      } else if (request.method == 'POST') {
        // Créer une room
        final body = await utf8.decoder.bind(request).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        
        final roomId = DateTime.now().millisecondsSinceEpoch.toString();
        final roomData = {
          'id': roomId,
          'name': data['name'] ?? 'Room',
          'host': data['host'] ?? 'unknown',
          'players': {
            data['host'] ?? 'unknown': {
              'name': data['hostName'] ?? 'Joueur',
              'isHost': true,
              'isReady': false,
              'joinedAt': DateTime.now().toIso8601String(),
            }
          },
          'gameState': 'waiting',
          'createdAt': DateTime.now().toIso8601String(),
        };
        
        rooms[roomId] = roomData;
        
        request.response.statusCode = 201;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'id': roomId, 'room': roomData}));
        request.response.close();
      }
    } else if (path.startsWith('/room/')) {
      // API d'une room spécifique
      final roomId = path.split('/')[2];
      
      if (request.method == 'GET') {
        // Récupérer une room
        final room = rooms[roomId];
        request.response.statusCode = room != null ? 200 : 404;
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(room));
        request.response.close();
      } else if (request.method == 'PUT') {
        // Mettre à jour une room
        final body = await utf8.decoder.bind(request).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        
        if (rooms.containsKey(roomId)) {
          // Fusionner les données
          final existingRoom = rooms[roomId]!;
          if (data.containsKey('players')) {
            final newPlayers = data['players'] as Map<String, dynamic>;
            final existingPlayers = Map<String, dynamic>.from(existingRoom['players'] ?? {});
            
            // Fusionner les joueurs
            newPlayers.forEach((playerId, playerData) {
              if (playerData == null) {
                existingPlayers.remove(playerId);
              } else {
                existingPlayers[playerId] = playerData;
              }
            });
            
            existingRoom['players'] = existingPlayers;
          }
          
          if (data.containsKey('gameState')) {
            existingRoom['gameState'] = data['gameState'];
          }
          
          if (data.containsKey('gameData')) {
            existingRoom['gameData'] = data['gameData'];
          }
          
          existingRoom['lastUpdated'] = DateTime.now().toIso8601String();
          
          request.response.statusCode = 200;
          request.response.write('Room updated');
          request.response.close();
        } else {
          request.response.statusCode = 404;
          request.response.write('Room not found');
          request.response.close();
        }
      }
    } else {
      // 404
      request.response.statusCode = 404;
      request.response.write('Not Found');
      request.response.close();
    }
  } catch (e) {
    print('❌ Erreur HTTP: $e');
    request.response.statusCode = 500;
    request.response.write('Error: $e');
    request.response.close();
  }
}

// Gérer les messages WebSocket
void _handleWebSocketMessage(
  dynamic message,
  String connectionId,
  WebSocket webSocket,
  Map<String, Map<String, dynamic>> rooms,
) {
  try {
    final data = jsonDecode(message) as Map<String, dynamic>;
    final type = data['type'] as String;
    
    print('📨 Message reçu: $type');
    
    switch (type) {
      case 'ping':
        _sendMessage(webSocket, {'type': 'pong', 'timestamp': DateTime.now().toIso8601String()});
        break;
      case 'create_room':
        _handleCreateRoom(data, webSocket, rooms);
        break;
      case 'join_room':
        _handleJoinRoom(data, webSocket, rooms);
        break;
      case 'get_rooms':
        _handleGetRooms(webSocket, rooms);
        break;
      default:
        _sendMessage(webSocket, {'type': 'error', 'message': 'Type de message non reconnu: $type'});
    }
  } catch (e) {
    print('❌ Erreur traitement message: $e');
    _sendMessage(webSocket, {'type': 'error', 'message': 'Erreur lors du traitement du message: $e'});
  }
}

// Gérer la création de room
void _handleCreateRoom(
  Map<String, dynamic> data,
  WebSocket webSocket,
  Map<String, Map<String, dynamic>> rooms,
) {
  final roomName = data['roomName'] as String? ?? 'Room';
  final host = data['host'] as String? ?? 'unknown';
  final hostName = data['hostName'] as String? ?? 'Joueur';
  
  final roomId = DateTime.now().millisecondsSinceEpoch.toString();
  final roomData = {
    'id': roomId,
    'name': roomName,
    'host': host,
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
  
  _sendMessage(webSocket, {
    'type': 'room_update',
    'room': roomData,
  });
  
  print('🏠 Room créée: $roomName (ID: $roomId) par $host');
}

// Gérer la connexion à une room
void _handleJoinRoom(
  Map<String, dynamic> data,
  WebSocket webSocket,
  Map<String, Map<String, dynamic>> rooms,
) {
  final roomId = data['roomId'] as String?;
  final userId = data['userId'] as String?;
  final userName = data['userName'] as String? ?? 'Joueur';
  
  if (roomId == null || userId == null) {
    _sendMessage(webSocket, {'type': 'error', 'message': 'roomId et userId requis'});
    return;
  }
  
  final room = rooms[roomId];
  if (room == null) {
    _sendMessage(webSocket, {'type': 'error', 'message': 'Room introuvable'});
    return;
  }
  
  final players = Map<String, dynamic>.from(room['players'] ?? {});
  
  // Vérifier si le joueur n'est pas déjà dans la room
  if (players.containsKey(userId)) {
    _sendMessage(webSocket, {
      'type': 'room_update',
      'room': room,
    });
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
  rooms[roomId] = room;
  
  _sendMessage(webSocket, {
    'type': 'room_update',
    'room': room,
  });
  
  print('👥 $userName a rejoint la room $roomId');
}

// Gérer la demande de liste des rooms
void _handleGetRooms(
  WebSocket webSocket,
  Map<String, Map<String, dynamic>> rooms,
) {
  final availableRooms = rooms.values.where((room) => room['gameState'] == 'waiting').toList();
  
  _sendMessage(webSocket, {
    'type': 'rooms_list',
    'rooms': availableRooms,
  });
}

// Envoyer un message à un WebSocket
void _sendMessage(WebSocket webSocket, Map<String, dynamic> message) {
  try {
    webSocket.add(jsonEncode(message));
  } catch (e) {
    print('❌ Erreur lors de l\'envoi du message: $e');
  }
}

// Page d'accueil
String _getHomePage(String localIP) {
  return '''
<!DOCTYPE html>
<html>
<head>
    <title>Pandora Box - Test Serveur</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            text-align: center; 
            padding: 50px; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            margin: 0;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: rgba(255,255,255,0.1);
            padding: 30px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
        }
        .success { color: #4CAF50; font-size: 24px; }
        .info { color: #81C784; margin: 20px 0; }
        .button {
            background: #4CAF50;
            color: white;
            padding: 15px 30px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 16px;
            margin: 10px;
            text-decoration: none;
            display: inline-block;
        }
        .button:hover { background: #45a049; }
        .websocket-status {
            background: rgba(255,255,255,0.1);
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
        }
        .connected { color: #4CAF50; }
        .disconnected { color: #f44336; }
        input {
            padding: 10px;
            border: none;
            border-radius: 5px;
            margin: 5px;
            width: 200px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="success">✅ Serveur Pandora Box Actif !</h1>
        <p class="info">Le serveur de test fonctionne correctement</p>
        
        <div class="info">
            <p><strong>IP:</strong> $localIP</p>
            <p><strong>Port HTTP:</strong> 5001</p>
            <p><strong>Port WebSocket:</strong> 5002</p>
            <p><strong>Timestamp:</strong> ${DateTime.now()}</p>
        </div>
        
        <div class="websocket-status">
            <h3>🔌 Test WebSocket</h3>
            <div id="ws-status" class="disconnected">Déconnecté</div>
            <div>
                <input type="text" id="roomName" placeholder="Nom de la room" />
                <button class="button" onclick="createRoomWS()">Créer Room (WS)</button>
            </div>
            <div>
                <input type="text" id="roomId" placeholder="ID de la room" />
                <button class="button" onclick="joinRoomWS()">Rejoindre (WS)</button>
            </div>
            <div id="ws-messages"></div>
        </div>
        
        <div class="info">
            <p><strong>Instructions:</strong></p>
            <p>1. Ouvrez cette même URL sur l'autre PC</p>
            <p>2. Créez une room avec WebSocket</p>
            <p>3. Rejoignez la room sur l'autre PC</p>
            <p>4. Les mises à jour sont en temps réel !</p>
        </div>
    </div>

    <script>
        let ws = null;
        let userId = 'user_' + Date.now();
        
        function connectWebSocket() {
            const wsUrl = 'ws://$localIP:5002';
            ws = new WebSocket(wsUrl);
            
            ws.onopen = function() {
                document.getElementById('ws-status').textContent = 'Connecté';
                document.getElementById('ws-status').className = 'connected';
                
                // Envoyer un message de connexion
                ws.send(JSON.stringify({
                    type: 'ping',
                    timestamp: new Date().toISOString()
                }));
            };
            
            ws.onmessage = function(event) {
                const data = JSON.parse(event.data);
                addMessage('Reçu: ' + JSON.stringify(data));
                
                if (data.type === 'room_update') {
                    addMessage('Room mise à jour: ' + data.room.name);
                } else if (data.type === 'rooms_list') {
                    addMessage('Liste des rooms: ' + data.rooms.length + ' rooms');
                } else if (data.type === 'pong') {
                    addMessage('Pong reçu du serveur');
                }
            };
            
            ws.onclose = function() {
                document.getElementById('ws-status').textContent = 'Déconnecté';
                document.getElementById('ws-status').className = 'disconnected';
            };
            
            ws.onerror = function(error) {
                addMessage('Erreur WebSocket: ' + error);
            };
        }
        
        function createRoomWS() {
            if (!ws || ws.readyState !== WebSocket.OPEN) {
                alert('WebSocket non connecté');
                return;
            }
            
            const name = document.getElementById('roomName').value || 'Test Room';
            
            ws.send(JSON.stringify({
                type: 'create_room',
                roomName: name,
                host: userId,
                hostName: 'Joueur ' + userId
            }));
        }
        
        function joinRoomWS() {
            if (!ws || ws.readyState !== WebSocket.OPEN) {
                alert('WebSocket non connecté');
                return;
            }
            
            const roomId = document.getElementById('roomId').value;
            if (!roomId) {
                alert('Entrez un ID de room');
                return;
            }
            
            ws.send(JSON.stringify({
                type: 'join_room',
                roomId: roomId,
                userId: userId,
                userName: 'Joueur ' + userId
            }));
        }
        
        function addMessage(message) {
            const div = document.createElement('div');
            div.textContent = new Date().toLocaleTimeString() + ': ' + message;
            div.style.margin = '5px 0';
            div.style.padding = '5px';
            div.style.background = 'rgba(255,255,255,0.1)';
            div.style.borderRadius = '5px';
            document.getElementById('ws-messages').appendChild(div);
        }
        
        // Se connecter automatiquement
        connectWebSocket();
    </script>
</body>
</html>
  ''';
}
