import 'dart:io';
import 'dart:convert';

void main() async {
  print('🎮 Pandora Box - Serveur + Application');
  print('======================================');
  
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
    localIP = '192.0.0.2';
  }
  
  print('📱 Votre IP: $localIP');
  print('');
  print('🌐 URLs à partager:');
  print('   Application: http://$localIP:8085');
  print('   API Backend: http://$localIP:5002');
  print('');
  print('📋 Instructions pour l\'autre PC:');
  print('1. Connectez-vous au même WiFi');
  print('2. Ouvrez un navigateur');
  print('3. Allez à: http://$localIP:8085');
  print('4. Les rooms seront partagées entre tous les PC ! 🎉');
  print('');
  
  // Démarrer le serveur backend
  print('🚀 Démarrage du serveur backend...');
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 5002);
  print('✅ Serveur backend démarré sur le port 5002');
  
  // Stockage des rooms partagées
  final Map<String, Map<String, dynamic>> rooms = {};
  
  // Gérer les requêtes du serveur
  server.listen((HttpRequest request) async {
    // Headers CORS pour permettre l'accès depuis Flutter
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
        // Page d'accueil de l'API
        request.response.statusCode = 200;
        request.response.headers.contentType = ContentType.html;
        request.response.write('''
<!DOCTYPE html>
<html>
<head>
    <title>Pandora Box API</title>
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
            max-width: 600px;
            margin: 0 auto;
            background: rgba(255,255,255,0.1);
            padding: 30px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
        }
        .success { color: #4CAF50; font-size: 24px; }
        .info { color: #81C784; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="success">✅ API Backend Actif !</h1>
        <p class="info">Le serveur Pandora Box fonctionne correctement</p>
        
        <div class="info">
            <p><strong>IP:</strong> $localIP</p>
            <p><strong>Port:</strong> 5001</p>
            <p><strong>Timestamp:</strong> ${DateTime.now()}</p>
        </div>
        
        <div class="info">
            <p><strong>Endpoints disponibles:</strong></p>
            <p>GET /rooms - Liste des rooms</p>
            <p>POST /rooms - Créer une room</p>
            <p>GET /room/{id} - Détails d'une room</p>
            <p>PUT /room/{id} - Mettre à jour une room</p>
        </div>
        
        <div class="info">
            <p><strong>Application Flutter:</strong></p>
            <p><a href="http://$localIP:8082" style="color: #4CAF50;">http://$localIP:8082</a></p>
        </div>
    </div>
</body>
</html>
        ''');
        request.response.close();
      } else if (path == '/rooms') {
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
  });
  
  print('🚀 Démarrage de l\'application Flutter...');
  print('==========================================');
  
  // Démarrer Flutter
  final process = await Process.start(
    'flutter',
    [
      'run', 
      '-d', 'web-server', 
      '--web-port', '8085', 
      '--web-hostname', '0.0.0.0'
    ],
    mode: ProcessStartMode.inheritStdio,
  );
  
  await process.exitCode;
}
