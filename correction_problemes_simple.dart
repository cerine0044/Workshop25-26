import 'dart:io';

void main() async {
  print('🔧 CORRECTION DES PROBLÈMES IDENTIFIÉS');
  print('=====================================');
  
  // Problème 1: URLs hardcodées dans les services
  await fixHardcodedUrls();
  
  // Problème 2: Créer des services améliorés
  await createEnhancedServices();
  
  print('\n✅ CORRECTIONS TERMINÉES');
}

Future<void> fixHardcodedUrls() async {
  print('\n🔗 CORRECTION 1: URLs hardcodées');
  print('----------------------------------');
  
  // Corriger HttpGameService
  final httpServiceFile = File('lib/services/http_game_service.dart');
  if (await httpServiceFile.exists()) {
    String content = await httpServiceFile.readAsString();
    
    // Remplacer l'URL hardcodée par une configuration dynamique
    content = content.replaceAll(
      "String _serverUrl = 'http://localhost:5002';",
      '''String _serverUrl = 'http://localhost:5001';
  
  // Configuration dynamique du serveur
  void setServerUrl(String url) {
    _serverUrl = url;
  }
  
  String getServerUrl() {
    return _serverUrl;
  }'''
    );
    
    await httpServiceFile.writeAsString(content);
    print('✅ HttpGameService corrigé');
  }
  
  // Corriger WebSocketGameService
  final wsServiceFile = File('lib/services/websocket_game_service.dart');
  if (await wsServiceFile.exists()) {
    String content = await wsServiceFile.readAsString();
    
    // Remplacer l'IP hardcodée par une configuration dynamique
    content = content.replaceAll(
      "String _serverUrl = 'ws://10.151.18.84:5002';",
      '''String _serverUrl = 'ws://localhost:5002';
  
  // Configuration dynamique du serveur WebSocket
  void setServerUrl(String url) {
    _serverUrl = url;
  }
  
  String getServerUrl() {
    return _serverUrl;
  }'''
    );
    
    await wsServiceFile.writeAsString(content);
    print('✅ WebSocketGameService corrigé');
  }
}

Future<void> createEnhancedServices() async {
  print('\n🛠️  CRÉATION 2: Services améliorés');
  print('-----------------------------------');
  
  // Créer un service de gestion d'erreurs amélioré
  final errorHandlerContent = '''import 'dart:io';
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
    
    print('❌ Erreur: \$message');
    if (context != null) print('   Contexte: \$context');
    if (data != null) print('   Données: \$data');
  }

  // Gérer les erreurs de connexion spécifiquement
  void handleConnectionError(dynamic error, {String? operation}) {
    String message = 'Erreur de connexion';
    String context = operation ?? 'Connexion réseau';
    
    if (error is SocketException) {
      message = 'Connexion refusée: \${error.message}';
      context = 'Socket';
    } else if (error is TimeoutException) {
      message = 'Timeout de connexion: \${error.message}';
      context = 'Timeout';
    } else if (error is HttpException) {
      message = 'Erreur HTTP: \${error.message}';
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
}''';

  final errorHandlerFile = File('lib/services/enhanced_error_handler.dart');
  await errorHandlerFile.writeAsString(errorHandlerContent);
  print('✅ EnhancedErrorHandler créé');
  
  // Créer un service de configuration réseau
  final networkConfigContent = '''import 'dart:io';
import 'dart:async';

class NetworkConfigurationService {
  static final NetworkConfigurationService _instance = NetworkConfigurationService._internal();
  factory NetworkConfigurationService() => _instance;
  NetworkConfigurationService._internal();

  String? _detectedIP;
  String _serverUrl = 'http://localhost:5001';
  String _wsUrl = 'ws://localhost:5002';

  // Détecter l'IP locale automatiquement
  Future<String?> detectLocalIP() async {
    try {
      final interfaces = await NetworkInterface.list();
      
      for (NetworkInterface interface in interfaces) {
        for (InternetAddress address in interface.addresses) {
          if (address.type == InternetAddressType.IPv4 && 
              !address.isLoopback && 
              !address.address.startsWith('169.254') &&
              !address.address.startsWith('127.')) {
            _detectedIP = address.address;
            return _detectedIP;
          }
        }
      }
    } catch (e) {
      print('❌ Erreur détection IP: \$e');
    }
    
    return null;
  }

  // Configurer les URLs automatiquement
  Future<void> configureUrls() async {
    final ip = await detectLocalIP();
    
    if (ip != null) {
      _serverUrl = 'http://\$ip:5001';
      _wsUrl = 'ws://\$ip:5002';
      print('✅ URLs configurées: \$_serverUrl, \$_wsUrl');
    } else {
      print('⚠️  Utilisation des URLs par défaut');
    }
  }

  // Tester la connectivité
  Future<bool> testConnectivity(String url) async {
    try {
      final uri = Uri.parse(url);
      final socket = await Socket.connect(uri.host, uri.port, timeout: Duration(seconds: 3));
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Obtenir l'IP détectée
  String? get detectedIP => _detectedIP;

  // Obtenir l'URL du serveur
  String get serverUrl => _serverUrl;

  // Obtenir l'URL WebSocket
  String get wsUrl => _wsUrl;

  // Configurer manuellement
  void setUrls(String serverUrl, String wsUrl) {
    _serverUrl = serverUrl;
    _wsUrl = wsUrl;
  }
}''';

  final networkConfigFile = File('lib/services/network_configuration_service.dart');
  await networkConfigFile.writeAsString(networkConfigContent);
  print('✅ NetworkConfigurationService créé');
  
  // Créer un fichier de configuration
  final configContent = '''// Configuration automatique du réseau
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
}''';

  final configFile = File('lib/config/app_config.dart');
  await configFile.writeAsString(configContent);
  print('✅ AppConfig créé');
}
