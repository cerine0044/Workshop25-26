import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'stress_page.dart';

class Page1Puzzle extends StatefulWidget {
  const Page1Puzzle({super.key});

  @override
  State<Page1Puzzle> createState() => _Page1PuzzleState();
}

class _Page1PuzzleState extends State<Page1Puzzle> with TickerProviderStateMixin {
  late AnimationController _sequenceController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // État du jeu de mémoire
  List<int> _sequence = [];
  List<int> _playerSequence = [];
  int _currentStep = 0;
  bool _isShowingSequence = false;
  bool _isPlayerTurn = false;
  bool _gameCompleted = false;
  bool _gameStarted = false;
  int _score = 0;
  int _maxSteps = 3;

  // Couleurs des boutons
  final List<Color> _buttonColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
  ];

  final List<String> _buttonSounds = [
    'note1',
    'note2', 
    'note3',
    'note4',
  ];

  @override
  void initState() {
    super.initState();
    
    _sequenceController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _sequenceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _gameStarted = true;
      _sequence = [];
      _playerSequence = [];
      _currentStep = 0;
      _score = 0;
      _gameCompleted = false;
    });
    
    _generateSequence();
    _showSequence();
  }

  void _generateSequence() {
    final random = math.Random();
    _sequence = List.generate(_maxSteps, (index) => random.nextInt(4));
  }

  Future<void> _showSequence() async {
    setState(() {
      _isShowingSequence = true;
      _isPlayerTurn = false;
    });

    // Attendre un peu avant de commencer
    await Future.delayed(const Duration(milliseconds: 500));

    for (int i = 0; i < _sequence.length; i++) {
      if (!mounted) return;
      
      final buttonIndex = _sequence[i];
      
      // Animer le bouton
      await _animateButton(buttonIndex);
      
      // Pause entre les boutons
      if (i < _sequence.length - 1) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }

    // Attendre un peu avant que le joueur puisse jouer
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _isShowingSequence = false;
      _isPlayerTurn = true;
      _playerSequence = [];
    });
  }

  Future<void> _animateButton(int buttonIndex) async {
    // Effet visuel
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });
    
    // Effet haptique
    HapticFeedback.mediumImpact();
    
    // Son (simulation)
    await Future.delayed(const Duration(milliseconds: 200));
  }

  void _onButtonPressed(int buttonIndex) {
    if (!_isPlayerTurn || _isShowingSequence) return;
    
    setState(() {
      _playerSequence.add(buttonIndex);
    });
    
    // Effet haptique
    HapticFeedback.lightImpact();
    
    // Vérifier si la séquence est correcte
    _checkSequence();
  }

  void _checkSequence() {
    final currentStep = _playerSequence.length - 1;
    
    if (_playerSequence[currentStep] != _sequence[currentStep]) {
      // Mauvaise réponse
      _gameOver();
      return;
    }
    
    if (_playerSequence.length == _sequence.length) {
      // Séquence complète correcte
      _nextLevel();
    }
  }

  void _nextLevel() {
    setState(() {
      _score++;
      _currentStep++;
      _playerSequence = [];
    });
    
    // Effet de réussite
    HapticFeedback.heavyImpact();
    
    if (_currentStep >= _maxSteps) {
      // Jeu terminé avec succès
      setState(() {
        _gameCompleted = true;
      });
      
      // Animation de victoire
      _celebrateVictory();
    } else {
      // Passer au niveau suivant
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted) {
          _showSequence();
        }
      });
    }
  }

  void _gameOver() {
    setState(() {
      _isPlayerTurn = false;
    });
    
    // Effet d'échec
    HapticFeedback.heavyImpact();
    
    // Montrer dialogue d'échec
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Échec !'),
        content: Text('Tu as fait une erreur à l\'étape ${_playerSequence.length}.\nScore: $_score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetGame();
            },
            child: const Text('Recommencer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StressPage()),
              );
            },
            child: const Text('Continuer quand même'),
          ),
        ],
      ),
    );
  }

  void _celebrateVictory() {
    // Animation de victoire
    _pulseController.repeat(reverse: true);
    
    // Son de victoire (simulation)
    HapticFeedback.heavyImpact();
    
    // Montrer dialogue de victoire
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('🎉 Victoire !'),
            content: Text('Félicitations ! Tu as réussi la séquence de mémoire.\nScore final: $_score'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const StressPage()),
                  );
                },
                child: const Text('Continuer'),
              ),
            ],
          ),
        );
      }
    });
  }

  void _resetGame() {
    setState(() {
      _gameStarted = false;
      _sequence = [];
      _playerSequence = [];
      _currentStep = 0;
      _score = 0;
      _gameCompleted = false;
      _isShowingSequence = false;
      _isPlayerTurn = false;
    });
    
    _pulseController.stop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('SALLE 1 - JEU DE MÉMOIRE'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetGame,
            tooltip: 'Recommencer',
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Arrière-plan mystérieux
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [
                      Colors.black,
                      Colors.deepPurple.shade900,
                      Colors.indigo.shade900,
                    ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                ),
              ),
            ),

            // Interface principale
            Column(
              children: [
                // Barre d'information
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.deepPurple),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _gameStarted 
                          ? 'Étape ${_currentStep + 1}/$_maxSteps'
                          : 'Jeu de Mémoire - 3 Étapes',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_gameStarted) ...[
                        LinearProgressIndicator(
                          value: (_currentStep + 1) / _maxSteps,
                          backgroundColor: Colors.grey.shade800,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _gameCompleted ? Colors.green : Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Score: $_score',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      if (!_gameStarted) ...[
                        ElevatedButton.icon(
                          onPressed: _startGame,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Commencer'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ] else if (_isShowingSequence) ...[
                        const Text(
                          'Regarde la séquence...',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ] else if (_isPlayerTurn) ...[
                        const Text(
                          'Reproduis la séquence !',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Zone de jeu - Grille 2x2
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        return _buildMemoryButton(index);
                      },
                    ),
                  ),
                ),

                // Boutons de debug
                Container(
                  margin: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const StressPage()),
                          );
                        },
                        icon: const Icon(Icons.bug_report),
                        label: const Text('Debug Page 2'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _gameCompleted ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const StressPage()),
                          );
                        } : null,
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Continuer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gameCompleted ? Colors.green : Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoryButton(int index) {
    final isActive = _isShowingSequence && 
                     _sequence.isNotEmpty && 
                     _sequence[_playerSequence.length] == index;
    
    final isPressed = _isPlayerTurn && 
                     _playerSequence.isNotEmpty && 
                     _playerSequence.last == index;
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isActive ? _pulseAnimation.value : 1.0,
          child: GestureDetector(
            onTap: () => _onButtonPressed(index),
            child: Container(
              decoration: BoxDecoration(
                color: isActive || isPressed 
                  ? _buttonColors[index].withOpacity(0.8)
                  : _buttonColors[index].withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive || isPressed 
                    ? _buttonColors[index]
                    : _buttonColors[index].withOpacity(0.5),
                  width: 3,
                ),
                boxShadow: isActive || isPressed ? [
                  BoxShadow(
                    color: _buttonColors[index].withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ] : null,
              ),
              child: Center(
                child: Icon(
                  Icons.circle,
                  color: isActive || isPressed 
                    ? Colors.white
                    : _buttonColors[index].withOpacity(0.7),
                  size: 40,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}