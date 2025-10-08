import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketGameService {
  static final WebSocketGameService _instance = WebSocketGameService._internal();
  factory WebSocketGameService() => _instance;
  WebSocketGameService._internal();

  String? _currentUserId;
  String? _currentRoomId;
  String _serverUrl = 'ws://localhost:5002';
  
  // Configuration dynamique du serveur WebSocket
  void setServerUrl(String url) {
    _serverUrl = url;
  }
  
  String getServerUrl() {
    return _serverUrl;
  } // URL WebSocket du serveur
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _roomController;
  StreamController<List<Map<String, dynamic>>>? _roomsController;
  Timer? _heartbeatTimer;
  bool _isConnected = false;

  // Initialiser le service
  Future<void> initialize() async {
    _currentUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
    _roomController = StreamController<Map<String, dynamic>>.broadcast();
    _roomsController = StreamController<List<Map<String, dynamic>>>.broadcast();
  }

  // Se connecter au serveur WebSocket
  Future<void> connect() async {
    if (_isConnected) return;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_serverUrl));
      _isConnected = true;

      // Écouter les messages du serveur
      _channel!.stream.listen(
        _handleMessage,
        onError: _handleError,
        onDone: _handleDisconnection,
      );

      // Envoyer un message de connexion
      await _sendMessage({
        'type': 'connect',
        'userId': _currentUserId,
      });

      // Démarrer le heartbeat
      _startHeartbeat();

      print('WebSocket connecté avec succès');
    } catch (e) {
      _isConnected = false;
      throw Exception('Erreur de connexion WebSocket: $e');
    }
  }

  // Se déconnecter du serveur
  Future<void> disconnect() async {
    if (_channel != null) {
      await _channel!.sink.close(status.goingAway);
      _channel = null;
    }
    _isConnected = false;
    _stopHeartbeat();
    print('WebSocket déconnecté');
  }

  // Gérer les messages reçus
  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message) as Map<String, dynamic>;
      final type = data['type'] as String;

      switch (type) {
        case 'room_update':
          _handleRoomUpdate(data);
          break;
        case 'rooms_list':
          _handleRoomsList(data);
          break;
        case 'pong':
          // Réponse au ping, pas d'action nécessaire
          break;
        case 'error':
          print('Erreur serveur: ${data['message']}');
          break;
        default:
          print('Message non reconnu: $type');
      }
    } catch (e) {
      print('Erreur lors du traitement du message: $e');
    }
  }

  // Gérer les mises à jour de room
  void _handleRoomUpdate(Map<String, dynamic> data) {
    final roomData = data['room'] as Map<String, dynamic>?;
    if (roomData != null && _roomController != null) {
      _roomController!.add(roomData);
    }
  }

  // Gérer la liste des rooms
  void _handleRoomsList(Map<String, dynamic> data) {
    final rooms = (data['rooms'] as List<dynamic>?)
        ?.cast<Map<String, dynamic>>() ?? [];
    if (_roomsController != null) {
      _roomsController!.add(rooms);
    }
  }

  // Gérer les erreurs
  void _handleError(error) {
    print('Erreur WebSocket: $error');
    _isConnected = false;
  }

  // Gérer la déconnexion
  void _handleDisconnection() {
    print('WebSocket déconnecté par le serveur');
    _isConnected = false;
    _stopHeartbeat();
  }

  // Envoyer un message au serveur
  Future<void> _sendMessage(Map<String, dynamic> message) async {
    if (_channel == null || !_isConnected) {
      throw Exception('WebSocket non connecté');
    }

    try {
      _channel!.sink.add(jsonEncode(message));
    } catch (e) {
      throw Exception('Erreur lors de l\'envoi du message: $e');
    }
  }

  // Démarrer le heartbeat pour maintenir la connexion
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected) {
        _sendMessage({'type': 'ping'});
      }
    });
  }

  // Arrêter le heartbeat
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  // Créer une room de jeu
  Future<String> createGameRoom(String roomName) async {
    if (_currentUserId == null) {
      throw Exception('Service non initialisé');
    }

    if (!_isConnected) {
      await connect();
    }

    try {
      await _sendMessage({
        'type': 'create_room',
        'roomName': roomName,
        'host': _currentUserId!,
        'hostName': 'Joueur $_currentUserId',
      });

      // Attendre la réponse avec l'ID de la room
      final completer = Completer<String>();
      late StreamSubscription subscription;

      subscription = _roomController!.stream.listen((roomData) {
        if (roomData['host'] == _currentUserId) {
          _currentRoomId = roomData['id'] as String;
          subscription.cancel();
          completer.complete(_currentRoomId!);
        }
      });

      return await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout lors de la création de la room'),
      );
    } catch (e) {
      throw Exception('Erreur lors de la création de la room: $e');
    }
  }

  // Rejoindre une room existante
  Future<void> joinGameRoom(String roomId) async {
    if (_currentUserId == null) {
      throw Exception('Service non initialisé');
    }

    if (!_isConnected) {
      await connect();
    }

    try {
      await _sendMessage({
        'type': 'join_room',
        'roomId': roomId,
        'userId': _currentUserId!,
        'userName': 'Joueur $_currentUserId',
      });

      _currentRoomId = roomId;
    } catch (e) {
      throw Exception('Erreur lors de la connexion à la room: $e');
    }
  }

  // Quitter une room
  Future<void> leaveGameRoom(String roomId) async {
    if (_currentUserId == null) return;

    try {
      await _sendMessage({
        'type': 'leave_room',
        'roomId': roomId,
        'userId': _currentUserId!,
      });

      if (_currentRoomId == roomId) {
        _currentRoomId = null;
      }
    } catch (e) {
      throw Exception('Erreur lors de la sortie de la room: $e');
    }
  }

  // Mettre à jour l'état de préparation d'un joueur
  Future<void> updatePlayerReady(String roomId, bool isReady) async {
    if (_currentUserId == null) {
      throw Exception('Service non initialisé');
    }

    try {
      await _sendMessage({
        'type': 'update_player_ready',
        'roomId': roomId,
        'userId': _currentUserId!,
        'isReady': isReady,
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  // Mettre à jour l'état du jeu
  Future<void> updateGameState(String roomId, String gameState, {Map<String, dynamic>? gameData}) async {
    try {
      final Map<String, dynamic> message = {
        'type': 'update_game_state',
        'roomId': roomId,
        'gameState': gameState,
        'lastUpdated': DateTime.now().toIso8601String(),
      };

      if (gameData != null) {
        message['gameData'] = gameData;
      }

      await _sendMessage(message);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour: $e');
    }
  }

  // Écouter les changements d'une room
  Stream<Map<String, dynamic>?> listenToRoom(String roomId) {
    if (_roomController == null) {
      return Stream.value(null);
    }

    return _roomController!.stream.where((roomData) {
      return roomData['id'] == roomId;
    });
  }

  // Obtenir la liste des rooms disponibles
  Stream<List<Map<String, dynamic>>> getAvailableRooms() {
    if (_roomsController == null) {
      return Stream.value([]);
    }

    // Demander la liste des rooms
    if (_isConnected) {
      _sendMessage({'type': 'get_rooms'});
    }

    return _roomsController!.stream;
  }

  // Connexion anonyme
  Future<void> signInAnonymously() async {
    await initialize();
    await connect();
  }

  // Déconnexion
  Future<void> signOut() async {
    if (_currentRoomId != null) {
      try {
        await leaveGameRoom(_currentRoomId!);
      } catch (e) {
        // Ignorer les erreurs de déconnexion
      }
    }
    await disconnect();
    _currentUserId = null;
    _currentRoomId = null;
  }

  // Vérifier si connecté
  bool get isConnected => _isConnected;

  // Obtenir l'ID utilisateur actuel
  String? get currentUserId => _currentUserId;

  // Obtenir l'ID de room actuel
  String? get currentRoomId => _currentRoomId;
}
