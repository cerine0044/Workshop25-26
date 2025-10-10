import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MultiplayerTestApp());
}

class MultiplayerTestApp extends StatelessWidget {
  const MultiplayerTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test Multijoueur',
      theme: ThemeData.dark(),
      home: const MultiplayerTestPage(),
    );
  }
}

class MultiplayerTestPage extends StatefulWidget {
  const MultiplayerTestPage({super.key});

  @override
  State<MultiplayerTestPage> createState() => _MultiplayerTestPageState();
}

class _MultiplayerTestPageState extends State<MultiplayerTestPage> {
  String _logOutput = '';
  bool _isHost = true;
  int _playerCount = 2;

  void _addLog(String message) {
    setState(() {
      _logOutput += '${DateTime.now().toString().substring(11, 19)}: $message\n';
    });
    print(message);
  }

  void _testStartGame() async {
    _addLog('🎮 Test _startGame() démarré');
    
    try {
      // Simuler les conditions
      _addLog('📊 Players count: $_playerCount');
      _addLog('🏠 Is host: $_isHost');
      
      if (_playerCount >= 2) {
        _addLog('✅ Condition joueurs OK');
        
        // Simuler le feedback haptique
        HapticFeedback.mediumImpact();
        _addLog('✅ HapticFeedback.mediumImpact() appelé');
        
        // Simuler le message de succès
        _addLog('✅ Message "Démarrage du jeu..." affiché');
        
        // Simuler la vérification hôte
        _addLog('📊 Vérification hôte...');
        if (_isHost) {
          _addLog('✅ Vérification hôte OK');
          
          // Simuler startGame()
          _addLog('🎮 Appel startGame()...');
          await Future.delayed(const Duration(milliseconds: 500));
          _addLog('✅ startGame() terminé avec succès');
          
          // Simuler l'attente
          _addLog('⏳ Attente 1 seconde...');
          await Future.delayed(const Duration(seconds: 1));
          
          // Simuler la navigation
          _addLog('🚀 Navigation vers MultiplayerGamePage...');
          _addLog('✅ Navigation simulée terminée');
          
        } else {
          _addLog('❌ Pas l\'hôte - arrêt du test');
        }
        
      } else {
        _addLog('❌ Pas assez de joueurs');
      }
      
    } catch (e) {
      _addLog('❌ Erreur: $e');
    }
  }

  void _testButtonClick() {
    _addLog('🖱️ Bouton cliqué');
    _testStartGame();
  }

  void _testFirebaseConnection() {
    _addLog('🔥 Test connexion Firebase...');
    
    // Vérifier si Firebase est disponible
    try {
      // Simuler une vérification Firebase
      _addLog('📊 Firebase disponible: ${html.window.location.href.contains('firebase')}');
      _addLog('📊 URL actuelle: ${html.window.location.href}');
      _addLog('📊 User Agent: ${html.window.navigator.userAgent}');
    } catch (e) {
      _addLog('❌ Erreur Firebase: $e');
    }
  }

  void _clearLogs() {
    setState(() {
      _logOutput = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Test Multijoueur'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Contrôles de test
            Card(
              color: Colors.grey.shade900,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Paramètres de Test',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SwitchListTile(
                            title: const Text('Est Hôte'),
                            value: _isHost,
                            onChanged: (value) {
                              setState(() {
                                _isHost = value;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: Slider(
                            value: _playerCount.toDouble(),
                            min: 1,
                            max: 4,
                            divisions: 3,
                            label: 'Joueurs: $_playerCount',
                            onChanged: (value) {
                              setState(() {
                                _playerCount = value.round();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Boutons de test
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testButtonClick,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Test Bouton'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _testFirebaseConnection,
                    icon: const Icon(Icons.cloud),
                    label: const Text('Test Firebase'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _clearLogs,
                    icon: const Icon(Icons.clear),
                    label: const Text('Effacer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Logs
            Expanded(
              child: Card(
                color: Colors.black,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Logs de Test',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _logOutput.isEmpty ? 'Aucun log...' : _logOutput,
                            style: const TextStyle(
                              color: Colors.green,
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
