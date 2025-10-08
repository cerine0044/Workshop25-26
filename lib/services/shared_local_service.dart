import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

class SharedLocalService {
  static final SharedLocalService _instance = SharedLocalService._internal();
  factory SharedLocalService() => _instance;
  SharedLocalService._internal();

  final Map<String, Map<String, dynamic>> _rooms = {};
  final Map<String, StreamController<Map<String, dynamic>?>> _roomControllers = {};
  final StreamController<List<Map<String, dynamic>>> _roomsListStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
  
  String? _currentUserId;
  String? _currentRoomId;
  HttpServer? _server;
  int _port = 8081;

  // Initialiser le service avec serveur HTTP local
  Future<void> initialize() async {
    _currentUserId = 'user_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
    await _startHttpServer();
  }

  Future<void> _startHttpServer() async {
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, _port);
      print('Serveur local démarré sur le port $_port');
      
      await for (HttpRequest request in _server!) {
        _handleRequest(request);
      }
    } catch (e) {
      print('Erreur lors du démarrage du serveur: $e');
    }
  }

  void _handleRequest(HttpRequest request) {
    // Ajouter les headers CORS
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');

    if (request.method == 'OPTIONS') {
      request.response.statusCode = 200;
      request.response.close();
      return;
    }

    final uri = request.uri;
    final path = uri.path;

    try {
      if (path.startsWith('/rooms')) {
        _handleRoomsRequest(request);
      } else if (path.startsWith('/room/')) {
        final roomId = path.split('/')[2];
        _handleRoomRequest(request, roomId);
      } else {
        request.response.statusCode = 404;
        request.response.write('Not Found');
        request.response.close();
      }
    } catch (e) {
      request.response.statusCode = 500;
      request.response.write('Error: $e');
      request.response.close();
    }
  }

  void _handleRoomsRequest(HttpRequest request) {
    if (request.method == 'GET') {
      // Récupérer la liste des rooms
      final availableRooms = _rooms.values
          .where((room) => room['gameState'] == 'waiting')
          .map((room) => Map<String, dynamic>.from(room))
          .toList();
      
      request.response.statusCode = 200;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(availableRooms));
      request.response.close();
    } else if (request.method == 'POST') {
      // Créer une nouvelle room
      _handleCreateRoom(request);
    }
  }

  void _handleRoomRequest(HttpRequest request, String roomId) {
    if (request.method == 'GET') {
      // Récupérer une room spécifique
      final room = _rooms[roomId];
      request.response.statusCode = room != null ? 200 : 404;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(room));
      request.response.close();
    } else if (request.method == 'PUT') {
      // Mettre à jour une room
      _handleUpdateRoom(request, roomId);
    } else if (request.method == 'DELETE') {
      // Supprimer une room
      _rooms.remove(roomId);
      _roomControllers[roomId]?.close();
      _roomControllers.remove(roomId);
      request.response.statusCode = 200;
      request.response.write('Room deleted');
      request.response.close();
    }
  }

  Future<void> _handleCreateRoom(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    final data = jsonDecode(body) as Map<String, dynamic>;
    
    final roomId = DateTime.now().millisecondsSinceEpoch.toString();
    final roomData = {
      'id': roomId,
      'name': data['name'] ?? 'Room',
      'host': _currentUserId!,
      'hostName': 'Joueur $_currentUserId',
      'players': {
        _currentUserId!: {
          'name': 'Joueur $_currentUserId',
          'isHost': true,
          'isReady': false,
          'joinedAt': DateTime.now().toIso8601String(),
        }
      },
      'gameState': 'waiting',
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    _rooms[roomId] = roomData;
    _currentRoomId = roomId;
    
    request.response.statusCode = 201;
    request.response.headers.contentType = ContentType.json;
    request.response.write(jsonEncode({'id': roomId}));
    request.response.close();
    
    _notifyRoomUpdate(roomId);
    _notifyRoomsListUpdate();
  }

  Future<void> _handleUpdateRoom(HttpRequest request, String roomId) async {
    final body = await utf8.decoder.bind(request).join();
    final data = jsonDecode(body) as Map<String, dynamic>;
    
    if (_rooms.containsKey(roomId)) {
      _rooms[roomId]!.addAll(data);
      _notifyRoomUpdate(roomId);
      _notifyRoomsListUpdate();
    }
    
    request.response.statusCode = 200;
    request.response.write('Room updated');
    request.response.close();
  }

  // Créer une room de jeu
  Future<String> createGameRoom(String roomName) async {
    if (_currentUserId == null) {
      throw Exception('Service non initialisé');
    }
    
    final roomId = DateTime.now().millisecondsSinceEpoch.toString();
    final roomData = {
      'id': roomId,
      'name': roomName,
      'host': _currentUserId!,
      'hostName': 'Joueur $_currentUserId',
      'players': {
        _currentUserId!: {
          'name': 'Joueur $_currentUserId',
          'isHost': true,
          'isReady': false,
          'joinedAt': DateTime.now().toIso8601String(),
        }
      },
      'gameState': 'waiting',
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    _rooms[roomId] = roomData;
    _currentRoomId = roomId;
    
    _notifyRoomUpdate(roomId);
    _notifyRoomsListUpdate();
    
    return roomId;
  }

  // Rejoindre une room existante
  Future<void> joinGameRoom(String roomId) async {
    if (_currentUserId == null) {
      throw Exception('Service non initialisé');
    }
    
    if (!_rooms.containsKey(roomId)) {
      throw Exception('Room introuvable');
    }
    
    final roomData = _rooms[roomId]!;
    final players = Map<String, dynamic>.from(roomData['players'] ?? {});
    
    if (players.containsKey(_currentUserId!)) {
      return;
    }
    
    players[_currentUserId!] = {
      'name': 'Joueur $_currentUserId',
      'isHost': false,
      'isReady': false,
      'joinedAt': DateTime.now().toIso8601String(),
    };
    
    roomData['players'] = players;
    _currentRoomId = roomId;
    
    _notifyRoomUpdate(roomId);
    _notifyRoomsListUpdate();
  }

  // Quitter une room
  Future<void> leaveGameRoom(String roomId) async {
    if (_currentUserId == null || !_rooms.containsKey(roomId)) return;
    
    final roomData = _rooms[roomId]!;
    final players = Map<String, dynamic>.from(roomData['players'] ?? {});
    
    if (players.containsKey(_currentUserId!)) {
      players.remove(_currentUserId!);
      
      if (roomData['host'] == _currentUserId!) {
        if (players.isNotEmpty) {
          final newHostId = players.keys.first;
          players[newHostId]['isHost'] = true;
          roomData['host'] = newHostId;
          roomData['players'] = players;
        } else {
          _rooms.remove(roomId);
          _roomControllers[roomId]?.close();
          _roomControllers.remove(roomId);
        }
      } else {
        roomData['players'] = players;
      }
      
      _currentRoomId = null;
      
      _notifyRoomUpdate(roomId);
      _notifyRoomsListUpdate();
    }
  }

  // Écouter les changements d'une room
  Stream<Map<String, dynamic>?> listenToRoom(String roomId) {
    if (!_roomControllers.containsKey(roomId)) {
      _roomControllers[roomId] = StreamController<Map<String, dynamic>?>.broadcast();
    }
    return _roomControllers[roomId]!.stream;
  }

  // Mettre à jour l'état de préparation d'un joueur
  Future<void> updatePlayerReady(String roomId, bool isReady) async {
    if (_currentUserId == null || !_rooms.containsKey(roomId)) return;
    
    final roomData = _rooms[roomId]!;
    final players = Map<String, dynamic>.from(roomData['players'] ?? {});
    
    if (players.containsKey(_currentUserId!)) {
      players[_currentUserId!]['isReady'] = isReady;
      roomData['players'] = players;
      
      _notifyRoomUpdate(roomId);
    }
  }

  // Mettre à jour l'état du jeu
  Future<void> updateGameState(String roomId, String gameState, {Map<String, dynamic>? gameData}) async {
    if (!_rooms.containsKey(roomId)) return;
    
    final roomData = _rooms[roomId]!;
    roomData['gameState'] = gameState;
    roomData['lastUpdated'] = DateTime.now().toIso8601String();
    
    if (gameData != null) {
      roomData['gameData'] = gameData;
    }
    
    _notifyRoomUpdate(roomId);
  }

  // Obtenir la liste des rooms disponibles
  Stream<List<Map<String, dynamic>>> getAvailableRooms() {
    return _roomsListStreamController.stream;
  }

  // Connexion anonyme pour le jeu
  Future<void> signInAnonymously() async {
    // Déjà fait dans initialize()
  }

  // Déconnexion
  Future<void> signOut() async {
    if (_currentRoomId != null) {
      await leaveGameRoom(_currentRoomId!);
    }
    _currentUserId = null;
    _currentRoomId = null;
  }

  // Méthodes privées
  void _notifyRoomUpdate(String roomId) {
    if (_roomControllers.containsKey(roomId)) {
      _roomControllers[roomId]!.add(_rooms[roomId]);
    }
  }

  void _notifyRoomsListUpdate() {
    final availableRooms = _rooms.values
        .where((room) => room['gameState'] == 'waiting')
        .map((room) => Map<String, dynamic>.from(room))
        .toList();
    
    _roomsListStreamController.add(availableRooms);
  }

  // Nettoyer les ressources
  void dispose() {
    for (var controller in _roomControllers.values) {
      controller.close();
    }
    _roomControllers.clear();
    _roomsListStreamController.close();
    _server?.close();
  }
}
