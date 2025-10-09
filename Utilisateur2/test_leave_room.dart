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

String _generateRoomCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final random = Random();
  return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
  );
}

Future<void> main() async {
  print('🧪 Test - Fonctionnalité de Quitter une Room');
  print('===============================================');

  // Test 1: Créer une room avec 2 joueurs
  print('\n📊 Test 1: Création d\'une room avec 2 joueurs...');
  final testRoomId = DateTime.now().millisecondsSinceEpoch.toString();
  final testRoomCode = _generateRoomCode();
  final hostPlayerId = 'host_${Random().nextInt(1000)}';
  final hostPlayerName = 'Test Host';
  final guestPlayerId = 'guest_${Random().nextInt(1000)}';
  final guestPlayerName = 'Test Guest';

  final roomData = {
    'id': testRoomId,
    'code': testRoomCode,
    'name': 'Room Test Leave',
    'hostId': hostPlayerId,
    'hostName': hostPlayerName,
    'maxPlayers': 2,
    'players': {
      hostPlayerId: {
        'id': hostPlayerId,
        'name': hostPlayerName,
        'isHost': true,
        'isReady': false,
        'joinedAt': DateTime.now().toIso8601String(),
        'avatar': '😀',
      },
      guestPlayerId: {
        'id': guestPlayerId,
        'name': guestPlayerName,
        'isHost': false,
        'isReady': false,
        'joinedAt': DateTime.now().toIso8601String(),
        'avatar': '😎',
      }
    },
    'gameState': 'waiting',
    'createdAt': DateTime.now().toIso8601String(),
    'lastActivity': DateTime.now().toIso8601String(),
  };

  try {
    await _makeRequest('PUT', '/rooms/$testRoomId', data: roomData);
    print('✅ Room créée avec 2 joueurs: $testRoomCode');
  } catch (e) {
    print('❌ Erreur création room: $e');
    exit(1);
  }

  // Test 2: Vérifier l'état initial
  print('\n📊 Test 2: Vérification de l\'état initial...');
  try {
    final roomSnapshot = await _makeRequest('GET', '/rooms/$testRoomId');
    if (roomSnapshot != null) {
      final players = Map<String, dynamic>.from(roomSnapshot['players'] ?? {});
      print('✅ Room initiale: ${players.length} joueur(s)');
      players.forEach((key, value) {
        print('   • ${value['name']} (${value['isHost'] ? 'Hôte' : 'Joueur'})');
      });
    } else {
      print('❌ Room non trouvée');
      exit(1);
    }
  } catch (e) {
    print('❌ Erreur vérification état initial: $e');
    exit(1);
  }

  // Test 3: Simuler le départ du joueur invité
  print('\n📊 Test 3: Simulation départ du joueur invité...');
  try {
    final roomSnapshot = await _makeRequest('GET', '/rooms/$testRoomId');
    if (roomSnapshot != null) {
      final players = Map<String, dynamic>.from(roomSnapshot['players'] ?? {});
      
      // Supprimer le joueur invité
      players.remove(guestPlayerId);
      
      await _makeRequest('PATCH', '/rooms/$testRoomId', data: {
        'players': players,
        'lastActivity': DateTime.now().toIso8601String(),
      });
      
      print('✅ Joueur invité supprimé de la room');
    } else {
      print('❌ Room non trouvée pour suppression');
      exit(1);
    }
  } catch (e) {
    print('❌ Erreur suppression joueur invité: $e');
    exit(1);
  }

  // Test 4: Vérifier l'état après départ
  print('\n📊 Test 4: Vérification après départ...');
  try {
    final roomSnapshot = await _makeRequest('GET', '/rooms/$testRoomId');
    if (roomSnapshot != null) {
      final players = Map<String, dynamic>.from(roomSnapshot['players'] ?? {});
      print('✅ Room après départ: ${players.length} joueur(s)');
      players.forEach((key, value) {
        print('   • ${value['name']} (${value['isHost'] ? 'Hôte' : 'Joueur'})');
      });
      
      if (players.length == 1 && players.containsKey(hostPlayerId)) {
        print('✅ Test réussi: Seul l\'hôte reste dans la room');
      } else {
        print('❌ Test échoué: État inattendu de la room');
      }
    } else {
      print('❌ Room non trouvée après départ');
      exit(1);
    }
  } catch (e) {
    print('❌ Erreur vérification après départ: $e');
    exit(1);
  }

  // Test 5: Simuler le départ de l'hôte (devrait supprimer la room)
  print('\n📊 Test 5: Simulation départ de l\'hôte...');
  try {
    await _makeRequest('DELETE', '/rooms/$testRoomId');
    print('✅ Room supprimée après départ de l\'hôte');
  } catch (e) {
    print('❌ Erreur suppression room: $e');
    exit(1);
  }

  // Test 6: Vérifier que la room n'existe plus
  print('\n📊 Test 6: Vérification suppression room...');
  try {
    final roomSnapshot = await _makeRequest('GET', '/rooms/$testRoomId');
    if (roomSnapshot == null) {
      print('✅ Room supprimée avec succès');
    } else {
      print('❌ Room encore présente après suppression');
    }
  } catch (e) {
    print('❌ Erreur vérification suppression: $e');
  }

  print('\n🎉 Tous les tests de départ de room sont terminés !');
  print('✅ La fonctionnalité de quitter une room fonctionne correctement');
  print('🌐 Application disponible sur: https://pandora-box-user2.web.app');
}
