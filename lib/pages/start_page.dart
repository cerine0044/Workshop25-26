import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'page1_puzzle.dart';
import '../services/http_game_service.dart';

class StartPage extends StatefulWidget {
  final bool isMultiplayer;
  final String? roomId;
  
  const StartPage({super.key, this.isMultiplayer = false, this.roomId});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Variables pour le chrono et la synchronisation
  Timer? _countdownTimer;
  int _countdown = 3;
  bool _showCountdown = false;
  bool _gameStarted = false;
  bool _isWaitingForOtherPlayer = false;
  
  // Variables pour le multijoueur
  Map<String, dynamic>? _roomData;
  StreamSubscription<Map<String, dynamic>?>? _roomSubscription;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat();
    
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

    // Si mode multijoueur, écouter les changements de room
    if (widget.isMultiplayer && widget.roomId != null) {
      _listenToRoom();
    }
  }

  void _listenToRoom() {
    _roomSubscription = HttpGameService().listenToRoom(widget.roomId!).listen((roomData) {
      setState(() {
        _roomData = roomData;
      });
      
      // Vérifier si les deux joueurs sont prêts
      _checkPlayersReady();
    });
  }

  void _checkPlayersReady() {
    if (_roomData == null) return;
    
    final players = Map<String, dynamic>.from(_roomData!['players'] ?? {});
    final playerCount = players.length;
    
    // Si on a 2 joueurs et qu'on attend l'autre joueur
    if (playerCount == 2 && _isWaitingForOtherPlayer) {
      setState(() {
        _isWaitingForOtherPlayer = false;
      });
      _startGameCountdown();
    }
  }

  void _startGame() {
    if (widget.isMultiplayer) {
      // Mode multijoueur : vérifier si on est 2 joueurs
      if (_roomData != null) {
        final players = Map<String, dynamic>.from(_roomData!['players'] ?? {});
        if (players.length == 2) {
          _startGameCountdown();
        } else {
          setState(() {
            _isWaitingForOtherPlayer = true;
          });
          _showWaitingDialog();
        }
      }
    } else {
      // Mode solo : démarrer directement
      _startGameCountdown();
    }
  }

  void _showWaitingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('⏳ En attente'),
        content: const Text('En attente du deuxième joueur...'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Retour à la page précédente
            },
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _startGameCountdown() {
    setState(() {
      _showCountdown = true;
      _countdown = 3;
      _gameStarted = true;
    });

    // Effet haptique
    HapticFeedback.heavyImpact();

    // Mettre à jour l'état du jeu sur le serveur si multijoueur
    if (widget.isMultiplayer && widget.roomId != null) {
      HttpGameService().updateGameState(widget.roomId!, 'starting');
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdown--;
      });

      // Effet haptique à chaque seconde
      HapticFeedback.mediumImpact();

      if (_countdown <= 0) {
        timer.cancel();
        _redirectToGame();
      }
    });
  }

  void _redirectToGame() {
    setState(() {
      _showCountdown = false;
    });

    // Mettre à jour l'état du jeu sur le serveur si multijoueur
    if (widget.isMultiplayer && widget.roomId != null) {
      HttpGameService().updateGameState(widget.roomId!, 'playing');
    }

    // Rediriger vers la page de jeu
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => Page1Puzzle(
          isMultiplayer: widget.isMultiplayer,
          roomId: widget.roomId,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    _countdownTimer?.cancel();
    _roomSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Arrière-plan mystérieux
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final double t = _controller.value;
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(
                        math.sin(t * math.pi * 2) * 0.4,
                        math.cos(t * math.pi * 2) * 0.4,
                      ),
                      radius: 1.2,
                      colors: [
                        Colors.black,
                        Color.lerp(Colors.blueGrey.shade900, Colors.deepPurple.shade900, (0.5 + 0.5 * math.sin(t * 6)).clamp(0.0, 1.0))!,
                        Color.lerp(Colors.indigo, Colors.deepPurple, (0.5 + 0.5 * math.cos(t * 5)).clamp(0.0, 1.0))!,
                      ],
                      stops: const [0.2, 0.65, 1.0],
                    ),
                  ),
                );
              },
            ),

            // Titre
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'PANDORA BOX',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                        letterSpacing: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.isMultiplayer ? 'Mode Multijoueur' : 'Mode Solo',
                      style: const TextStyle(
                        color: Colors.yellowAccent,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Interface principale
            if (_showCountdown)
              _buildCountdownScreen()
            else
              _buildStartScreen(),

            // Footer
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isWaitingForOtherPlayer 
                        ? 'En attente du deuxième joueur...'
                        : 'Chrono: commence dès que tu appuies sur START',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                    if (widget.isMultiplayer && _roomData != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Joueurs: ${Map<String, dynamic>.from(_roomData!['players'] ?? {}).length}/2',
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStartScreen() {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final double t = _controller.value;
          final double pulse = 1.0 + 0.05 * math.sin(t * math.pi * 2);
          
          return Transform.scale(
            scale: pulse,
            child: GestureDetector(
              onTap: _gameStarted ? null : _startGame,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 22),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _gameStarted 
                      ? Colors.grey.withOpacity(0.5)
                      : Colors.redAccent.withOpacity(0.8), 
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _gameStarted 
                        ? Colors.grey.withOpacity(0.3)
                        : Colors.redAccent.withOpacity(0.5 + 0.3 * math.sin(t * 6)), 
                      blurRadius: 28, 
                      spreadRadius: 2,
                    ),
                  ],
                  gradient: LinearGradient(
                    colors: _gameStarted ? [
                      Colors.grey.withOpacity(0.3),
                      Colors.grey.withOpacity(0.1),
                    ] : [
                      Colors.redAccent.withOpacity(0.85),
                      Colors.deepPurpleAccent.withOpacity(0.6),
                    ],
                  ),
                ),
                child: Text(
                  _gameStarted ? 'DÉMARRAGE...' : 'START',
                  style: TextStyle(
                    color: _gameStarted ? Colors.grey : Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCountdownScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'DÉMARRAGE DU JEU',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 40),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.red.withOpacity(0.2),
              border: Border.all(
                color: Colors.red,
                width: 4,
              ),
            ),
            child: Center(
              child: Text(
                '$_countdown',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 80,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'Préparez-vous !',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.isMultiplayer 
              ? 'Redirection vers la Salle 1 (Multijoueur)...'
              : 'Redirection vers la Salle 1...',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
