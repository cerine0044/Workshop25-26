import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_leaderboard_service.dart';
import 'firebase_history_service.dart';
import 'player_name_service.dart';

/// Service de gestion des statistiques de jeu et du chronomètre
class GameStatsService {
  static final GameStatsService _instance = GameStatsService._internal();
  factory GameStatsService() => _instance;

  // Contrôleurs de chronomètre
  int _sessionCounter = 0;
  Timer? _timer;
  DateTime? _gameStartTime;
  Duration _currentGameDuration = Duration.zero;
  
  // Temps global de bout en bout
  DateTime? _globalGameStartTime;
  Duration _globalGameDuration = Duration.zero;
  bool _isGlobalSessionActive = false;
  
  // Statistiques de session
  String? _currentPlayerName;
  String? _currentGameRoom;
  String? _currentGameMode; // 'solo' ou 'multiplayer'
  List<GameSession> _completedSessions = [];
  
  // Callbacks pour les mises à jour
  final List<VoidCallback> _durationListeners = [];
  final List<VoidCallback> _statsListeners = [];
  
  // Service de classement et historique
  final FirebaseLeaderboardService _leaderboardService = FirebaseLeaderboardService();
  final FirebaseHistoryService _historyService = FirebaseHistoryService();
  final PlayerNameService _playerNameService = PlayerNameService();

  /// Constructeur privé avec initialisation
  GameStatsService._internal() {
    // Initialisation immédiate des services
    _initializeServicesSync();
  }

  /// Initialise les services Firebase de manière synchrone
  void _initializeServicesSync() {
    debugPrint('🔧 Initialisation synchrone des services Firebase...');
    // L'initialisation sera faite lors du premier appel
    debugPrint('✅ Services Firebase prêts pour l\'initialisation');
  }

  /// Initialise les services Firebase
  Future<void> _initializeServices() async {
    try {
      debugPrint('🔧 Initialisation des services Firebase...');
      await _leaderboardService.initialize();
      debugPrint('✅ Service de classement initialisé');
      await _historyService.initialize();
      debugPrint('✅ Service d\'historique initialisé');
      debugPrint('🔧 Services Firebase initialisés avec succès');
    } catch (e) {
      debugPrint('❌ Erreur initialisation services: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
    }
  }

  /// Démarre le chronomètre global de bout en bout
  void startGlobalGameSession({
    String? playerName,
    String gameMode = 'solo',
  }) {
    if (!_isGlobalSessionActive) {
      _currentPlayerName = playerName ?? _playerNameService.getPlayerNameOrDefault();
      _currentGameMode = gameMode;
      _globalGameStartTime = DateTime.now();
      _globalGameDuration = Duration.zero;
      _isGlobalSessionActive = true;
      
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_globalGameStartTime != null) {
          _globalGameDuration = DateTime.now().difference(_globalGameStartTime!);
          _notifyDurationListeners();
        }
      });
      
      debugPrint('🌍 Session globale démarrée: $playerName');
    }
  }

  /// Démarre une session individuelle de salle (sans redémarrer le timer global)
  void startGameSession({
    required String playerName,
    required String gameRoom,
    String gameMode = 'solo', // 'solo' ou 'multiplayer'
  }) {
    // Si c'est la première salle, démarrer la session globale
    if (!_isGlobalSessionActive) {
      startGlobalGameSession(playerName: playerName, gameMode: gameMode);
    }
    
    _currentGameRoom = gameRoom;
    _gameStartTime = DateTime.now();
    _currentGameDuration = Duration.zero;
    
    debugPrint('🎮 Session de salle démarrée: $playerName dans $gameRoom');
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

    // Ne pas arrêter le timer global, seulement la session de salle
    final session = GameSession(
      playerName: _currentPlayerName!,
      gameRoom: _currentGameRoom!,
      gameMode: _currentGameMode ?? 'solo',
      startTime: _gameStartTime!,
      endTime: DateTime.now(),
      duration: _currentGameDuration,
      completed: completed,
      score: score,
      additionalData: additionalData ?? {},
    );

    _completedSessions.add(session);
    await _saveStatsToStorage();

    // Sauvegarder la session sur le serveur Firebase
    await _saveSessionToServer(session);

    // Mettre à jour le classement Firebase
    await _updateLeaderboard(session);
    
    debugPrint('🏁 Session terminée: ${session.duration.inSeconds}s - Score: ${score ?? "N/A"}');
    
    // Reset seulement pour la prochaine salle (pas le timer global)
    _gameStartTime = null;
    _currentGameDuration = Duration.zero;
    _currentGameRoom = null;
    // Ne pas reset _currentPlayerName et _currentGameMode pour garder la session globale
    
    _notifyStatsListeners();
  }

  /// Termine complètement la session globale (appelé quand on quitte le jeu)
  Future<void> endGlobalGameSession() async {
    if (_isGlobalSessionActive) {
      _timer?.cancel();
      _timer = null;
      _isGlobalSessionActive = false;
      _globalGameStartTime = null;
      _globalGameDuration = Duration.zero;
      _currentPlayerName = null;
      _currentGameMode = null;
      _gameStartTime = null;
      _currentGameRoom = null;
      _currentGameDuration = Duration.zero;
      
      debugPrint('🌍 Session globale terminée');
      _notifyDurationListeners();
      _notifyStatsListeners();
    }
  }

  /// Obtient la durée actuelle de la session globale
  Duration get currentDuration => _isGlobalSessionActive ? _globalGameDuration : Duration.zero;

  /// Obtient la durée de la session de salle actuelle
  Duration get currentRoomDuration => _currentGameDuration;

  /// Vérifie si une session globale est active
  bool get isGlobalSessionActive => _isGlobalSessionActive;

  /// Obtient le nom du joueur actuel
  String? get currentPlayerName => _currentPlayerName;

  /// Obtient la salle de jeu actuelle
  String? get currentGameRoom => _currentGameRoom;

  /// Vérifie si une session est active (globale ou de salle)
  bool get isSessionActive => _isGlobalSessionActive;

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

  /// Sauvegarde une session sur le serveur Firebase
  Future<void> _saveSessionToServer(GameSession session) async {
    try {
      // Initialiser les services si nécessaire
      await _initializeServices();
      
      _sessionCounter++;
      final historySession = GameSessionHistory(
        sessionId: '${session.playerName}_run_${_sessionCounter}_${session.startTime.millisecondsSinceEpoch}',
        playerName: session.playerName,
        gameRoom: session.gameRoom,
        gameMode: session.gameMode,
        startTime: session.startTime,
        endTime: session.endTime,
        duration: session.duration,
        completed: session.completed,
        score: session.score,
        additionalData: session.additionalData,
      );

      await _historyService.saveGameSession(historySession);
      debugPrint('💾 Session sauvegardée sur le serveur: ${session.playerName}');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde session serveur: $e');
    }
  }

  /// Met à jour le classement Firebase avec les nouvelles statistiques
  Future<void> _updateLeaderboard(GameSession session) async {
    try {
      // Calculer les statistiques du joueur
      final playerSessions = _completedSessions.where((s) => s.playerName == session.playerName).toList();
      final totalSessions = playerSessions.length;
      final completedSessions = playerSessions.where((s) => s.completed).length;

      final scores = playerSessions.where((s) => s.score != null).map((s) => s.score!.toDouble()).toList();
      final averageScore = scores.isNotEmpty ? scores.reduce((a, b) => a + b) / scores.length : 0.0;

      final times = playerSessions.where((s) => s.completed).map((s) => s.duration).toList();
      final bestTime = times.isNotEmpty ? times.reduce((a, b) => a < b ? a : b) : Duration.zero;

      // Générer un ID unique pour le joueur basé sur son nom
      final playerId = 'player_${session.playerName.hashCode}';

      // Mettre à jour le classement
      await _leaderboardService.updatePlayerStats(
        playerId: playerId,
        playerName: session.playerName,
        totalSessions: totalSessions,
        completedSessions: completedSessions,
        averageScore: averageScore,
        bestTime: bestTime,
        isOnline: true,
        gameMode: session.gameMode,
      );

      debugPrint('🏆 Classement mis à jour pour ${session.playerName}');
    } catch (e) {
      debugPrint('❌ Erreur mise à jour classement: $e');
    }
  }

  /// Crée des données de test pour vérifier le fonctionnement
  Future<void> createTestData() async {
    try {
      debugPrint('🧪 Création de données de test...');
      
      // Initialiser les services d'abord
      await _initializeServices();
      
      final testSession = GameSessionHistory(
        sessionId: 'test_${DateTime.now().millisecondsSinceEpoch}',
        playerName: 'Joueur Test',
        gameRoom: 'Puzzle',
        gameMode: 'solo',
        startTime: DateTime.now().subtract(const Duration(minutes: 5)),
        endTime: DateTime.now(),
        duration: const Duration(minutes: 5),
        completed: true,
        score: 100,
        additionalData: {'test': true},
      );

      debugPrint('🧪 Sauvegarde de la session de test...');
      await _historyService.saveGameSession(testSession);
      debugPrint('✅ Session de test sauvegardée avec succès');
      
      // Attendre un peu pour la propagation
      await Future.delayed(const Duration(seconds: 2));
      
      // Vérifier que la session a été sauvegardée
      final sessions = await _historyService.getRecentSessions();
      debugPrint('📊 Sessions récupérées: ${sessions.length}');
      for (final session in sessions) {
        debugPrint('  - ${session.playerName}: ${session.gameRoom} (${session.duration.inMinutes}m) - Mode: ${session.gameMode}');
      }
      
      debugPrint('🧪 Données de test créées avec succès');
    } catch (e) {
      debugPrint('❌ Erreur création données test: $e');
      debugPrint('❌ Stack trace: ${StackTrace.current}');
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
  final String gameMode; // 'solo' ou 'multiplayer'
  final DateTime startTime;
  final DateTime endTime;
  final Duration duration;
  final bool completed;
  final int? score;
  final Map<String, dynamic> additionalData;

  GameSession({
    required this.playerName,
    required this.gameRoom,
    required this.gameMode,
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
      'gameMode': gameMode,
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
      gameMode: json['gameMode'] ?? 'solo', // Par défaut solo pour compatibilité
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
