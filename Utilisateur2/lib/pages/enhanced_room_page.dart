import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/enhanced_room_service.dart';

class EnhancedRoomPage extends StatefulWidget {
  const EnhancedRoomPage({super.key});

  @override
  State<EnhancedRoomPage> createState() => _EnhancedRoomPageState();
}

class _EnhancedRoomPageState extends State<EnhancedRoomPage> 
    with TickerProviderStateMixin {
  
  final EnhancedRoomService _roomService = EnhancedRoomService();
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _roomCodeController = TextEditingController();
  final TextEditingController _playerNameController = TextEditingController();
  
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  
  Room? _currentRoom;
  List<Room> _availableRooms = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeRoomService();
  }
  
  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
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
  }
  
  Future<void> _initializeRoomService() async {
    setState(() => _isLoading = true);
    try {
      await _roomService.initialize();
      
      // Écouter les changements d'état de la room
      _roomService.roomStateStream.listen((state) {
        setState(() {
          if (state is RoomStateJoined) {
            _currentRoom = state.room;
            _errorMessage = null;
          } else if (state is RoomStateLeft) {
            _currentRoom = null;
          } else if (state is RoomStateError) {
            _errorMessage = state.message;
          }
        });
      });
      
      // Écouter les rooms disponibles
      _roomService.availableRoomsStream.listen((rooms) {
        setState(() {
          _availableRooms = rooms;
        });
      });
      
      _fadeController.forward();
    } catch (e) {
      setState(() => _errorMessage = 'Erreur d\'initialisation: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _createRoom() async {
    if (_roomNameController.text.trim().isEmpty) {
      _showError('Veuillez entrer un nom de room');
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      await _roomService.createRoom(
        name: _roomNameController.text.trim(),
        description: 'Room créée par ${_playerNameController.text.trim().isEmpty ? "Joueur" : _playerNameController.text.trim()}',
        maxPlayers: 4,
        isPrivate: false,
        gameSettings: {
          'difficulty': 'normal',
          'timeLimit': 300, // 5 minutes
        },
      );
      _roomNameController.clear();
      _showSuccess('Room créée avec succès!');
    } catch (e) {
      _showError('Erreur lors de la création: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _joinRoom(String roomCode) async {
    if (roomCode.trim().isEmpty) {
      _showError('Veuillez entrer un code de room');
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      await _roomService.joinRoom(roomCode.trim());
      _roomCodeController.clear();
      _showSuccess('Room rejointe avec succès!');
    } catch (e) {
      _showError('Erreur lors de la connexion: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  Future<void> _leaveRoom() async {
    try {
      await _roomService.leaveRoom();
      _showSuccess('Room quittée');
    } catch (e) {
      _showError('Erreur lors de la déconnexion: $e');
    }
  }
  
  Future<void> _toggleReady() async {
    try {
      await _roomService.toggleReady();
    } catch (e) {
      _showError('Erreur lors du changement d\'état: $e');
    }
  }
  
  Future<void> _startGame() async {
    if (_currentRoom?.canStart != true) {
      _showError('Tous les joueurs doivent être prêts pour commencer');
      return;
    }
    
    try {
      await _roomService.startGame();
      _showSuccess('Jeu démarré!');
    } catch (e) {
      _showError('Erreur lors du démarrage: $e');
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text('Connexion en cours...', style: TextStyle(color: Colors.white)),
                  ],
                ),
              )
            : FadeTransition(
                opacity: _fadeAnimation,
                child: _currentRoom == null ? _buildRoomSelection() : _buildCurrentRoom(),
              ),
      ),
    );
  }
  
  Widget _buildRoomSelection() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Titre
          const Text(
            'PANDORA BOX',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Multijoueur',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 40),
          
          // Nom du joueur
          _buildInputCard(
            title: 'Votre nom',
            child: TextField(
              controller: _playerNameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Entrez votre nom',
                hintStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.white30),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Créer une room
          _buildInputCard(
            title: 'Créer une room',
            child: Column(
              children: [
                TextField(
                  controller: _roomNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Nom de la room',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.green),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildAnimatedButton(
                  'Créer Room',
                  Colors.green,
                  Icons.add,
                  _createRoom,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Rejoindre une room
          _buildInputCard(
            title: 'Rejoindre une room',
            child: Column(
              children: [
                TextField(
                  controller: _roomCodeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Code de la room',
                    hintStyle: TextStyle(color: Colors.white54),
                    border: OutlineInputBorder(),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildAnimatedButton(
                  'Rejoindre',
                  Colors.blue,
                  Icons.login,
                  () => _joinRoom(_roomCodeController.text),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Rooms disponibles
          _buildAvailableRooms(),
          
          // Message d'erreur
          if (_errorMessage != null) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildCurrentRoom() {
    if (_currentRoom == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête de la room
          _buildRoomHeader(),
          
          const SizedBox(height: 20),
          
          // Informations de la room
          _buildRoomInfo(),
          
          const SizedBox(height: 20),
          
          // Liste des joueurs
          Expanded(child: _buildPlayersList()),
          
          const SizedBox(height: 20),
          
          // Actions
          _buildRoomActions(),
        ],
      ),
    );
  }
  
  Widget _buildInputCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
  
  Widget _buildAnimatedButton(
    String text,
    Color color,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(text),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildAvailableRooms() {
    return _buildInputCard(
      title: 'Rooms disponibles (${_availableRooms.length})',
      child: _availableRooms.isEmpty
          ? const Text(
              'Aucune room disponible',
              style: TextStyle(color: Colors.white54),
            )
          : Column(
              children: _availableRooms.take(5).map((room) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              room.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${room.playerCount}/${room.maxPlayers} joueurs',
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => _joinRoom(room.code),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(80, 32),
                        ),
                        child: const Text('Rejoindre'),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
  
  Widget _buildRoomHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.withOpacity(0.3), Colors.purple.withOpacity(0.3)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentRoom!.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Code: ${_currentRoom!.code}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _leaveRoom,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRoomInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem('Joueurs', '${_currentRoom!.playerCount}/${_currentRoom!.maxPlayers}'),
          _buildInfoItem('État', _getGameStateText(_currentRoom!.gameState)),
          _buildInfoItem('Hôte', _currentRoom!.hostName),
        ],
      ),
    );
  }
  
  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
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
            'Joueurs',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _currentRoom!.playersList.length,
              itemBuilder: (context, index) {
                final player = _currentRoom!.playersList[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: player.isHost ? Colors.blue.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: player.isHost ? Colors.blue : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        player.avatar,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (player.isHost)
                              const Text(
                                'Hôte',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        player.isReady ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: player.isReady ? Colors.green : Colors.grey,
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
  
  Widget _buildRoomActions() {
    final isHost = _currentRoom!.hostId == _roomService.currentPlayerId;
    final canStart = _currentRoom!.canStart;
    
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _toggleReady,
            icon: const Icon(Icons.check),
            label: const Text('Prêt/Non prêt'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        if (isHost) ...[
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: canStart ? _startGame : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Démarrer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: canStart ? Colors.green : Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ],
    );
  }
  
  String _getGameStateText(GameState state) {
    switch (state) {
      case GameState.waiting:
        return 'En attente';
      case GameState.playing:
        return 'En cours';
      case GameState.finished:
        return 'Terminé';
    }
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _roomNameController.dispose();
    _roomCodeController.dispose();
    _playerNameController.dispose();
    _roomService.dispose();
    super.dispose();
  }
}
