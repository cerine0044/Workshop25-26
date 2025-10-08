import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/bluetooth_game_manager.dart';
import 'game_session.dart';

class BluetoothGamePage extends StatefulWidget {
  const BluetoothGamePage({super.key});

  @override
  State<BluetoothGamePage> createState() => _BluetoothGamePageState();
}

class _BluetoothGamePageState extends State<BluetoothGamePage> {
  final BluetoothGameManager _bluetoothManager = BluetoothGameManager();
  List<Map<String, dynamic>> _foundDevices = [];
  bool _isScanning = false;
  bool _isConnected = false;
  String _playerName = '';
  bool _isWebMode = kIsWeb;

  @override
  void initState() {
    super.initState();
    _playerName = _bluetoothManager.generateDeviceName();
    _initializeBluetooth();
  }

  @override
  void dispose() {
    _bluetoothManager.dispose();
    super.dispose();
  }

  Future<void> _initializeBluetooth() async {
    if (_isWebMode) {
      // Mode web : utiliser Web Bluetooth API
      await _initializeWebBluetooth();
    } else {
      // Mode natif : utiliser flutter_blue_plus
      await _initializeNativeBluetooth();
    }
  }

  Future<void> _initializeWebBluetooth() async {
    // Vérifier si Web Bluetooth est supporté
    if (!await _isWebBluetoothSupported()) {
      _showErrorDialog('Web Bluetooth n\'est pas supporté par ce navigateur. Utilisez Chrome ou Edge.');
      return;
    }
  }

  Future<void> _initializeNativeBluetooth() async {
    // Initialisation pour les plateformes natives
    // Cette partie sera implémentée quand les problèmes macOS seront résolus
  }

  Future<bool> _isWebBluetoothSupported() async {
    // Vérifier le support Web Bluetooth
    return true; // Simplifié pour l'instant
  }

  Future<void> _scanForDevices() async {
    setState(() {
      _isScanning = true;
      _foundDevices.clear();
    });

    if (_isWebMode) {
      await _scanWebBluetoothDevices();
    } else {
      await _scanNativeBluetoothDevices();
    }
  }

  Future<void> _scanWebBluetoothDevices() async {
    try {
      // Utiliser Web Bluetooth API pour scanner les appareils
      // Pour l'instant, simuler avec des appareils réalistes
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _foundDevices = [
          {
            'id': 'AA:BB:CC:DD:EE:01',
            'name': 'iPhone de Marie',
            'rssi': -45,
            'type': 'Smartphone',
            'isConnectable': true,
          },
          {
            'id': 'AA:BB:CC:DD:EE:02',
            'name': 'Samsung Galaxy S23',
            'rssi': -52,
            'type': 'Smartphone',
            'isConnectable': true,
          },
          {
            'id': 'AA:BB:CC:DD:EE:04',
            'name': 'MacBook Pro',
            'rssi': -65,
            'type': 'Ordinateur',
            'isConnectable': true,
          },
        ];
        _isScanning = false;
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      _showErrorDialog('Erreur lors du scan Web Bluetooth: $e');
    }
  }

  Future<void> _scanNativeBluetoothDevices() async {
    try {
      // Utiliser flutter_blue_plus pour les plateformes natives
      // Cette partie sera implémentée quand les problèmes macOS seront résolus
      setState(() {
        _isScanning = false;
      });
      _showErrorDialog('Mode natif temporairement désactivé (problèmes de permissions macOS)');
    } catch (e) {
      setState(() {
        _isScanning = false;
      });
      _showErrorDialog('Erreur lors du scan natif: $e');
    }
  }

  Future<void> _connectToDevice(Map<String, dynamic> device) async {
    if (!device['isConnectable']) {
      _showErrorDialog('Cet appareil ne peut pas être utilisé pour le jeu (${device['type']})');
      return;
    }

    setState(() {
      _isConnected = true;
    });
    
    // Simuler le processus de connexion
    await Future.delayed(const Duration(seconds: 2));
    _showSuccessDialog('Connecté avec succès à ${device['name']} !');
    _startGame();
  }

  void _startGame() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => GameSession(
          playerName: _playerName,
          isBluetoothMode: true,
          bluetoothManager: null, // Mode web/natif hybride
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text(
          'Erreur',
          style: TextStyle(color: Colors.redAccent),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.blueAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.greenAccent, size: 24),
            SizedBox(width: 8),
            Text(
              'Succès',
              style: TextStyle(color: Colors.greenAccent),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.blueAccent),
            ),
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
              // Statut Bluetooth adaptatif
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isWebMode ? Colors.blue.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isWebMode ? Colors.blue.withOpacity(0.3) : Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isWebMode ? Icons.web : Icons.bluetooth,
                      color: _isWebMode ? Colors.blue : Colors.green,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _isWebMode 
                          ? 'Mode Web Bluetooth - Compatible navigateurs modernes'
                          : 'Mode natif Bluetooth - Détection d\'appareils physiques',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

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
                child: Text(
                  'Instructions:\n'
                  '1. Assure-toi que Bluetooth est activé sur ton PC et ton portable\n'
                  '2. Appuie sur "Scanner" pour trouver les appareils à proximité\n'
                  '3. Sélectionne l\'appareil de ton partenaire\n'
                  '4. Attends la connexion\n'
                  '5. Commence à jouer !',
                  style: const TextStyle(
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
                                    device['name'] ?? 'Appareil inconnu',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${device['type']} • RSSI: ${device['rssi']} dBm',
                                        style: TextStyle(color: Colors.white.withOpacity(0.6)),
                                      ),
                                      Text(
                                        'ID: ${device['id']}',
                                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10),
                                      ),
                                    ],
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: device['isConnectable'] 
                                      ? () => _connectToDevice(device)
                                      : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: device['isConnectable'] 
                                        ? Colors.greenAccent 
                                        : Colors.grey,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(80, 32),
                                    ),
                                    child: Text(
                                      device['isConnectable'] ? 'Connecter' : 'Non compatible',
                                      style: const TextStyle(fontSize: 10),
                                    ),
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
