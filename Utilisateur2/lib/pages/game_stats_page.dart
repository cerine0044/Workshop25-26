import 'package:flutter/material.dart';
import '../services/game_stats_service.dart';

class GameStatsPage extends StatefulWidget {
  const GameStatsPage({super.key});

  @override
  State<GameStatsPage> createState() => _GameStatsPageState();
}

class _GameStatsPageState extends State<GameStatsPage> {
  final GameStatsService _statsService = GameStatsService();
  GameStats _stats = GameStats.empty();

  @override
  void initState() {
    super.initState();
    _loadStats();
    _statsService.addStatsListener(_updateStats);
  }

  @override
  void dispose() {
    _statsService.removeStatsListener(_updateStats);
    super.dispose();
  }

  void _loadStats() async {
    await _statsService.loadStatsFromStorage();
    _updateStats();
  }

  void _updateStats() {
    setState(() {
      _stats = _statsService.getStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101018),
      appBar: AppBar(
        title: const Text(
          'Statistiques de Jeu',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1C1C28),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Actualiser',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _showClearStatsDialog();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Effacer toutes les stats'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: _stats.totalSessions == 0
            ? _buildEmptyState()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCard(),
                    const SizedBox(height: 16),
                    _buildRoomStatsCard(),
                    const SizedBox(height: 16),
                    _buildRecentSessionsCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune statistique disponible',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Jouez à quelques jeux pour voir vos statistiques ici',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Card(
      color: const Color(0xFF1C1C28),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vue d\'ensemble',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Sessions totales',
                    '${_stats.totalSessions}',
                    Icons.games,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Sessions réussies',
                    '${_stats.completedSessions}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Taux de réussite',
                    '${(_stats.completionRate * 100).toStringAsFixed(1)}%',
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Temps total',
                    _formatDuration(_stats.totalPlayTime),
                    Icons.timer,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Temps moyen',
                    _formatDuration(_stats.averageSessionTime),
                    Icons.schedule,
                    Colors.cyan,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Dernière partie',
                    _stats.lastPlayed != null
                        ? _formatDate(_stats.lastPlayed!)
                        : 'Jamais',
                    Icons.history,
                    Colors.indigo,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRoomStatsCard() {
    return Card(
      color: const Color(0xFF1C1C28),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Statistiques par salle',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._stats.roomStats.map((roomStats) => _buildRoomStatItem(roomStats)),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomStatItem(RoomStats roomStats) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900]?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[700]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getRoomIcon(roomStats.roomName),
                color: _getRoomColor(roomStats.roomName),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                roomStats.roomName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sessions: ${roomStats.totalSessions}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ),
              Expanded(
                child: Text(
                  'Réussies: ${roomStats.completedSessions}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Temps moyen: ${_formatDuration(roomStats.averageDuration)}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ),
              Expanded(
                child: Text(
                  'Meilleur temps: ${roomStats.bestTime != null ? _formatDuration(roomStats.bestTime!) : "N/A"}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ),
            ],
          ),
          if (roomStats.averageScore > 0)
            Text(
              'Score moyen: ${roomStats.averageScore.toStringAsFixed(1)}',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentSessionsCard() {
    final recentSessions = _statsService.completedSessions
        .take(5)
        .toList()
        .reversed
        .toList();

    return Card(
      color: const Color(0xFF1C1C28),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sessions récentes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...recentSessions.map((session) => _buildSessionItem(session)),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionItem(GameSession session) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: session.completed 
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: session.completed 
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            session.completed ? Icons.check_circle : Icons.cancel,
            color: session.completed ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.gameRoom,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_formatDate(session.endTime)} - ${_formatDuration(session.duration)}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
          ),
          if (session.score != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${session.score}',
                style: const TextStyle(
                  color: Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getRoomIcon(String roomName) {
    switch (roomName.toLowerCase()) {
      case 'puzzle':
        return Icons.extension;
      case 'stress':
        return Icons.psychology;
      case 'mots croisés':
      case 'words':
        return Icons.grid_on;
      case 'tram':
        return Icons.train;
      case 'notifications':
        return Icons.notifications;
      default:
        return Icons.games;
    }
  }

  Color _getRoomColor(String roomName) {
    switch (roomName.toLowerCase()) {
      case 'puzzle':
        return Colors.blue;
      case 'stress':
        return Colors.red;
      case 'mots croisés':
      case 'words':
        return Colors.green;
      case 'tram':
        return Colors.orange;
      case 'notifications':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

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

  void _showClearStatsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C28),
        title: const Text(
          'Effacer les statistiques',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir effacer toutes vos statistiques ? Cette action est irréversible.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await _statsService.clearAllStats();
              Navigator.of(context).pop();
              _updateStats();
            },
            child: const Text(
              'Effacer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
