import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class GameSessionHistory {
  final String sessionId;
  final String playerName;
  final String gameRoom;
  final String gameMode; // 'solo' ou 'multiplayer'
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final bool completed;
  final int? score;
  final Map<String, dynamic> additionalData;

  GameSessionHistory({
    required this.sessionId,
    required this.playerName,
    required this.gameRoom,
    this.gameMode = 'solo',
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.completed,
    this.score,
    this.additionalData = const {},
  });

  factory GameSessionHistory.fromMap(Map<String, dynamic> data, String id) {
    return GameSessionHistory(
      sessionId: id,
      playerName: data['playerName'] ?? 'Inconnu',
      gameRoom: data['gameRoom'] ?? 'N/A',
      gameMode: data['gameMode'] ?? 'solo',
      startTime: DateTime.fromMillisecondsSinceEpoch(data['startTime'] ?? 0),
      endTime: DateTime.fromMillisecondsSinceEpoch(data['endTime'] ?? 0),
      duration: Duration(milliseconds: data['duration'] ?? 0),
      completed: data['completed'] ?? false,
      score: data['score'],
      additionalData: Map<String, dynamic>.from(data['additionalData'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playerName': playerName,
      'gameRoom': gameRoom,
      'gameMode': gameMode,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'duration': duration.inMilliseconds,
      'completed': completed,
      'score': score,
      'additionalData': additionalData,
    };
  }
}

class FirebaseHistoryService {
  static final FirebaseHistoryService _instance = FirebaseHistoryService._internal();
  factory FirebaseHistoryService() => _instance;
  FirebaseHistoryService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _historySubscription;
  final StreamController<List<GameSessionHistory>> _historyController = StreamController<List<GameSessionHistory>>.broadcast();

  /// Initialise le service d'historique
  Future<void> initialize() async {
    try {
      await _listenToGameSessions();
      if (kDebugMode) {
        print('📚 Service d\'historique initialisé');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur initialisation historique: $e');
      }
      rethrow;
    }
  }

  /// Écoute les sessions de jeu en temps réel
  Future<void> _listenToGameSessions() async {
    try {
      _historySubscription?.cancel();

      _historySubscription = _database
          .child('gameSessions')
          .orderByChild('endTime')
          .limitToLast(100) // Limite pour éviter de charger trop de données
          .onValue
          .listen((event) {
        if (event.snapshot.exists) {
          final Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          final List<GameSessionHistory> sessions = [];

          data.forEach((key, value) {
            if (value is Map) {
              sessions.add(GameSessionHistory.fromMap(Map<String, dynamic>.from(value), key));
            }
          });

          // Trier par endTime décroissant (plus récent en premier)
          sessions.sort((a, b) => b.endTime.compareTo(a.endTime));

          _historyController.add(sessions);
        } else {
          _historyController.add([]);
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur écoute sessions historique: $e');
      }
      rethrow;
    }
  }

  /// Sauvegarde une session de jeu dans l'historique
  Future<void> saveGameSession(GameSessionHistory session) async {
    try {
      await _database
          .child('gameSessions')
          .child(session.sessionId)
          .set(session.toMap());

      if (kDebugMode) {
        print('💾 Session de jeu sauvegardée: ${session.playerName} - ${session.gameRoom}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur sauvegarde session de jeu: $e');
      }
      rethrow;
    }
  }

  /// Stream des sessions de jeu
  Stream<List<GameSessionHistory>> get historyStream => _historyController.stream;

  /// Obtient les sessions récentes
  Future<List<GameSessionHistory>> getRecentSessions({int limit = 50}) async {
    try {
      final snapshot = await _database
          .child('gameSessions')
          .orderByChild('endTime')
          .limitToLast(limit)
          .once();

      if (snapshot.snapshot.exists) {
        final Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
        final List<GameSessionHistory> sessions = [];

        data.forEach((key, value) {
          if (value is Map) {
            sessions.add(GameSessionHistory.fromMap(Map<String, dynamic>.from(value), key));
          }
        });

        // Trier par endTime décroissant
        sessions.sort((a, b) => b.endTime.compareTo(a.endTime));
        return sessions;
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur récupération sessions récentes: $e');
      }
      return [];
    }
  }

  /// Nettoie les anciennes sessions (garde seulement les dernières)
  Future<void> cleanupOldSessions({int maxSessions = 100}) async {
    try {
      final snapshot = await _database
          .child('gameSessions')
          .orderByChild('endTime')
          .once();

      if (snapshot.snapshot.exists) {
        final Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
        final List<MapEntry<String, dynamic>> sortedSessions = [];

        data.forEach((key, value) {
          if (value is Map) {
            sortedSessions.add(MapEntry(key, value));
          }
        });

        // Trier par endTime
        sortedSessions.sort((a, b) {
          final timestampA = a.value['endTime'] ?? 0;
          final timestampB = b.value['endTime'] ?? 0;
          return timestampA.compareTo(timestampB);
        });

        // Supprimer les anciennes sessions si on dépasse la limite
        if (sortedSessions.length > maxSessions) {
          final sessionsToDelete = sortedSessions.take(sortedSessions.length - maxSessions);

          for (final session in sessionsToDelete) {
            await _database
                .child('gameSessions')
                .child(session.key)
                .remove();
          }

          if (kDebugMode) {
            print('🧹 ${sessionsToDelete.length} anciennes sessions supprimées de l\'historique');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur nettoyage sessions historique: $e');
      }
    }
  }

  /// Ferme le service et nettoie les ressources
  Future<void> dispose() async {
    await _historySubscription?.cancel();
    await _historyController.close();
    if (kDebugMode) {
      print('📚 Service d\'historique fermé');
    }
  }
}
