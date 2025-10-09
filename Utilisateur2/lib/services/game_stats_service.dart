import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service de gestion des statistiques de jeu et du chronomètre
class GameStatsService {
  static final GameStatsService _instance = GameStatsService._internal();
  factory GameStatsService() => _instance;
  GameStatsService._internal();

  // Contrôleurs de chronomètre
  Timer? _timer;
  DateTime? _gameStartTime;
  Duration _currentGameDuration = Duration.zero;
  
  // Statistiques de session
  String? _currentPlayerName;
  String? _currentGameRoom;
  List<GameSession> _completedSessions = [];
  
  // Callbacks pour les mises à jour
  final List<VoidCallback> _durationListeners = [];
  final List<VoidCallback> _statsListeners = [];

  /// Démarre le chronomètre pour une nouvelle session de jeu
  void startGameSession({
    required String playerName,
    required String gameRoom,
  }) {
    _currentPlayerName = playerName;
    _currentGameRoom = gameRoom;
    _gameStartTime = DateTime.now();
    _currentGameDuration = Duration.zero;
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_gameStartTime != null) {
        _currentGameDuration = DateTime.now().difference(_gameStartTime!);
        _notifyDurationListeners();
      }
    });
    
    debugPrint('🎮 Session démarrée: $playerName dans $gameRoom');
  }

  /// Termine la session de jeu et sauvegarde les statistiques
  Future<void> endGameSession({
    bool completed = true,
    int? score,
    Map<String, dynamic>? additionalData,
  }) async {
    if (_gameStartTime == null || _currentPlayerName == null || _currentGameRoom == null) {
      debugPrint('⚠️ Aucune session active à terminer');
      return;
    }

    _timer?.cancel();
    _timer = null;

    final session = GameSession(
      playerName: _currentPlayerName!,
      gameRoom: _currentGameRoom!,
      startTime: _gameStartTime!,
      endTime: DateTime.now(),
      duration: _currentGameDuration,
      completed: completed,
      score: score,
      additionalData: additionalData ?? {},
    );

    _completedSessions.add(session);
    await _saveStatsToStorage();
    
    debugPrint('🏁 Session terminée: ${session.duration.inSeconds}s - Score: ${score ?? "N/A"}');
    
    // Reset pour la prochaine session
    _gameStartTime = null;
    _currentGameDuration = Duration.zero;
    _currentPlayerName = null;
    _currentGameRoom = null;
    
    _notifyStatsListeners();
  }

  /// Obtient la durée actuelle de la session
  Duration get currentDuration => _currentGameDuration;

  /// Obtient le nom du joueur actuel
  String? get currentPlayerName => _currentPlayerName;

  /// Obtient la salle de jeu actuelle
  String? get currentGameRoom => _currentGameRoom;

  /// Vérifie si une session est active
  bool get isSessionActive => _gameStartTime != null;

  /// Obtient toutes les sessions complétées
  List<GameSession> get completedSessions => List.unmodifiable(_completedSessions);

  /// Obtient les statistiques agrégées
  GameStats getStats() {
    if (_completedSessions.isEmpty) {
      return GameStats.empty();
    }

    final totalSessions = _completedSessions.length;
    final completedSessions = _completedSessions.where((s) => s.completed).length;
    final totalDuration = _completedSessions.fold<Duration>(
      Duration.zero,
      (sum, session) => sum + session.duration,
    );
    final averageDuration = Duration(
      milliseconds: totalDuration.inMilliseconds ~/ totalSessions,
    );

    // Statistiques par salle
    final roomStats = <String, RoomStats>{};
    for (final session in _completedSessions) {
      roomStats[session.gameRoom] ??= RoomStats(
        roomName: session.gameRoom,
        totalSessions: 0,
        completedSessions: 0,
        totalDuration: Duration.zero,
        bestTime: null,
        averageScore: 0,
      );
      
      final stats = roomStats[session.gameRoom]!;
      roomStats[session.gameRoom] = RoomStats(
        roomName: session.gameRoom,
        totalSessions: stats.totalSessions + 1,
        completedSessions: stats.completedSessions + (session.completed ? 1 : 0),
        totalDuration: stats.totalDuration + session.duration,
        bestTime: stats.bestTime == null || session.duration < stats.bestTime!
            ? session.duration
            : stats.bestTime,
        averageScore: session.score != null 
            ? (stats.averageScore * stats.totalSessions + session.score!) / (stats.totalSessions + 1)
            : stats.averageScore,
      );
    }

    return GameStats(
      totalSessions: totalSessions,
      completedSessions: completedSessions,
      totalPlayTime: totalDuration,
      averageSessionTime: averageDuration,
      roomStats: roomStats.values.toList(),
      lastPlayed: _completedSessions.isNotEmpty 
          ? _completedSessions.last.endTime 
          : null,
    );
  }

  /// Sauvegarde les statistiques dans le stockage local
  Future<void> _saveStatsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = _completedSessions.map((s) => s.toJson()).toList();
      await prefs.setString('game_sessions', jsonEncode(sessionsJson));
      debugPrint('💾 Statistiques sauvegardées: ${_completedSessions.length} sessions');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde stats: $e');
    }
  }

  /// Charge les statistiques depuis le stockage local
  Future<void> loadStatsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionsJson = prefs.getString('game_sessions');
      
      if (sessionsJson != null) {
        final sessionsList = jsonDecode(sessionsJson) as List;
        _completedSessions = sessionsList
            .map((json) => GameSession.fromJson(json))
            .toList();
        debugPrint('📊 Statistiques chargées: ${_completedSessions.length} sessions');
        _notifyStatsListeners();
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement stats: $e');
    }
  }

  /// Efface toutes les statistiques
  Future<void> clearAllStats() async {
    _completedSessions.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('game_sessions');
    _notifyStatsListeners();
    debugPrint('🗑️ Toutes les statistiques ont été effacées');
  }

  /// Ajoute un listener pour les mises à jour de durée
  void addDurationListener(VoidCallback listener) {
    _durationListeners.add(listener);
  }

  /// Supprime un listener de durée
  void removeDurationListener(VoidCallback listener) {
    _durationListeners.remove(listener);
  }

  /// Ajoute un listener pour les mises à jour de statistiques
  void addStatsListener(VoidCallback listener) {
    _statsListeners.add(listener);
  }

  /// Supprime un listener de statistiques
  void removeStatsListener(VoidCallback listener) {
    _statsListeners.remove(listener);
  }

  /// Notifie tous les listeners de durée
  void _notifyDurationListeners() {
    for (final listener in _durationListeners) {
      listener();
    }
  }

  /// Notifie tous les listeners de statistiques
  void _notifyStatsListeners() {
    for (final listener in _statsListeners) {
      listener();
    }
  }

  /// Libère les ressources
  void dispose() {
    _timer?.cancel();
    _durationListeners.clear();
    _statsListeners.clear();
  }
}

/// Représente une session de jeu
class GameSession {
  final String playerName;
  final String gameRoom;
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final bool completed;
  final int? score;
  final Map<String, dynamic> additionalData;

  GameSession({
    required this.playerName,
    required this.gameRoom,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.completed,
    this.score,
    required this.additionalData,
  });

  Map<String, dynamic> toJson() {
    return {
      'playerName': playerName,
      'gameRoom': gameRoom,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'duration': duration.inMilliseconds,
      'completed': completed,
      'score': score,
      'additionalData': additionalData,
    };
  }

  factory GameSession.fromJson(Map<String, dynamic> json) {
    return GameSession(
      playerName: json['playerName'],
      gameRoom: json['gameRoom'],
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      duration: Duration(milliseconds: json['duration']),
      completed: json['completed'],
      score: json['score'],
      additionalData: Map<String, dynamic>.from(json['additionalData'] ?? {}),
    );
  }
}

/// Statistiques agrégées des jeux
class GameStats {
  final int totalSessions;
  final int completedSessions;
  final Duration totalPlayTime;
  final Duration averageSessionTime;
  final List<RoomStats> roomStats;
  final DateTime? lastPlayed;

  GameStats({
    required this.totalSessions,
    required this.completedSessions,
    required this.totalPlayTime,
    required this.averageSessionTime,
    required this.roomStats,
    this.lastPlayed,
  });

  factory GameStats.empty() {
    return GameStats(
      totalSessions: 0,
      completedSessions: 0,
      totalPlayTime: Duration.zero,
      averageSessionTime: Duration.zero,
      roomStats: [],
      lastPlayed: null,
    );
  }

  double get completionRate => totalSessions > 0 ? completedSessions / totalSessions : 0.0;
}

/// Statistiques par salle de jeu
class RoomStats {
  final String roomName;
  final int totalSessions;
  final int completedSessions;
  final Duration totalDuration;
  final Duration? bestTime;
  final double averageScore;

  RoomStats({
    required this.roomName,
    required this.totalSessions,
    required this.completedSessions,
    required this.totalDuration,
    this.bestTime,
    required this.averageScore,
  });

  double get completionRate => totalSessions > 0 ? completedSessions / totalSessions : 0.0;
  Duration get averageDuration => Duration(
    milliseconds: totalDuration.inMilliseconds ~/ totalSessions,
  );
}
