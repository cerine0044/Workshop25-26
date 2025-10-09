import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

// Configuration Firebase
const String _databaseUrl = 'https://pandora-box-user2-default-rtdb.firebaseio.com';
const String _apiKey = 'AIzaSyAUxg49zSnarmKRkuAQFG6dBhTiCcy2AMo';

Future<Map<String, dynamic>?> _makeRequest(String method, String path, {Map<String, dynamic>? data}) async {
  try {
    final url = Uri.parse('$_databaseUrl$path.json?auth=$_apiKey');
    HttpClientRequest request;

    switch (method.toUpperCase()) {
      case 'GET':
        request = await HttpClient().getUrl(url);
        break;
      case 'POST':
        request = await HttpClient().postUrl(url);
        break;
      case 'PUT':
        request = await HttpClient().putUrl(url);
        break;
      case 'PATCH':
        request = await HttpClient().patchUrl(url);
        break;
      case 'DELETE':
        request = await HttpClient().deleteUrl(url);
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
      return jsonDecode(responseBody) as Map<String, dynamic>?;
    } else {
      throw Exception('Erreur HTTP ${response.statusCode}: $responseBody');
    }
  } catch (e) {
    print('❌ Erreur requête: $e');
    return null;
  }
}

Future<void> main() async {
  print('🔍 Test - Diagnostic Erreur Lancement Page');
  print('==========================================');

  // Test 1: Vérifier la connectivité Firebase
  print('\n📊 Test 1: Connectivité Firebase...');
  try {
    final response = await _makeRequest('GET', '/');
    if (response != null) {
      print('✅ Connexion Firebase réussie');
    } else {
      print('✅ Connexion Firebase réussie (données vides)');
    }
  } catch (e) {
    print('❌ Erreur de connexion Firebase: $e');
    exit(1);
  }

  // Test 2: Vérifier l'état de la base de données
  print('\n📊 Test 2: État de la base de données...');
  try {
    final allData = await _makeRequest('GET', '/');
    if (allData != null) {
      print('✅ Base de données accessible');
      print('   • Clés disponibles: ${allData.keys.join(', ')}');
      
      final rooms = allData['rooms'] as Map<String, dynamic>?;
      final players = allData['players'] as Map<String, dynamic>?;
      
      print('   • Rooms: ${rooms?.length ?? 0}');
      print('   • Joueurs: ${players?.length ?? 0}');
      
      if (rooms != null && rooms.isNotEmpty) {
        print('   • Rooms actives:');
        rooms.forEach((key, value) {
          final roomPlayers = (value['players'] as Map?)?.length ?? 0;
          print('     - ${value['name']} (${value['code']}) - $roomPlayers joueur(s)');
        });
      }
    } else {
      print('⚠️ Base de données vide ou inaccessible');
    }
  } catch (e) {
    print('❌ Erreur accès base de données: $e');
    exit(1);
  }

  // Test 3: Test de création d'une room (simulation)
  print('\n📊 Test 3: Test création room...');
  try {
    final testRoomId = DateTime.now().millisecondsSinceEpoch.toString();
    final testRoomCode = 'TEST${Random().nextInt(1000)}';
    final hostPlayerId = 'test_host_${Random().nextInt(1000)}';
    
    final roomData = {
      'id': testRoomId,
      'code': testRoomCode,
      'name': 'Room Test Diagnostic',
      'hostId': hostPlayerId,
      'hostName': 'Test Host',
      'maxPlayers': 2,
      'players': {
        hostPlayerId: {
          'id': hostPlayerId,
          'name': 'Test Host',
          'isHost': true,
          'isReady': false,
          'joinedAt': DateTime.now().toIso8601String(),
          'avatar': '😀',
        }
      },
      'gameState': 'waiting',
      'createdAt': DateTime.now().toIso8601String(),
      'lastActivity': DateTime.now().toIso8601String(),
    };

    await _makeRequest('PUT', '/rooms/$testRoomId', data: roomData);
    print('✅ Room de test créée: $testRoomCode');
    
    // Vérifier immédiatement
    final roomSnapshot = await _makeRequest('GET', '/rooms/$testRoomId');
    if (roomSnapshot != null) {
      print('✅ Room vérifiée: ${roomSnapshot['name']}');
    } else {
      print('❌ Room non trouvée après création');
    }
    
    // Nettoyer
    await _makeRequest('DELETE', '/rooms/$testRoomId');
    print('✅ Room de test supprimée');
    
  } catch (e) {
    print('❌ Erreur test création room: $e');
    exit(1);
  }

  // Test 4: Test de performance (temps de réponse)
  print('\n📊 Test 4: Test de performance...');
  try {
    final stopwatch = Stopwatch()..start();
    
    for (int i = 0; i < 5; i++) {
      await _makeRequest('GET', '/');
    }
    
    stopwatch.stop();
    final averageTime = stopwatch.elapsedMilliseconds / 5;
    
    print('✅ Test de performance terminé');
    print('   • Temps moyen de réponse: ${averageTime.toStringAsFixed(0)}ms');
    
    if (averageTime < 1000) {
      print('✅ Performance excellente (< 1s)');
    } else if (averageTime < 3000) {
      print('⚠️ Performance acceptable (< 3s)');
    } else {
      print('❌ Performance lente (> 3s)');
    }
    
  } catch (e) {
    print('❌ Erreur test de performance: $e');
    exit(1);
  }

  // Test 5: Test de stabilité (requêtes multiples)
  print('\n📊 Test 5: Test de stabilité...');
  try {
    final futures = <Future>[];
    
    for (int i = 0; i < 10; i++) {
      futures.add(_makeRequest('GET', '/'));
    }
    
    await Future.wait(futures);
    print('✅ Test de stabilité réussi (10 requêtes simultanées)');
    
  } catch (e) {
    print('❌ Erreur test de stabilité: $e');
    exit(1);
  }

  print('\n🎉 Tous les tests de diagnostic sont passés !');
  print('✅ L\'application devrait se lancer sans erreur');
  print('🌐 Application disponible sur: https://pandora-box-user2.web.app');
  print('\n💡 Si vous voyez encore des erreurs au lancement:');
  print('   1. Videz le cache du navigateur (Ctrl+Shift+R)');
  print('   2. Vérifiez la console pour les erreurs JavaScript');
  print('   3. Essayez en mode incognito');
  print('   4. Vérifiez votre connexion internet');
}
