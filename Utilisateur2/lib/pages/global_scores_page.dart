import 'package:flutter/material.dart';
import '../services/firebase_history_service.dart';
import 'global_history_page.dart';

class GlobalScoresPage extends StatefulWidget {
  const GlobalScoresPage({super.key});

  @override
  State<GlobalScoresPage> createState() => _GlobalScoresPageState();
}

class _GlobalScoresPageState extends State<GlobalScoresPage> {
  final FirebaseHistoryService _historyService = FirebaseHistoryService();
  List<GameSessionHistory> _sessions = [];
  bool _isLoading = true;
  String _sortBy = 'duration'; // duration, score, playerName, gameRoom
  String _gameModeFilter = 'all'; // all, solo, multiplayer

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      setState(() => _isLoading = true);
      
      await _historyService.initialize();
      
      // Charger toutes les sessions d'abord
      final allSessions = await _historyService.getRecentSessions(limit: 1000);
      if (mounted) {
        setState(() {
          _sessions = allSessions;
          _isLoading = false;
        });
        _sortSessions();
      }
      
      // Puis écouter les mises à jour en temps réel
      _historyService.historyStream.listen((sessions) {
        if (mounted) {
          setState(() {
            _sessions = sessions;
          });
          _sortSessions();
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('❌ Erreur chargement sessions: $e');
      }
    }
  }

  void _sortSessions() {
    setState(() {
      switch (_sortBy) {
        case 'duration':
          _sessions.sort((a, b) => a.duration.compareTo(b.duration));
          break;
        case 'score':
          _sessions.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
          break;
        case 'playerName':
          _sessions.sort((a, b) => a.playerName.compareTo(b.playerName));
          break;
        case 'gameRoom':
          _sessions.sort((a, b) => a.gameRoom.compareTo(b.gameRoom));
          break;
        case 'startTime':
          _sessions.sort((a, b) => b.startTime.compareTo(a.startTime));
          break;
      }
    });
  }

  List<GameSessionHistory> _getFilteredSessions() {
    if (_gameModeFilter == 'all') return _sessions;
    
    return _sessions.where((session) {
      if (_gameModeFilter == 'solo') {
        return session.gameMode == 'solo';
      } else if (_gameModeFilter == 'multiplayer') {
        return session.gameMode == 'multiplayer';
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredSessions = _getFilteredSessions();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 Toutes les Sessions'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GlobalHistoryPage()),
              );
            },
            tooltip: 'Voir l\'Historique Global',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtres et tri
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Filtre par mode de jeu
                Row(
                  children: [
                    const Text('Mode de jeu:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          _buildFilterChip('Tous', 'all'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Solo', 'solo'),
                          const SizedBox(width: 8),
                          _buildFilterChip('Multijoueur', 'multiplayer'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Compteur de sessions
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.deepPurple.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.games, color: Colors.deepPurple, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        '${filteredSessions.length} session${filteredSessions.length > 1 ? 's' : ''} affiché${filteredSessions.length != _sessions.length ? ' sur ${_sessions.length}' : ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Tri
                Row(
                  children: [
                    const Text('Trier par:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          _buildSortChip('Temps Session', 'duration'),
                          const SizedBox(width: 8),
                          _buildSortChip('Score', 'score'),
                          const SizedBox(width: 8),
                          _buildSortChip('Joueur', 'playerName'),
                          const SizedBox(width: 8),
                          _buildSortChip('Salle', 'gameRoom'),
                          const SizedBox(width: 8),
                          _buildSortChip('Date', 'startTime'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Statistiques globales
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade100, Colors.deepPurple.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Sessions', '${filteredSessions.length}', Icons.games),
                _buildStatCard('Solo', '${filteredSessions.where((s) => s.gameMode == 'solo').length}', Icons.person),
                _buildStatCard('Multi', '${filteredSessions.where((s) => s.gameMode == 'multiplayer').length}', Icons.group),
                _buildStatCard('Réussies', '${filteredSessions.where((s) => s.completed).length}', Icons.check_circle, Colors.green),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Liste des sessions
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
                : filteredSessions.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucune session trouvée',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredSessions.length,
                        itemBuilder: (context, index) {
                          final session = filteredSessions[index];
                          final isTopThree = index < 3;
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isTopThree ? Colors.deepPurple.withOpacity(0.1) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: isTopThree ? Border.all(color: Colors.deepPurple.withOpacity(0.3)) : null,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                // Position
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isTopThree ? Colors.deepPurple : Colors.grey.shade300,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        color: isTopThree ? Colors.white : Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(width: 16),
                                
                                // Informations de la session
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            session.playerName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: session.gameMode == 'multiplayer' 
                                                  ? Colors.blue.shade100 
                                                  : Colors.orange.shade100,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              session.gameMode == 'multiplayer' ? 'Multi' : 'Solo',
                                              style: TextStyle(
                                                color: session.gameMode == 'multiplayer' 
                                                    ? Colors.blue.shade800 
                                                    : Colors.orange.shade800,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        session.gameRoom,
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            session.completed ? Icons.check_circle : Icons.cancel,
                                            color: session.completed ? Colors.green : Colors.red,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            session.completed ? 'Réussie' : 'Échouée',
                                            style: TextStyle(
                                              color: session.completed ? Colors.green : Colors.red,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Temps et score
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _formatDuration(session.duration),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.deepPurple,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Score: ${session.score ?? 0}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDateTime(session.startTime),
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatFullDate(session.startTime),
                                      style: TextStyle(
                                        color: Colors.grey.shade400,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
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

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _gameModeFilter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _gameModeFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.deepPurple),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.deepPurple,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSortChip(String label, String value) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _sortBy = value;
        });
        _sortSessions();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.deepPurple),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.deepPurple,
            fontWeight: FontWeight.bold,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, [Color? iconColor]) {
    return Column(
      children: [
        Icon(
          icon,
          color: iconColor ?? Colors.deepPurple,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}j';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Maintenant';
    }
  }

  String _formatFullDate(DateTime dateTime) {
    final months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun',
      'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    
    return '$day $month $year • $hour:$minute';
  }
}