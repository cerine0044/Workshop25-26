import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'player_name_service.dart';

/// Service de persistance pour synchroniser les données entre services
class PlayerPersistenceService {
  static final PlayerPersistenceService _instance = PlayerPersistenceService._internal();
  factory PlayerPersistenceService() => _instance;
  PlayerPersistenceService._internal();

  DatabaseReference? _database;
  FirebaseAuth? _auth;
  bool _isInitialized = false;

  /// Initialiser le service de persistance
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _database = FirebaseDatabase.instance.ref();
      _auth = FirebaseAuth.instance;
      _isInitialized = true;
      
      debugPrint('✅ PlayerPersistenceService initialisé');
    } catch (e) {
      debugPrint('❌ Erreur initialisation PlayerPersistenceService: $e');
    }
  }

  /// Sauvegarder les données du joueur sur Firebase
  Future<void> savePlayerData({
    required String playerId,
    required String playerName,
    Map<String, dynamic>? additionalData,
  }) async {
    if (!_isInitialized || _database == null) return;

    try {
      final playerData = {
        'name': playerName,
        'lastUpdated': DateTime.now().toIso8601String(),
        'platform': 'web',
        'version': '1.0',
        ...?additionalData,
      };

      await _database!.child('players/$playerId').set(playerData);
      debugPrint('✅ Données joueur sauvegardées: $playerName');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde données joueur: $e');
    }
  }

  /// Charger les données du joueur depuis Firebase
  Future<Map<String, dynamic>?> loadPlayerData(String playerId) async {
    if (!_isInitialized || _database == null) return null;

    try {
      final snapshot = await _database!.child('players/$playerId').get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          debugPrint('✅ Données joueur chargées: ${data['name']}');
          return Map<String, dynamic>.from(data);
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement données joueur: $e');
    }
    
    return null;
  }

  /// Synchroniser les données du joueur entre services
  Future<void> syncPlayerData() async {
    try {
      final playerNameService = PlayerNameService();
      await playerNameService.initialize();
      
      final playerId = playerNameService.currentPlayerId;
      final playerName = playerNameService.currentPlayerName;
      
      if (playerId != null && playerName != null) {
        await savePlayerData(
          playerId: playerId,
          playerName: playerName,
          additionalData: {
            'lastSync': DateTime.now().toIso8601String(),
          },
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur synchronisation données joueur: $e');
    }
  }

  /// Restaurer les données du joueur depuis Firebase
  Future<bool> restorePlayerData() async {
    try {
      final playerNameService = PlayerNameService();
      await playerNameService.initialize();
      
      final playerId = playerNameService.currentPlayerId;
      if (playerId == null) return false;
      
      final playerData = await loadPlayerData(playerId);
      if (playerData != null) {
        final playerName = playerData['name'] as String?;
        if (playerName != null && playerName.isNotEmpty) {
          await playerNameService.setPlayerName(playerName);
          debugPrint('✅ Données joueur restaurées: $playerName');
          return true;
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur restauration données joueur: $e');
    }
    
    return false;
  }

  /// Nettoyer les données obsolètes
  Future<void> cleanupOldData() async {
    if (!_isInitialized || _database == null) return;

    try {
      final cutoffTime = DateTime.now().subtract(const Duration(days: 30));
      final snapshot = await _database!.child('players').get();
      
      if (snapshot.exists) {
        final players = snapshot.value as Map<dynamic, dynamic>?;
        if (players != null) {
          for (final entry in players.entries) {
            final playerId = entry.key;
            final playerData = entry.value as Map<dynamic, dynamic>?;
            
            if (playerData != null) {
              final lastUpdated = DateTime.tryParse(playerData['lastUpdated'] ?? '');
              if (lastUpdated != null && lastUpdated.isBefore(cutoffTime)) {
                await _database!.child('players/$playerId').remove();
                debugPrint('🗑️ Données obsolètes supprimées: $playerId');
              }
            }
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur nettoyage données: $e');
    }
  }

  /// Obtenir les statistiques de persistance
  Future<Map<String, dynamic>> getPersistenceStats() async {
    if (!_isInitialized || _database == null) {
      return {'error': 'Service non initialisé'};
    }

    try {
      final snapshot = await _database!.child('players').get();
      int totalPlayers = 0;
      int activePlayers = 0;
      final now = DateTime.now();
      final weekAgo = now.subtract(const Duration(days: 7));

      if (snapshot.exists) {
        final players = snapshot.value as Map<dynamic, dynamic>?;
        if (players != null) {
          totalPlayers = players.length;
          
          for (final playerData in players.values) {
            if (playerData is Map<dynamic, dynamic>) {
              final lastUpdated = DateTime.tryParse(playerData['lastUpdated'] ?? '');
              if (lastUpdated != null && lastUpdated.isAfter(weekAgo)) {
                activePlayers++;
              }
            }
          }
        }
      }

      return {
        'totalPlayers': totalPlayers,
        'activePlayers': activePlayers,
        'lastSync': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      debugPrint('❌ Erreur statistiques persistance: $e');
      return {'error': e.toString()};
    }
  }
}
