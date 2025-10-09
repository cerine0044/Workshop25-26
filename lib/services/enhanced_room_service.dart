import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'firebase_service.dart';

class EnhancedRoomService {
  static final EnhancedRoomService _instance = EnhancedRoomService._internal();
  factory EnhancedRoomService() => _instance;
  EnhancedRoomService._internal();

  // Configuration
  static const int maxPlayersPerRoom = 6;
  static const int roomCodeLength = 6;
  static const Duration roomTimeout = Duration(minutes: 30);
  
  // État local
  String? _currentRoomId;
  String? _currentPlayerId;
  String? _currentPlayerName;
  Timer? _heartbeatTimer;
  Timer? _roomCleanupTimer;
  
  // Streams
  final StreamController<RoomState> _roomStateController = StreamController<RoomState>.broadcast();
  final StreamController<List<Room>> _availableRoomsController = StreamController<List<Room>>.broadcast();
  
  // Getters
  Stream<RoomState> get roomStateStream => _roomStateController.stream;
  Stream<List<Room>> get availableRoomsStream => _availableRoomsController.stream;
  String? get currentRoomId => _currentRoomId;
  String? get currentPlayerId => _currentPlayerId;
  String? get currentPlayerName => _currentPlayerName;
  
  // Initialisation
  Future<void> initialize() async {
    await FirebaseService.initialize();
    await FirebaseService.signInAnonymously();
    _startRoomCleanupTimer();
    _loadAvailableRooms();
  }
  
  // Générer un code de room unique
  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(roomCodeLength, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }
  
  // Créer une room avec des fonctionnalités avancées
  Future<Room> createRoom({
    required String name,
    String? description,
    int maxPlayers = maxPlayersPerRoom,
    bool isPrivate = false,
    Map<String, dynamic>? gameSettings,
  }) async {
    try {
      final roomCode = _generateRoomCode();
      final playerId = _generatePlayerId();
      final playerName = _generatePlayerName();
      
      _currentPlayerId = playerId;
      _currentPlayerName = playerName;
      
      final roomId = await FirebaseService.createGameRoom(name);
      
      // Créer l'objet Room avec toutes les informations
      final room = Room(
        id: roomId,
        code: roomCode,
        name: name,
        description: description ?? '',
        hostId: playerId,
        hostName: playerName,
        maxPlayers: maxPlayers,
        isPrivate: isPrivate,
        gameSettings: gameSettings ?? {},
        players: {
          playerId: Player(
            id: playerId,
            name: playerName,
            isHost: true,
            isReady: false,
            joinedAt: DateTime.now(),
            avatar: _generateAvatar(),
          ),
        },
        gameState: GameState.waiting,
        createdAt: DateTime.now(),
        lastActivity: DateTime.now(),
      );
      
      _currentRoomId = roomId;
      _startHeartbeat();
      _roomStateController.add(RoomStateJoined(room));
      
      return room;
    } catch (e) {
      _roomStateController.add(RoomStateError('Erreur lors de la création: $e'));
      rethrow;
    }
  }
  
  // Rejoindre une room par code ou ID
  Future<Room> joinRoom(String roomCodeOrId) async {
    try {
      final playerId = _generatePlayerId();
      final playerName = _generatePlayerName();
      
      _currentPlayerId = playerId;
      _currentPlayerName = playerName;
      
      await FirebaseService.joinGameRoom(roomCodeOrId);
      
      // Écouter les changements de la room
      FirebaseService.listenToRoom(roomCodeOrId).listen((roomData) {
        if (roomData != null) {
          final room = _convertToRoom(roomData);
          _roomStateController.add(RoomStateJoined(room));
        } else {
          _roomStateController.add(RoomStateLeft());
        }
      });
      
      _currentRoomId = roomCodeOrId;
      _startHeartbeat();
      
      // Récupérer les données de la room
      final roomData = await _getRoomData(roomCodeOrId);
      final room = _convertToRoom(roomData);
      _roomStateController.add(RoomStateJoined(room));
      
      return room;
    } catch (e) {
      _roomStateController.add(RoomStateError('Erreur lors de la connexion: $e'));
      rethrow;
    }
  }
  
  // Quitter la room actuelle
  Future<void> leaveRoom() async {
    if (_currentRoomId == null) return;
    
    try {
      await FirebaseService.leaveGameRoom(_currentRoomId!);
      _stopHeartbeat();
      _currentRoomId = null;
      _currentPlayerId = null;
      _currentPlayerName = null;
      _roomStateController.add(RoomStateLeft());
    } catch (e) {
      _roomStateController.add(RoomStateError('Erreur lors de la déconnexion: $e'));
    }
  }
  
  // Mettre à jour l'état de préparation
  Future<void> toggleReady() async {
    if (_currentRoomId == null || _currentPlayerId == null) return;
    
    try {
      // Récupérer l'état actuel
      final roomData = await _getRoomData(_currentRoomId!);
      final players = Map<String, dynamic>.from(roomData['players'] ?? {});
      final currentPlayer = players[_currentPlayerId];
      
      if (currentPlayer != null) {
        final newReadyState = !(currentPlayer['isReady'] ?? false);
        await FirebaseService.updatePlayerReady(_currentRoomId!, newReadyState);
      }
    } catch (e) {
      _roomStateController.add(RoomStateError('Erreur lors du changement d\'état: $e'));
    }
  }
  
  // Démarrer le jeu (hôte seulement)
  Future<void> startGame() async {
    if (_currentRoomId == null) return;
    
    try {
      await FirebaseService.updateGameState(_currentRoomId!, 'playing');
    } catch (e) {
      _roomStateController.add(RoomStateError('Erreur lors du démarrage: $e'));
    }
  }
  
  // Charger les rooms disponibles
  void _loadAvailableRooms() {
    FirebaseService.getAvailableRooms().listen((roomsData) {
      final rooms = roomsData.map((data) => _convertToRoom(data)).toList();
      _availableRoomsController.add(rooms);
    });
  }
  
  // Convertir les données Firebase en objet Room
  Room _convertToRoom(Map<String, dynamic> data) {
    final players = Map<String, dynamic>.from(data['players'] ?? {});
    final playersMap = <String, Player>{};
    
    players.forEach((id, playerData) {
      playersMap[id] = Player(
        id: id,
        name: playerData['name'] ?? 'Joueur',
        isHost: playerData['isHost'] ?? false,
        isReady: playerData['isReady'] ?? false,
        joinedAt: DateTime.tryParse(playerData['joinedAt'] ?? '') ?? DateTime.now(),
        avatar: playerData['avatar'] ?? _generateAvatar(),
      );
    });
    
    return Room(
      id: data['id'] ?? '',
      code: data['code'] ?? '',
      name: data['name'] ?? 'Room sans nom',
      description: data['description'] ?? '',
      hostId: data['host'] ?? '',
      hostName: data['hostName'] ?? 'Hôte',
      maxPlayers: data['maxPlayers'] ?? maxPlayersPerRoom,
      isPrivate: data['isPrivate'] ?? false,
      gameSettings: Map<String, dynamic>.from(data['gameSettings'] ?? {}),
      players: playersMap,
      gameState: _parseGameState(data['gameState']),
      createdAt: DateTime.tryParse(data['createdAt'] ?? '') ?? DateTime.now(),
      lastActivity: DateTime.tryParse(data['lastActivity'] ?? '') ?? DateTime.now(),
    );
  }
  
  // Parser l'état du jeu
  GameState _parseGameState(String? state) {
    switch (state) {
      case 'waiting': return GameState.waiting;
      case 'playing': return GameState.playing;
      case 'finished': return GameState.finished;
      default: return GameState.waiting;
    }
  }
  
  // Récupérer les données d'une room
  Future<Map<String, dynamic>> _getRoomData(String roomId) async {
    // Cette méthode devrait être implémentée dans FirebaseService
    // Pour l'instant, on utilise une approche simplifiée
    return {};
  }
  
  // Générer un ID de joueur unique
  String _generatePlayerId() {
    return 'player_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }
  
  // Générer un nom de joueur
  String _generatePlayerName() {
    final names = ['Joueur', 'Gamer', 'Player', 'Guest'];
    final random = Random();
    return '${names[random.nextInt(names.length)]} ${random.nextInt(999) + 1}';
  }
  
  // Générer un avatar
  String _generateAvatar() {
    final avatars = ['👤', '🎮', '🎯', '🚀', '⭐', '🔥', '💎', '🌟'];
    final random = Random();
    return avatars[random.nextInt(avatars.length)];
  }
  
  // Heartbeat pour maintenir la connexion
  void _startHeartbeat() {
    _stopHeartbeat();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_currentRoomId != null) {
        // Envoyer un heartbeat pour maintenir la connexion
        FirebaseService.updateGameState(_currentRoomId!, 'heartbeat');
      }
    });
  }
  
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }
  
  // Nettoyage périodique des rooms inactives
  void _startRoomCleanupTimer() {
    _roomCleanupTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      _cleanupInactiveRooms();
    });
  }
  
  Future<void> _cleanupInactiveRooms() async {
    // Implémentation du nettoyage des rooms inactives
    // Cette fonctionnalité pourrait être implémentée côté serveur
  }
  
  // Nettoyage
  void dispose() {
    _stopHeartbeat();
    _roomCleanupTimer?.cancel();
    _roomStateController.close();
    _availableRoomsController.close();
  }
}

// Modèles de données
class Room {
  final String id;
  final String code;
  final String name;
  final String description;
  final String hostId;
  final String hostName;
  final int maxPlayers;
  final bool isPrivate;
  final Map<String, dynamic> gameSettings;
  final Map<String, Player> players;
  final GameState gameState;
  final DateTime createdAt;
  final DateTime lastActivity;
  
  Room({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.hostId,
    required this.hostName,
    required this.maxPlayers,
    required this.isPrivate,
    required this.gameSettings,
    required this.players,
    required this.gameState,
    required this.createdAt,
    required this.lastActivity,
  });
  
  int get playerCount => players.length;
  bool get isFull => playerCount >= maxPlayers;
  bool get canStart => playerCount >= 2 && players.values.every((p) => p.isReady);
  
  Player? get host => players[hostId];
  List<Player> get playersList => players.values.toList();
}

class Player {
  final String id;
  final String name;
  final bool isHost;
  final bool isReady;
  final DateTime joinedAt;
  final String avatar;
  
  Player({
    required this.id,
    required this.name,
    required this.isHost,
    required this.isReady,
    required this.joinedAt,
    required this.avatar,
  });
}

enum GameState {
  waiting,
  playing,
  finished,
}

abstract class RoomState {
  const RoomState();
}

class RoomStateDisconnected extends RoomState {
  const RoomStateDisconnected();
}

class RoomStateConnecting extends RoomState {
  const RoomStateConnecting();
}

class RoomStateJoined extends RoomState {
  final Room room;
  const RoomStateJoined(this.room);
}

class RoomStateLeft extends RoomState {
  const RoomStateLeft();
}

class RoomStateError extends RoomState {
  final String message;
  const RoomStateError(this.message);
}
