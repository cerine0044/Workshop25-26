import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_multiplayer_service.dart';
import '../services/game_stats_service.dart';
import '../services/player_name_service.dart';
import 'page1_puzzle.dart';
import 'stress_page.dart';
import 'page3_words.dart';
import 'page4_tram.dart';
import 'page5_notifications.dart';
import 'multiplayer_success_page.dart';

class MultiplayerGamePage extends StatefulWidget {
  const MultiplayerGamePage({super.key});

  @override
  State<MultiplayerGamePage> createState() => _MultiplayerGamePageState();
}

class _MultiplayerGamePageState extends State<MultiplayerGamePage>
    with TickerProviderStateMixin {
  final FirebaseMultiplayerService _multiplayerService = FirebaseMultiplayerService();
  final GameStatsService _gameStatsService = GameStatsService();
  final PlayerNameService _playerNameService = PlayerNameService();
  
  // État du jeu
  int _currentRoomIndex = 0;
  bool _isGameStarted = false;
  bool _isCountdownActive = false;
  int _countdownValue = 3;
  
  // Données des joueurs
  Map<String, dynamic> _playersData = {};
  List<Map<String, dynamic>> _gameRooms = [
    {'name': 'Puzzle', 'page': const Page1Puzzle()},
    {'name': 'Détecteur de Stress', 'page': const StressPage()},
    {'name': 'Mots Croisés', 'page': const Page3Words()},
    {'name': 'Tram', 'page': const Page4Tram()},
    {'name': 'Notifications', 'page': const Page5Notifications()},
  ];
  
  // Animations
  late AnimationController _countdownController;
  late Animation<double> _countdownScale;
  late Animation<double> _countdownOpacity;
  
  // Timers
  Timer? _countdownTimer;
  Timer? _gameStateTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeGame();
  }

  void _initializeAnimations() {
    _countdownController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _countdownScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _countdownController,
      curve: Curves.elasticOut,
    ));

    _countdownOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _countdownController,
      curve: Curves.easeInOut,
    ));
  }

  Future<void> _initializeGame() async {
    try {
      print('🎮 MultiplayerGamePage initialisé');
      
      // Initialiser les services
      await _playerNameService.initialize();
      
      // Démarrer le countdown directement
      _startCountdown();
      
    } catch (e) {
      print('❌ Erreur initialisation: $e');
      // Démarrer le countdown quand même
      _startCountdown();
    }
  }

  void _startCountdown() {
    setState(() {
      _isCountdownActive = true;
      _countdownValue = 3;
    });
    
    _countdownController.forward();
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownValue > 1) {
        setState(() {
          _countdownValue--;
        });
        _countdownController.reset();
        _countdownController.forward();
      } else {
        timer.cancel();
        _startGame();
      }
    });
  }

  void _startGame() {
    setState(() {
      _isCountdownActive = false;
      _isGameStarted = true;
    });
    
    _countdownController.dispose();
    
    // Démarrer la session de jeu globale
    _gameStatsService.startGlobalGameSession(
      gameMode: 'multiplayer',
      playerName: _playerNameService.getPlayerNameOrDefault(),
    );
    
    // Naviguer vers la première salle
    _navigateToRoom(0);
  }

  void _navigateToRoom(int roomIndex) {
    if (roomIndex < _gameRooms.length) {
      setState(() {
        _currentRoomIndex = roomIndex;
      });
      
      // Sauvegarder le début de la salle
      _gameStatsService.startRoomSession(
        gameRoom: _gameRooms[roomIndex]['name'],
        gameMode: 'multiplayer',
        playerName: _playerNameService.getPlayerNameOrDefault(),
      );
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => _gameRooms[roomIndex]['page'],
        ),
      ).then((result) {
        // Quand on revient de la salle, sauvegarder les résultats
        if (result != null && result is Map<String, dynamic>) {
          _saveRoomResults(roomIndex, result);
        }
        
        // Passer à la salle suivante ou terminer
        if (roomIndex < _gameRooms.length - 1) {
          _navigateToRoom(roomIndex + 1);
        } else {
          _finishGame();
        }
      });
    }
  }

  void _saveRoomResults(int roomIndex, Map<String, dynamic> results) {
    final roomName = _gameRooms[roomIndex]['name'];
    final score = results['score'] ?? 0;
    final time = results['time'] ?? Duration.zero;
    final completed = results['completed'] ?? false;
    final additionalData = results['additionalData'] ?? {};
    
    // Sauvegarder les résultats de la salle
    _gameStatsService.endRoomSession(
      gameRoom: roomName,
      score: score,
      time: time,
      completed: completed,
      additionalData: additionalData,
    );
    
    debugPrint('🎮 Salle $roomName sauvegardée: Score=$score, Temps=$time, Complété=$completed');
  }

  void _debugSkipToNotifications() {
    debugPrint('🐛 DEBUG: Passage direct aux notifications');
    
    // Simuler les résultats de toutes les salles précédentes
    for (int i = 0; i < 4; i++) {
      final roomName = _gameRooms[i]['name'];
      _saveRoomResults(i, {
        'score': 100,
        'time': const Duration(seconds: 30),
        'completed': true,
        'additionalData': {'debug': true},
      });
    }
    
    // Aller directement à la page des notifications (salle 5)
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _gameRooms[4]['page'], // Page des notifications
      ),
    ).then((result) {
      // Sauvegarder les résultats de la page notifications
      if (result != null && result is Map<String, dynamic>) {
        _saveRoomResults(4, result);
      }
      
      // Terminer le jeu
      _finishGame();
    });
  }

  void _finishGame() {
    // Terminer la session de jeu globale
    _gameStatsService.endGlobalGameSession();
    
    // Récupérer les sessions des joueurs depuis GameStatsService
    final playerSessions = _gameStatsService.getPlayerSessions();
    
    // Naviguer vers la page de succès avec les vraies données
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MultiplayerSuccessPage(
          playersData: _playersData,
          playerSessions: playerSessions,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _gameStateTimer?.cancel();
    _countdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: _isCountdownActive ? _buildCountdown() : _buildGameInterface(),
      ),
    );
  }

  Widget _buildCountdown() {
    return Center(
      child: AnimatedBuilder(
        animation: _countdownController,
        builder: (context, child) {
          return Transform.scale(
            scale: _countdownScale.value,
            child: Opacity(
              opacity: _countdownOpacity.value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.deepPurple.withOpacity(0.2),
                      border: Border.all(
                        color: Colors.deepPurple,
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$_countdownValue',
                        style: const TextStyle(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Text(
                    'Le jeu commence dans...',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameInterface() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Text(
                  'Jeu Multijoueur',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Salle ${_currentRoomIndex + 1}/${_gameRooms.length}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInfoCard(
                      'Joueurs',
                      '${_playersData.length} joueurs',
                      Icons.people,
                    ),
                    _buildInfoCard(
                      'Mode',
                      'Multijoueur',
                      Icons.group,
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),
          
          // Salle actuelle
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.play_circle_filled,
                  color: Colors.green,
                  size: 50,
                ),
                const SizedBox(height: 15),
                Text(
                  _gameRooms[_currentRoomIndex]['name'],
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Cliquez pour commencer cette salle',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _navigateToRoom(_currentRoomIndex),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Commencer la Salle'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // Bouton de debug
                ElevatedButton.icon(
                  onPressed: _debugSkipToNotifications,
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Debug: Aller aux Notifications'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.7), size: 30),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
