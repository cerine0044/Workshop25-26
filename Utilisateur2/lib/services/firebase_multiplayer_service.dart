import 'dart:async';
import 'dart:math';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_options.dart';
import 'player_name_service.dart';
import 'player_persistence_service.dart';

class FirebaseMultiplayerService {
  static final FirebaseMultiplayerService _instance = FirebaseMultiplayerService._internal();
  factory FirebaseMultiplayerService() => _instance;
  FirebaseMultiplayerService._internal();

  FirebaseDatabase? _database;
  FirebaseAuth? _auth;
  bool _isInitialized = false;
  
  String? _currentRoomId;
  String? _currentPlayerId;
  String? _currentPlayerName;
  
  final PlayerNameService _playerNameService = PlayerNameService();
  final PlayerPersistenceService _persistenceService = PlayerPersistenceService();
  
  StreamController<Map<String, dynamic>?>? _roomStateController;
  StreamController<List<Map<String, dynamic>>>? _availableRoomsController;
  StreamSubscription? _roomSubscription;
  StreamSubscription? _availableRoomsSubscription;
  
  Stream<Map<String, dynamic>?> get roomStateStream => _roomStateController?.stream ?? const Stream.empty();
  Stream<List<Map<String, dynamic>>> get availableRoomsStream => _availableRoomsController?.stream ?? const Stream.empty();
  
  String? get currentRoomId => _currentRoomId;
  String? get currentPlayerId => _currentPlayerId;
  String? get currentPlayerName => _currentPlayerName;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🔥 Initialisation Firebase...');
      
      // Initialiser les controllers de stream
      _roomStateController = StreamController<Map<String, dynamic>?>.broadcast();
      _availableRoomsController = StreamController<List<Map<String, dynamic>>>.broadcast();
      
      // Initialiser Firebase
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      _database = FirebaseDatabase.instance;
      _auth = FirebaseAuth.instance;
      
      print('✅ Firebase initialisé');
      
      // Essayer la connexion anonyme
      try {
        print('🔐 Tentative de connexion anonyme...');
        await _auth!.signInAnonymously();
        print('✅ Connexion anonyme réussie');
      } catch (authError) {
        print('⚠️ Erreur auth, création d\'un utilisateur local: $authError');
        // Créer un utilisateur local si l'auth échoue
        _currentPlayerId = _generatePlayerId();
        _currentPlayerName = _playerNameService.getPlayerNameOrDefault();
      }
      
      // Initialiser le PlayerNameService d'abord
      await _playerNameService.initialize();
      
      // Initialiser le service de persistance
      await _persistenceService.initialize();
      
      // Récupérer les infos utilisateur
      if (_auth!.currentUser != null) {
        _currentPlayerId = _auth!.currentUser!.uid;
        // Utiliser le nom du PlayerNameService en priorité, sinon Firebase Auth
        _currentPlayerName = _playerNameService.currentPlayerName ?? 
                           _auth!.currentUser!.displayName ?? 
                           _playerNameService.getPlayerNameOrDefault();
      } else if (_currentPlayerId == null) {
        _currentPlayerId = _generatePlayerId();
        _currentPlayerName = _playerNameService.currentPlayerName ?? 
                           _playerNameService.getPlayerNameOrDefault();
      }
      
      // Synchroniser avec PlayerNameService et persistance
      if (_currentPlayerName != null && _currentPlayerId != null) {
        await _playerNameService.setPlayerName(_currentPlayerName!);
        await _persistenceService.syncPlayerData();
      }
      
      _isInitialized = true;
      print('✅ FirebaseMultiplayerService initialisé avec succès');
      print('👤 Joueur: $_currentPlayerName ($_currentPlayerId)');
      
      // Charger les rooms disponibles
      _loadAvailableRooms();
      
      // Démarrer le nettoyage périodique des joueurs inactifs
      _startPlayerCleanup();
      
    } catch (e) {
      print('❌ Erreur initialisation FirebaseMultiplayerService: $e');
      throw Exception('Erreur d\'initialisation Firebase: $e');
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

  Future<String> createRoom({
    required String name,
    String? description,
    int maxPlayers = 2,
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
            'isCurrentPlayer': true,
            'joinedAt': DateTime.now().toIso8601String(),
            'avatar': _generateAvatar(),
          }
        },
        'gameState': 'waiting',
        'createdAt': DateTime.now().toIso8601String(),
        'lastActivity': DateTime.now().toIso8601String(),
      };

      print('🏠 Création room Firebase: $name ($roomCode)');
      await _database!.ref('rooms/$roomId').set(roomData);
      
      _currentRoomId = roomId;
      _listenToRoom(roomId);
      
      print('✅ Room créée dans Firebase: $name ($roomCode)');
      return roomCode;
      
    } catch (e) {
      print('❌ Erreur création room Firebase: $e');
      throw Exception('Erreur lors de la création de la room: $e');
    }
  }

  Future<void> joinRoom(String roomCode) async {
    if (!_isInitialized) {
      throw Exception('Service non initialisé');
    }

    try {
      print('🚪 Tentative de rejoindre room avec code: $roomCode');
      
      // Rechercher la room par code
      final roomsRef = _database!.ref('rooms');
      final snapshot = await roomsRef.get();
      
      if (!snapshot.exists) {
        throw Exception('Aucune room trouvée');
      }
      
      final roomsData = _convertToMap(snapshot.value);
      if (roomsData == null) {
        throw Exception('Erreur de lecture des données des rooms');
      }
      
      String? foundRoomId;
      Map<String, dynamic>? foundRoomData;
      
      // Chercher la room avec le bon code
      roomsData.forEach((roomId, roomData) {
        final room = _convertToMap(roomData);
        if (room != null && room['code'] == roomCode) {
          foundRoomId = roomId;
          foundRoomData = room;
        }
      });
      
      if (foundRoomId == null || foundRoomData == null) {
        throw Exception('Room avec le code $roomCode introuvable');
      }
      
      final roomRef = _database!.ref('rooms/$foundRoomId');
      final players = _convertToMap(foundRoomData!['players']) ?? {};
      
      // Vérifier si la room est pleine
      if (players.length >= (foundRoomData!['maxPlayers'] ?? 2)) {
        throw Exception('Room pleine');
      }
      
      // Vérifier si le joueur n'est pas déjà dans la room
      if (players.containsKey(_currentPlayerId)) {
        _currentRoomId = foundRoomId!;
        _listenToRoom(foundRoomId!);
        print('✅ Joueur déjà dans la room');
        return;
      }
      
      // Démarrer l'écoute AVANT de modifier la room
      _currentRoomId = foundRoomId!;
      _listenToRoom(foundRoomId!);
      
      // S'assurer que le nom du joueur est défini et sauvegardé
      String playerName = _currentPlayerName ?? 'Joueur ${_currentPlayerId!.substring(0, 4)}';
      
      // Ajouter le joueur à la room avec sauvegarde complète
      players[_currentPlayerId!] = {
        'id': _currentPlayerId,
        'name': playerName,
        'isHost': false,
        'isReady': false,
        'isCurrentPlayer': true,
        'joinedAt': DateTime.now().toIso8601String(),
        'lastActivity': DateTime.now().toIso8601String(),
        'avatar': _generateAvatar(),
        'playerId': _currentPlayerId!, // Sauvegarder l'ID pour référence externe
      };
      
      print('👤 Ajout du joueur à la room Firebase');
      await roomRef.update({
        'players': players,
        'lastActivity': DateTime.now().toIso8601String(),
      });
      
      print('✅ Rejoint room Firebase: $foundRoomId (code: $roomCode)');
      
    } catch (e) {
      print('❌ Erreur rejoindre room Firebase: $e');
      throw Exception('Erreur lors de la connexion à la room: $e');
    }
  }

  Future<void> leaveRoom() async {
    if (_currentRoomId == null || !_isInitialized) return;

    try {
      print('🚪 Quitter room Firebase: $_currentRoomId');
      
      final roomRef = _database!.ref('rooms/$_currentRoomId');
      final snapshot = await roomRef.get();
      
      if (!snapshot.exists) {
        _currentRoomId = null;
        if (_roomStateController != null && !_roomStateController!.isClosed) {
          _roomStateController!.add(null);
        }
        return;
      }
      
      final roomData = _convertToMap(snapshot.value);
      if (roomData == null) {
        print('❌ Erreur lecture room data pour leaveRoom');
        return;
      }
      
      final players = _convertToMap(roomData['players']) ?? {};
      
      if (players.containsKey(_currentPlayerId)) {
        final playerName = players[_currentPlayerId]['name'] ?? 'Joueur';
        
        // Envoyer un message système avant de quitter
        try {
          await _sendSystemMessage('$playerName a quitté la room');
        } catch (e) {
          print('⚠️ Erreur envoi message système: $e');
        }
        
        players.remove(_currentPlayerId);
        
        // Si c'était l'hôte qui partait
        if (roomData['hostId'] == _currentPlayerId) {
          if (players.isNotEmpty) {
            // Transférer l'hôte au premier joueur restant
            final newHostId = players.keys.first;
            players[newHostId]['isHost'] = true;
            await roomRef.update({
              'hostId': newHostId,
              'hostName': players[newHostId]['name'],
              'players': players,
              'lastActivity': DateTime.now().toIso8601String(),
            });
            
            // Envoyer un message système pour le nouveau hôte
            try {
              await _sendSystemMessage('${players[newHostId]['name']} est maintenant l\'hôte');
            } catch (e) {
              print('⚠️ Erreur envoi message système hôte: $e');
            }
          } else {
            // Supprimer la room si plus personne
            await roomRef.remove();
          }
        } else {
          await roomRef.update({
            'players': players,
            'lastActivity': DateTime.now().toIso8601String(),
          });
        }
      }
      
      _currentRoomId = null;
      _roomSubscription?.cancel();
      if (_roomStateController != null && !_roomStateController!.isClosed) {
        _roomStateController!.add(null);
      }
      
      print('✅ Quitté room Firebase');
      
    } catch (e) {
      print('❌ Erreur quitter room Firebase: $e');
    }
  }

  Future<void> toggleReady() async {
    if (_currentRoomId == null || !_isInitialized) return;

    try {
      final roomRef = _database!.ref('rooms/$_currentRoomId');
      final snapshot = await roomRef.get();
      
      if (!snapshot.exists) return;
      
      final roomData = _convertToMap(snapshot.value);
      if (roomData == null) {
        print('❌ Erreur lecture room data pour toggleReady');
        return;
      }
      
      final players = _convertToMap(roomData['players']) ?? {};
      
      if (players.containsKey(_currentPlayerId)) {
        final currentReady = players[_currentPlayerId]['isReady'] ?? false;
        players[_currentPlayerId]['isReady'] = !currentReady;
        
        await roomRef.update({
          'players': players,
          'lastActivity': DateTime.now().toIso8601String(),
        });
        
        print('✅ Statut prêt changé Firebase: ${!currentReady}');
      }
      
    } catch (e) {
      print('❌ Erreur toggle ready Firebase: $e');
    }
  }

  Future<void> startGame() async {
    if (_currentRoomId == null || !_isInitialized) return;

    try {
      final roomRef = _database!.ref('rooms/$_currentRoomId');
      final snapshot = await roomRef.get();
      
      if (!snapshot.exists) return;
      
      final roomData = _convertToMap(snapshot.value);
      if (roomData == null) {
        print('❌ Erreur lecture room data pour startGame');
        return;
      }
      
      // Vérifier que c'est l'hôte
      if (roomData['hostId'] != _currentPlayerId) {
        throw Exception('Seul l\'hôte peut démarrer le jeu');
      }
      
      await roomRef.update({
        'gameState': 'playing',
        'gameStartedAt': DateTime.now().toIso8601String(),
        'lastActivity': DateTime.now().toIso8601String(),
      });
      
      print('✅ Jeu démarré Firebase');
      
    } catch (e) {
      print('❌ Erreur démarrer jeu Firebase: $e');
      throw Exception('Erreur lors du démarrage du jeu: $e');
    }
  }

  Future<void> refreshRoomData() async {
    if (_currentRoomId == null || !_isInitialized) {
      print('⚠️ Aucune room active pour rafraîchissement');
      return;
    }

    try {
      print('🔄 Rafraîchissement forcé des données de la room: $_currentRoomId');
      
      final roomRef = _database!.ref('rooms/$_currentRoomId');
      final snapshot = await roomRef.get();
      
      if (snapshot.exists) {
        final rawData = snapshot.value;
        final roomData = _convertToMap(rawData);
        
        if (_roomStateController != null && !_roomStateController!.isClosed) {
          _roomStateController!.add(roomData);
          print('✅ Données room rafraîchies et envoyées au stream');
        }
      } else {
        print('⚠️ Room $_currentRoomId n\'existe plus');
        if (_roomStateController != null && !_roomStateController!.isClosed) {
          _roomStateController!.add(null);
        }
        _currentRoomId = null;
      }
      
    } catch (e) {
      print('❌ Erreur rafraîchissement room: $e');
    }
  }

  void _listenToRoom(String roomId) {
    print('👂 Démarrage écoute room: $roomId');
    _roomSubscription?.cancel();
    _roomSubscription = _database!.ref('rooms/$roomId').onValue.listen((event) {
      print('📡 Événement reçu pour room $roomId: ${event.snapshot.exists}');
      if (event.snapshot.exists) {
        try {
          final rawData = event.snapshot.value;
          final roomData = _convertToMap(rawData);
          print('📊 Données room reçues: ${roomData?['name']} - ${roomData?['players']?.length ?? 0} joueur(s)');
          
          if (_roomStateController != null && !_roomStateController!.isClosed) {
            _roomStateController!.add(roomData);
            print('✅ Données envoyées au stream controller');
          } else {
            print('⚠️ Stream controller fermé ou null');
          }
        } catch (e) {
          print('❌ Erreur conversion room data: $e');
          if (_roomStateController != null && !_roomStateController!.isClosed) {
            _roomStateController!.add(null);
          }
        }
      } else {
        print('📡 Room $roomId supprimée ou n\'existe plus');
        if (_roomStateController != null && !_roomStateController!.isClosed) {
          _roomStateController!.add(null);
        }
        _currentRoomId = null;
      }
    }, onError: (e) {
      print('❌ Erreur écoute room Firebase: $e');
      if (_roomStateController != null && !_roomStateController!.isClosed) {
        _roomStateController!.add(null);
      }
    });
  }

  void _loadAvailableRooms() {
    _availableRoomsSubscription?.cancel();
    _availableRoomsSubscription = _database!.ref('rooms').onValue.listen((event) {
      if (event.snapshot.exists) {
        try {
          final rawData = event.snapshot.value;
          final roomsData = _convertToMap(rawData);
          final rooms = <Map<String, dynamic>>[];
          
          if (roomsData != null && roomsData is Map) {
            roomsData.forEach((key, value) {
              try {
                final roomData = _convertToMap(value);
                if (roomData != null) {
                  roomData['id'] = key;
                  
                  // Ne montrer que les rooms en attente
                  if (roomData['gameState'] == 'waiting') {
                    rooms.add(roomData);
                  }
                }
              } catch (e) {
                print('❌ Erreur conversion room $key: $e');
              }
            });
          }
          
          if (_availableRoomsController != null && !_availableRoomsController!.isClosed) {
            _availableRoomsController!.add(rooms);
          }
        } catch (e) {
          print('❌ Erreur conversion rooms data: $e');
          if (_availableRoomsController != null && !_availableRoomsController!.isClosed) {
            _availableRoomsController!.add([]);
          }
        }
      } else {
        if (_availableRoomsController != null && !_availableRoomsController!.isClosed) {
          _availableRoomsController!.add([]);
        }
      }
    }, onError: (e) {
      print('❌ Erreur chargement rooms Firebase: $e');
      if (_availableRoomsController != null && !_availableRoomsController!.isClosed) {
        _availableRoomsController!.add([]);
      }
    });
  }

  String _generateAvatar() {
    final avatars = ['😀', '😎', '🤩', '🥳', '😇', '😈'];
    return avatars[Random().nextInt(avatars.length)];
  }

  Timer? _cleanupTimer;

  void _startPlayerCleanup() {
    // Nettoyer les joueurs inactifs toutes les 30 secondes
    _cleanupTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _cleanupInactivePlayers();
    });
  }

  Future<void> _cleanupInactivePlayers() async {
    if (!_isInitialized || _database == null) return;

    try {
      final roomsRef = _database!.ref('rooms');
      final snapshot = await roomsRef.get();
      
      if (!snapshot.exists) return;
      
      final roomsData = _convertToMap(snapshot.value);
      if (roomsData == null) return;
      
      final now = DateTime.now();
      final cutoffTime = now.subtract(const Duration(minutes: 5)); // 5 minutes d'inactivité
      
      for (final entry in roomsData.entries) {
        final roomId = entry.key;
        final roomData = _convertToMap(entry.value);
        
        if (roomData == null) continue;
        
        final players = _convertToMap(roomData['players']) ?? {};
        final playersToRemove = <String>[];
        
        for (final playerEntry in players.entries) {
          final playerId = playerEntry.key;
          final playerData = _convertToMap(playerEntry.value);
          
          if (playerData == null) continue;
          
          // Vérifier si le joueur est inactif depuis plus de 5 minutes
          final joinedAt = DateTime.tryParse(playerData['joinedAt'] ?? '');
          if (joinedAt != null && joinedAt.isBefore(cutoffTime)) {
            // Vérifier si le joueur n'est pas l'hôte actuel
            if (roomData['hostId'] != playerId) {
              playersToRemove.add(playerId);
            }
          }
        }
        
        // Supprimer les joueurs inactifs
        if (playersToRemove.isNotEmpty) {
          for (final playerId in playersToRemove) {
            players.remove(playerId);
            print('🧹 Joueur inactif supprimé: $playerId de la room $roomId');
          }
          
          // Mettre à jour la room
          await roomsRef.child(roomId).update({
            'players': players,
            'lastActivity': now.toIso8601String(),
          });
        }
      }
    } catch (e) {
      print('❌ Erreur nettoyage joueurs inactifs: $e');
    }
  }

  void dispose() {
    _cleanupTimer?.cancel();
    _roomSubscription?.cancel();
    _availableRoomsSubscription?.cancel();
    _roomStateController?.close();
    _availableRoomsController?.close();
  }

  /// Convertit les données Firebase en Map<String, dynamic> de manière sécurisée
  Map<String, dynamic>? _convertToMap(dynamic data) {
    if (data == null) return null;
    
    try {
      if (data is Map<String, dynamic>) {
        return data;
      } else if (data is Map) {
        // Conversion sécurisée pour les Maps minifiés
        final Map<String, dynamic> result = {};
        data.forEach((key, value) {
          if (key is String) {
            if (value is Map) {
              result[key] = _convertToMap(value);
            } else if (value is List) {
              result[key] = _convertToList(value);
            } else {
              result[key] = value;
            }
          }
        });
        return result;
      }
      return null;
    } catch (e) {
      print('❌ Erreur conversion Map: $e');
      return null;
    }
  }

  /// Convertit les listes Firebase de manière sécurisée
  List<dynamic>? _convertToList(dynamic data) {
    if (data == null) return null;
    
    try {
      if (data is List) {
        return data.map((item) {
          if (item is Map) {
            return _convertToMap(item);
          } else if (item is List) {
            return _convertToList(item);
          } else {
            return item;
          }
        }).toList();
      }
      return null;
    } catch (e) {
      print('❌ Erreur conversion List: $e');
      return null;
    }
  }

  /// Mettre à jour le nom du joueur actuel depuis PlayerNameService
  Future<void> updateCurrentPlayerName() async {
    try {
      await _playerNameService.initialize();
      final newName = _playerNameService.getPlayerNameOrDefault();
      
      if (newName != _currentPlayerName) {
        _currentPlayerName = newName;
        print('🔄 Nom du joueur mis à jour: $newName');
        
        // Mettre à jour le nom dans la room si on est dans une room
        if (_currentRoomId != null) {
          await updatePlayerName(newName);
        }
      }
    } catch (e) {
      print('❌ Erreur mise à jour nom joueur: $e');
    }
  }

  Future<void> updatePlayerName(String newName) async {
    if (!_isInitialized || _currentPlayerId == null) {
      throw Exception('Service non initialisé ou joueur non connecté');
    }

    try {
      _currentPlayerName = newName;
      
      // Synchroniser avec PlayerNameService
      await _playerNameService.setPlayerName(newName);
      
      // Mettre à jour le nom dans la room si on est dans une room
      if (_currentRoomId != null) {
        final roomRef = _database!.ref('rooms/$_currentRoomId');
        final snapshot = await roomRef.get();
        
        if (snapshot.exists) {
          final roomData = _convertToMap(snapshot.value);
          if (roomData != null) {
            final players = _convertToMap(roomData['players']) ?? {};
            
            if (players.containsKey(_currentPlayerId)) {
              players[_currentPlayerId]['name'] = newName;
              
              await roomRef.update({
                'players': players,
                'lastActivity': DateTime.now().toIso8601String(),
              });
              
              print('✅ Nom du joueur mis à jour: $newName');
            }
          }
        }
      }
      
    } catch (e) {
      print('❌ Erreur mise à jour nom joueur: $e');
      throw Exception('Erreur lors de la mise à jour du nom: $e');
    }
  }

  Future<void> sendMessage(String message) async {
    if (_currentRoomId == null || !_isInitialized) return;

    try {
      final messageData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'playerId': _currentPlayerId,
        'playerName': _currentPlayerName,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await _database!.ref('rooms/$_currentRoomId/messages').push().set(messageData);
      print('✅ Message envoyé: $message');
      
    } catch (e) {
      print('❌ Erreur envoi message: $e');
    }
  }

  /// Envoie un message système dans le chat de la room
  Future<void> _sendSystemMessage(String message) async {
    if (_currentRoomId == null || !_isInitialized) return;

    try {
      final messageData = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'playerId': 'system',
        'playerName': 'Système',
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
        'isSystemMessage': true,
      };

      await _database!.ref('rooms/$_currentRoomId/chat').push().set(messageData);
      print('✅ Message système envoyé: $message');
      
    } catch (e) {
      print('❌ Erreur envoi message système: $e');
    }
  }
}
