import 'dart:io';
import 'dart:convert';
import 'dart:async';

void main() async {
  print('🔄 TEST SYNCHRONISATION TEMPS RÉEL');
  print('==================================');
  
  // Simuler deux clients WebSocket
  await testRealTimeSynchronization();
  
  print('\n✅ TEST TERMINÉ');
}

Future<void> testRealTimeSynchronization() async {
  print('\n🔌 Test de synchronisation WebSocket...');
  
  try {
    // Client 1 - Créateur de room
    final client1 = await WebSocket.connect('ws://localhost:5002');
    final client1Id = 'client1_${DateTime.now().millisecondsSinceEpoch}';
    
    print('✅ Client 1 connecté');
    
    // Client 2 - Rejoindre la room
    final client2 = await WebSocket.connect('ws://localhost:5002');
    final client2Id = 'client2_${DateTime.now().millisecondsSinceEpoch}';
    
    print('✅ Client 2 connecté');
    
    // Variables pour capturer les messages
    final client1Messages = <Map<String, dynamic>>[];
    final client2Messages = <Map<String, dynamic>>[];
    
    // Écouter les messages du Client 1
    client1.listen((message) {
      final data = jsonDecode(message) as Map<String, dynamic>;
      client1Messages.add(data);
      print('📨 Client 1 reçu: ${data['type']}');
      
      if (data['type'] == 'room_update') {
        final room = data['room'] as Map<String, dynamic>;
        final players = room['players'] as Map<String, dynamic>;
        print('👥 Client 1 voit ${players.length} joueur(s) dans la room');
      }
    });
    
    // Écouter les messages du Client 2
    client2.listen((message) {
      final data = jsonDecode(message) as Map<String, dynamic>;
      client2Messages.add(data);
      print('📨 Client 2 reçu: ${data['type']}');
      
      if (data['type'] == 'room_update') {
        final room = data['room'] as Map<String, dynamic>;
        final players = room['players'] as Map<String, dynamic>;
        print('👥 Client 2 voit ${players.length} joueur(s) dans la room');
      }
    });
    
    // Attendre que les connexions soient établies
    await Future.delayed(Duration(milliseconds: 500));
    
    // Client 1: Se connecter
    client1.add(jsonEncode({
      'type': 'connect',
      'userId': client1Id,
    }));
    
    // Client 2: Se connecter
    client2.add(jsonEncode({
      'type': 'connect',
      'userId': client2Id,
    }));
    
    await Future.delayed(Duration(milliseconds: 500));
    
    // Client 1: Créer une room
    print('\n🏠 Client 1 crée une room...');
    client1.add(jsonEncode({
      'type': 'create_room',
      'roomName': 'Test Sync Room',
      'host': client1Id,
      'hostName': 'Client 1',
    }));
    
    await Future.delayed(Duration(milliseconds: 1000));
    
    // Extraire l'ID de la room des messages du Client 1
    String? roomId;
    for (var msg in client1Messages) {
      if (msg['type'] == 'room_update') {
        roomId = msg['room']['id'] as String?;
        break;
      }
    }
    
    if (roomId == null) {
      print('❌ Impossible de récupérer l\'ID de la room');
      return;
    }
    
    print('📋 Room ID: $roomId');
    
    // Client 2: Rejoindre la room
    print('\n👥 Client 2 rejoint la room...');
    client2.add(jsonEncode({
      'type': 'join_room',
      'roomId': roomId,
      'userId': client2Id,
      'userName': 'Client 2',
    }));
    
    // Attendre les mises à jour
    await Future.delayed(Duration(milliseconds: 2000));
    
    // Vérifier la synchronisation
    print('\n🔍 Vérification de la synchronisation...');
    
    // Compter les messages de room_update pour chaque client
    final client1RoomUpdates = client1Messages.where((msg) => msg['type'] == 'room_update').length;
    final client2RoomUpdates = client2Messages.where((msg) => msg['type'] == 'room_update').length;
    
    print('📊 Client 1 a reçu $client1RoomUpdates mises à jour de room');
    print('📊 Client 2 a reçu $client2RoomUpdates mises à jour de room');
    
    // Vérifier que les deux clients voient 2 joueurs
    bool client1Sees2Players = false;
    bool client2Sees2Players = false;
    
    for (var msg in client1Messages) {
      if (msg['type'] == 'room_update') {
        final room = msg['room'] as Map<String, dynamic>;
        final players = room['players'] as Map<String, dynamic>;
        if (players.length == 2) {
          client1Sees2Players = true;
          break;
        }
      }
    }
    
    for (var msg in client2Messages) {
      if (msg['type'] == 'room_update') {
        final room = msg['room'] as Map<String, dynamic>;
        final players = room['players'] as Map<String, dynamic>;
        if (players.length == 2) {
          client2Sees2Players = true;
          break;
        }
      }
    }
    
    print('\n📋 Résultats de la synchronisation:');
    print('👤 Client 1 voit 2 joueurs: ${client1Sees2Players ? "✅ OUI" : "❌ NON"}');
    print('👤 Client 2 voit 2 joueurs: ${client2Sees2Players ? "✅ OUI" : "❌ NON"}');
    
    if (client1Sees2Players && client2Sees2Players) {
      print('\n🎉 SYNCHRONISATION RÉUSSIE !');
      print('Les deux joueurs voient correctement l\'autre joueur dans la room');
    } else {
      print('\n❌ PROBLÈME DE SYNCHRONISATION');
      print('Un ou plusieurs joueurs ne voient pas les autres joueurs');
    }
    
    // Fermer les connexions
    await client1.close();
    await client2.close();
    
  } catch (e) {
    print('❌ Erreur test synchronisation: $e');
  }
}
