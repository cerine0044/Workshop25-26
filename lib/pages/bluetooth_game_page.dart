import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../services/bluetooth_game_manager.dart';
import 'game_session.dart';

class BluetoothGamePage extends StatefulWidget {
  const BluetoothGamePage({super.key});

  @override
  State<BluetoothGamePage> createState() => _BluetoothGamePageState();
}

class _BluetoothGamePageState extends State<BluetoothGamePage> {
  final BluetoothGameManager _bluetoothManager = BluetoothGameManager();
  List<BluetoothDevice> _foundDevices = [];
  bool _isScanning = false;
  bool _isConnected = false;
  String _playerName = '';
  StreamSubscription<List<BluetoothDevice>>? _devicesSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  @override
  void initState() {
    super.initState();
    _initializeBluetooth();
    _playerName = _bluetoothManager.generateDeviceName();
  }

  @override
  void dispose() {
    _devicesSubscription?.cancel();
    _connectionSubscription?.cancel();
    _bluetoothManager.dispose();
    super.dispose();
  }

  Future<void> _initializeBluetooth() async {
    bool initialized = await _bluetoothManager.initialize();
    if (!initialized) {
      _showErrorDialog('Bluetooth non disponible ou non activé');
      return;
    }

    // Écouter les appareils trouvés
    _devicesSubscription = _bluetoothManager.devicesStream.listen((devices) {
      setState(() {
        _foundDevices = devices;
      });
    });

    // Écouter les changements de connexion
    _connectionSubscription = _bluetoothManager.connectionStream.listen((connected) {
      setState(() {
        _isConnected = connected;
      });
      
      if (connected) {
        _showSuccessDialog('Connecté avec succès !');
        _startGame();
      }
    });
  }

  Future<void> _scanForDevices() async {
    setState(() {
      _isScanning = true;
      _foundDevices.clear();
    });

    try {
      List<BluetoothDevice> devices = await _bluetoothManager.scanForDevices();
      setState(() {
        _foundDevices = devices;
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      _showErrorDialog('Erreur lors du scan: $e');
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    bool connected = await _bluetoothManager.connectToDevice(device);
    if (!connected) {
      _showErrorDialog('Impossible de se connecter à ${device.name}');
    }
  }

  void _startGame() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameSession(
          playerName: _playerName,
          isBluetoothMode: true,
          bluetoothManager: _bluetoothManager,
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Succès'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Mode Bluetooth'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isScanning ? Icons.stop : Icons.bluetooth_searching),
            onPressed: _isScanning ? null : _scanForDevices,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // En-tête
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.bluetooth,
                      color: Colors.blueAccent,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Joueur: $_playerName',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isConnected ? 'Connecté' : 'Non connecté',
                      style: TextStyle(
                        color: _isConnected ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Instructions:\n'
                  '1. Assure-toi que Bluetooth est activé\n'
                  '2. Appuie sur "Scanner" pour trouver des appareils\n'
                  '3. Sélectionne l\'appareil de ton partenaire\n'
                  '4. Attends la connexion\n'
                  '5. Commence à jouer !',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Bouton scanner
              ElevatedButton.icon(
                onPressed: _isScanning ? null : _scanForDevices,
                icon: _isScanning 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.bluetooth_searching),
                label: Text(_isScanning ? 'Scan en cours...' : 'Scanner les appareils'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Liste des appareils
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Appareils trouvés',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _foundDevices.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.bluetooth_disabled,
                                    color: Colors.white.withOpacity(0.3),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _isScanning 
                                      ? 'Recherche d\'appareils...'
                                      : 'Aucun appareil trouvé',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _foundDevices.length,
                              itemBuilder: (context, index) {
                                final device = _foundDevices[index];
                                return ListTile(
                                  leading: const Icon(
                                    Icons.bluetooth,
                                    color: Colors.blueAccent,
                                  ),
                                  title: Text(
                                    device.name.isNotEmpty ? device.name : 'Appareil inconnu',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    device.id.toString(),
                                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: () => _connectToDevice(device),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.greenAccent,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(80, 32),
                                    ),
                                    child: const Text('Connecter'),
                                  ),
                                );
                              },
                            ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Bouton retour
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Retour',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
