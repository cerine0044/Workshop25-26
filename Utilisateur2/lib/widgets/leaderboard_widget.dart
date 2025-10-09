import 'package:flutter/material.dart';
import '../services/firebase_leaderboard_service.dart';

class LeaderboardWidget extends StatefulWidget {
  const LeaderboardWidget({super.key});

  @override
  State<LeaderboardWidget> createState() => _LeaderboardWidgetState();
}

class _LeaderboardWidgetState extends State<LeaderboardWidget> {
  final FirebaseLeaderboardService _leaderboardService = FirebaseLeaderboardService();
  List<LeaderboardEntry> _players = [];
  bool _isLoading = true;
  String _sortBy = 'averageScore'; // averageScore, totalSessions, bestTime

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  Future<void> _loadLeaderboard() async {
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
        debugPrint('❌ Erreur chargement classement: $e');
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🏆 Classement Global',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  setState(() => _sortBy = value);
                  _sortPlayers();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'averageScore',
                    child: Text('Score Moyen'),
                  ),
                  const PopupMenuItem(
                    value: 'totalSessions',
                    child: Text('Sessions Total'),
                  ),
                  const PopupMenuItem(
                    value: 'bestTime',
                    child: Text('Meilleur Temps'),
                  ),
                ],
                child: const Icon(Icons.sort, color: Colors.deepPurple),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.deepPurple),
            )
          else if (_players.isEmpty)
            const Center(
              child: Text(
                'Aucun joueur dans le classement',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 16,
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: _players.length,
                itemBuilder: (context, index) {
                  final player = _players[index];
                  final isTopThree = index < 3;
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isTopThree ? Colors.deepPurple.withOpacity(0.1) : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: isTopThree ? Border.all(color: Colors.deepPurple.withOpacity(0.3)) : null,
                    ),
                    child: Row(
                      children: [
                        // Position
                        Container(
                          width: 32,
                          height: 32,
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
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                                      fontSize: 16,
                                      color: isTopThree ? Colors.deepPurple : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (player.isOnline)
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
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.games,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${player.totalSessions} sessions',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${player.completedSessions} réussies',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
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
                                fontSize: 16,
                                color: isTopThree ? Colors.deepPurple : Colors.black87,
                              ),
                            ),
                            if (_sortBy != 'averageScore')
                              Text(
                                'Score: ${player.averageScore.toStringAsFixed(1)}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
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
}
