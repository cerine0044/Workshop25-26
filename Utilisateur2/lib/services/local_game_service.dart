import 'dart:async';
import 'dart:math';

class LocalGameService {
  static final LocalGameService _instance = LocalGameService._internal();
  factory LocalGameService() => _instance;
  LocalGameService._internal();

  final Map<String, Map<String, dynamic>> _rooms = {};
  final Map<String, StreamController<Map<String, dynamic>?>> _roomControllers = {};
  final Map<String, StreamController<List<Map<String, dynamic>>>> _roomsListController = {};
  final StreamController<List<Map<String, dynamic>>> _roomsListStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
  
  String? _currentUserId;
  String? _currentRoomId;

  // Initialiser le service
  Future<void> initialize() async {
    _currentUserId = 'user_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
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
    
    // Notifier les changements
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
    
    // Vérifier si le joueur n'est pas déjà dans la room
    if (players.containsKey(_currentUserId!)) {
      return; // Déjà dans la room
    }
    
    // Ajouter le joueur à la room
    players[_currentUserId!] = {
      'name': 'Joueur $_currentUserId',
      'isHost': false,
      'isReady': false,
      'joinedAt': DateTime.now().toIso8601String(),
    };
    
    roomData['players'] = players;
    _currentRoomId = roomId;
    
    // Notifier les changements
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
      
      // Si c'était l'hôte qui partait, transférer l'hôte ou supprimer la room
      if (roomData['host'] == _currentUserId!) {
        if (players.isNotEmpty) {
          // Transférer l'hôte au premier joueur restant
          final newHostId = players.keys.first;
          players[newHostId]['isHost'] = true;
          roomData['host'] = newHostId;
          roomData['players'] = players;
        } else {
          // Supprimer la room si plus personne
          _rooms.remove(roomId);
          _roomControllers[roomId]?.close();
          _roomControllers.remove(roomId);
        }
      } else {
        roomData['players'] = players;
      }
      
      _currentRoomId = null;
      
      // Notifier les changements
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
  }
}
