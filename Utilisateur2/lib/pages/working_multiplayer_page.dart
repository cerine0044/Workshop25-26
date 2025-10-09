import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_multiplayer_service.dart';

class WorkingMultiplayerPage extends StatefulWidget {
  const WorkingMultiplayerPage({super.key});

  @override
  State<WorkingMultiplayerPage> createState() => _WorkingMultiplayerPageState();
}

class _WorkingMultiplayerPageState extends State<WorkingMultiplayerPage>
    with TickerProviderStateMixin {
  final FirebaseMultiplayerService _multiplayerService = FirebaseMultiplayerService();
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _roomIdController = TextEditingController();
  final TextEditingController _roomCodeController = TextEditingController();

  Map<String, dynamic>? _currentRoom;
  List<Map<String, dynamic>> _availableRooms = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  
  // Animations
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeMultiplayer();
  }
  
  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _scaleController.forward();
    });
  }

  Future<void> _initializeMultiplayer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔄 Initialisation du service multijoueur...');
      await _multiplayerService.initialize();
      print('✅ Service multijoueur initialisé avec succès');
      
      // Écouter les changements de room avec gestion d'erreur
      _multiplayerService.roomStateStream.listen(
        (roomData) {
          try {
            setState(() {
              _currentRoom = roomData;
              if (roomData != null && roomData['gameState'] == 'playing') {
                _showGameStartedDialog();
              }
            });
          } catch (e) {
            print('❌ Erreur stream room state: $e');
            setState(() {
              _errorMessage = 'Erreur de synchronisation: $e';
            });
          }
        },
        onError: (error) {
          print('❌ Erreur stream room state: $error');
          setState(() {
            _errorMessage = 'Erreur de connexion: $error';
          });
        },
      );

      // Écouter les rooms disponibles
      _multiplayerService.availableRoomsStream.listen(
        (rooms) {
          try {
            setState(() {
              _availableRooms = rooms;
            });
          } catch (e) {
            print('❌ Erreur stream available rooms: $e');
          }
        },
        onError: (error) {
          print('❌ Erreur stream available rooms: $error');
        },
      );

      // Rafraîchir la liste des rooms toutes les 5 secondes
      _refreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
        _refreshAvailableRooms();
      });

    } catch (e) {
      print('❌ Erreur initialisation Firebase: $e');
      setState(() {
        _errorMessage = 'Erreur d\'initialisation: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _refreshAvailableRooms() {
    // Cette méthode sera appelée automatiquement par le stream
    // Pas besoin d'implémentation supplémentaire
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        title: const Text('Mode Multijoueur'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: _buildBody(),
          ),
        ),
      ),
    );
  }
  
  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingScreen();
    }
    
    if (_currentRoom != null) {
      return _buildRoomView();
    }
    
    return _buildMainMenu();
  }
  
  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.blue.withOpacity(0.2),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.8),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.people,
                    color: Colors.blue,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Connexion au serveur...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMainMenu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête
          _buildHeader(),
          
          const SizedBox(height: 40),
          
          // Messages d'erreur/succès
          if (_errorMessage != null) _buildErrorMessage(),
          if (_successMessage != null) _buildSuccessMessage(),
          
          const SizedBox(height: 30),
          
          // Section créer une room
          _buildCreateRoomSection(),
          
          const SizedBox(height: 30),
          
          // Section rejoindre une room
          _buildJoinRoomSection(),
          
          const SizedBox(height: 30),
          
          // Liste des rooms disponibles
          _buildAvailableRoomsSection(),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(0.2),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.8),
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.people,
                  color: Colors.blue,
                  size: 50,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'Mode Multijoueur',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Jouez avec vos amis en temps réel',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
  
  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
                child: Text(
                  _errorMessage!,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () {
              setState(() {
                _errorMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildSuccessMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
                child: Text(
                  _successMessage!,
              style: const TextStyle(
                color: Colors.green,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.green),
            onPressed: () {
              setState(() {
                _successMessage = null;
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildCreateRoomSection() {
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
                      const Text(
            'Créer une Room',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _roomNameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Nom de la room',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.create, color: Colors.blue),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
              onPressed: _createRoom,
              icon: const Icon(Icons.add),
              label: const Text('Créer Room'),
                          style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                          ),
                        ),
                      ),
                    ],
                  ),
    );
  }
  
  Widget _buildJoinRoomSection() {
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
                      const Text(
            'Rejoindre une Room',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _roomCodeController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Code de la room (6 caractères)',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.vpn_key, color: Colors.green),
            ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
              onPressed: _joinRoom,
              icon: const Icon(Icons.login),
              label: const Text('Rejoindre Room'),
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
                    ],
                  ),
    );
  }
  
  Widget _buildAvailableRoomsSection() {
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
                      const Text(
                'Rooms Disponibles',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _refreshAvailableRooms,
                icon: const Icon(Icons.refresh, color: Colors.white),
              ),
            ],
                      ),
                      const SizedBox(height: 16),
                      if (_availableRooms.isEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'Aucune room disponible',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
                        )
                      else
            ..._availableRooms.map((room) => _buildRoomCard(room)),
        ],
      ),
    );
  }
  
  Widget _buildRoomCard(Map<String, dynamic> room) {
    final playerCount = (room['players'] as Map?)?.length ?? 0;
    final maxPlayers = 4; // Limite arbitraire
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.meeting_room,
            color: Colors.blue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                Text(
                  room['name'] ?? 'Room sans nom',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$playerCount/$maxPlayers joueurs',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
                          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
              room['id']?.toString().substring(0, 6) ?? 'N/A',
              style: const TextStyle(
                color: Colors.blue,
                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              _roomCodeController.text = room['id']?.toString().substring(0, 6) ?? '';
              _joinRoom();
            },
            icon: const Icon(Icons.copy, color: Colors.blue),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRoomView() {
    if (_currentRoom == null) return const SizedBox.shrink();
    
    final players = _currentRoom!['players'] as Map<String, dynamic>? ?? {};
    final playerList = players.values.toList();
    final isHost = _currentRoom!['host'] == _multiplayerService.currentPlayerId;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // En-tête de la room
          _buildRoomHeader(),
          
          const SizedBox(height: 30),
          
          // Code de la room
          _buildRoomCode(),
          
          const SizedBox(height: 30),
                      
                      // Liste des joueurs
          _buildPlayersList(playerList),
          
          const SizedBox(height: 30),
                      
                      // Boutons d'action
          _buildRoomActions(isHost),
          
          const SizedBox(height: 30),
          
          // Bouton quitter
          _buildLeaveButton(),
        ],
      ),
    );
  }
  
  Widget _buildRoomHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.meeting_room,
            color: Colors.white,
            size: 50,
          ),
          const SizedBox(height: 16),
          Text(
            _currentRoom!['name'] ?? 'Room',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Room active',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCode() {
    final roomId = _currentRoom!['id']?.toString() ?? '';
    final roomCode = roomId.length >= 6 ? roomId.substring(0, 6) : roomId;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
          children: [
          const Text(
            'Code de la Room',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
            Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
              roomCode,
              style: const TextStyle(
                fontSize: 24,
                  fontWeight: FontWeight.bold,
                color: Colors.blue,
                letterSpacing: 2,
                ),
              ),
            ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: roomCode));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Code copié dans le presse-papiers'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Copier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlayersList(List<dynamic> players) {
    return Container(
      padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Joueurs',
                  style: TextStyle(
              fontSize: 18,
                    fontWeight: FontWeight.bold,
              color: Colors.white,
                  ),
                ),
          const SizedBox(height: 16),
          ...players.map((player) => _buildPlayerCard(player)),
          ],
      ),
    );
  }

  Widget _buildPlayerCard(dynamic player) {
    final isCurrentPlayer = player['id'] == _multiplayerService.currentPlayerId;
    final isHost = player['isHost'] == true;
    final isReady = player['isReady'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentPlayer ? Colors.blue.withOpacity(0.2) : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentPlayer ? Colors.blue.withOpacity(0.5) : Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isHost ? Icons.star : Icons.person,
            color: isHost ? Colors.amber : Colors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              player['name'] ?? 'Joueur',
                      style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: isCurrentPlayer ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
          ),
                      Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
              color: isReady ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
              isReady ? 'Prêt' : 'Pas prêt',
                          style: TextStyle(
                color: isReady ? Colors.green : Colors.red,
                fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
        ],
      ),
    );
  }
  
  Widget _buildRoomActions(bool isHost) {
    return Column(
      children: [
        // Bouton Ready/Unready
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _toggleReady,
            icon: const Icon(Icons.check_circle),
            label: const Text('Prêt / Pas prêt'),
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
        
        if (isHost) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startGame,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Commencer le jeu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
                  ),
                ),
              ],
      ],
    );
  }
  
  Widget _buildLeaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _leaveRoom,
        icon: const Icon(Icons.exit_to_app),
        label: const Text('Quitter la Room'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
  
  void _createRoom() async {
    if (_roomNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer un nom de room';
      });
      return;
    }
    
    HapticFeedback.mediumImpact();
    
    try {
      final roomId = await _multiplayerService.createRoom(name: _roomNameController.text.trim());
      setState(() {
        _successMessage = 'Room créée avec succès !';
        _errorMessage = null;
      });
      
      // Le stream va automatiquement mettre à jour _currentRoom
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la création: $e';
      });
    }
  }
  
  void _joinRoom() async {
    if (_roomCodeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer un code de room';
      });
      return;
    }
    
    HapticFeedback.mediumImpact();
    
    try {
      await _multiplayerService.joinRoom(_roomCodeController.text.trim());
      setState(() {
        _successMessage = 'Room rejoint avec succès !';
        _errorMessage = null;
      });
      
      // Le stream va automatiquement mettre à jour _currentRoom
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la connexion: $e';
      });
    }
  }
  
  void _toggleReady() async {
    HapticFeedback.lightImpact();
    
    try {
      final currentPlayer = _currentRoom!['players'][_multiplayerService.currentPlayerId];
      final isReady = currentPlayer?['isReady'] == true;
      
      await _multiplayerService.toggleReady();
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du changement d\'état: $e';
      });
    }
  }
  
  void _startGame() async {
    HapticFeedback.heavyImpact();
    
    try {
      await _multiplayerService.startGame();
      setState(() {
        _successMessage = 'Jeu démarré !';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du démarrage: $e';
      });
    }
  }
  
  void _leaveRoom() async {
    HapticFeedback.mediumImpact();
    
    try {
      await _multiplayerService.leaveRoom();
      setState(() {
        _currentRoom = null;
        _successMessage = 'Room quittée';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la sortie: $e';
      });
    }
  }
  
  void _showGameStartedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Jeu Démarré !',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Le jeu a commencé. Bonne chance !',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Ici vous pouvez naviguer vers le jeu
            },
            child: const Text('Commencer'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    _scaleController.dispose();
    _refreshTimer?.cancel();
    _roomNameController.dispose();
    _roomIdController.dispose();
    _roomCodeController.dispose();
    super.dispose();
  }
}