import 'dart:async';
import 'package:flutter/foundation.dart';

class GlobalScoreService {
  static final GlobalScoreService _instance = GlobalScoreService._internal();
  factory GlobalScoreService() => _instance;
  GlobalScoreService._internal();

  // État du timer global (plus de score)
  DateTime? _sessionStartTime;
  DateTime? _currentPageStartTime;
  Timer? _sessionTimer;
  Timer? _pageTimer;
  
  // Historique des sessions par page
  final Map<String, PageSession> _pageSessions = {};
  
  // Streams pour les notifications (simplifiés)
  final StreamController<SessionInfo> _sessionController = StreamController<SessionInfo>.broadcast();
  final StreamController<Duration> _timerController = StreamController<Duration>.broadcast();
  
  // Getters
  Stream<SessionInfo> get sessionStream => _sessionController.stream;
  Stream<Duration> get timerStream => _timerController.stream;
  
  Duration get sessionDuration => _sessionStartTime != null 
      ? DateTime.now().difference(_sessionStartTime!)
      : Duration.zero;
  Duration get currentPageDuration => _currentPageStartTime != null
      ? DateTime.now().difference(_currentPageStartTime!)
      : Duration.zero;
  
  Map<String, PageSession> get pageSessions => Map.unmodifiable(_pageSessions);
  
  // Initialiser une nouvelle session
  void startSession() {
    _sessionStartTime = DateTime.now();
    _pageSessions.clear();
    
    _startSessionTimer();
    _notifySessionUpdate();
  }
  
  // Démarrer le suivi d'une page
  void startPage(String pageName, {String? pageDescription}) {
    _endCurrentPage();
    
    _currentPageStartTime = DateTime.now();
    
    _startPageTimer();
    _notifySessionUpdate();
  }
  
  // Terminer la page actuelle
  void endPage(String pageName) {
    if (_currentPageStartTime != null) {
      final duration = DateTime.now().difference(_currentPageStartTime!);
      final pageSession = PageSession(
        pageName: pageName,
        duration: duration,
        startTime: _currentPageStartTime!,
        endTime: DateTime.now(),
      );
      
      _pageSessions[pageName] = pageSession;
      _notifySessionUpdate();
    }
    
    _endCurrentPage();
  }
  
  // Réinitialiser complètement la session (pour corriger le chrono)
  void resetSession() {
    _sessionTimer?.cancel();
    _pageTimer?.cancel();
    _sessionStartTime = null;
    _currentPageStartTime = null;
    _pageSessions.clear();
    _notifySessionUpdate();
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
  }
  
  // Notifier les mises à jour de session
  void _notifySessionUpdate() {
    final sessionInfo = SessionInfo(
      sessionDuration: sessionDuration,
      currentPageDuration: currentPageDuration,
      pageCount: _pageSessions.length,
      currentPageName: _getCurrentPageName(),
    );
    
    _sessionController.add(sessionInfo);
  }
  
  // Obtenir le nom de la page actuelle
  String _getCurrentPageName() {
    if (_currentPageStartTime == null) return 'unknown';
    return 'current_page';
  }
  
  // Obtenir les statistiques finales
  SessionStats getSessionStats() {
    final totalDuration = _sessionStartTime != null 
        ? DateTime.now().difference(_sessionStartTime!)
        : Duration.zero;
    
    final averageTimePerPage = _pageSessions.isNotEmpty
        ? _pageSessions.values.map((p) => p.duration.inSeconds).reduce((a, b) => a + b) / _pageSessions.length
        : 0.0;
    
    final longestPage = _pageSessions.values.isNotEmpty
        ? _pageSessions.values.reduce((a, b) => a.duration > b.duration ? a : b)
        : null;
    
    final shortestPage = _pageSessions.values.isNotEmpty
        ? _pageSessions.values.reduce((a, b) => a.duration < b.duration ? a : b)
        : null;
    
    return SessionStats(
      totalDuration: totalDuration,
      pageSessions: Map.unmodifiable(_pageSessions),
      averageTimePerPage: averageTimePerPage,
      longestPage: longestPage,
      shortestPage: shortestPage,
      sessionStartTime: _sessionStartTime,
      sessionEndTime: DateTime.now(),
    );
  }
  
  // Nettoyer les ressources
  void dispose() {
    _sessionTimer?.cancel();
    _pageTimer?.cancel();
    _sessionController.close();
    _timerController.close();
  }
}

// Modèles de données simplifiés (plus de score)
class SessionInfo {
  final Duration sessionDuration;
  final Duration currentPageDuration;
  final int pageCount;
  final String currentPageName;
  
  SessionInfo({
    required this.sessionDuration,
    required this.currentPageDuration,
    required this.pageCount,
    required this.currentPageName,
  });
}

class PageSession {
  final String pageName;
  final Duration duration;
  final DateTime startTime;
  final DateTime endTime;
  
  PageSession({
    required this.pageName,
    required this.duration,
    required this.startTime,
    required this.endTime,
  });
  
  double get durationInSeconds => duration.inSeconds.toDouble();
}

class SessionStats {
  final Duration totalDuration;
  final Map<String, PageSession> pageSessions;
  final double averageTimePerPage;
  final PageSession? longestPage;
  final PageSession? shortestPage;
  final DateTime? sessionStartTime;
  final DateTime sessionEndTime;
  
  SessionStats({
    required this.totalDuration,
    required this.pageSessions,
    required this.averageTimePerPage,
    required this.longestPage,
    required this.shortestPage,
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
}
