import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class HttpGameService {
  static final HttpGameService _instance = HttpGameService._internal();
  factory HttpGameService() => _instance;
  HttpGameService._internal();

  String? _currentUserId;
  String? _currentRoomId;
  String _serverUrl = 'http://10.151.18.84:5001'; // URL du serveur backend

  // Initialiser le service
  Future<void> initialize() async {
    _currentUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Créer une room de jeu
  Future<String> createGameRoom(String roomName) async {
    if (_currentUserId == null) {
      throw Exception('Service non initialisé');
    }

    try {
      final response = await http.post(
        Uri.parse('$_serverUrl/rooms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': roomName,
          'host': _currentUserId!,
          'hostName': 'Joueur $_currentUserId',
        }),
      );
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _currentRoomId = data['id'] as String;
        return _currentRoomId!;
      } else {
        throw Exception('Erreur lors de la création de la room');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Rejoindre une room existante
  Future<void> joinGameRoom(String roomId) async {
    if (_currentUserId == null) {
      throw Exception('Service non initialisé');
    }

    try {
      final response = await http.get(Uri.parse('$_serverUrl/room/$roomId'));
      
      if (response.statusCode == 200) {
        _currentRoomId = roomId;
        // Ici vous pourriez ajouter le joueur à la room si nécessaire
      } else {
        throw Exception('Room introuvable');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Récupérer toutes les rooms disponibles
  Future<List<Map<String, dynamic>>> getAvailableRooms() async {
    try {
      final response = await http.get(Uri.parse('$_serverUrl/rooms'));
      
      if (response.statusCode == 200) {
        final List<dynamic> roomsJson = jsonDecode(response.body);
        return roomsJson.cast<Map<String, dynamic>>();
      } else {
        return [];
      }
    } catch (e) {
      print('Erreur lors de la récupération des rooms: $e');
      return [];
    }
  }

  // Récupérer une room spécifique
  Future<Map<String, dynamic>?> getRoom(String roomId) async {
    try {
      final response = await http.get(Uri.parse('$_serverUrl/room/$roomId'));
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        return null;
      }
    } catch (e) {
      print('Erreur lors de la récupération de la room: $e');
      return null;
    }
  }

  // Stream des rooms disponibles (polling toutes les 2 secondes)
  Stream<List<Map<String, dynamic>>> getAvailableRoomsStream() async* {
    while (true) {
      try {
        final rooms = await getAvailableRooms();
        yield rooms;
      } catch (e) {
        yield [];
      }
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  // Stream d'une room spécifique (polling toutes les 2 secondes)
  Stream<Map<String, dynamic>?> getRoomStream(String roomId) async* {
    while (true) {
      try {
        final room = await getRoom(roomId);
        yield room;
      } catch (e) {
        yield null;
      }
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  // Écouter les changements d'une room (alias pour compatibilité)
  Stream<Map<String, dynamic>?> listenToRoom(String roomId) {
    return getRoomStream(roomId);
  }

  // Quitter une room
  Future<void> leaveGameRoom(String roomId) async {
    if (_currentUserId == null) {
      throw Exception('Service non initialisé');
    }

    try {
      final response = await http.put(
        Uri.parse('$_serverUrl/room/$roomId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'players': {
            _currentUserId: null, // Supprimer le joueur
          }
        }),
      );
      
      if (response.statusCode == 200) {
        _currentRoomId = null;
      } else {
        throw Exception('Erreur lors de la sortie de la room');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Mettre à jour l'état de préparation d'un joueur
  Future<void> updatePlayerReady(String roomId, bool isReady) async {
    if (_currentUserId == null) {
      throw Exception('Service non initialisé');
    }

    try {
      final response = await http.put(
        Uri.parse('$_serverUrl/room/$roomId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'players': {
            _currentUserId: {
              'isReady': isReady,
            }
          }
        }),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Erreur lors de la mise à jour');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Mettre à jour l'état du jeu
  Future<void> updateGameState(String roomId, String gameState, {Map<String, dynamic>? gameData}) async {
    try {
      final Map<String, dynamic> body = {
        'gameState': gameState,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      
      if (gameData != null) {
        body['gameData'] = gameData;
      }
      
      final response = await http.put(
        Uri.parse('$_serverUrl/room/$roomId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Erreur lors de la mise à jour');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  // Connexion anonyme - vraie connexion au serveur
  Future<void> signInAnonymously() async {
    if (_currentUserId == null) {
      await initialize();
    }
    
    // Tester la connexion au serveur
    try {
      final response = await http.get(Uri.parse('$_serverUrl/rooms'));
      
      if (response.statusCode != 200) {
        throw Exception('Serveur backend non accessible');
      }
    } catch (e) {
      throw Exception('Impossible de se connecter au serveur backend: $e');
    }
  }

  // Déconnexion - vraie déconnexion
  Future<void> signOut() async {
    if (_currentRoomId != null) {
      try {
        await leaveGameRoom(_currentRoomId!);
      } catch (e) {
        // Ignorer les erreurs de déconnexion
      }
    }
    _currentUserId = null;
    _currentRoomId = null;
  }
}