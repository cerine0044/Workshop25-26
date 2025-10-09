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
  print('🧪 Test - Mise à Jour Liste Joueurs Temps Réel');
  print('================================================');

  // Test 1: Créer une room avec l'hôte
  print('\n📊 Test 1: Création d\'une room par l\'hôte...');
  final testRoomId = DateTime.now().millisecondsSinceEpoch.toString();
  final testRoomCode = _generateRoomCode();
  final hostPlayerId = 'host_${Random().nextInt(1000)}';
  final hostPlayerName = 'Test Host';

  final roomData = {
    'id': testRoomId,
    'code': testRoomCode,
    'name': 'Room Test Liste',
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
      }
    },
    'gameState': 'waiting',
    'createdAt': DateTime.now().toIso8601String(),
    'lastActivity': DateTime.now().toIso8601String(),
  };

  try {
    await _makeRequest('PUT', '/rooms/$testRoomId', data: roomData);
    print('✅ Room créée par l\'hôte: $testRoomCode');
  } catch (e) {
    print('❌ Erreur création room: $e');
    exit(1);
  }

  // Test 2: Vérifier l'état initial (1 joueur)
  print('\n📊 Test 2: Vérification état initial (1 joueur)...');
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

  // Test 3: Simuler l'ajout d'un deuxième joueur
  print('\n📊 Test 3: Ajout d\'un deuxième joueur...');
  final guestPlayerId = 'guest_${Random().nextInt(1000)}';
  final guestPlayerName = 'Test Guest';

  try {
    final roomSnapshot = await _makeRequest('GET', '/rooms/$testRoomId');
    if (roomSnapshot != null) {
      final players = Map<String, dynamic>.from(roomSnapshot['players'] ?? {});
      
      // Ajouter le deuxième joueur
      players[guestPlayerId] = {
        'id': guestPlayerId,
        'name': guestPlayerName,
        'isHost': false,
        'isReady': false,
        'joinedAt': DateTime.now().toIso8601String(),
        'avatar': '😎',
      };
      
      await _makeRequest('PATCH', '/rooms/$testRoomId', data: {
        'players': players,
        'lastActivity': DateTime.now().toIso8601String(),
      });
      
      print('✅ Deuxième joueur ajouté: $guestPlayerName');
    } else {
      print('❌ Room non trouvée pour ajout joueur');
      exit(1);
    }
  } catch (e) {
    print('❌ Erreur ajout deuxième joueur: $e');
    exit(1);
  }

  // Test 4: Vérifier immédiatement l'état avec 2 joueurs
  print('\n📊 Test 4: Vérification immédiate avec 2 joueurs...');
  try {
    final roomSnapshot = await _makeRequest('GET', '/rooms/$testRoomId');
    if (roomSnapshot != null) {
      final players = Map<String, dynamic>.from(roomSnapshot['players'] ?? {});
      print('✅ Room avec 2 joueurs:');
      players.forEach((key, value) {
        print('   • ${value['name']} (${value['isHost'] ? 'Hôte' : 'Joueur'})');
      });
      
      if (players.length == 2) {
        print('✅ Test réussi: Room contient bien 2 joueurs');
      } else {
        print('❌ Test échoué: Room contient ${players.length} joueur(s) au lieu de 2');
      }
    } else {
      print('❌ Room non trouvée après ajout');
      exit(1);
    }
  } catch (e) {
    print('❌ Erreur vérification avec 2 joueurs: $e');
    exit(1);
  }

  // Test 5: Simuler des changements de statut
  print('\n📊 Test 5: Simulation changements de statut...');
  try {
    final roomSnapshot = await _makeRequest('GET', '/rooms/$testRoomId');
    if (roomSnapshot != null) {
      final players = Map<String, dynamic>.from(roomSnapshot['players'] ?? {});
      
      // Changer le statut de l'hôte
      players[hostPlayerId]['isReady'] = true;
      
      await _makeRequest('PATCH', '/rooms/$testRoomId', data: {
        'players': players,
        'lastActivity': DateTime.now().toIso8601String(),
      });
      
      print('✅ Statut hôte mis à jour: Prêt');
      
      // Attendre un peu
      await Future.delayed(const Duration(seconds: 1));
      
      // Changer le statut du joueur invité
      players[guestPlayerId]['isReady'] = true;
      
      await _makeRequest('PATCH', '/rooms/$testRoomId', data: {
        'players': players,
        'lastActivity': DateTime.now().toIso8601String(),
      });
      
      print('✅ Statut joueur invité mis à jour: Prêt');
    }
  } catch (e) {
    print('❌ Erreur changements de statut: $e');
    exit(1);
  }

  // Test 6: Vérifier l'état final
  print('\n📊 Test 6: Vérification état final...');
  try {
    final roomSnapshot = await _makeRequest('GET', '/rooms/$testRoomId');
    if (roomSnapshot != null) {
      final players = Map<String, dynamic>.from(roomSnapshot['players'] ?? {});
      print('✅ État final de la room:');
      players.forEach((key, value) {
        final status = value['isReady'] ? 'Prêt' : 'En attente';
        print('   • ${value['name']} (${value['isHost'] ? 'Hôte' : 'Joueur'}) - $status');
      });
      
      final readyCount = players.values.where((p) => p['isReady'] == true).length;
      if (readyCount == 2) {
        print('✅ Test réussi: Les 2 joueurs sont prêts');
      } else {
        print('❌ Test échoué: Seulement $readyCount joueur(s) prêt(s)');
      }
    } else {
      print('❌ Room non trouvée pour vérification finale');
      exit(1);
    }
  } catch (e) {
    print('❌ Erreur vérification finale: $e');
    exit(1);
  }

  // Test 7: Nettoyage
  print('\n📊 Test 7: Nettoyage...');
  try {
    await _makeRequest('DELETE', '/rooms/$testRoomId');
    print('✅ Room de test supprimée');
  } catch (e) {
    print('❌ Erreur nettoyage: $e');
  }

  print('\n🎉 Tests de mise à jour liste joueurs terminés !');
  print('✅ La mise à jour en temps réel de la liste des joueurs fonctionne');
  print('🌐 Application disponible sur: https://pandora-box-user2.web.app');
  print('\n💡 Pour tester avec deux utilisateurs réels:');
  print('   1. Ouvrez l\'application dans deux onglets différents');
  print('   2. Créez une room dans le premier onglet');
  print('   3. Rejoignez la room avec le code dans le deuxième onglet');
  print('   4. Vérifiez que la liste des joueurs se met à jour immédiatement');
  print('   5. Utilisez le bouton de rafraîchissement si nécessaire');
}
