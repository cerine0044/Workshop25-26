import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/http_game_service.dart';
import '../services/error_handler.dart';
import 'start_page.dart';
import 'dart:async';

class ModernRoomManagementPage extends StatefulWidget {
  const ModernRoomManagementPage({super.key});

  @override
  State<ModernRoomManagementPage> createState() => _ModernRoomManagementPageState();
}

class _ModernRoomManagementPageState extends State<ModernRoomManagementPage> 
    with TickerProviderStateMixin {
  
  // Contrôleurs et état
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _roomIdController = TextEditingController();
  String? _currentRoomId;
  Map<String, dynamic>? _currentRoom;
  List<Map<String, dynamic>> _availableRooms = [];
  bool _isLoading = false;
  bool _isConnected = false;
  
  // Variables pour la gestion de la redirection
  bool _gameStarted = false;
  Timer? _roomCheckTimer;
  List<Map<String, dynamic>> _activePlayers = [];
  
  // Animations
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  
  // État de l'interface
  bool _showCreateRoom = false;
  bool _showJoinRoom = false;
  String _connectionStatus = 'Déconnecté';
  Color _connectionColor = Colors.red;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeHttpService();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _initializeHttpService() async {
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Connexion...';
      _connectionColor = Colors.orange;
    });
    
    try {
      await HttpGameService().initialize();
      await HttpGameService().signInAnonymously();
      
      setState(() {
        _isConnected = true;
        _connectionStatus = 'Connecté';
        _connectionColor = Colors.green;
      });
      
      _loadAvailableRooms();
      _slideController.forward();
    } catch (e) {
      final errorMessage = 'Erreur d\'initialisation: $e';
      ErrorHandler().handleError(errorMessage);
      
      setState(() {
        _isConnected = false;
        _connectionStatus = 'Erreur de connexion';
        _connectionColor = Colors.red;
      });
      
      _showError(errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadAvailableRooms() {
    HttpGameService().getAvailableRoomsStream().listen(
      (rooms) {
        setState(() {
          _availableRooms = rooms;
        });
      },
      onError: (error) {
        final errorMessage = 'Erreur lors du chargement des rooms: $error';
        ErrorHandler().handleError(errorMessage);
        _showError(errorMessage);
      },
    );
  }

  Future<void> _createRoom() async {
    if (_roomNameController.text.trim().isEmpty) {
      _showError('Veuillez entrer un nom de room');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final roomId = await HttpGameService().createGameRoom(_roomNameController.text.trim());
      setState(() => _currentRoomId = roomId);
      _listenToCurrentRoom();
      _roomNameController.clear();
      _showCreateRoom = false;
      _showSuccess('Room créée avec succès!');
    } catch (e) {
      final errorMessage = 'Erreur lors de la création: $e';
      ErrorHandler().handleError(errorMessage);
      _showError(errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinRoom(String roomId) async {
    setState(() => _isLoading = true);
    try {
      await HttpGameService().joinGameRoom(roomId);
      setState(() => _currentRoomId = roomId);
      _listenToCurrentRoom();
      _showJoinRoom = false;
      _showSuccess('Room rejointe avec succès!');
    } catch (e) {
      _showError('Erreur lors de la connexion: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _listenToCurrentRoom() {
    if (_currentRoomId == null) return;
    
    HttpGameService().listenToRoom(_currentRoomId!).listen((roomData) {
      setState(() {
        _currentRoom = roomData;
      });
      
      _checkActivePlayers();
      _checkForGameStart(roomData);
    });

    _roomCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkActivePlayers();
    });
  }

  Future<void> _checkActivePlayers() async {
    if (_currentRoomId == null) return;
    
    try {
      final activePlayers = await HttpGameService().getActivePlayersInRoom(_currentRoomId!);
      setState(() {
        _activePlayers = activePlayers;
      });
      
      if (activePlayers.isEmpty) {
        _handleEmptyRoom();
      }
    } catch (e) {
      print('Erreur lors de la vérification des joueurs actifs: $e');
    }
  }

  void _handleEmptyRoom() {
    setState(() {
      _currentRoomId = null;
      _currentRoom = null;
      _gameStarted = false;
    });
    
    _showError('La room est maintenant vide. Vous avez été déconnecté.');
  }

  void _checkForGameStart(Map<String, dynamic>? roomData) {
    if (roomData == null) return;
    
    final activePlayerCount = _activePlayers.length;
    
    if (activePlayerCount == 2 && !_gameStarted) {
      _showGameStartDialog();
    }
  }

  void _showGameStartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.grey[900],
        title: Row(
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: const Icon(Icons.gamepad, color: Colors.green, size: 30),
                );
              },
            ),
            const SizedBox(width: 10),
            const Text('🎮 Prêt à commencer !', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          '2 joueurs sont présents dans le salon.\nVoulez-vous aller à la page Start ?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Attendre', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _goToStartPage();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('ALLER À START'),
          ),
        ],
      ),
    );
  }

  void _goToStartPage() {
    setState(() {
      _gameStarted = true;
    });

    if (_currentRoomId != null) {
      HttpGameService().updateGameState(_currentRoomId!, 'ready_to_start');
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => StartPage(
          isMultiplayer: true,
          roomId: _currentRoomId,
        ),
      ),
    );
  }

  Future<void> _leaveRoom() async {
    if (_currentRoomId == null) return;
    
    setState(() => _isLoading = true);
    try {
      await HttpGameService().leaveGameRoom(_currentRoomId!);
      setState(() {
        _currentRoomId = null;
        _currentRoom = null;
      });
      _showSuccess('Room quittée');
    } catch (e) {
      _showError('Erreur lors de la déconnexion: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showCreateRoomDialog() {
    setState(() {
      _showCreateRoom = true;
    });
  }

  void _showJoinRoomDialog() {
    setState(() {
      _showJoinRoom = true;
    });
  }

  void _hideCreateRoomDialog() {
    setState(() {
      _showCreateRoom = false;
    });
  }

  void _hideJoinRoomDialog() {
    setState(() {
      _showJoinRoom = false;
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Arrière-plan animé
            _buildAnimatedBackground(),
            
            // Contenu principal
            _buildMainContent(),
            
            // Indicateur de connexion
            _buildConnectionIndicator(),
            
            // Loading overlay
            if (_isLoading) _buildLoadingOverlay(),
            
            // Modales
            if (_showCreateRoom) _buildCreateRoomModal(),
            if (_showJoinRoom) _buildJoinRoomModal(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                Colors.black,
                Color.lerp(Colors.deepPurple.shade900, Colors.indigo.shade900, 
                   0.5 + 0.3 * math.sin(_pulseController.value * math.pi * 2))!,
                Color.lerp(Colors.blue.shade900, Colors.purple.shade900, 
                   0.5 + 0.3 * math.cos(_pulseController.value * math.pi * 2))!,
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainContent() {
    return SlideTransition(
      position: _slideAnimation,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            const SizedBox(height: 30),
            
            // Actions principales
            _buildMainActions(),
            
            const SizedBox(height: 30),
            
            // Rooms disponibles
            Expanded(child: _buildRoomsList()),
            
            // Room actuelle
            if (_currentRoom != null) _buildCurrentRoom(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
            const Spacer(),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: const Icon(Icons.people, color: Colors.white, size: 30),
                );
              },
            ),
            const Spacer(),
            IconButton(
              onPressed: _initializeHttpService,
              icon: const Icon(Icons.refresh, color: Colors.white),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'SALONS MULTIJOUEUR',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Rejoignez ou créez un salon pour jouer avec d\'autres',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMainActions() {
    return Row(
      children: [
        Expanded(
          child: _buildActionCard(
            title: 'Créer un salon',
            subtitle: 'Nouveau salon',
            icon: Icons.add_circle_outline,
            color: Colors.green,
            onTap: () => setState(() => _showCreateRoom = true),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: _buildActionCard(
            title: 'Rejoindre',
            subtitle: 'Avec un code',
            icon: Icons.login,
            color: Colors.blue,
            onTap: () => setState(() => _showJoinRoom = true),
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.8), color.withOpacity(0.4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 30),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Salons disponibles',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Expanded(
          child: _availableRooms.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _availableRooms.length,
                  itemBuilder: (context, index) {
                    final room = _availableRooms[index];
                    return _buildRoomCard(room);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.meeting_room_outlined,
            color: Colors.white.withOpacity(0.5),
            size: 60,
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun salon disponible',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Créez le premier salon !',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final players = Map<String, dynamic>.from(room['players'] ?? {});
    final playerCount = players.length;
    final isFull = playerCount >= 2;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: isFull ? Colors.red.withOpacity(0.5) : Colors.white.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: CircleAvatar(
          backgroundColor: isFull ? Colors.red : Colors.green,
          child: Text(
            '$playerCount',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          room['name']?.toString() ?? 'Salon sans nom',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$playerCount/2 joueurs',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
            Text(
              'ID: ${room['id']?.toString() ?? 'N/A'}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: isFull ? null : () => _joinRoom(room['id']?.toString() ?? ''),
          style: ElevatedButton.styleFrom(
            backgroundColor: isFull ? Colors.grey : Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(isFull ? 'Complet' : 'Rejoindre'),
        ),
      ),
    );
  }

  Widget _buildCurrentRoom() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green.withOpacity(0.8), Colors.green.withOpacity(0.4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.meeting_room, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Salon: ${_currentRoom!['name']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _leaveRoom,
                icon: const Icon(Icons.exit_to_app, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Text(
                'Joueurs: ${_activePlayers.length}/2',
                style: const TextStyle(color: Colors.white),
              ),
              const Spacer(),
              if (_activePlayers.length < 2) ...[
                const Icon(Icons.hourglass_empty, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                const Text('En attente...', style: TextStyle(color: Colors.orange, fontSize: 12)),
              ] else ...[
                const Icon(Icons.check_circle, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                const Text('Prêt !', style: TextStyle(color: Colors.white, fontSize: 12)),
              ],
            ],
          ),
          const SizedBox(height: 15),
          ..._activePlayers.map(
            (player) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    player['name'] ?? 'Joueur',
                    style: const TextStyle(color: Colors.white),
                  ),
                  if (player['isHost'] == true) ...[
                    const SizedBox(width: 8),
                    const Text('(Hôte)', style: TextStyle(color: Colors.yellow, fontSize: 12)),
                  ],
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_activePlayers.length == 2) ...[
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _gameStarted ? null : _goToStartPage,
                icon: const Icon(Icons.play_arrow),
                label: const Text('COMMENCER LE JEU'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectionIndicator() {
    return Positioned(
      top: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _connectionColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _connectionColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _connectionColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _connectionStatus,
              style: TextStyle(
                color: _connectionColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            Text(
              'Connexion en cours...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCreateRoomModal() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.withOpacity(0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_circle, color: Colors.green, size: 50),
              const SizedBox(height: 20),
              const Text(
                'Créer un salon',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _roomNameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Nom du salon',
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.green),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.green.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => setState(() => _showCreateRoom = false),
                      child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _createRoom,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Créer'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJoinRoomModal() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.withOpacity(0.5)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.login, color: Colors.blue, size: 50),
              const SizedBox(height: 20),
              const Text(
                'Rejoindre un salon',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _roomIdController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Code du salon',
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.blue.withOpacity(0.5)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.blue),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => setState(() => _showJoinRoom = false),
                      child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _joinRoom(_roomIdController.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Rejoindre'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    _roomIdController.dispose();
    _roomCheckTimer?.cancel();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}
