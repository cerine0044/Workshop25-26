import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/enhanced_room_service.dart';

class MultiplayerGamePage extends StatefulWidget {
  final Room room;
  
  const MultiplayerGamePage({
    super.key,
    required this.room,
  });

  @override
  State<MultiplayerGamePage> createState() => _MultiplayerGamePageState();
}

class _MultiplayerGamePageState extends State<MultiplayerGamePage>
    with TickerProviderStateMixin {
  
  final EnhancedRoomService _roomService = EnhancedRoomService();
  
  late AnimationController _gameController;
  late AnimationController _timerController;
  late Animation<double> _gameAnimation;
  late Animation<double> _timerAnimation;
  
  Timer? _gameTimer;
  int _timeRemaining = 300; // 5 minutes par défaut
  int _currentRound = 1;
  int _totalRounds = 5;
  Map<String, int> _playerScores = {};
  String _currentGameState = 'waiting';
  List<String> _gameMessages = [];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeGame();
  }
  
  void _initializeAnimations() {
    _gameController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _timerController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat();
    
    _gameAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _gameController,
      curve: Curves.easeInOut,
    ));
    
    _timerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _timerController,
      curve: Curves.linear,
    ));
  }
  
  void _initializeGame() {
    // Initialiser les scores des joueurs
    for (final player in widget.room.playersList) {
      _playerScores[player.id] = 0;
    }
    
    // Écouter les changements de la room
    _roomService.roomStateStream.listen((state) {
      if (state is RoomStateJoined) {
        setState(() {
          // Mettre à jour l'état du jeu basé sur les données de la room
          _currentGameState = state.room.gameState.name;
        });
      }
    });
    
    // Démarrer le jeu si c'est l'hôte
    if (widget.room.hostId == _roomService.currentPlayerId) {
      _startGame();
    }
  }
  
  void _startGame() {
    setState(() {
      _currentGameState = 'playing';
      _timeRemaining = widget.room.gameSettings['timeLimit'] ?? 300;
    });
    
    _gameController.forward();
    _startGameTimer();
    _addGameMessage('🎮 Le jeu a commencé!');
  }
  
  void _startGameTimer() {
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining--;
      });
      
      if (_timeRemaining <= 0) {
        _endRound();
      }
    });
  }
  
  void _endRound() {
    _gameTimer?.cancel();
    setState(() {
      _currentGameState = 'round_end';
    });
    
    _addGameMessage('⏰ Temps écoulé pour le round $_currentRound!');
    
    // Passer au round suivant ou terminer le jeu
    if (_currentRound < _totalRounds) {
      Timer(const Duration(seconds: 3), () {
        _nextRound();
      });
    } else {
      _endGame();
    }
  }
  
  void _nextRound() {
    setState(() {
      _currentRound++;
      _timeRemaining = widget.room.gameSettings['timeLimit'] ?? 300;
      _currentGameState = 'playing';
    });
    
    _startGameTimer();
    _addGameMessage('🎯 Round $_currentRound/$_totalRounds commencé!');
  }
  
  void _endGame() {
    _gameTimer?.cancel();
    setState(() {
      _currentGameState = 'finished';
    });
    
    _addGameMessage('🏆 Jeu terminé!');
    
    // Déterminer le gagnant
    final winner = _playerScores.entries.reduce((a, b) => a.value > b.value ? a : b);
    _addGameMessage('🎉 ${_getPlayerName(winner.key)} a gagné avec ${winner.value} points!');
  }
  
  void _addGameMessage(String message) {
    setState(() {
      _gameMessages.insert(0, '${DateTime.now().toString().substring(11, 19)} - $message');
      if (_gameMessages.length > 10) {
        _gameMessages.removeLast();
      }
    });
  }
  
  String _getPlayerName(String playerId) {
    final player = widget.room.players[playerId];
    return player?.name ?? 'Joueur inconnu';
  }
  
  void _updateScore(String playerId, int points) {
    setState(() {
      _playerScores[playerId] = (_playerScores[playerId] ?? 0) + points;
    });
    
    _addGameMessage('${_getPlayerName(playerId)} a gagné $points points!');
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // En-tête du jeu
            _buildGameHeader(),
            
            // Contenu principal
            Expanded(
              child: _currentGameState == 'waiting'
                  ? _buildWaitingScreen()
                  : _currentGameState == 'playing'
                      ? _buildGameScreen()
                      : _currentGameState == 'round_end'
                          ? _buildRoundEndScreen()
                          : _buildGameEndScreen(),
            ),
            
            // Messages du jeu
            _buildGameMessages(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGameHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.withOpacity(0.3), Colors.blue.withOpacity(0.3)],
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          // Informations de la room
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.room.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Round $_currentRound/$_totalRounds',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          
          // Timer
          _buildTimer(),
          
          // Bouton retour
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimer() {
    final minutes = _timeRemaining ~/ 60;
    final seconds = _timeRemaining % 60;
    final isLowTime = _timeRemaining <= 30;
    
    return AnimatedBuilder(
      animation: _timerAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isLowTime ? Colors.red.withOpacity(0.3) : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLowTime ? Colors.red : Colors.white.withOpacity(0.3),
            ),
          ),
          child: Text(
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
            style: TextStyle(
              color: isLowTime ? Colors.red : Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildWaitingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.hourglass_empty,
            size: 80,
            color: Colors.white54,
          ),
          const SizedBox(height: 24),
          const Text(
            'En attente du début du jeu...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'L\'hôte va démarrer le jeu bientôt',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          _buildPlayersList(),
        ],
      ),
    );
  }
  
  Widget _buildGameScreen() {
    return AnimatedBuilder(
      animation: _gameAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.9 + 0.1 * _gameAnimation.value,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Zone de jeu principale
                Expanded(
                  flex: 3,
                  child: _buildGameArea(),
                ),
                
                const SizedBox(height: 20),
                
                // Scores des joueurs
                Expanded(
                  flex: 2,
                  child: _buildScoresList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildGameArea() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            Colors.blue.withOpacity(0.3),
            Colors.purple.withOpacity(0.2),
            Colors.black,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '🎮',
              style: TextStyle(fontSize: 80),
            ),
            const SizedBox(height: 16),
            const Text(
              'Zone de jeu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Round $_currentRound',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildGameButton('Action 1', Colors.green, () => _performAction(1)),
                _buildGameButton('Action 2', Colors.blue, () => _performAction(2)),
                _buildGameButton('Action 3', Colors.orange, () => _performAction(3)),
                _buildGameButton('Action 4', Colors.red, () => _performAction(4)),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGameButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(label),
    );
  }
  
  void _performAction(int actionId) {
    final currentPlayerId = _roomService.currentPlayerId;
    if (currentPlayerId != null) {
      final points = math.Random().nextInt(10) + 1;
      _updateScore(currentPlayerId, points);
    }
  }
  
  Widget _buildScoresList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scores',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _playerScores.length,
              itemBuilder: (context, index) {
                final entry = _playerScores.entries.elementAt(index);
                final player = widget.room.players[entry.key];
                final isCurrentPlayer = entry.key == _roomService.currentPlayerId;
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isCurrentPlayer ? Colors.blue.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCurrentPlayer ? Colors.blue : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        player?.avatar ?? '👤',
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          player?.name ?? 'Joueur',
                          style: TextStyle(
                            color: isCurrentPlayer ? Colors.blue : Colors.white,
                            fontWeight: isCurrentPlayer ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      Text(
                        '${entry.value} pts',
                        style: TextStyle(
                          color: isCurrentPlayer ? Colors.blue : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlayersList() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Joueurs connectés',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.room.playersList.map((player) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(player.avatar, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      player.name,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    if (player.isHost) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.star, color: Colors.yellow, size: 12),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRoundEndScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.pause_circle,
            size: 80,
            color: Colors.orange,
          ),
          const SizedBox(height: 24),
          const Text(
            'Round terminé!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Round $_currentRound/$_totalRounds',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          _buildScoresList(),
        ],
      ),
    );
  }
  
  Widget _buildGameEndScreen() {
    final winner = _playerScores.entries.reduce((a, b) => a.value > b.value ? a : b);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.emoji_events,
            size: 80,
            color: Colors.yellow,
          ),
          const SizedBox(height: 24),
          const Text(
            'Jeu terminé!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '🏆 ${_getPlayerName(winner.key)} a gagné!',
            style: const TextStyle(
              color: Colors.yellow,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          _buildScoresList(),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Retour aux rooms'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGameMessages() {
    if (_gameMessages.isEmpty) return const SizedBox.shrink();
    
    return Container(
      height: 120,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Messages du jeu',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _gameMessages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    _gameMessages[index],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _gameController.dispose();
    _timerController.dispose();
    _gameTimer?.cancel();
    super.dispose();
  }
}
