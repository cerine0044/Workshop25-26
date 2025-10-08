import 'dart:async';
import 'package:flutter/material.dart';
import '../services/bluetooth_game_manager.dart';
import 'page1_puzzle.dart';
import 'stress_page.dart';
import 'page3_crossword.dart';
import 'page4_tram.dart';
import 'page5_notifications.dart';
import 'certificate_page.dart';
import 'results_screen.dart';

class GameSession extends StatefulWidget {
  final String playerName;
  final bool isBluetoothMode;
  final BluetoothGameManager? bluetoothManager;

  const GameSession({
    super.key,
    required this.playerName,
    this.isBluetoothMode = false,
    this.bluetoothManager,
  });

  @override
  State<GameSession> createState() => _GameSessionState();
}

class _GameSessionState extends State<GameSession> {
  // Chronomètre
  Timer? _gameTimer;
  Duration _gameDuration = Duration.zero;
  DateTime? _gameStartTime;
  
  // Progression
  int _currentPage = 0;
  final List<String> _pageNames = [
    'Page1 - Boutons cachés',
    'Page2 - Détecteur stress',
    'Page3 - Mots fléchés RGPD',
    'Page4 - Dilemme tramway',
    'Page5 - Notifications',
    'Certificat',
  ];
  
  // Statistiques
  Map<String, dynamic> _gameStats = {
    'pageTimes': <String, Duration>{},
    'totalTime': Duration.zero,
    'playerName': '',
    'isBluetoothMode': false,
  };

  @override
  void initState() {
    super.initState();
    _startGameTimer();
    _gameStats['playerName'] = widget.playerName;
    _gameStats['isBluetoothMode'] = widget.isBluetoothMode;
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    super.dispose();
  }

  void _startGameTimer() {
    _gameStartTime = DateTime.now();
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _gameDuration = DateTime.now().difference(_gameStartTime!);
      });
    });
  }

  void _stopGameTimer() {
    _gameTimer?.cancel();
    _gameStats['totalTime'] = _gameDuration;
  }

  void _onPageComplete(String pageName, Map<String, dynamic> pageData) {
    // Enregistrer le temps de la page
    _gameStats['pageTimes'][pageName] = _gameDuration;
    
    // Envoyer données via Bluetooth si mode activé
    if (widget.isBluetoothMode && widget.bluetoothManager != null) {
      widget.bluetoothManager!.sendGameData({
        'playerName': widget.playerName,
        'pageName': pageName,
        'pageData': pageData,
        'timestamp': DateTime.now().toIso8601String(),
        'gameDuration': _gameDuration.inSeconds,
      });
    }
    
    // Passer à la page suivante
    _nextPage();
  }

  void _nextPage() {
    setState(() {
      _currentPage++;
    });
    
    if (_currentPage >= _pageNames.length) {
      _gameComplete();
    }
  }

  void _gameComplete() {
    _stopGameTimer();
    
    if (widget.isBluetoothMode) {
      // Mode Bluetooth : aller aux résultats
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            playerStats: _gameStats,
            bluetoothManager: widget.bluetoothManager,
          ),
        ),
      );
    } else {
      // Mode Solo : aller au certificat
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CertificatePage(
            playerStats: _gameStats,
          ),
        ),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Session: ${widget.playerName}'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          // Chronomètre
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Text(
                  _formatDuration(_gameDuration),
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Barre de progression
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Progression
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: _currentPage / (_pageNames.length - 1),
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.blueAccent,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${_currentPage + 1}/${_pageNames.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Page actuelle
                  Text(
                    _currentPage < _pageNames.length 
                      ? _pageNames[_currentPage]
                      : 'Terminé',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenu de la page
            Expanded(
              child: _buildCurrentPage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case 0:
        return Page1Puzzle(
          onComplete: (data) => _onPageComplete('Page1', data),
        );
      case 1:
        return StressPage(
          onComplete: (data) => _onPageComplete('Page2', data),
        );
      case 2:
        return Page3Crossword(
          onComplete: (data) => _onPageComplete('Page3', data),
        );
      case 3:
        return Page4Tram(
          onComplete: (data) => _onPageComplete('Page4', data),
        );
      case 4:
        return Page5Notifications(
          onComplete: (data) => _onPageComplete('Page5', data),
        );
      case 5:
        return CertificatePage(
          playerStats: _gameStats,
        );
      default:
        return const Center(
          child: Text(
            'Session terminée',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        );
    }
  }
}
