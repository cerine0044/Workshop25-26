import 'package:flutter/material.dart';
import '../services/firebase_leaderboard_service.dart';
import 'global_history_page.dart';

class GlobalScoresPage extends StatefulWidget {
  const GlobalScoresPage({super.key});

  @override
  State<GlobalScoresPage> createState() => _GlobalScoresPageState();
}

class _GlobalScoresPageState extends State<GlobalScoresPage> {
  final FirebaseLeaderboardService _leaderboardService = FirebaseLeaderboardService();
  List<LeaderboardEntry> _players = [];
  bool _isLoading = true;
  String _sortBy = 'averageScore';
  String _gameModeFilter = 'all'; // all, solo, multiplayer

  @override
  void initState() {
    super.initState();
    _loadPlayers();
  }

  Future<void> _loadPlayers() async {
    try {
      setState(() => _isLoading = true);
      
      await _leaderboardService.initialize();
      
      _leaderboardService.leaderboardStream.listen((players) {
        if (mounted) {
          setState(() {
            _players = players;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('❌ Erreur chargement scores globaux: $e');
      }
    }
  }

  void _sortPlayers() {
    setState(() {
      switch (_sortBy) {
        case 'averageScore':
          _players.sort((a, b) => b.averageScore.compareTo(a.averageScore));
          break;
        case 'totalSessions':
          _players.sort((a, b) => b.totalSessions.compareTo(a.totalSessions));
          break;
        case 'bestTime':
          _players.sort((a, b) => a.bestTime.inMilliseconds.compareTo(b.bestTime.inMilliseconds));
          break;
      }
    });
  }

  List<LeaderboardEntry> _getFilteredPlayers() {
    if (_gameModeFilter == 'all') return _players;
    
    return _players.where((player) {
      if (_gameModeFilter == 'solo') {
        return player.gameMode == 'solo' || player.gameMode == null;
      } else if (_gameModeFilter == 'multiplayer') {
        return player.gameMode == 'multiplayer';
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPlayers = _getFilteredPlayers();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 Scores Globaux'),
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
                // Tri
                Row(
                  children: [
                    const Text('Trier par:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Row(
                        children: [
                          _buildSortChip('Score Moyen', 'averageScore'),
                          const SizedBox(width: 8),
                          _buildSortChip('Sessions', 'totalSessions'),
                          const SizedBox(width: 8),
                          _buildSortChip('Temps', 'bestTime'),
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
                _buildStatCard('Joueurs', '${filteredPlayers.length}', Icons.people),
                _buildStatCard('Sessions Solo', '${filteredPlayers.where((p) => p.gameMode == 'solo' || p.gameMode == null).length}', Icons.person),
                _buildStatCard('Sessions Multi', '${filteredPlayers.where((p) => p.gameMode == 'multiplayer').length}', Icons.group),
                _buildStatCard('En Ligne', '${filteredPlayers.where((p) => p.isOnline).length}', Icons.circle, Colors.green),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Liste des joueurs
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.deepPurple))
                : filteredPlayers.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun joueur trouvé',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredPlayers.length,
                        itemBuilder: (context, index) {
                          final player = filteredPlayers[index];
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
                                    color: isTopThree ? Colors.deepPurple : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                
                                // Informations joueur
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            player.playerName,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: isTopThree ? Colors.deepPurple : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (player.isOnline)
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: const BoxDecoration(
                                                color: Colors.green,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: player.gameMode == 'multiplayer' ? Colors.blue.shade100 : Colors.orange.shade100,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              player.gameMode == 'multiplayer' ? 'Multi' : 'Solo',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: player.gameMode == 'multiplayer' ? Colors.blue.shade800 : Colors.orange.shade800,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.games, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text('${player.totalSessions} sessions', style: TextStyle(color: Colors.grey[600])),
                                          const SizedBox(width: 16),
                                          Icon(Icons.check_circle, size: 16, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text('${player.completedSessions} réussies', style: TextStyle(color: Colors.grey[600])),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Score principal
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _sortBy == 'averageScore' 
                                        ? '${player.averageScore.toStringAsFixed(1)} pts'
                                        : _sortBy == 'totalSessions'
                                          ? '${player.totalSessions}'
                                          : '${player.bestTime.inMinutes}m ${player.bestTime.inSeconds % 60}s',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: isTopThree ? Colors.deepPurple : Colors.black87,
                                      ),
                                    ),
                                    if (_sortBy != 'averageScore')
                                      Text(
                                        'Score: ${player.averageScore.toStringAsFixed(1)}',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
        setState(() => _gameModeFilter = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
        setState(() => _sortBy = value);
        _sortPlayers();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepPurple : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.deepPurple, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color ?? Colors.deepPurple,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
