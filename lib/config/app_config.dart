// Configuration automatique du réseau
// Ce fichier est généré automatiquement

class AppConfig {
  static const String defaultServerUrl = 'http://localhost:5001';
  static const String defaultWsUrl = 'ws://localhost:5002';
  
  // URLs de fallback
  static const List<String> fallbackServerUrls = [
    'http://127.0.0.1:5001',
    'http://192.168.1.1:5001',
    'http://10.0.0.1:5001',
  ];
  
  static const List<String> fallbackWsUrls = [
    'ws://127.0.0.1:5002',
    'ws://192.168.1.1:5002',
    'ws://10.0.0.1:5002',
  ];
  
  // Configuration des timeouts
  static const Duration connectionTimeout = Duration(seconds: 5);
  static const Duration syncInterval = Duration(seconds: 2);
  
  // Configuration des erreurs
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 1);
}