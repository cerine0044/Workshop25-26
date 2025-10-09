import 'package:flutter/material.dart';
import '../services/firebase_multiplayer_service.dart';

class WorkingMultiplayerPage extends StatefulWidget {
  const WorkingMultiplayerPage({super.key});

  @override
  State<WorkingMultiplayerPage> createState() => _WorkingMultiplayerPageState();
}

class _WorkingMultiplayerPageState extends State<WorkingMultiplayerPage> {
  final FirebaseMultiplayerService _multiplayerService = FirebaseMultiplayerService();
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _roomIdController = TextEditingController();
  final TextEditingController _roomCodeController = TextEditingController();

  Map<String, dynamic>? _currentRoom;
  List<Map<String, dynamic>> _availableRooms = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _initializeMultiplayer();
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
            print('❌ Erreur mise à jour room state: $e');
            setState(() {
              _errorMessage = 'Erreur de synchronisation: $e';
            });
          }
        },
        onError: (e) {
          print('❌ Erreur stream room state: $e');
          setState(() {
            _errorMessage = 'Erreur de connexion: $e';
          });
        },
      );

      // Écouter les rooms disponibles avec gestion d'erreur
      _multiplayerService.availableRoomsStream.listen(
        (rooms) {
          try {
            setState(() {
              _availableRooms = rooms;
            });
          } catch (e) {
            print('❌ Erreur mise à jour rooms disponibles: $e');
          }
        },
        onError: (e) {
          print('❌ Erreur stream rooms disponibles: $e');
        },
      );

      setState(() {
        _successMessage = '✅ Connexion multijoueur établie !';
      });

    } catch (e) {
      setState(() {
        _errorMessage = '❌ Erreur de connexion: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _createRoom() async {
    if (_roomNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer un nom de room';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🏠 Création de room: ${_roomNameController.text.trim()}');
      await _multiplayerService.createRoom(
        name: _roomNameController.text.trim(),
        description: 'Room créée par ${_multiplayerService.currentPlayerName}',
      );
      
      print('✅ Room créée avec succès');
      
      // Attendre un peu pour que la room soit mise à jour
      await Future.delayed(const Duration(milliseconds: 500));
      
      setState(() {
        _successMessage = '✅ Room créée avec succès !';
      });
      _roomNameController.clear();
      
    } catch (e) {
      print('❌ Erreur création room: $e');
      setState(() {
        _errorMessage = '❌ Erreur création room: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _joinRoom(String roomId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _multiplayerService.joinRoom(roomId);
      setState(() {
        _successMessage = '✅ Room rejointe avec succès !';
      });
    } catch (e) {
      setState(() {
        _errorMessage = '❌ Erreur rejoindre room: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _joinRoomByCode() async {
    if (_roomCodeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer un code de room';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final roomCode = _roomCodeController.text.trim().toUpperCase();
      
      // Chercher la room par code
      final room = _availableRooms.firstWhere(
        (room) => room['code'] == roomCode,
        orElse: () => throw Exception('Aucune room trouvée avec ce code'),
      );
      
      await _multiplayerService.joinRoom(room['id']);
      setState(() {
        _successMessage = '✅ Room rejointe avec succès !';
      });
      _roomCodeController.clear();
    } catch (e) {
      setState(() {
        _errorMessage = '❌ Erreur rejoindre room: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _leaveRoom() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _multiplayerService.leaveRoom();
      setState(() {
        _successMessage = '✅ Room quittée';
      });
    } catch (e) {
      setState(() {
        _errorMessage = '❌ Erreur quitter room: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleReady() async {
    try {
      await _multiplayerService.toggleReady();
    } catch (e) {
      setState(() {
        _errorMessage = '❌ Erreur toggle ready: $e';
      });
    }
  }

  Future<void> _startGame() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _multiplayerService.startGame();
      setState(() {
        _successMessage = '✅ Jeu démarré !';
      });
    } catch (e) {
      setState(() {
        _errorMessage = '❌ Erreur démarrer jeu: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showGameStartedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🎮 Jeu démarré !'),
        content: const Text('Le jeu multijoueur a commencé !'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Ici on pourrait naviguer vers la page de jeu
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode Multijoueur'),
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        actions: [
          if (_currentRoom != null)
            IconButton(
              onPressed: _leaveRoom,
              icon: const Icon(Icons.exit_to_app),
              tooltip: 'Quitter la room',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Messages d'état
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            
            if (_successMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Text(
                  _successMessage!,
                  style: TextStyle(color: Colors.green.shade800),
                ),
              ),

            // Informations joueur
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '👤 Informations Joueur',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Nom: ${_multiplayerService.currentPlayerName ?? "Non connecté"}'),
                    Text('ID: ${_multiplayerService.currentPlayerId ?? "Non connecté"}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            if (_currentRoom == null) ...[
              // Section création de room
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🏠 Créer une Room',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _roomNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom de la room',
                          border: OutlineInputBorder(),
                          hintText: 'Ex: Ma Room de Jeu',
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _createRoom,
                          icon: _isLoading 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.add),
                          label: Text(_isLoading ? 'Création...' : 'Créer Room'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Section rejoindre par code
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🔑 Rejoindre par Code',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _roomCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Code de la room',
                          border: OutlineInputBorder(),
                          hintText: 'Ex: ABC123',
                          prefixIcon: Icon(Icons.vpn_key),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        maxLength: 6,
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _joinRoomByCode,
                          icon: _isLoading 
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.login),
                          label: Text(_isLoading ? 'Connexion...' : 'Rejoindre par Code'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Section rooms disponibles
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🌐 Rooms Disponibles',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (_availableRooms.isEmpty)
                        const Text(
                          'Aucune room disponible pour le moment.',
                          style: TextStyle(color: Colors.grey),
                        )
                      else
                        ...(_availableRooms.map((room) => _buildRoomCard(room))),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Section room actuelle
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            '🏠 Room Actuelle',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _currentRoom!['code'] ?? 'N/A',
                              style: TextStyle(
                                color: Colors.green.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text('Nom: ${_currentRoom!['name'] ?? 'N/A'}'),
                      Text('Hôte: ${_currentRoom!['hostName'] ?? 'N/A'}'),
                      Text('Joueurs: ${(_currentRoom!['players'] as Map).length}/${_currentRoom!['maxPlayers'] ?? 6}'),
                      const SizedBox(height: 16),
                      
                      // Liste des joueurs
                      const Text(
                        '👥 Joueurs',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ...((_currentRoom!['players'] as Map).values.map((player) => _buildPlayerCard(player))),
                      
                      const SizedBox(height: 16),
                      
                      // Boutons d'action
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _toggleReady,
                              icon: const Icon(Icons.check),
                              label: const Text('Prêt'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_currentRoom!['hostId'] == _multiplayerService.currentPlayerId)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _isLoading ? null : _startGame,
                                icon: const Icon(Icons.play_arrow),
                                label: const Text('Démarrer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ),
                        ],
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

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final players = room['players'] as Map? ?? {};
    final playerCount = players.length;
    final maxPlayers = room['maxPlayers'] ?? 6;
    final isHost = room['hostId'] == _multiplayerService.currentPlayerId;
    final roomCode = room['code'] ?? 'N/A';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            roomCode.substring(0, 2),
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(room['name'] ?? 'Room sans nom'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hôte: ${room['hostName'] ?? 'N/A'}'),
            Text('Joueurs: $playerCount/$maxPlayers'),
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Text(
                'Code: $roomCode',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isLoading || isHost ? null : () => _joinRoom(room['id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                minimumSize: const Size(80, 32),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: Text(
                isHost ? 'Hôte' : 'Rejoindre',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () {
                _roomCodeController.text = roomCode;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Code "$roomCode" copié dans le champ !'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Text(
                  'Copier',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard(dynamic player) {
    final playerData = player as Map<String, dynamic>;
    final isReady = playerData['isReady'] ?? false;
    final isHost = playerData['isHost'] ?? false;
    final isCurrentPlayer = playerData['id'] == _multiplayerService.currentPlayerId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentPlayer ? Colors.blue.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isCurrentPlayer ? Colors.blue.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Text(
            playerData['avatar'] ?? '😀',
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      playerData['name'] ?? 'Joueur',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isCurrentPlayer ? Colors.blue.shade800 : null,
                      ),
                    ),
                    if (isHost) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'HÔTE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  isReady ? '✅ Prêt' : '⏳ En attente',
                  style: TextStyle(
                    color: isReady ? Colors.green.shade600 : Colors.orange.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    _roomIdController.dispose();
    _roomCodeController.dispose();
    _multiplayerService.dispose();
    super.dispose();
  }
}
