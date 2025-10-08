import 'dart:io';
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
      print('❌ Erreur détection IP: $e');
    }
    
    return null;
  }

  // Configurer les URLs automatiquement
  Future<void> configureUrls() async {
    final ip = await detectLocalIP();
    
    if (ip != null) {
      _serverUrl = 'http://$ip:5001';
      _wsUrl = 'ws://$ip:5002';
      print('✅ URLs configurées: $_serverUrl, $_wsUrl');
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
}