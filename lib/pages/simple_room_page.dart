import 'package:flutter/material.dart';

class SimpleRoomPage extends StatefulWidget {
  const SimpleRoomPage({super.key});

  @override
  State<SimpleRoomPage> createState() => _SimpleRoomPageState();
}

class _SimpleRoomPageState extends State<SimpleRoomPage> {
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _roomIdController = TextEditingController();
  bool _isLoading = false;
  String _currentRoomId = '';
  List<String> _players = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Pandora Box - Multijoueur', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titre
            const Text(
              '🎮 Mode Multijoueur',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Actions principales
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showCreateRoomDialog,
                    icon: const Icon(Icons.add_circle),
                    label: const Text('Créer un salon'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showJoinRoomDialog,
                    icon: const Icon(Icons.login),
                    label: const Text('Rejoindre'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),

            // Statut de la salle
            if (_currentRoomId.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    const Text(
                      '✅ Salon Actif',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'ID: $_currentRoomId',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Joueurs: ${_players.length}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],

            const Spacer(),

            // Instructions
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                border: Border.all(color: Colors.blue),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 Instructions:',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    '1. Créez un salon et partagez l\'ID\n'
                    '2. L\'autre joueur utilise cet ID pour rejoindre\n'
                    '3. Les mises à jour sont en temps réel !',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Créer un salon', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _roomNameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'Nom du salon',
            labelStyle: TextStyle(color: Colors.white70),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: _createRoom,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Créer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showJoinRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Rejoindre un salon', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _roomIdController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: 'ID du salon',
            labelStyle: TextStyle(color: Colors.white70),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: _joinRoom,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Rejoindre', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _createRoom() async {
    if (_roomNameController.text.trim().isEmpty) {
      _showSnackBar('Veuillez entrer un nom de salon', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simuler la création
      await Future.delayed(const Duration(seconds: 1));
      
      final roomId = DateTime.now().millisecondsSinceEpoch.toString();
      setState(() {
        _currentRoomId = roomId;
        _players = ['Vous (Hôte)'];
      });
      
      _showSnackBar('Salon créé ! ID: $roomId', Colors.green);
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Erreur lors de la création', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _joinRoom() async {
    if (_roomIdController.text.trim().isEmpty) {
      _showSnackBar('Veuillez entrer un ID de salon', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Simuler la connexion
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _currentRoomId = _roomIdController.text.trim();
        _players = ['Joueur 1', 'Vous'];
      });
      
      _showSnackBar('Connexion réussie !', Colors.green);
      Navigator.pop(context);
    } catch (e) {
      _showSnackBar('Erreur lors de la connexion', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}
