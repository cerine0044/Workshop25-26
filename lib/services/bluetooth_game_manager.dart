import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothGameManager {
  static final BluetoothGameManager _instance = BluetoothGameManager._internal();
  factory BluetoothGameManager() => _instance;
  BluetoothGameManager._internal();

  // Configuration Bluetooth
  static const String serviceUUID = "12345678-1234-1234-1234-123456789ABC";
  static const String characteristicUUID = "87654321-4321-4321-4321-CBA987654321";
  
  // État de connexion
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _gameCharacteristic;
  bool _isConnected = false;
  bool _isScanning = false;
  
  // Streams pour les données
  final StreamController<List<BluetoothDevice>> _devicesController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _gameDataController = StreamController.broadcast();
  final StreamController<bool> _connectionController = StreamController.broadcast();
  
  // Getters
  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  
  // Streams
  Stream<List<BluetoothDevice>> get devicesStream => _devicesController.stream;
  Stream<Map<String, dynamic>> get gameDataStream => _gameDataController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Initialiser le Bluetooth
  Future<bool> initialize() async {
    try {
      // Vérifier si Bluetooth est disponible
      if (!await FlutterBluePlus.isAvailable) {
        print('Bluetooth non disponible');
        return false;
      }
      
      // Vérifier si Bluetooth est activé
      if (!await FlutterBluePlus.isOn) {
        print('Bluetooth non activé');
        return false;
      }
      
      return true;
    } catch (e) {
      print('Erreur initialisation Bluetooth: $e');
      return false;
    }
  }

  /// Scanner les appareils à proximité
  Future<List<BluetoothDevice>> scanForDevices() async {
    if (_isScanning) return [];
    
    try {
      _isScanning = true;
      List<BluetoothDevice> foundDevices = [];
      
      // Démarrer le scan
      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 10),
        withServices: [Guid(serviceUUID)],
      );
      
      // Écouter les résultats
      FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          if (!foundDevices.any((device) => device.id == result.device.id)) {
            foundDevices.add(result.device);
            _devicesController.add(List.from(foundDevices));
          }
        }
      });
      
      // Attendre la fin du scan
      await Future.delayed(const Duration(seconds: 10));
      await FlutterBluePlus.stopScan();
      
      _isScanning = false;
      return foundDevices;
    } catch (e) {
      print('Erreur scan Bluetooth: $e');
      _isScanning = false;
      return [];
    }
  }

  /// Se connecter à un appareil
  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      _connectedDevice = device;
      
      // Se connecter
      await device.connect(timeout: const Duration(seconds: 15));
      
      // Découvrir les services
      List<BluetoothService> services = await device.discoverServices();
      
      // Chercher notre service
      for (BluetoothService service in services) {
        if (service.uuid.toString().toUpperCase() == serviceUUID.toUpperCase()) {
          // Chercher notre caractéristique
          for (BluetoothCharacteristic characteristic in service.characteristics) {
            if (characteristic.uuid.toString().toUpperCase() == characteristicUUID.toUpperCase()) {
              _gameCharacteristic = characteristic;
              
              // Écouter les notifications
              await characteristic.setNotifyValue(true);
              characteristic.onValueReceived.listen((data) {
                try {
                  String jsonString = utf8.decode(data);
                  Map<String, dynamic> gameData = jsonDecode(jsonString);
                  _gameDataController.add(gameData);
                } catch (e) {
                  print('Erreur décodage données: $e');
                }
              });
              
              _isConnected = true;
              _connectionController.add(true);
              return true;
            }
          }
        }
      }
      
      // Si pas trouvé, créer le service (pour le premier appareil)
      if (services.isEmpty) {
        await _createGameService(device);
        _isConnected = true;
        _connectionController.add(true);
        return true;
      }
      
      return false;
    } catch (e) {
      print('Erreur connexion Bluetooth: $e');
      _isConnected = false;
      _connectionController.add(false);
      return false;
    }
  }

  /// Créer le service de jeu (pour le premier appareil)
  Future<void> _createGameService(BluetoothDevice device) async {
    // Cette fonction serait implémentée côté serveur Bluetooth
    // Pour l'instant, on simule une connexion réussie
    print('Service de jeu créé pour ${device.name}');
  }

  /// Envoyer des données de jeu
  Future<void> sendGameData(Map<String, dynamic> data) async {
    if (_gameCharacteristic == null || !_isConnected) {
      print('Pas de connexion Bluetooth active');
      return;
    }
    
    try {
      String jsonData = jsonEncode(data);
      await _gameCharacteristic!.write(utf8.encode(jsonData));
      print('Données envoyées: $data');
    } catch (e) {
      print('Erreur envoi données: $e');
    }
  }

  /// Déconnecter
  Future<void> disconnect() async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
      
      _connectedDevice = null;
      _gameCharacteristic = null;
      _isConnected = false;
      _connectionController.add(false);
      
      print('Déconnecté du Bluetooth');
    } catch (e) {
      print('Erreur déconnexion: $e');
    }
  }

  /// Générer un nom d'appareil unique
  String generateDeviceName() {
    final random = Random();
    final adjectives = ['Mystérieux', 'Étrange', 'Caché', 'Secret', 'Obscur'];
    final nouns = ['Pandora', 'Box', 'Player', 'Gamer', 'Explorer'];
    
    final adjective = adjectives[random.nextInt(adjectives.length)];
    final noun = nouns[random.nextInt(nouns.length)];
    final number = random.nextInt(999) + 1;
    
    return '$adjective $noun $number';
  }

  /// Nettoyer les ressources
  void dispose() {
    _devicesController.close();
    _gameDataController.close();
    _connectionController.close();
    disconnect();
  }
}

/// Modèle de données de jeu
class GameData {
  final String playerId;
  final String playerName;
  final String action; // 'start', 'progress', 'complete', 'result'
  final Map<String, dynamic> data;
  final DateTime timestamp;

  GameData({
    required this.playerId,
    required this.playerName,
    required this.action,
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'playerName': playerName,
    'action': action,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
  };

  factory GameData.fromJson(Map<String, dynamic> json) => GameData(
    playerId: json['playerId'],
    playerName: json['playerName'],
    action: json['action'],
    data: json['data'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}
