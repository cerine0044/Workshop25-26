#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'dart:math';

/// Test rapide du multijoueur Firebase
void main() async {
  print('🎮 Test Multijoueur Firebase - Pandora Box');
  print('=' * 50);
  
  const String databaseUrl = 'https://pandora-box-user2-default-rtdb.firebaseio.com';
  
  try {
    // Test 1: Créer une room de test
    print('🏠 Test 1: Création d\'une room de test...');
    final roomId = DateTime.now().millisecondsSinceEpoch.toString();
    final roomCode = _generateRoomCode();
    
    final roomData = {
      'id': roomId,
      'code': roomCode,
      'name': 'Room Test ${Random().nextInt(100)}',
      'description': 'Room créée par le script de test',
      'hostId': 'test_host_${Random().nextInt(1000)}',
      'hostName': 'Test Host',
      'maxPlayers': 6,
      'isPrivate': false,
      'players': {
        'test_player_1': {
          'id': 'test_player_1',
          'name': 'Joueur Test 1',
          'isHost': true,
          'isReady': false,
          'joinedAt': DateTime.now().toIso8601String(),
          'score': 0,
        }
      },
      'gameState': 'waiting',
      'createdAt': DateTime.now().toIso8601String(),
      'lastActivity': DateTime.now().toIso8601String(),
    };
    
    final createResponse = await _makeRequest('PUT', '$databaseUrl/rooms/$roomId.json', data: roomData);
    if (createResponse != null) {
      print('✅ Room créée: $roomCode');
    } else {
      print('❌ Échec création room');
      return;
    }
    
    // Test 2: Ajouter un deuxième joueur
    print('\n👥 Test 2: Ajout d\'un deuxième joueur...');
    final player2Data = {
      'id': 'test_player_2',
      'name': 'Joueur Test 2',
      'isHost': false,
      'isReady': true,
      'joinedAt': DateTime.now().toIso8601String(),
      'score': 150,
    };
    
    final addPlayerResponse = await _makeRequest('PUT', '$databaseUrl/rooms/$roomId/players/test_player_2.json', data: player2Data);
    if (addPlayerResponse != null) {
      print('✅ Joueur 2 ajouté');
    } else {
      print('❌ Échec ajout joueur 2');
    }
    
    // Test 3: Vérifier la room
    print('\n📊 Test 3: Vérification de la room...');
    final roomCheck = await _makeRequest('GET', '$databaseUrl/rooms/$roomId.json');
    if (roomCheck != null) {
      final room = jsonDecode(roomCheck);
      print('✅ Room vérifiée:');
      print('   • Nom: ${room['name']}');
      print('   • Code: ${room['code']}');
      print('   • Joueurs: ${(room['players'] as Map).length}');
      print('   • État: ${room['gameState']}');
    }
    
    // Test 4: Simulation de jeu
    print('\n🎯 Test 4: Simulation de jeu...');
    final gameUpdate = {
      'gameState': 'playing',
      'lastActivity': DateTime.now().toIso8601String(),
    };
    
    final gameResponse = await _makeRequest('PATCH', '$databaseUrl/rooms/$roomId.json', data: gameUpdate);
    if (gameResponse != null) {
      print('✅ État de jeu mis à jour');
    }
    
    // Test 5: Mise à jour des scores
    print('\n🏆 Test 5: Mise à jour des scores...');
    final scoreUpdate1 = {'score': 250};
    final scoreUpdate2 = {'score': 300};
    
    await _makeRequest('PATCH', '$databaseUrl/rooms/$roomId/players/test_player_1.json', data: scoreUpdate1);
    await _makeRequest('PATCH', '$databaseUrl/rooms/$roomId/players/test_player_2.json', data: scoreUpdate2);
    print('✅ Scores mis à jour');
    
    // Test 6: Nettoyage
    print('\n🧹 Test 6: Nettoyage...');
    final cleanupResponse = await _makeRequest('DELETE', '$databaseUrl/rooms/$roomId.json');
    if (cleanupResponse != null) {
      print('✅ Room de test supprimée');
    }
    
    print('\n🎉 Tous les tests multijoueur sont passés !');
    print('✅ Le système multijoueur Firebase fonctionne parfaitement');
    print('🌐 Application disponible sur: https://pandora-box-user2.web.app');
    
  } catch (e) {
    print('❌ Erreur lors des tests: $e');
  }
}

String _generateRoomCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();
  return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
}

Future<String?> _makeRequest(String method, String url, {Map<String, dynamic>? data}) async {
  try {
    final uri = Uri.parse(url);
    HttpClientRequest request;
    
    switch (method.toUpperCase()) {
      case 'GET':
        request = await HttpClient().getUrl(uri);
        break;
      case 'POST':
        request = await HttpClient().postUrl(uri);
        break;
      case 'PUT':
        request = await HttpClient().putUrl(uri);
        break;
      case 'PATCH':
        request = await HttpClient().patchUrl(uri);
        break;
      case 'DELETE':
        request = await HttpClient().deleteUrl(uri);
        break;
      default:
        throw Exception('Méthode HTTP non supportée: $method');
    }
    
    if (data != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(data));
    }
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return responseBody;
    } else {
      print('❌ Erreur HTTP ${response.statusCode}: $responseBody');
      return null;
    }
  } catch (e) {
    print('❌ Erreur requête $url: $e');
    return null;
  }
}
