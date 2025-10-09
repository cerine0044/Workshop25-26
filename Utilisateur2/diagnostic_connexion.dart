#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'dart:math';

/// Test de diagnostic pour le problème de connexion aux rooms
void main() async {
  print('🔍 Diagnostic - Problème de Connexion aux Rooms');
  print('=' * 60);
  
  const String databaseUrl = 'https://pandora-box-user2-default-rtdb.firebaseio.com';
  
  try {
    // Test 1: Vérifier l'état de la base de données
    print('📊 Test 1: État de la base de données...');
    final allData = await _makeRequest('GET', '$databaseUrl/.json');
    if (allData != null) {
      final data = jsonDecode(allData);
      print('✅ Base de données accessible');
      print('   • Clés disponibles: ${data.keys.join(', ')}');
      
      if (data.containsKey('rooms')) {
        final rooms = data['rooms'] as Map;
        print('   • Nombre de rooms: ${rooms.length}');
        
        if (rooms.isNotEmpty) {
          print('   • Rooms disponibles:');
          rooms.forEach((id, roomData) {
            print('     - ${roomData['name']} (${roomData['code']}) - ${(roomData['players'] as Map).length} joueur(s)');
          });
        } else {
          print('   ⚠️ Aucune room disponible');
        }
      } else {
        print('   ⚠️ Pas de nœud "rooms" dans la base de données');
      }
    } else {
      print('❌ Impossible d\'accéder à la base de données');
      return;
    }
    
    // Test 2: Créer une room de test
    print('\n🏠 Test 2: Création d\'une room de test...');
    final roomId = DateTime.now().millisecondsSinceEpoch.toString();
    final roomCode = _generateRoomCode();
    
    final roomData = {
      'id': roomId,
      'code': roomCode,
      'name': 'Room Test Diagnostic',
      'description': 'Room créée pour tester la connexion',
      'hostId': 'test_host_diagnostic',
      'hostName': 'Test Host',
      'maxPlayers': 6,
      'isPrivate': false,
      'players': {
        'test_host_diagnostic': {
          'id': 'test_host_diagnostic',
          'name': 'Test Host',
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
      print('✅ Room de test créée: $roomCode');
    } else {
      print('❌ Échec création room de test');
      return;
    }
    
    // Test 3: Simuler la recherche de room par code
    print('\n🔍 Test 3: Recherche de room par code...');
    final searchResponse = await _makeRequest('GET', '$databaseUrl/rooms.json');
    if (searchResponse != null) {
      final rooms = jsonDecode(searchResponse);
      bool found = false;
      String? foundRoomId;
      
      rooms.forEach((id, data) {
        if (data['code'] == roomCode) {
          found = true;
          foundRoomId = id;
          print('✅ Room trouvée par code: ${data['name']} (ID: $id)');
        }
      });
      
      if (!found) {
        print('❌ Room non trouvée par code - problème de recherche');
        return;
      }
      
      // Test 4: Simuler l'ajout d'un joueur
      print('\n👥 Test 4: Ajout d\'un joueur à la room...');
      final playerId = 'test_player_diagnostic';
      final playerData = {
        'id': playerId,
        'name': 'Test Player',
        'isHost': false,
        'isReady': true,
        'joinedAt': DateTime.now().toIso8601String(),
        'score': 100,
      };
      
      final addPlayerResponse = await _makeRequest('PUT', '$databaseUrl/rooms/$foundRoomId/players/$playerId.json', data: playerData);
      if (addPlayerResponse != null) {
        print('✅ Joueur ajouté avec succès');
      } else {
        print('❌ Échec ajout du joueur');
      }
      
      // Test 5: Vérifier l'état final
      print('\n📊 Test 5: Vérification de l\'état final...');
      final finalCheck = await _makeRequest('GET', '$databaseUrl/rooms/$foundRoomId.json');
      if (finalCheck != null) {
        final room = jsonDecode(finalCheck);
        print('✅ État final de la room:');
        print('   • Nom: ${room['name']}');
        print('   • Code: ${room['code']}');
        print('   • Joueurs: ${(room['players'] as Map).length}');
        print('   • État: ${room['gameState']}');
        
        final players = room['players'] as Map;
        players.forEach((id, player) {
          print('     - ${player['name']} (${player['isHost'] ? 'Hôte' : 'Joueur'})');
        });
      }
      
      // Test 6: Nettoyage
      print('\n🧹 Test 6: Nettoyage...');
      final cleanupResponse = await _makeRequest('DELETE', '$databaseUrl/rooms/$foundRoomId.json');
      if (cleanupResponse != null) {
        print('✅ Room de test supprimée');
      }
      
    } else {
      print('❌ Impossible de rechercher les rooms');
    }
    
    print('\n🎉 Diagnostic terminé !');
    print('✅ Si tous les tests sont passés, le problème pourrait être dans l\'interface utilisateur');
    print('🌐 Application disponible sur: https://pandora-box-user2.web.app');
    
  } catch (e) {
    print('❌ Erreur lors du diagnostic: $e');
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
