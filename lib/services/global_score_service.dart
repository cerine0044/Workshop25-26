import 'dart:async';
import 'package:flutter/foundation.dart';

class GlobalScoreService {
  static final GlobalScoreService _instance = GlobalScoreService._internal();
  factory GlobalScoreService() => _instance;
  GlobalScoreService._internal();

  // État du score global
  int _totalScore = 0;
  int _currentPageScore = 0;
  DateTime? _sessionStartTime;
  DateTime? _currentPageStartTime;
  Timer? _sessionTimer;
  Timer? _pageTimer;
  
  // Historique des scores par page
  final Map<String, PageScore> _pageScores = {};
  final List<ScoreEvent> _scoreEvents = [];
  
  // Streams pour les notifications
  final StreamController<GlobalScore> _scoreController = StreamController<GlobalScore>.broadcast();
  final StreamController<PageScore> _pageScoreController = StreamController<PageScore>.broadcast();
  final StreamController<Duration> _timerController = StreamController<Duration>.broadcast();
  
  // Getters
  Stream<GlobalScore> get scoreStream => _scoreController.stream;
  Stream<PageScore> get pageScoreStream => _pageScoreController.stream;
  Stream<Duration> get timerStream => _timerController.stream;
  
  int get totalScore => _totalScore;
  int get currentPageScore => _currentPageScore;
  Duration get sessionDuration => _sessionStartTime != null 
      ? DateTime.now().difference(_sessionStartTime!)
      : Duration.zero;
  Duration get currentPageDuration => _currentPageStartTime != null
      ? DateTime.now().difference(_currentPageStartTime!)
      : Duration.zero;
  
  Map<String, PageScore> get pageScores => Map.unmodifiable(_pageScores);
  List<ScoreEvent> get scoreEvents => List.unmodifiable(_scoreEvents);
  
  // Initialiser une nouvelle session
  void startSession() {
    _sessionStartTime = DateTime.now();
    _totalScore = 0;
    _currentPageScore = 0;
    _pageScores.clear();
    _scoreEvents.clear();
    
    _startSessionTimer();
    _addScoreEvent('Session démarrée', 0, 'system');
    _notifyScoreUpdate();
  }
  
  // Démarrer le suivi d'une page
  void startPage(String pageName, {String? pageDescription}) {
    _endCurrentPage();
    
    _currentPageStartTime = DateTime.now();
    _currentPageScore = 0;
    
    _startPageTimer();
    _addScoreEvent('Page "$pageName" démarrée', 0, 'page_start');
    _notifyPageScoreUpdate();
  }
  
  // Terminer la page actuelle
  void endPage(String pageName) {
    if (_currentPageStartTime != null) {
      final duration = DateTime.now().difference(_currentPageStartTime!);
      final pageScore = PageScore(
        pageName: pageName,
        score: _currentPageScore,
        duration: duration,
        startTime: _currentPageStartTime!,
        endTime: DateTime.now(),
        events: _scoreEvents.where((e) => e.pageName == pageName).toList(),
      );
      
      _pageScores[pageName] = pageScore;
      _totalScore += _currentPageScore;
      
      _addScoreEvent('Page "$pageName" terminée', _currentPageScore, 'page_end');
      _notifyScoreUpdate();
    }
    
    _endCurrentPage();
  }
  
  // Ajouter des points
  void addScore(int points, String reason, {String? pageName}) {
    _currentPageScore += points;
    _totalScore += points;
    
    final eventPageName = pageName ?? _getCurrentPageName();
    _addScoreEvent(reason, points, 'score_add', pageName: eventPageName);
    
    _notifyScoreUpdate();
    _notifyPageScoreUpdate();
  }
  
  // Soustraire des points (pénalités)
  void subtractScore(int points, String reason, {String? pageName}) {
    _currentPageScore -= points;
    _totalScore -= points;
    
    // S'assurer que le score ne devient pas négatif
    if (_currentPageScore < 0) _currentPageScore = 0;
    if (_totalScore < 0) _totalScore = 0;
    
    final eventPageName = pageName ?? _getCurrentPageName();
    _addScoreEvent(reason, -points, 'score_subtract', pageName: eventPageName);
    
    _notifyScoreUpdate();
    _notifyPageScoreUpdate();
  }
  
  // Multiplier le score (bonus)
  void multiplyScore(double multiplier, String reason, {String? pageName}) {
    final oldScore = _currentPageScore;
    _currentPageScore = (_currentPageScore * multiplier).round();
    _totalScore = _totalScore - oldScore + _currentPageScore;
    
    final eventPageName = pageName ?? _getCurrentPageName();
    _addScoreEvent(reason, _currentPageScore - oldScore, 'score_multiply', pageName: eventPageName);
    
    _notifyScoreUpdate();
    _notifyPageScoreUpdate();
  }
  
  // Ajouter un événement de score
  void _addScoreEvent(String reason, int points, String type, {String? pageName}) {
    final event = ScoreEvent(
      timestamp: DateTime.now(),
      reason: reason,
      points: points,
      type: type,
      pageName: pageName ?? _getCurrentPageName(),
    );
    
    _scoreEvents.add(event);
  }
  
  // Obtenir le nom de la page actuelle
  String _getCurrentPageName() {
    if (_currentPageStartTime == null) return 'unknown';
    
    // Logique pour déterminer la page actuelle basée sur le temps
    // Cette méthode peut être améliorée selon les besoins
    return 'current_page';
  }
  
  // Démarrer le timer de session
  void _startSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timerController.add(sessionDuration);
    });
  }
  
  // Démarrer le timer de page
  void _startPageTimer() {
    _pageTimer?.cancel();
    _pageTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_currentPageStartTime != null) {
        _timerController.add(currentPageDuration);
      }
    });
  }
  
  // Terminer la page actuelle
  void _endCurrentPage() {
    _pageTimer?.cancel();
    _currentPageStartTime = null;
    _currentPageScore = 0;
  }
  
  // Notifier les mises à jour de score
  void _notifyScoreUpdate() {
    final globalScore = GlobalScore(
      totalScore: _totalScore,
      currentPageScore: _currentPageScore,
      sessionDuration: sessionDuration,
      currentPageDuration: currentPageDuration,
      pageCount: _pageScores.length,
      eventCount: _scoreEvents.length,
    );
    
    _scoreController.add(globalScore);
  }
  
  // Notifier les mises à jour de score de page
  void _notifyPageScoreUpdate() {
    if (_currentPageStartTime != null) {
      final pageScore = PageScore(
        pageName: _getCurrentPageName(),
        score: _currentPageScore,
        duration: currentPageDuration,
        startTime: _currentPageStartTime!,
        endTime: DateTime.now(),
        events: _scoreEvents.where((e) => e.pageName == _getCurrentPageName()).toList(),
      );
      
      _pageScoreController.add(pageScore);
    }
  }
  
  // Obtenir le score final avec statistiques
  FinalScore getFinalScore() {
    final totalDuration = _sessionStartTime != null 
        ? DateTime.now().difference(_sessionStartTime!)
        : Duration.zero;
    
    final averageScorePerPage = _pageScores.isNotEmpty 
        ? _pageScores.values.map((p) => p.score).reduce((a, b) => a + b) / _pageScores.length
        : 0.0;
    
    final averageTimePerPage = _pageScores.isNotEmpty
        ? _pageScores.values.map((p) => p.duration.inSeconds).reduce((a, b) => a + b) / _pageScores.length
        : 0.0;
    
    final bestPage = _pageScores.values.isNotEmpty
        ? _pageScores.values.reduce((a, b) => a.score > b.score ? a : b)
        : null;
    
    final worstPage = _pageScores.values.isNotEmpty
        ? _pageScores.values.reduce((a, b) => a.score < b.score ? a : b)
        : null;
    
    return FinalScore(
      totalScore: _totalScore,
      totalDuration: totalDuration,
      pageScores: Map.unmodifiable(_pageScores),
      scoreEvents: List.unmodifiable(_scoreEvents),
      averageScorePerPage: averageScorePerPage,
      averageTimePerPage: averageTimePerPage,
      bestPage: bestPage,
      worstPage: worstPage,
      sessionStartTime: _sessionStartTime,
      sessionEndTime: DateTime.now(),
    );
  }
  
  // Réinitialiser le service
  void reset() {
    _sessionTimer?.cancel();
    _pageTimer?.cancel();
    _sessionStartTime = null;
    _currentPageStartTime = null;
    _totalScore = 0;
    _currentPageScore = 0;
    _pageScores.clear();
    _scoreEvents.clear();
  }
  
  // Nettoyer les ressources
  void dispose() {
    _sessionTimer?.cancel();
    _pageTimer?.cancel();
    _scoreController.close();
    _pageScoreController.close();
    _timerController.close();
  }
}

// Modèles de données
class GlobalScore {
  final int totalScore;
  final int currentPageScore;
  final Duration sessionDuration;
  final Duration currentPageDuration;
  final int pageCount;
  final int eventCount;
  
  GlobalScore({
    required this.totalScore,
    required this.currentPageScore,
    required this.sessionDuration,
    required this.currentPageDuration,
    required this.pageCount,
    required this.eventCount,
  });
}

class PageScore {
  final String pageName;
  final int score;
  final Duration duration;
  final DateTime startTime;
  final DateTime endTime;
  final List<ScoreEvent> events;
  
  PageScore({
    required this.pageName,
    required this.score,
    required this.duration,
    required this.startTime,
    required this.endTime,
    required this.events,
  });
  
  double get scorePerSecond => duration.inSeconds > 0 ? score / duration.inSeconds : 0.0;
}

class ScoreEvent {
  final DateTime timestamp;
  final String reason;
  final int points;
  final String type;
  final String pageName;
  
  ScoreEvent({
    required this.timestamp,
    required this.reason,
    required this.points,
    required this.type,
    required this.pageName,
  });
}

class FinalScore {
  final int totalScore;
  final Duration totalDuration;
  final Map<String, PageScore> pageScores;
  final List<ScoreEvent> scoreEvents;
  final double averageScorePerPage;
  final double averageTimePerPage;
  final PageScore? bestPage;
  final PageScore? worstPage;
  final DateTime? sessionStartTime;
  final DateTime sessionEndTime;
  
  FinalScore({
    required this.totalScore,
    required this.totalDuration,
    required this.pageScores,
    required this.scoreEvents,
    required this.averageScorePerPage,
    required this.averageTimePerPage,
    required this.bestPage,
    required this.worstPage,
    required this.sessionStartTime,
    required this.sessionEndTime,
  });
  
  String get formattedDuration {
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes.remainder(60);
    final seconds = totalDuration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
  
  double get scorePerSecond => totalDuration.inSeconds > 0 ? totalScore / totalDuration.inSeconds : 0.0;
}
