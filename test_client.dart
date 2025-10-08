import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() async {
  print('🧪 Client de Test WebSocket - Pandora Box');
  print('=========================================');
  
  // Demander l'IP du serveur
  stdout.write('Entrez l\'IP du serveur (défaut: 10.151.18.84): ');
  final serverIP = stdin.readLineSync()?.trim() ?? '10.151.18.84';
  
  final wsUrl = 'ws://$serverIP:5002';
  print('🔌 Connexion à: $wsUrl');
  
  try {
    final channel = WebSocketChannel.connect(Uri.parse(wsUrl));
    print('✅ Connexion WebSocket établie');
    
    // Écouter les messages du serveur
    channel.stream.listen(
      (message) {
        try {
          final data = jsonDecode(message) as Map<String, dynamic>;
          final type = data['type'] as String;
          
          print('📨 Message reçu: $type');
          
          switch (type) {
            case 'room_update':
              _handleRoomUpdate(data);
              break;
            case 'rooms_list':
              _handleRoomsList(data);
              break;
            case 'pong':
              print('🏓 Pong reçu');
              break;
            case 'error':
              print('❌ Erreur serveur: ${data['message']}');
              break;
            default:
              print('⚠️ Message non reconnu: $type');
          }
        } catch (e) {
          print('❌ Erreur lors du traitement du message: $e');
        }
      },
      onError: (error) {
        print('❌ Erreur WebSocket: $error');
      },
      onDone: () {
        print('🔌 Connexion fermée par le serveur');
      },
    );
    
    // Générer un ID utilisateur unique
    final userId = 'test_user_${DateTime.now().millisecondsSinceEpoch}';
    print('👤 ID utilisateur: $userId');
    
    // Se connecter
    channel.sink.add(jsonEncode({
      'type': 'connect',
      'userId': userId,
    }));
    
    // Menu interactif
    await _showMenu(channel, userId);
    
  } catch (e) {
    print('❌ Erreur de connexion: $e');
    print('');
    print('🔧 Vérifications:');
    print('1. Le serveur WebSocket est-il démarré ?');
    print('2. L\'IP est-elle correcte ?');
    print('3. Le port 5002 est-il ouvert ?');
    print('4. Êtes-vous sur le même réseau ?');
  }
}

void _handleRoomUpdate(Map<String, dynamic> data) {
  final room = data['room'] as Map<String, dynamic>?;
  if (room != null) {
    print('🏠 Room mise à jour:');
    print('   ID: ${room['id']}');
    print('   Nom: ${room['name']}');
    print('   Hôte: ${room['hostName']}');
    print('   État: ${room['gameState']}');
    
    final players = Map<String, dynamic>.from(room['players'] ?? {});
    print('   Joueurs (${players.length}):');
    for (final entry in players.entries) {
      final player = entry.value as Map<String, dynamic>;
      final status = player['isReady'] == true ? '✅ Prêt' : '⏳ En attente';
      final host = player['isHost'] == true ? ' (Hôte)' : '';
      print('     - ${player['name']}$host: $status');
    }
  }
}

void _handleRoomsList(Map<String, dynamic> data) {
  final rooms = (data['rooms'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];
  print('📋 Rooms disponibles (${rooms.length}):');
  
  if (rooms.isEmpty) {
    print('   Aucune room disponible');
  } else {
    for (final room in rooms) {
      final players = Map<String, dynamic>.from(room['players'] ?? {});
      print('   - ${room['name']} (ID: ${room['id']}) - ${players.length} joueur(s)');
    }
  }
}

Future<void> _showMenu(WebSocketChannel channel, String userId) async {
  while (true) {
    print('');
    print('🎮 Menu de Test:');
    print('1. Créer une room');
    print('2. Rejoindre une room');
    print('3. Quitter une room');
    print('4. Demander la liste des rooms');
    print('5. Tester le ping');
    print('6. Quitter');
    print('');
    stdout.write('Choisissez une option (1-6): ');
    
    final choice = stdin.readLineSync()?.trim();
    
    switch (choice) {
      case '1':
        await _createRoom(channel, userId);
        break;
      case '2':
        await _joinRoom(channel, userId);
        break;
      case '3':
        await _leaveRoom(channel, userId);
        break;
      case '4':
        _getRooms(channel);
        break;
      case '5':
        _ping(channel);
        break;
      case '6':
        print('👋 Au revoir !');
        await channel.sink.close();
        return;
      default:
        print('❌ Option invalide');
    }
  }
}

Future<void> _createRoom(WebSocketChannel channel, String userId) async {
  stdout.write('Nom de la room: ');
  final roomName = stdin.readLineSync()?.trim() ?? 'Test Room';
  
  channel.sink.add(jsonEncode({
    'type': 'create_room',
    'roomName': roomName,
    'host': userId,
    'hostName': 'Test User',
  }));
  
  print('✅ Demande de création envoyée');
}

Future<void> _joinRoom(WebSocketChannel channel, String userId) async {
  stdout.write('ID de la room à rejoindre: ');
  final roomId = stdin.readLineSync()?.trim();
  
  if (roomId == null || roomId.isEmpty) {
    print('❌ ID de room invalide');
    return;
  }
  
  channel.sink.add(jsonEncode({
    'type': 'join_room',
    'roomId': roomId,
    'userId': userId,
    'userName': 'Test User',
  }));
  
  print('✅ Demande de connexion envoyée');
}

Future<void> _leaveRoom(WebSocketChannel channel, String userId) async {
  stdout.write('ID de la room à quitter: ');
  final roomId = stdin.readLineSync()?.trim();
  
  if (roomId == null || roomId.isEmpty) {
    print('❌ ID de room invalide');
    return;
  }
  
  channel.sink.add(jsonEncode({
    'type': 'leave_room',
    'roomId': roomId,
    'userId': userId,
  }));
  
  print('✅ Demande de déconnexion envoyée');
}

void _getRooms(WebSocketChannel channel) {
  channel.sink.add(jsonEncode({
    'type': 'get_rooms',
  }));
  
  print('✅ Demande de liste des rooms envoyée');
}

void _ping(WebSocketChannel channel) {
  channel.sink.add(jsonEncode({
    'type': 'ping',
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  }));
  
  print('🏓 Ping envoyé');
}
