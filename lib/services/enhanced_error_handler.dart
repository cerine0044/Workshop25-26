import 'dart:io';
import 'dart:convert';
import 'dart:async';

class EnhancedErrorHandler {
  static final EnhancedErrorHandler _instance = EnhancedErrorHandler._internal();
  factory EnhancedErrorHandler() => _instance;
  EnhancedErrorHandler._internal();

  final List<Map<String, dynamic>> _errorLog = [];
  final StreamController<Map<String, dynamic>> _errorStream = StreamController<Map<String, dynamic>>.broadcast();

  // Gérer une erreur avec contexte
  void handleError(String message, {String? context, Map<String, dynamic>? data}) {
    final error = {
      'timestamp': DateTime.now().toIso8601String(),
      'message': message,
      'context': context ?? 'Unknown',
      'data': data ?? {},
      'stackTrace': StackTrace.current.toString(),
    };
    
    _errorLog.add(error);
    _errorStream.add(error);
    
    print('❌ Erreur: $message');
    if (context != null) print('   Contexte: $context');
    if (data != null) print('   Données: $data');
  }

  // Gérer les erreurs de connexion spécifiquement
  void handleConnectionError(dynamic error, {String? operation}) {
    String message = 'Erreur de connexion';
    String context = operation ?? 'Connexion réseau';
    
    if (error is SocketException) {
      message = 'Connexion refusée: ${error.message}';
      context = 'Socket';
    } else if (error is TimeoutException) {
      message = 'Timeout de connexion: ${error.message}';
      context = 'Timeout';
    } else if (error is HttpException) {
      message = 'Erreur HTTP: ${error.message}';
      context = 'HTTP';
    }
    
    handleError(message, context: context, data: {
      'errorType': error.runtimeType.toString(),
      'operation': operation,
    });
  }

  // Obtenir le log d'erreurs
  List<Map<String, dynamic>> getErrorLog() {
    return List.from(_errorLog);
  }

  // Stream des erreurs
  Stream<Map<String, dynamic>> get errorStream => _errorStream.stream;

  // Nettoyer les erreurs anciennes
  void clearOldErrors({Duration? olderThan}) {
    final cutoff = DateTime.now().subtract(olderThan ?? Duration(hours: 1));
    _errorLog.removeWhere((error) {
      final timestamp = DateTime.parse(error['timestamp']);
      return timestamp.isBefore(cutoff);
    });
  }
}