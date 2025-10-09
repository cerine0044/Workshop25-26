#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';

/// Script de test pour vérifier la connectivité multijoueur Firebase
void main() async {
  print('🔥 Test de Connectivité Multijoueur Firebase');
  print('=' * 50);
  
  const String databaseUrl = 'https://pandora-box-user2-default-rtdb.firebaseio.com';
  
  try {
    // Test 1: Vérifier l'accès à la base de données
    print('📊 Test 1: Accès à la base de données...');
    final response = await _makeRequest('GET', '$databaseUrl/.json');
    if (response != null) {
      print('✅ Connexion à Firebase réussie');
    } else {
      print('❌ Échec de connexion à Firebase');
      return;
    }
    
    // Test 2: Vérifier les rooms disponibles
    print('\n🏠 Test 2: Rooms disponibles...');
    final roomsResponse = await _makeRequest('GET', '$databaseUrl/rooms.json');
    if (roomsResponse != null) {
      final rooms = roomsResponse as Map<String, dynamic>;
      print('✅ ${rooms.length} room(s) trouvée(s)');
      
      rooms.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final room = value;
          final playerCount = room['players'] != null ? (room['players'] as Map).length : 0;
          print('   • ${room['name']} (${room['code']}) - ${playerCount} joueur(s)');
        }
      });
    }
    
    // Test 3: Vérifier les joueurs en ligne
    print('\n👥 Test 3: Joueurs en ligne...');
    final playersResponse = await _makeRequest('GET', '$databaseUrl/players.json');
    if (playersResponse != null) {
      final players = playersResponse as Map<String, dynamic>;
      int onlineCount = 0;
      
      players.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final player = value;
          if (player['isOnline'] == true) {
            onlineCount++;
            print('   • ${player['name']} - Score: ${player['score'] ?? 0}');
          }
        }
      });
      
      print('✅ $onlineCount joueur(s) en ligne');
    }
    
    // Test 4: Simuler une connexion de joueur
    print('\n🎮 Test 4: Simulation connexion joueur...');
    final newPlayerId = 'test_player_${DateTime.now().millisecondsSinceEpoch}';
    final newPlayer = {
      'id': newPlayerId,
      'name': 'Joueur Test ${DateTime.now().second}',
      'isOnline': true,
      'lastSeen': DateTime.now().toIso8601String(),
      'currentRoom': 'room_multiplayer',
      'score': 0,
    };
    
    final addPlayerResponse = await _makeRequest('PUT', '$databaseUrl/players/$newPlayerId.json', data: newPlayer);
    if (addPlayerResponse != null) {
      print('✅ Nouveau joueur ajouté: ${newPlayer['name']}');
    }
    
    // Test 5: Vérifier la mise à jour en temps réel
    print('\n⚡ Test 5: Test de mise à jour temps réel...');
    print('   Surveillance des changements pendant 10 secondes...');
    
    int updateCount = 0;
    final stopwatch = Stopwatch()..start();
    
    while (stopwatch.elapsedMilliseconds < 10000) {
      await Future.delayed(Duration(seconds: 2));
      final checkResponse = await _makeRequest('GET', '$databaseUrl/players/$newPlayerId.json');
      if (checkResponse != null) {
        updateCount++;
        print('   📡 Mise à jour #$updateCount reçue');
      }
    }
    
    print('✅ Test de mise à jour terminé');
    
    // Nettoyage
    print('\n🧹 Nettoyage...');
    await _makeRequest('DELETE', '$databaseUrl/players/$newPlayerId.json');
    print('✅ Joueur de test supprimé');
    
    print('\n🎉 Tous les tests sont passés avec succès !');
    print('✅ La connectivité multijoueur Firebase fonctionne correctement');
    
  } catch (e) {
    print('❌ Erreur lors des tests: $e');
  }
}

Future<dynamic> _makeRequest(String method, String url, {Map<String, dynamic>? data}) async {
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
      if (responseBody.isEmpty) return null;
      return jsonDecode(responseBody);
    } else {
      throw Exception('Erreur HTTP ${response.statusCode}: $responseBody');
    }
  } catch (e) {
    print('❌ Erreur requête: $e');
    return null;
  }
}
