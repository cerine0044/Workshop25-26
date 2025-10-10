import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_multiplayer_service.dart';
import '../services/game_stats_service.dart';

class MultiplayerSuccessPage extends StatefulWidget {
  final Map<String, dynamic> playersData;
  final Map<String, Map<String, dynamic>> playerSessions;

  const MultiplayerSuccessPage({
    super.key,
    required this.playersData,
    required this.playerSessions,
  });

  @override
  State<MultiplayerSuccessPage> createState() => _MultiplayerSuccessPageState();
}

class _MultiplayerSuccessPageState extends State<MultiplayerSuccessPage>
    with TickerProviderStateMixin {
  final FirebaseMultiplayerService _multiplayerService = FirebaseMultiplayerService();
  final GameStatsService _gameStatsService = GameStatsService();
  
  // Animations
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _celebrationController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _celebrationAnimation;
  
  // Données calculées
  List<Map<String, dynamic>> _playersResults = [];
  String? _winner;
  Duration _totalGameTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _calculateResults();
    _saveGameResults();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    _celebrationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _celebrationController,
      curve: Curves.elasticOut,
    ));
    
    // Démarrer les animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      _celebrationController.forward();
    });
  }

  void _calculateResults() {
    final List<Map<String, dynamic>> results = [];
    
    // Utiliser les sessions des joueurs directement
    widget.playerSessions.forEach((playerName, sessionData) {
      final totalScore = sessionData['totalScore'] ?? 0;
      final totalTime = Duration(seconds: sessionData['totalTime'] ?? 0);
      final completed = sessionData['completed'] ?? false;
      final rooms = sessionData['rooms'] as Map<String, dynamic>? ?? {};
      
      final List<Map<String, dynamic>> roomResults = [];
      rooms.forEach((roomName, roomData) {
        roomResults.add({
          'roomName': roomName,
          'score': roomData['score'] ?? 0,
          'time': Duration(seconds: roomData['time'] ?? 0),
          'completed': roomData['completed'] ?? false,
        });
      });
      
      results.add({
        'playerName': playerName,
        'totalScore': totalScore,
        'totalTime': totalTime,
        'completedRooms': roomResults.length,
        'completed': completed,
        'roomResults': roomResults,
      });
    });
    
    // Trier par score décroissant
    results.sort((a, b) => (b['totalScore'] as int).compareTo(a['totalScore'] as int));
    
    setState(() {
      _playersResults = results;
      _winner = results.isNotEmpty ? results.first['playerName'] : null;
      
      // Calculer le temps total de jeu
      _totalGameTime = results.fold<Duration>(
        Duration.zero,
        (sum, result) => sum + (result['totalTime'] as Duration),
      );
    });
  }

  void _saveGameResults() {
    // Les résultats sont déjà sauvegardés dans GameStatsService
    // lors de la fin de chaque salle
    debugPrint('🎮 Résultats multijoueur sauvegardés');
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Titre avec animation de célébration
                  AnimatedBuilder(
                    animation: _celebrationAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 0.8 + (0.2 * _celebrationAnimation.value),
                        child: Column(
                          children: [
                            Text(
                              '🎉 Partie Terminée !',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Colors.deepPurple.withOpacity(0.5),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_winner != null)
                              Text(
                                '🏆 Gagnant: $_winner',
                                style: const TextStyle(
                                  color: Colors.amber,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Statistiques générales
                  Card(
                    color: Colors.grey.shade900,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          const Text(
                            '📊 Statistiques Générales',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatCard('Joueurs', '${_playersResults.length}', Icons.people),
                              _buildStatCard('Temps Total', _formatDuration(_totalGameTime), Icons.timer),
                              _buildStatCard('Salles', '5', Icons.door_front_door),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Résultats des joueurs
                  if (_playersResults.isNotEmpty)
                    ..._playersResults.asMap().entries.map((entry) {
                      final index = entry.key;
                      final player = entry.value;
                      return _buildPlayerCard(player, index);
                    }).toList(),
                  
                  const SizedBox(height: 30),
                  
                  // Boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        icon: const Icon(Icons.home),
                        label: const Text('Accueil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Rejouer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepPurple, size: 30),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player, int index) {
    final isWinner = index == 0;
    final playerName = player['playerName'] as String;
    final totalScore = player['totalScore'] as int;
    final totalTime = player['totalTime'] as Duration;
    final completedRooms = player['completedRooms'] as int;
    final roomResults = player['roomResults'] as List<Map<String, dynamic>>;
    
    return Card(
      color: isWinner ? Colors.amber.withOpacity(0.1) : Colors.grey.shade900,
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du joueur
            Row(
              children: [
                if (isWinner) const Icon(Icons.emoji_events, color: Colors.amber, size: 30),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    playerName,
                    style: TextStyle(
                      color: isWinner ? Colors.amber : Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '#${index + 1}',
                  style: TextStyle(
                    color: isWinner ? Colors.amber : Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 15),
            
            // Statistiques du joueur
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildPlayerStat('Score', totalScore.toString(), Icons.star),
                _buildPlayerStat('Temps', _formatDuration(totalTime), Icons.timer),
                _buildPlayerStat('Salles', '$completedRooms/5', Icons.door_front_door),
              ],
            ),
            
            const SizedBox(height: 15),
            
            // Détails des salles
            const Text(
              'Détails des Salles:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            
            ...roomResults.map((room) => _buildRoomResult(room)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerStat(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.deepPurple, size: 20),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildRoomResult(Map<String, dynamic> room) {
    final roomName = room['roomName'] as String;
    final score = room['score'] as int;
    final time = room['time'] as Duration;
    final completed = room['completed'] as bool;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: completed ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: completed ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              roomName,
              style: TextStyle(
                color: completed ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            children: [
              Text(
                '${score}pts',
                style: TextStyle(
                  color: completed ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatDuration(time),
                style: TextStyle(
                  color: completed ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}