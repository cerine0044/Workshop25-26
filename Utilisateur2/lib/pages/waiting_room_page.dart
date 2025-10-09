import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_multiplayer_service.dart';
import '../widgets/chat_widget.dart';

class WaitingRoomPage extends StatefulWidget {
  final String roomCode;
  final String roomName;
  final bool isHost;

  const WaitingRoomPage({
    super.key,
    required this.roomCode,
    required this.roomName,
    required this.isHost,
  });

  @override
  State<WaitingRoomPage> createState() => _WaitingRoomPageState();
}

class _WaitingRoomPageState extends State<WaitingRoomPage>
    with TickerProviderStateMixin {
  final FirebaseMultiplayerService _multiplayerService = FirebaseMultiplayerService();
  
  Map<String, dynamic>? _currentRoom;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _showChat = false;
  
  // Animations
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeRoomConnection();
  }

  void _initializeRoomConnection() async {
    try {
      // S'assurer que le service est initialisé
      await _multiplayerService.initialize();
      
      // Écouter les mises à jour de la room
      _listenToRoomUpdates();
      
      // Forcer un rafraîchissement initial
      _refreshRoomData();
      
    } catch (e) {
      print('❌ Erreur initialisation connexion room: $e');
      _showErrorMessage('Erreur de connexion à la room');
    }
  }

  void _refreshRoomData() async {
    try {
      print('🔄 Rafraîchissement des données de la room...');
      
      // Utiliser la méthode du service Firebase pour forcer le rafraîchissement
      await _multiplayerService.refreshRoomData();
      
      if (mounted) {
        _showSuccessMessage('Données actualisées');
      }
    } catch (e) {
      print('❌ Erreur rafraîchissement room: $e');
      if (mounted) {
        _showErrorMessage('Erreur lors de l\'actualisation');
      }
    }
  }
  
  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
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
      curve: Curves.easeOutCubic,
    ));
    
    _fadeController.forward();
    _slideController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _listenToRoomUpdates() {
    _multiplayerService.roomStateStream.listen(
      (room) {
        if (mounted) {
          print('📡 Mise à jour room reçue: ${room?['name']} - ${room?['players']?.length ?? 0} joueur(s)');
          setState(() {
            _currentRoom = room;
          });
        }
      },
      onError: (error) {
        print('❌ Erreur écoute room: $error');
        if (mounted) {
          _showErrorMessage('Erreur de connexion: $error');
        }
      },
    );
  }

  void _showErrorMessage(String message) {
    setState(() {
      _errorMessage = message;
      _successMessage = null;
    });
    HapticFeedback.heavyImpact();
    
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  void _showSuccessMessage(String message) {
    setState(() {
      _successMessage = message;
      _errorMessage = null;
    });
    HapticFeedback.lightImpact();
    
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _successMessage = null;
        });
      }
    });
  }

  void _leaveRoom() async {
    try {
      HapticFeedback.mediumImpact();
      await _multiplayerService.leaveRoom();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorMessage('Erreur quitter room: $e');
    }
  }

  void _startGame() async {
    if (widget.isHost && _currentRoom != null) {
      final players = _currentRoom!['players'] as Map<String, dynamic>? ?? {};
      if (players.length >= 2) {
        try {
          HapticFeedback.mediumImpact();
          _showSuccessMessage('Démarrage du jeu...');
          
          // Mettre à jour l'état de la room pour démarrer le jeu
          await _multiplayerService.startGame();
          
          // Attendre un peu puis naviguer vers le jeu
          await Future.delayed(const Duration(seconds: 1));
          
          if (mounted) {
            // Pour l'instant, on reste dans la salle d'attente
            // mais on pourrait naviguer vers une page de jeu
            _showSuccessMessage('Jeu démarré ! En attente de développement...');
          }
        } catch (e) {
          _showErrorMessage('Erreur démarrage jeu: $e');
        }
      } else {
        _showErrorMessage('Il faut au moins 2 joueurs pour commencer');
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final players = _currentRoom?['players'] as Map<String, dynamic>? ?? {};
    final playerList = players.values.toList();
    final playerCount = playerList.length;
    final maxPlayers = _currentRoom?['maxPlayers'] ?? 2;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      appBar: AppBar(
        backgroundColor: Colors.red.shade700,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _leaveRoom,
        ),
        title: const Text(
          'Salle d\'Attente',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showChat ? Icons.chat : Icons.chat_bubble_outline,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showChat = !_showChat;
              });
              HapticFeedback.lightImpact();
            },
            tooltip: _showChat ? 'Masquer le chat' : 'Afficher le chat',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshRoomData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Column(
        children: [
          // Contenu principal
          Expanded(
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Messages de statut
                          if (_errorMessage != null)
                            _buildStatusMessage(_errorMessage!, Colors.red),
                          if (_successMessage != null)
                            _buildStatusMessage(_successMessage!, Colors.green),
                          
                          const SizedBox(height: 20),
                          
                          // Informations de la room
                          _buildRoomInfo(),
                          
                          const SizedBox(height: 30),
                          
                          // Animation d'attente
                          _buildWaitingAnimation(),
                          
                          const SizedBox(height: 30),
                          
                          // Liste des joueurs
                          _buildPlayersList(playerList),
                          
                          const SizedBox(height: 30),
                          
                          // Boutons d'action
                          _buildActionButtons(playerCount, maxPlayers),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Chat widget
          if (_showChat)
            _buildChatWidget(),
        ],
      ),
    );
  }

  Widget _buildStatusMessage(String message, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            color == Colors.red ? Icons.error : Icons.check_circle,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomInfo() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.meeting_room, color: Colors.blue.shade400, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.roomName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Code: ${widget.roomCode}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.yellow.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildInfoCard('Joueurs', '${_currentRoom?['players']?.length ?? 0}/${_currentRoom?['maxPlayers'] ?? 2}', Icons.people),
              _buildInfoCard('Statut', widget.isHost ? 'Hôte' : 'Invité', Icons.person),
              _buildInfoCard('Connexion', _currentRoom != null ? 'Connecté' : 'Déconnecté', _currentRoom != null ? Icons.wifi : Icons.wifi_off),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.7), size: 20),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingAnimation() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.blue.shade400.withOpacity(0.3),
                  Colors.blue.shade600.withOpacity(0.1),
                ],
              ),
            ),
            child: const Icon(
              Icons.hourglass_empty,
              size: 60,
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlayersList(List<dynamic> playerList) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.people, color: Colors.purple.shade400, size: 24),
              const SizedBox(width: 12),
              Text(
                'Joueurs connectés (${playerList.length})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (playerList.isEmpty)
            Center(
              child: Text(
                'En attente de joueurs...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            ...playerList.map((player) => _buildPlayerCard(player)).toList(),
        ],
      ),
    );
  }

  Widget _buildPlayerCard(Map<String, dynamic> player) {
    final isHost = player['isHost'] == true;
    final isCurrentPlayer = player['id'] == _multiplayerService.currentPlayerId;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCurrentPlayer 
          ? Colors.blue.withOpacity(0.2)
          : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentPlayer 
            ? Colors.blue.withOpacity(0.5)
            : Colors.white.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: isHost ? Colors.orange.shade400 : Colors.blue.shade400,
            child: Text(
              (player['name'] ?? 'Joueur').substring(0, 1).toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player['name'] ?? 'Joueur',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (isCurrentPlayer)
                  Text(
                    'Vous',
                    style: TextStyle(
                      color: Colors.blue.shade300,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (isHost)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.shade600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'HÔTE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(int playerCount, int maxPlayers) {
    return Column(
      children: [
        if (widget.isHost && playerCount >= 2)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startGame,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Commencer le Jeu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        
        if (widget.isHost && playerCount < 2)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange.shade400),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'En attente d\'un autre joueur pour commencer...',
                    style: TextStyle(
                      color: Colors.orange.shade300,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 16),
        
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _leaveRoom,
            icon: const Icon(Icons.exit_to_app),
            label: const Text('Quitter la Salle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatWidget() {
    // Obtenir les informations du joueur actuel
    final players = _currentRoom?['players'] as Map<String, dynamic>? ?? {};
    String? currentPlayerId;
    String? currentPlayerName;
    
    // Trouver le joueur actuel
    players.forEach((playerId, playerData) {
      if (playerData is Map && playerData['isCurrentPlayer'] == true) {
        currentPlayerId = playerId;
        currentPlayerName = playerData['name'];
      }
    });
    
    // Si pas trouvé, utiliser les valeurs par défaut
    currentPlayerId ??= 'player_${DateTime.now().millisecondsSinceEpoch}';
    currentPlayerName ??= widget.isHost ? 'Hôte' : 'Joueur';
    
    return ChatWidget(
      roomCode: widget.roomCode,
      playerId: currentPlayerId!,
      playerName: currentPlayerName!,
      isHost: widget.isHost,
    );
  }
}
