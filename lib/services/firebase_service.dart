import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_options.dart';
import 'local_game_service.dart';

class FirebaseService {
  static FirebaseDatabase? _database;
  static FirebaseAuth? _auth;
  static bool _isInitialized = false;
  static bool _useLocalService = false; // Mode Firebase réel pour multijoueur
  static final LocalGameService _localService = LocalGameService();
  
  // Initialiser Firebase
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    if (_useLocalService) {
      await _localService.initialize();
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _database = FirebaseDatabase.instance;
      _auth = FirebaseAuth.instance;
    }
    _isInitialized = true;
  }
  
  // Obtenir l'instance de la base de données
  static FirebaseDatabase get database {
    if (_database == null) {
      throw Exception('Firebase n\'est pas initialisé. Appelez initialize() d\'abord.');
    }
    return _database!;
  }
  
  // Obtenir l'instance d'authentification
  static FirebaseAuth get auth {
    if (_auth == null) {
      throw Exception('Firebase n\'est pas initialisé. Appelez initialize() d\'abord.');
    }
    return _auth!;
  }
  
  // Créer une room de jeu
  static Future<String> createGameRoom(String roomName) async {
    if (_useLocalService) {
      return await _localService.createGameRoom(roomName);
    }
    
    final user = _auth!.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }
    
    final roomId = DateTime.now().millisecondsSinceEpoch.toString();
    final roomData = {
      'id': roomId,
      'name': roomName,
      'host': user.uid,
      'hostName': user.displayName ?? 'Joueur',
      'players': {
        user.uid: {
          'name': user.displayName ?? 'Joueur',
          'isHost': true,
          'isReady': false,
          'joinedAt': DateTime.now().toIso8601String(),
        }
      },
      'gameState': 'waiting',
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    await _database!.ref('rooms/$roomId').set(roomData);
    return roomId;
  }
  
  // Rejoindre une room existante
  static Future<void> joinGameRoom(String roomId) async {
    if (_useLocalService) {
      return await _localService.joinGameRoom(roomId);
    }
    
    final user = _auth!.currentUser;
    if (user == null) {
      throw Exception('Utilisateur non connecté');
    }
    
    final roomRef = _database!.ref('rooms/$roomId');
    final snapshot = await roomRef.get();
    
    if (!snapshot.exists) {
      throw Exception('Room introuvable');
    }
    
    final roomData = Map<String, dynamic>.from(snapshot.value as Map);
    final players = Map<String, dynamic>.from(roomData['players'] ?? {});
    
    // Vérifier si le joueur n'est pas déjà dans la room
    if (players.containsKey(user.uid)) {
      return; // Déjà dans la room
    }
    
    // Ajouter le joueur à la room
    players[user.uid] = {
      'name': user.displayName ?? 'Joueur',
      'isHost': false,
      'isReady': false,
      'joinedAt': DateTime.now().toIso8601String(),
    };
    
    await roomRef.update({'players': players});
  }
  
  // Quitter une room
  static Future<void> leaveGameRoom(String roomId) async {
    if (_useLocalService) {
      return await _localService.leaveGameRoom(roomId);
    }
    
    final user = _auth!.currentUser;
    if (user == null) return;
    
    final roomRef = _database!.ref('rooms/$roomId');
    final snapshot = await roomRef.get();
    
    if (!snapshot.exists) return;
    
    final roomData = Map<String, dynamic>.from(snapshot.value as Map);
    final players = Map<String, dynamic>.from(roomData['players'] ?? {});
    
    if (players.containsKey(user.uid)) {
      players.remove(user.uid);
      
      // Si c'était l'hôte qui partait, transférer l'hôte ou supprimer la room
      if (roomData['host'] == user.uid) {
        if (players.isNotEmpty) {
          // Transférer l'hôte au premier joueur restant
          final newHostId = players.keys.first;
          players[newHostId]['isHost'] = true;
          await roomRef.update({
            'host': newHostId,
            'players': players,
          });
        } else {
          // Supprimer la room si plus personne
          await roomRef.remove();
        }
      } else {
        await roomRef.update({'players': players});
      }
    }
  }
  
  // Écouter les changements d'une room
  static Stream<Map<String, dynamic>?> listenToRoom(String roomId) {
    if (_useLocalService) {
      return _localService.listenToRoom(roomId);
    }
    
    return _database!.ref('rooms/$roomId').onValue.map((event) {
      if (event.snapshot.exists) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return null;
    });
  }
  
  // Mettre à jour l'état de préparation d'un joueur
  static Future<void> updatePlayerReady(String roomId, bool isReady) async {
    if (_useLocalService) {
      return await _localService.updatePlayerReady(roomId, isReady);
    }
    
    final user = _auth!.currentUser;
    if (user == null) return;
    
    await _database!.ref('rooms/$roomId/players/$user.uid/isReady').set(isReady);
  }
  
  // Mettre à jour l'état du jeu
  static Future<void> updateGameState(String roomId, String gameState, {Map<String, dynamic>? gameData}) async {
    if (_useLocalService) {
      return await _localService.updateGameState(roomId, gameState, gameData: gameData);
    }
    
    final updates = <String, dynamic>{
      'gameState': gameState,
      'lastUpdated': DateTime.now().toIso8601String(),
    };
    
    if (gameData != null) {
      updates['gameData'] = gameData;
    }
    
    await _database!.ref('rooms/$roomId').update(updates);
  }
  
  // Obtenir la liste des rooms disponibles
  static Stream<List<Map<String, dynamic>>> getAvailableRooms() {
    if (_useLocalService) {
      return _localService.getAvailableRooms();
    }
    
    return _database!.ref('rooms').onValue.map((event) {
      if (event.snapshot.exists) {
        final roomsData = event.snapshot.value as Map;
        return roomsData.entries.map((entry) {
          final roomData = Map<String, dynamic>.from(entry.value as Map);
          roomData['id'] = entry.key;
          return roomData;
        }).where((room) => room['gameState'] == 'waiting').toList();
      }
      return <Map<String, dynamic>>[];
    });
  }
  
  // Connexion anonyme pour le jeu
  static Future<void> signInAnonymously() async {
    if (_useLocalService) {
      return await _localService.signInAnonymously();
    }
    
    await _auth!.signInAnonymously();
  }
  
  // Déconnexion
  static Future<void> signOut() async {
    if (_useLocalService) {
      return await _localService.signOut();
    }
    
    await _auth!.signOut();
  }
}
