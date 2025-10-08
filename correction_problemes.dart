import 'dart:io';
import 'dart:convert';

void main() async {
  print('🔧 CORRECTION DES PROBLÈMES IDENTIFIÉS');
  print('=====================================');
  
  // Problème 1: URLs hardcodées dans les services
  await fixHardcodedUrls();
  
  // Problème 2: Gestion des erreurs manquante
  await fixErrorHandling();
  
  // Problème 3: Synchronisation des données
  await fixDataSynchronization();
  
  // Problème 4: Configuration réseau
  await fixNetworkConfiguration();
  
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

Future<void> fixErrorHandling() async {
  print('\n⚠️  CORRECTION 2: Gestion des erreurs');
  print('--------------------------------------');
  
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

  // Gérer les erreurs de synchronisation
  void handleSyncError(String message, {Map<String, dynamic>? gameData}) {
    handleError(message, context: 'Synchronisation', data: {
      'gameData': gameData,
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

  // Vérifier s'il y a des erreurs récentes
  bool hasRecentErrors({Duration? within}) {
    final cutoff = DateTime.now().subtract(within ?? Duration(minutes: 5));
    return _errorLog.any((error) {
      final timestamp = DateTime.parse(error['timestamp']);
      return timestamp.isAfter(cutoff);
    });
  }
}''';

  final errorHandlerFile = File('lib/services/enhanced_error_handler.dart');
  await errorHandlerFile.writeAsString(errorHandlerContent);
  print('✅ EnhancedErrorHandler créé');
}

Future<void> fixDataSynchronization() async {
  print('\n🔄 CORRECTION 3: Synchronisation des données');
  print('---------------------------------------------');
  
  // Créer un service de synchronisation amélioré
  final syncServiceContent = '''import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DataSynchronizationService {
  static final DataSynchronizationService _instance = DataSynchronizationService._internal();
  factory DataSynchronizationService() => _instance;
  DataSynchronizationService._internal();

  String _serverUrl = 'http://localhost:5001';
  Timer? _syncTimer;
  final Map<String, dynamic> _localData = {};
  final Map<String, dynamic> _remoteData = {};
  final StreamController<Map<String, dynamic>> _syncStream = StreamController<Map<String, dynamic>>.broadcast();

  // Démarrer la synchronisation automatique
  void startAutoSync({Duration interval = const Duration(seconds: 2)}) {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(interval, (timer) {
      _performSync();
    });
  }

  // Arrêter la synchronisation automatique
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }

  // Synchroniser les données
  Future<void> _performSync() async {
    try {
      // Récupérer les données du serveur
      final response = await http.get(Uri.parse('${_serverUrl}/sync'));
      
      if (response.statusCode == 200) {
        final remoteData = jsonDecode(response.body) as Map<String, dynamic>;
        _remoteData.clear();
        _remoteData.addAll(remoteData);
        
        // Comparer avec les données locales
        _compareAndSync();
      }
    } catch (e) {
      print('❌ Erreur synchronisation: \$e');
    }
  }

  // Comparer et synchroniser les données
  void _compareAndSync() {
    bool hasChanges = false;
    final changes = <String, dynamic>{};
    
    // Vérifier les différences
    _remoteData.forEach((key, value) {
      if (!_localData.containsKey(key) || _localData[key] != value) {
        _localData[key] = value;
        changes[key] = value;
        hasChanges = true;
      }
    });
    
    if (hasChanges) {
      _syncStream.add({
        'type': 'data_updated',
        'changes': changes,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  // Envoyer des données au serveur
  Future<void> sendData(String key, dynamic value) async {
    try {
      _localData[key] = value;
      
      final response = await http.post(
        Uri.parse('${_serverUrl}/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({key: value}),
      );
      
      if (response.statusCode == 200) {
        print('✅ Données envoyées: \$key');
      } else {
        print('❌ Erreur envoi données: \${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur envoi données: \$e');
    }
  }

  // Obtenir les données synchronisées
  Map<String, dynamic> getSyncedData() {
    return Map.from(_localData);
  }

  // Stream des changements
  Stream<Map<String, dynamic>> get syncStream => _syncStream.stream;

  // Vérifier la cohérence des données
  bool isDataConsistent() {
    return _localData.length == _remoteData.length &&
           _localData.entries.every((entry) => 
             _remoteData.containsKey(entry.key) && 
             _remoteData[entry.key] == entry.value);
  }

  // Forcer une synchronisation complète
  Future<void> forceFullSync() async {
    await _performSync();
  }
}''';

  final syncServiceFile = File('lib/services/data_synchronization_service.dart');
  await syncServiceFile.writeAsString(syncServiceContent);
  print('✅ DataSynchronizationService créé');
}

Future<void> fixNetworkConfiguration() async {
  print('\n🌐 CORRECTION 4: Configuration réseau');
  print('-------------------------------------');
  
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
  final List<String> _fallbackIPs = [
    '127.0.0.1',
    'localhost',
    '192.168.1.1',
    '10.0.0.1',
  ];

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
      _serverUrl = 'http://$ip:5001';
      _wsUrl = 'ws://$ip:5002';
      print('✅ URLs configurées: ${_serverUrl}, ${_wsUrl}');
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

  // Trouver la meilleure URL de serveur
  Future<String> findBestServerUrl() async {
    final candidates = [
      _serverUrl,
      'http://localhost:5001',
      'http://127.0.0.1:5001',
    ];
    
    if (_detectedIP != null) {
      candidates.insert(0, 'http://$_detectedIP:5001');
    }
    
    for (String url in candidates) {
      if (await testConnectivity(url)) {
        print('✅ Serveur accessible: $url');
        return url;
      }
    }
    
    print('❌ Aucun serveur accessible');
    return candidates.first;
  }

  // Trouver la meilleure URL WebSocket
  Future<String> findBestWebSocketUrl() async {
    final candidates = [
      _wsUrl,
      'ws://localhost:5002',
      'ws://127.0.0.1:5002',
    ];
    
    if (_detectedIP != null) {
      candidates.insert(0, 'ws://$_detectedIP:5002');
    }
    
    for (String url in candidates) {
      if (await testConnectivity(url)) {
        print('✅ WebSocket accessible: $url');
        return url;
      }
    }
    
    print('❌ Aucun WebSocket accessible');
    return candidates.first;
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
