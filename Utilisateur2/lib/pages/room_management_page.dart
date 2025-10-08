import 'package:flutter/material.dart';
import '../services/firebase_service.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseService.initialize();
      await FirebaseService.signInAnonymously();
      _loadAvailableRooms();
    } catch (e) {
      _showError('Erreur d\'initialisation: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadAvailableRooms() {
    FirebaseService.getAvailableRooms().listen((rooms) {
      setState(() {
        _availableRooms = rooms;
      });
    });
  }

  Future<void> _createRoom() async {
    if (_roomNameController.text.trim().isEmpty) {
      _showError('Veuillez entrer un nom de room');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final roomId = await FirebaseService.createGameRoom(_roomNameController.text.trim());
      setState(() => _currentRoomId = roomId);
      _listenToCurrentRoom();
      _roomNameController.clear();
      _showSuccess('Room créée avec succès!');
    } catch (e) {
      _showError('Erreur lors de la création: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinRoom(String roomId) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseService.joinGameRoom(roomId);
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
    
    FirebaseService.listenToRoom(_currentRoomId!).listen((roomData) {
      setState(() {
        _currentRoom = roomData;
      });
    });
  }

  Future<void> _leaveRoom() async {
    if (_currentRoomId == null) return;
    
    setState(() => _isLoading = true);
    try {
      await FirebaseService.leaveGameRoom(_currentRoomId!);
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
        await FirebaseService.updatePlayerReady(_currentRoomId!, newReadyState);
      }
    }
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
                                            title: Text(room['name'] ?? 'Room sans nom'),
                                            subtitle: Text('$playerCount joueur(s) - ID: ${room['id']}'),
                                            trailing: ElevatedButton(
                                              onPressed: () => _joinRoom(room['id']),
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
                            const Text('Joueurs:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ...Map<String, dynamic>.from(_currentRoom!['players'] ?? {}).entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(left: 16, top: 4),
                                child: Row(
                                  children: [
                                    Text(entry.value['name'] ?? 'Joueur'),
                                    if (entry.value['isHost'] == true)
                                      const Text(' (Hôte)', style: TextStyle(fontStyle: FontStyle.italic)),
                                    const Spacer(),
                                    Icon(
                                      entry.value['isReady'] == true ? Icons.check_circle : Icons.radio_button_unchecked,
                                      color: entry.value['isReady'] == true ? Colors.green : Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
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
    super.dispose();
  }
}
