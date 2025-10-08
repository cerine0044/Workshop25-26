import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() async {
  print('🧪 Client de Test Simple - Pandora Box');
  print('=====================================');
  
  // Utiliser l'IP par défaut ou demander
  String serverIP = '192.168.1.20'; // IP par défaut
  
  // Vérifier si une IP est fournie en argument
  if (Platform.environment.containsKey('SERVER_IP')) {
    serverIP = Platform.environment['SERVER_IP']!;
  }
  
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
    
    // Tests automatiques
    await _runAutomaticTests(channel, userId);
    
    // Fermer la connexion
    await channel.sink.close();
    print('👋 Test terminé');
    
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

Future<void> _runAutomaticTests(WebSocketChannel channel, String userId) async {
  print('');
  print('🧪 Démarrage des tests automatiques...');
  
  // Test 1: Ping
  print('Test 1: Ping');
  channel.sink.add(jsonEncode({
    'type': 'ping',
    'timestamp': DateTime.now().millisecondsSinceEpoch,
  }));
  await Future.delayed(Duration(seconds: 1));
  
  // Test 2: Créer une room
  print('Test 2: Création de room');
  channel.sink.add(jsonEncode({
    'type': 'create_room',
    'roomName': 'Room Test Client',
    'host': userId,
    'hostName': 'Test Client User',
  }));
  await Future.delayed(Duration(seconds: 2));
  
  // Test 3: Demander la liste des rooms
  print('Test 3: Liste des rooms');
  channel.sink.add(jsonEncode({
    'type': 'get_rooms',
  }));
  await Future.delayed(Duration(seconds: 1));
  
  print('✅ Tests automatiques terminés');
}
