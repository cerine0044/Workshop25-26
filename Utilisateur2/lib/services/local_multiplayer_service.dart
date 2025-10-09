import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class LocalMultiplayerService {
  static final LocalMultiplayerService _instance = LocalMultiplayerService._internal();
  factory LocalMultiplayerService() => _instance;
  LocalMultiplayerService._internal();

  bool _isInitialized = false;
  
  String? _currentRoomId;
  String? _currentPlayerId;
  String? _currentPlayerName;
  
  StreamController<Map<String, dynamic>?>? _roomStateController;
  StreamController<List<Map<String, dynamic>>>? _availableRoomsController;
  Map<String, dynamic>? _currentRoom;
  
  // Stockage partagé statique pour toutes les instances
  static List<Map<String, dynamic>> _sharedRooms = [];
  
  Stream<Map<String, dynamic>?> get roomStateStream => _roomStateController?.stream ?? const Stream.empty();
  Stream<List<Map<String, dynamic>>> get availableRoomsStream => _availableRoomsController?.stream ?? const Stream.empty();
  
  String? get currentRoomId => _currentRoomId;
  String? get currentPlayerId => _currentPlayerId;
  String? get currentPlayerName => _currentPlayerName;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🔥 Initialisation LocalMultiplayerService...');
      
      // Initialiser les controllers de stream
      _roomStateController = StreamController<Map<String, dynamic>?>.broadcast();
      _availableRoomsController = StreamController<List<Map<String, dynamic>>>.broadcast();
      
      // Créer un joueur local
      _currentPlayerId = _generatePlayerId();
      _currentPlayerName = _generatePlayerName();
      
      _isInitialized = true;
      print('✅ LocalMultiplayerService initialisé avec succès');
      print('👤 Joueur: $_currentPlayerName ($_currentPlayerId)');
      
    } catch (e) {
      print('❌ Erreur initialisation LocalMultiplayerService: $e');
      throw Exception('Erreur d\'initialisation: $e');
    }
  }

  String _generatePlayerId() {
    return 'player_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  String _generatePlayerName() {
    final names = ['Joueur A', 'Joueur B', 'Joueur C', 'Joueur D', 'Joueur E', 'Joueur F'];
    return names[Random().nextInt(names.length)];
  }

  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
        Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length)))
    );
  }

  String _generateAvatar() {
    final avatars = ['🎮', '👾', '🎯', '🎲', '🎪', '🎨'];
    return avatars[Random().nextInt(avatars.length)];
  }

  Future<String> createRoom({
    required String name,
    String? description,
    int maxPlayers = 4,
  }) async {
    if (!_isInitialized) {
      throw Exception('Service non initialisé');
    }

    try {
      final roomId = DateTime.now().millisecondsSinceEpoch.toString();
      final roomCode = _generateRoomCode();
      
      final roomData = {
        'id': roomId,
        'code': roomCode,
        'name': name,
        'description': description ?? '',
        'hostId': _currentPlayerId,
        'hostName': _currentPlayerName,
        'maxPlayers': maxPlayers,
        'isPrivate': false,
        'players': {
          _currentPlayerId: {
            'id': _currentPlayerId,
            'name': _currentPlayerName,
            'isHost': true,
            'isReady': false,
            'joinedAt': DateTime.now().toIso8601String(),
            'avatar': _generateAvatar(),
          }
        },
        'gameState': 'waiting',
        'createdAt': DateTime.now().toIso8601String(),
        'lastActivity': DateTime.now().toIso8601String(),
      };

      print('🏠 Création room locale: $name ($roomCode)');
      
      _currentRoomId = roomId;
      _currentRoom = roomData;
      _roomStateController?.add(_currentRoom);
      
      // Ajouter à la liste des rooms disponibles (stockage partagé)
      _sharedRooms.add(roomData);
      _availableRoomsController?.add(_sharedRooms);
      
      print('✅ Room créée localement: $name ($roomCode)');
      return roomCode; // Retourner le code au lieu de l'ID
      
    } catch (e) {
      print('❌ Erreur création room locale: $e');
      throw Exception('Erreur lors de la création de la room: $e');
    }
  }

  Future<void> joinRoom(String roomCode) async {
    if (!_isInitialized) {
      throw Exception('Service non initialisé');
    }

    try {
      print('🚪 Tentative de rejoindre room avec code: $roomCode');
      
      // Chercher une room existante avec ce code (stockage partagé)
      Map<String, dynamic>? foundRoom;
      for (var room in _sharedRooms) {
        if (room['code'] == roomCode) {
          foundRoom = room;
          break;
        }
      }
      
      if (foundRoom != null) {
        // Ajouter le joueur à la room existante
        final players = Map<String, dynamic>.from(foundRoom['players'] ?? {});
        players[_currentPlayerId!] = {
          'id': _currentPlayerId,
          'name': _currentPlayerName,
          'isHost': false,
          'isReady': false,
          'joinedAt': DateTime.now().toIso8601String(),
          'avatar': _generateAvatar(),
        };
        
        foundRoom['players'] = players;
        foundRoom['lastActivity'] = DateTime.now().toIso8601String();
        
        _currentRoomId = foundRoom['id'];
        _currentRoom = foundRoom;
        _roomStateController?.add(_currentRoom);
        
        // Mettre à jour la liste des rooms disponibles (stockage partagé)
        final roomIndex = _sharedRooms.indexWhere((r) => r['id'] == foundRoom!['id']);
        if (roomIndex != -1) {
          _sharedRooms[roomIndex] = foundRoom;
          _availableRoomsController?.add(_sharedRooms);
        }
        
        print('✅ Rejoint room existante: ${foundRoom['name']} (code: $roomCode)');
      } else {
        throw Exception('Room avec le code $roomCode introuvable');
      }
      
    } catch (e) {
      print('❌ Erreur rejoindre room locale: $e');
      throw Exception('Erreur lors de la connexion à la room: $e');
    }
  }

  Future<void> leaveRoom() async {
    try {
      print('🚪 Quitter room locale');
      
      _currentRoomId = null;
      _currentRoom = null;
      _roomStateController?.add(null);
      
      print('✅ Room quittée');
      
    } catch (e) {
      print('❌ Erreur quitter room locale: $e');
      throw Exception('Erreur lors de la déconnexion: $e');
    }
  }

  void dispose() {
    _roomStateController?.close();
  }
}
