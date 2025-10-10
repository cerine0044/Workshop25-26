import 'package:flutter/material.dart';
import '../services/firebase_history_service.dart';

class GlobalHistoryPage extends StatefulWidget {
  const GlobalHistoryPage({super.key});

  @override
  State<GlobalHistoryPage> createState() => _GlobalHistoryPageState();
}

class _GlobalHistoryPageState extends State<GlobalHistoryPage> {
  final FirebaseHistoryService _historyService = FirebaseHistoryService();
  List<GameSessionHistory> _sessions = [];
  bool _isLoading = true;
  String _gameModeFilter = 'all'; // all, solo, multiplayer
  String _sortBy = 'endTime'; // endTime, duration, score

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    try {
      setState(() => _isLoading = true);
      
      await _historyService.initialize();
      
      _historyService.historyStream.listen((sessions) {
        if (mounted) {
          setState(() {
            _sessions = sessions;
            _isLoading = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('❌ Erreur chargement historique global: $e');
      }
    }
  }

  /// Extraire le numéro de run du sessionId
  String _extractRunNumber(String sessionId) {
    final parts = sessionId.split('_');
    if (parts.length >= 3 && parts[1] == 'run') {
      return parts[2];
    }
    return 'N/A';
  }

  /// Extraire le nom du joueur du sessionId
  String _extractPlayerName(String sessionId) {
    final parts = sessionId.split('_');
    if (parts.isNotEmpty) {
      return parts[0];
    }
    return 'Inconnu';
  }

  void _sortSessions() {
    setState(() {
      switch (_sortBy) {
        case 'endTime':
          _sessions.sort((a, b) => b.endTime.compareTo(a.endTime));
          break;
        case 'duration':
          _sessions.sort((a, b) => b.duration.compareTo(a.duration));
          break;
        case 'score':
          _sessions.sort((a, b) => (b.score ?? 0).compareTo(a.score ?? 0));
          break;
      }
    });
  }

  List<GameSessionHistory> _getFilteredSessions() {
    List<GameSessionHistory> filtered = _sessions;
    
    if (_gameModeFilter != 'all') {
      filtered = filtered.where((session) {
        if (_gameModeFilter == 'solo') {
          return session.gameMode == 'solo' || session.gameMode == null;
        } else if (_gameModeFilter == 'multiplayer') {
          return session.gameMode == 'multiplayer';
        }
        return true;
      }).toList();
    }
    
    return filtered;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final filteredSessions = _getFilteredSessions();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 Historique Global'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
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
                          _buildSortChip('Date', 'endTime'),
                          const SizedBox(width: 8),
                          _buildSortChip('Durée', 'duration'),
                          const SizedBox(width: 8),
                          _buildSortChip('Score', 'score'),
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
                _buildStatCard('Sessions Total', '${filteredSessions.length}', Icons.games),
                _buildStatCard('Solo', '${filteredSessions.where((s) => s.gameMode == 'solo' || s.gameMode == null).length}', Icons.person),
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
                          'Aucun historique disponible',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filteredSessions.length,
                        itemBuilder: (context, index) {
                          final session = filteredSessions[index];
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Numéro de run
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Run #${_extractRunNumber(session.sessionId)}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.deepPurple.shade800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Nom du joueur
                                    Expanded(
                                      child: Text(
                                        session.playerName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: session.gameMode == 'multiplayer' ? Colors.blue.shade100 : Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        session.gameMode == 'multiplayer' ? 'Multi' : 'Solo',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: session.gameMode == 'multiplayer' ? Colors.blue.shade800 : Colors.orange.shade800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: session.completed ? Colors.green.shade100 : Colors.red.shade100,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        session.completed ? 'Réussi' : 'Échoué',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: session.completed ? Colors.green.shade800 : Colors.red.shade800,
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
                                    Text(session.gameRoom, style: TextStyle(color: Colors.grey[600])),
                                    const SizedBox(width: 16),
                                    Icon(Icons.timer, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(_formatDuration(session.duration), style: TextStyle(color: Colors.grey[600])),
                                    if (session.score != null) ...[
                                      const SizedBox(width: 16),
                                      Icon(Icons.star, size: 16, color: Colors.grey[600]),
                                      const SizedBox(width: 4),
                                      Text('${session.score} pts', style: TextStyle(color: Colors.grey[600])),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_formatDateTime(session.startTime)} - ${_formatDateTime(session.endTime)}',
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
        _sortSessions();
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
