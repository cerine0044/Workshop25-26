import 'dart:io';
import 'dart:convert';

void main() async {
  print('🌐 Pandora Box - Serveur Multijoueur Simple');
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
    localIP = '192.0.0.2'; // IP par défaut du hotspot
  }
  
  print('📱 IP détectée: $localIP');
  print('🌐 URL à partager: http://$localIP:5000');
  print('');
  
  // Démarrer le serveur
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 5000);
  print('✅ Serveur démarré sur le port 5000');
  print('📱 Testez avec: http://$localIP:5000');
  print('');
  print('🎮 Instructions:');
  print('1. Ouvrez http://$localIP:5000 sur l\'autre PC');
  print('2. Vous devriez voir l\'interface de test');
  print('3. Si ça marche, on configurera Flutter');
  print('');
  print('Appuyez sur Ctrl+C pour arrêter');
  
  // Stockage simple des rooms
  final Map<String, Map<String, dynamic>> rooms = {};
  
  await for (HttpRequest request in server) {
    // Headers CORS
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');
    
    if (request.method == 'OPTIONS') {
      request.response.statusCode = 200;
      request.response.close();
      continue;
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
            rooms[roomId]!.addAll(data);
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
      request.response.statusCode = 500;
      request.response.write('Error: $e');
      request.response.close();
    }
  }
}

String _getHomePage(String localIP) {
  return '''
<!DOCTYPE html>
<html>
<head>
    <title>Pandora Box - Test Multijoueur</title>
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
        .room-list {
            background: rgba(255,255,255,0.1);
            padding: 20px;
            border-radius: 10px;
            margin: 20px 0;
        }
        .room-item {
            background: rgba(255,255,255,0.2);
            padding: 15px;
            margin: 10px 0;
            border-radius: 8px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
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
        <h1 class="success">✅ Serveur Multijoueur Actif !</h1>
        <p class="info">Le serveur Pandora Box fonctionne correctement</p>
        
        <div class="info">
            <p><strong>IP:</strong> $localIP</p>
            <p><strong>Port:</strong> 5000</p>
            <p><strong>Timestamp:</strong> ${DateTime.now()}</p>
        </div>
        
        <div class="room-list">
            <h3>🎮 Test des Rooms</h3>
            <div>
                <input type="text" id="roomName" placeholder="Nom de la room" />
                <button class="button" onclick="createRoom()">Créer Room</button>
            </div>
            <div>
                <input type="text" id="roomId" placeholder="ID de la room" />
                <button class="button" onclick="joinRoom()">Rejoindre</button>
            </div>
            <div id="rooms"></div>
        </div>
        
        <div class="info">
            <p><strong>Instructions:</strong></p>
            <p>1. Ouvrez cette même URL sur l'autre PC</p>
            <p>2. Créez une room sur un PC</p>
            <p>3. Rejoignez la room sur l'autre PC</p>
            <p>4. Si ça marche, le multijoueur fonctionne !</p>
        </div>
        
        <a href="http://localhost:8080" class="button" target="_blank">
            🚀 Ouvrir Pandora Box (Local)
        </a>
    </div>

    <script>
        let rooms = {};
        
        function createRoom() {
            const name = document.getElementById('roomName').value || 'Test Room';
            const host = 'user_' + Date.now();
            
            fetch('/rooms', {
                method: 'POST',
                headers: {'Content-Type': 'application/json'},
                body: JSON.stringify({
                    name: name,
                    host: host,
                    hostName: 'Joueur ' + host
                })
            })
            .then(response => response.json())
            .then(data => {
                alert('Room créée ! ID: ' + data.id);
                loadRooms();
            });
        }
        
        function joinRoom() {
            const roomId = document.getElementById('roomId').value;
            if (!roomId) {
                alert('Entrez un ID de room');
                return;
            }
            
            fetch('/room/' + roomId)
            .then(response => response.json())
            .then(data => {
                if (data) {
                    alert('Room trouvée: ' + data.name);
                } else {
                    alert('Room introuvable');
                }
            });
        }
        
        function loadRooms() {
            fetch('/rooms')
            .then(response => response.json())
            .then(data => {
                const container = document.getElementById('rooms');
                container.innerHTML = '';
                
                data.forEach(room => {
                    const div = document.createElement('div');
                    div.className = 'room-item';
                    div.innerHTML = \`
                        <span>\${room.name} (ID: \${room.id})</span>
                        <span>\${Object.keys(room.players || {}).length} joueur(s)</span>
                    \`;
                    container.appendChild(div);
                });
            });
        }
        
        // Charger les rooms au démarrage
        loadRooms();
        
        // Rafraîchir toutes les 5 secondes
        setInterval(loadRooms, 5000);
    </script>
</body>
</html>
  ''';
}
