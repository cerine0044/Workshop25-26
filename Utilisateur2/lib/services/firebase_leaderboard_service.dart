import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class LeaderboardEntry {
  final String playerId;
  final String playerName;
  final int totalSessions;
  final int completedSessions;
  final double averageScore;
  final Duration bestTime;
  final DateTime lastPlayed;
  final bool isOnline;
  final String gameMode; // 'solo' ou 'multiplayer'

  LeaderboardEntry({
    required this.playerId,
    required this.playerName,
    required this.totalSessions,
    required this.completedSessions,
    required this.averageScore,
    required this.bestTime,
    required this.lastPlayed,
    required this.isOnline,
    this.gameMode = 'solo',
  });

  factory LeaderboardEntry.fromMap(Map<String, dynamic> data, String playerId) {
    return LeaderboardEntry(
      playerId: playerId,
      playerName: data['playerName'] ?? 'Joueur',
      totalSessions: data['totalSessions'] ?? 0,
      completedSessions: data['completedSessions'] ?? 0,
      averageScore: (data['averageScore'] ?? 0.0).toDouble(),
      bestTime: Duration(milliseconds: data['bestTime'] ?? 0),
      lastPlayed: DateTime.fromMillisecondsSinceEpoch(data['lastPlayed'] ?? 0),
      isOnline: data['isOnline'] ?? false,
      gameMode: data['gameMode'] ?? 'solo',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playerName': playerName,
      'totalSessions': totalSessions,
      'completedSessions': completedSessions,
      'averageScore': averageScore,
      'bestTime': bestTime.inMilliseconds,
      'lastPlayed': lastPlayed.millisecondsSinceEpoch,
      'isOnline': isOnline,
      'gameMode': gameMode,
    };
  }

  double get successRate => totalSessions > 0 ? completedSessions / totalSessions : 0.0;
}

class FirebaseLeaderboardService {
  static final FirebaseLeaderboardService _instance = FirebaseLeaderboardService._internal();
  factory FirebaseLeaderboardService() => _instance;
  FirebaseLeaderboardService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _leaderboardSubscription;
  final StreamController<List<LeaderboardEntry>> _leaderboardController = StreamController<List<LeaderboardEntry>>.broadcast();
  
  String? _currentPlayerId;
  
  /// Initialise le service de classement
  Future<void> initialize({String? currentPlayerId}) async {
    try {
      _currentPlayerId = currentPlayerId;
      await _listenToLeaderboard();
      
      if (kDebugMode) {
        print('🏆 Service de classement initialisé');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur initialisation classement: $e');
      }
      rethrow;
    }
  }

  /// Écoute les mises à jour du classement en temps réel
  Future<void> _listenToLeaderboard() async {
    try {
      _leaderboardSubscription?.cancel();
      
      _leaderboardSubscription = _database
          .child('leaderboard')
          .orderByChild('averageScore')
          .onValue
          .listen((event) {
        if (event.snapshot.exists) {
          final Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          final List<LeaderboardEntry> entries = [];
          
          data.forEach((key, value) {
            if (value is Map) {
              entries.add(LeaderboardEntry.fromMap(Map<String, dynamic>.from(value), key));
            }
          });
          
          // Trier par score moyen décroissant, puis par taux de réussite
          entries.sort((a, b) {
            if (a.averageScore != b.averageScore) {
              return b.averageScore.compareTo(a.averageScore);
            }
            return b.successRate.compareTo(a.successRate);
          });
          
          _leaderboardController.add(entries);
        } else {
          _leaderboardController.add([]);
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur écoute classement: $e');
      }
      rethrow;
    }
  }

  /// Met à jour les statistiques d'un joueur dans le classement
  Future<void> updatePlayerStats({
    required String playerId,
    required String playerName,
    required int totalSessions,
    required int completedSessions,
    required double averageScore,
    required Duration bestTime,
    required bool isOnline,
    String gameMode = 'solo',
  }) async {
    try {
      final entry = LeaderboardEntry(
        playerId: playerId,
        playerName: playerName,
        totalSessions: totalSessions,
        completedSessions: completedSessions,
        averageScore: averageScore,
        bestTime: bestTime,
        lastPlayed: DateTime.now(),
        isOnline: isOnline,
        gameMode: gameMode,
      );

      await _database
          .child('leaderboard')
          .child(playerId)
          .set(entry.toMap());

      if (kDebugMode) {
        print('🏆 Statistiques joueur mises à jour: $playerName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur mise à jour stats joueur: $e');
      }
      rethrow;
    }
  }

  /// Met à jour le statut en ligne d'un joueur
  Future<void> updatePlayerOnlineStatus(String playerId, bool isOnline) async {
    try {
      await _database
          .child('leaderboard')
          .child(playerId)
          .child('isOnline')
          .set(isOnline);

      if (kDebugMode) {
        print('🟢 Statut en ligne mis à jour: $playerId = $isOnline');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur mise à jour statut en ligne: $e');
      }
    }
  }

  /// Obtient les statistiques d'un joueur spécifique
  Future<LeaderboardEntry?> getPlayerStats(String playerId) async {
    try {
      final snapshot = await _database
          .child('leaderboard')
          .child(playerId)
          .once();

      if (snapshot.snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
        return LeaderboardEntry.fromMap(data, playerId);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération stats joueur: $e');
      }
      return null;
    }
  }

  /// Obtient le classement des meilleurs joueurs
  Future<List<LeaderboardEntry>> getTopPlayers({int limit = 10}) async {
    try {
      final snapshot = await _database
          .child('leaderboard')
          .orderByChild('averageScore')
          .limitToLast(limit)
          .once();

      if (snapshot.snapshot.exists) {
        final Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
        final List<LeaderboardEntry> entries = [];
        
        data.forEach((key, value) {
          if (value is Map) {
            entries.add(LeaderboardEntry.fromMap(Map<String, dynamic>.from(value), key));
          }
        });
        
        // Trier par score moyen décroissant
        entries.sort((a, b) => b.averageScore.compareTo(a.averageScore));
        return entries;
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération top joueurs: $e');
      }
      return [];
    }
  }

  /// Stream du classement en temps réel
  Stream<List<LeaderboardEntry>> get leaderboardStream => _leaderboardController.stream;

  /// Nettoie les anciennes entrées (garde seulement les joueurs actifs)
  Future<void> cleanupInactivePlayers({Duration maxInactivity = const Duration(days: 30)}) async {
    try {
      final snapshot = await _database
          .child('leaderboard')
          .once();

      if (snapshot.snapshot.exists) {
        final Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
        final DateTime cutoff = DateTime.now().subtract(maxInactivity);
        
        for (final entry in data.entries) {
          final playerData = Map<String, dynamic>.from(entry.value as Map);
          final lastPlayed = DateTime.fromMillisecondsSinceEpoch(playerData['lastPlayed'] ?? 0);
          
          if (lastPlayed.isBefore(cutoff)) {
            await _database
                .child('leaderboard')
                .child(entry.key)
                .remove();
            
            if (kDebugMode) {
              print('🧹 Joueur inactif supprimé: ${playerData['playerName']}');
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur nettoyage joueurs inactifs: $e');
      }
    }
  }

  /// Ferme le service et nettoie les ressources
  Future<void> dispose() async {
    await _leaderboardSubscription?.cancel();
    await _leaderboardController.close();
    _currentPlayerId = null;
    
    if (kDebugMode) {
      print('🏆 Service de classement fermé');
    }
  }

  /// Obtient les informations du service
  Map<String, String?> get serviceInfo => {
    'currentPlayerId': _currentPlayerId,
  };
}
