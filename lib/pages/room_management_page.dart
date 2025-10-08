import 'package:flutter/material.dart';
import '../services/http_game_service.dart';
import '../services/error_handler.dart';
import 'start_page.dart';
import 'dart:async';

class RoomManagementPage extends StatefulWidget {
  const RoomManagementPage({super.key});

  @override
  State<RoomManagementPage> createState() => _RoomManagementPageState();
}

class _RoomManagementPageState extends State<RoomManagementPage> {
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _roomIdController = TextEditingController();
  String? _currentRoomId;
  Map<String, dynamic>? _currentRoom;
  List<Map<String, dynamic>> _availableRooms = [];
  bool _isLoading = false;
  
  // Variables pour la gestion de la redirection
  bool _gameStarted = false;
  Timer? _roomCheckTimer;
  List<Map<String, dynamic>> _activePlayers = [];

  @override
  void initState() {
    super.initState();
    _initializeHttpService();
  }

  Future<void> _initializeHttpService() async {
    setState(() => _isLoading = true);
    try {
      await HttpGameService().initialize();
      await HttpGameService().signInAnonymously();
      _loadAvailableRooms();
    } catch (e) {
      final errorMessage = 'Erreur d\'initialisation: $e';
      ErrorHandler().handleError(errorMessage);
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
      
      // Vérifier les joueurs actifs dans la room
      _checkActivePlayers();
      
      // Vérifier si on peut aller à la page Start (2 joueurs présents)
      _checkForGameStart(roomData);
    });

    // Démarrer un timer pour vérifier périodiquement les joueurs actifs
    _roomCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkActivePlayers();
    });
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

  Future<void> _toggleReady() async {
    if (_currentRoomId == null || _currentRoom == null) return;
    
    // Pour le service local, on utilise l'ID utilisateur local
    final players = Map<String, dynamic>.from(_currentRoom!['players'] ?? {});
    final currentPlayerId = players.keys.firstWhere(
      (key) => players[key]['isHost'] == true || players[key]['name']?.contains('Joueur') == true,
      orElse: () => players.keys.first,
    );
    
    if (currentPlayerId != null) {
      final currentPlayer = players[currentPlayerId];
      if (currentPlayer != null) {
        final newReadyState = !(currentPlayer['isReady'] ?? false);
        await HttpGameService().updatePlayerReady(_currentRoomId!, newReadyState);
      }
    }
  }

  // Vérifier les joueurs actifs dans la room
  void _checkActivePlayers() async {
    if (_currentRoomId == null) return;
    
    try {
      final activePlayers = await HttpGameService().getActivePlayersInRoom(_currentRoomId!);
      setState(() {
        _activePlayers = activePlayers;
      });
      
      // Vérifier si la room est vide
      if (activePlayers.isEmpty) {
        _handleEmptyRoom();
      }
    } catch (e) {
      print('Erreur lors de la vérification des joueurs actifs: $e');
    }
  }

  // Gérer une room vide
  void _handleEmptyRoom() {
    setState(() {
      _currentRoomId = null;
      _currentRoom = null;
      _gameStarted = false;
    });
    
    _showError('La room est maintenant vide. Vous avez été déconnecté.');
  }

  // Vérifier si on peut aller à la page Start (2 joueurs présents)
  void _checkForGameStart(Map<String, dynamic>? roomData) {
    if (roomData == null) return;
    
    // Utiliser les joueurs actifs plutôt que les données de room
    final activePlayerCount = _activePlayers.length;
    
    // Si on a exactement 2 joueurs actifs et que le jeu n'a pas encore démarré
    if (activePlayerCount == 2 && !_gameStarted) {
      _showGameStartDialog();
    }
  }

  // Afficher le dialogue de démarrage du jeu
  void _showGameStartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎮 Prêt à commencer !'),
        content: const Text('2 joueurs sont présents dans le salon.\nVoulez-vous aller à la page Start ?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Attendre'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _goToStartPage();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('ALLER À START'),
          ),
        ],
      ),
    );
  }

  // Aller à la page Start
  void _goToStartPage() {
    setState(() {
      _gameStarted = true;
    });

    // Mettre à jour l'état du jeu sur le serveur
    if (_currentRoomId != null) {
      HttpGameService().updateGameState(_currentRoomId!, 'ready_to_start');
    }

    // Rediriger vers la page Start
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => StartPage(
          isMultiplayer: true,
          roomId: _currentRoomId,
        ),
      ),
    );
  }

  // Obtenir le nombre de joueurs dans la room actuelle
  int _getPlayerCount() {
    return _activePlayers.length;
  }

  // Obtenir la liste des joueurs dans la room actuelle
  List<Map<String, dynamic>> _getPlayers() {
    return _activePlayers;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Rooms - Pandora Box'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Section création de room
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Créer une nouvelle room',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _roomNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nom de la room',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _createRoom,
                            icon: const Icon(Icons.add),
                            label: const Text('Créer la room'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.deepPurple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Section rejoindre une room
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rejoindre une room existante',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _roomIdController,
                            decoration: const InputDecoration(
                              labelText: 'ID de la room',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _joinRoom(_roomIdController.text.trim()),
                            icon: const Icon(Icons.login),
                            label: const Text('Rejoindre'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Section rooms disponibles
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Rooms disponibles',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              child: _availableRooms.isEmpty
                                  ? const Center(
                                      child: Text('Aucune room disponible'),
                                    )
                                  : ListView.builder(
                                      itemCount: _availableRooms.length,
                                      itemBuilder: (context, index) {
                                        final room = _availableRooms[index];
                                        final players = Map<String, dynamic>.from(room['players'] ?? {});
                                        final playerCount = players.length;
                                        
                                        return Card(
                                          margin: const EdgeInsets.only(bottom: 8),
                                          child: ListTile(
                                            title: Text(room['name']?.toString() ?? 'Room sans nom'),
                                            subtitle: Text('$playerCount joueur(s) - ID: ${room['id']?.toString() ?? 'N/A'}'),
                                            trailing: ElevatedButton(
                                              onPressed: () => _joinRoom(room['id']?.toString() ?? ''),
                                              child: const Text('Rejoindre'),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // Section room actuelle
                  if (_currentRoom != null) ...[
                    const SizedBox(height: 20),
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Room actuelle: ${_currentRoom!['name']}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            const SizedBox(height: 16),
                            Text('État: ${_currentRoom!['gameState']}'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text('Joueurs actifs: ${_getPlayerCount()}/2', style: const TextStyle(fontWeight: FontWeight.bold)),
                                const Spacer(),
                                if (_getPlayerCount() < 2) ...[
                                  const Icon(Icons.hourglass_empty, color: Colors.orange, size: 16),
                                  const SizedBox(width: 4),
                                  const Text('En attente...', style: TextStyle(color: Colors.orange, fontSize: 12)),
                                ] else ...[
                                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                                  const SizedBox(width: 4),
                                  const Text('Prêt !', style: TextStyle(color: Colors.green, fontSize: 12)),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),
                            ..._getPlayers().map(
                              (player) => Padding(
                                padding: const EdgeInsets.only(left: 16, top: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color: Colors.blue,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(player['name'] ?? 'Joueur'),
                                    if (player['isHost'] == true)
                                      const Text(' (Hôte)', style: TextStyle(fontStyle: FontStyle.italic)),
                                    const Spacer(),
                                    Icon(
                                      Icons.circle,
                                      color: Colors.green,
                                      size: 12,
                                    ),
                                    const SizedBox(width: 4),
                                    const Text('Actif', style: TextStyle(color: Colors.green, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Bouton pour aller à la page Start si 2 joueurs sont présents
                            if (_getPlayerCount() == 2) ...[
                              ElevatedButton.icon(
                                onPressed: _gameStarted ? null : _goToStartPage,
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('ALLER À START'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            ElevatedButton.icon(
                              onPressed: _toggleReady,
                              icon: const Icon(Icons.check),
                              label: const Text('Prêt/Non prêt'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }


  @override
  void dispose() {
    _roomNameController.dispose();
    _roomIdController.dispose();
    _roomCheckTimer?.cancel();
    super.dispose();
  }
}
