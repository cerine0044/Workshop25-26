import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_database_manager.dart';

/// Interface d'administration pour la base de données Firebase
class FirebaseAdminPanel extends StatefulWidget {
  const FirebaseAdminPanel({super.key});

  @override
  State<FirebaseAdminPanel> createState() => _FirebaseAdminPanelState();
}

class _FirebaseAdminPanelState extends State<FirebaseAdminPanel> {
  final FirebaseDatabaseManager _dbManager = FirebaseDatabaseManager();
  
  Map<String, dynamic>? _analysis;
  List<Map<String, dynamic>> _monitoringEvents = [];
  bool _isMonitoring = false;
  StreamSubscription? _monitoringSubscription;
  
  // Couleurs du thème
  static const Color colorBg1 = Color(0xFF15162B);
  static const Color colorBg2 = Color(0xFF1D2453);
  static const Color colorText = Color(0xFFECF0F1);
  static const Color colorAccent = Color(0xFF66FCF1);
  static const Color colorSuccess = Color(0xFF2ECC71);
  static const Color colorWarning = Color(0xFFF39C12);
  static const Color colorError = Color(0xFFE74C3C);

  @override
  void initState() {
    super.initState();
    _initializeManager();
  }

  @override
  void dispose() {
    _monitoringSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeManager() async {
    try {
      await _dbManager.initialize();
      await _analyzeDatabase();
    } catch (e) {
      _showError('Erreur d\'initialisation: $e');
    }
  }

  Future<void> _analyzeDatabase() async {
    try {
      setState(() {});
      final analysis = await _dbManager.analyzeDatabase();
      setState(() {
        _analysis = analysis;
      });
    } catch (e) {
      _showError('Erreur d\'analyse: $e');
    }
  }

  Future<void> _cleanupInactiveRooms() async {
    try {
      final result = await _dbManager.cleanupInactiveRooms();
      _showSuccess('Nettoyage terminé: ${result['totalDeleted']} rooms supprimées');
      await _analyzeDatabase();
    } catch (e) {
      _showError('Erreur de nettoyage: $e');
    }
  }

  Future<void> _cleanupInactivePlayers() async {
    try {
      final result = await _dbManager.cleanupInactivePlayers();
      _showSuccess('Nettoyage terminé: ${result['totalDeleted']} joueurs supprimés');
      await _analyzeDatabase();
    } catch (e) {
      _showError('Erreur de nettoyage: $e');
    }
  }

  Future<void> _backupDatabase() async {
    try {
      final result = await _dbManager.backupDatabase();
      if (result['success'] == true) {
        _showSuccess('Sauvegarde créée: ${result['filename']}');
      } else {
        _showError('Erreur de sauvegarde: ${result['error']}');
      }
    } catch (e) {
      _showError('Erreur de sauvegarde: $e');
    }
  }

  Future<void> _clearAllData() async {
    final confirmed = await _showConfirmDialog(
      'Supprimer toutes les données',
      'Êtes-vous sûr de vouloir supprimer TOUTES les données de la base de données ?\n\nCette action est IRRÉVERSIBLE !',
    );
    
    if (confirmed) {
      try {
        final result = await _dbManager.clearAllData();
        _showSuccess('Toutes les données supprimées');
        await _analyzeDatabase();
      } catch (e) {
        _showError('Erreur de suppression: $e');
      }
    }
  }

  void _toggleMonitoring() {
    if (_isMonitoring) {
      _monitoringSubscription?.cancel();
      setState(() {
        _isMonitoring = false;
        _monitoringEvents.clear();
      });
    } else {
      _monitoringSubscription = _dbManager.monitorDatabase().listen((event) {
        setState(() {
          _monitoringEvents.insert(0, event);
          if (_monitoringEvents.length > 50) {
            _monitoringEvents = _monitoringEvents.take(50).toList();
          }
        });
      });
      setState(() {
        _isMonitoring = true;
      });
    }
  }

  Future<void> _generateReport() async {
    try {
      final report = await _dbManager.generateReport();
      await Clipboard.setData(ClipboardData(text: report));
      _showSuccess('Rapport copié dans le presse-papiers');
    } catch (e) {
      _showError('Erreur de génération du rapport: $e');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorSuccess,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorError,
        duration: const Duration(seconds: 5),
      ),
    );
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colorBg2,
        title: Text(title, style: const TextStyle(color: colorText)),
        content: Text(message, style: const TextStyle(color: colorText)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler', style: TextStyle(color: colorText)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirmer', style: TextStyle(color: colorError)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorBg1,
      appBar: AppBar(
        title: const Text(
          'Administration Firebase',
          style: TextStyle(color: colorText, fontWeight: FontWeight.w700),
        ),
        backgroundColor: colorBg2,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _analyzeDatabase,
            icon: const Icon(Icons.refresh, color: colorAccent),
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.8, -1.0),
            end: Alignment(0.8, 1.0),
            colors: [colorBg1, colorBg2],
          ),
        ),
        child: SafeArea(
          child: _analysis == null
              ? const Center(
                  child: CircularProgressIndicator(color: colorAccent),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatisticsCard(),
                      const SizedBox(height: 16),
                      _buildActionsCard(),
                      const SizedBox(height: 16),
                      _buildIssuesCard(),
                      const SizedBox(height: 16),
                      _buildMonitoringCard(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final stats = _analysis!['statistics'] as Map<String, dynamic>;
    final rooms = _analysis!['rooms'] as Map<String, dynamic>;
    final players = _analysis!['players'] as Map<String, dynamic>;

    return Card(
      color: colorBg2.withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Statistiques',
              style: TextStyle(
                color: colorAccent,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Rooms', stats['totalRooms'].toString(), colorAccent),
                ),
                Expanded(
                  child: _buildStatItem('Actives', stats['activeRooms'].toString(), colorSuccess),
                ),
                Expanded(
                  child: _buildStatItem('Joueurs', stats['totalPlayers'].toString(), colorWarning),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Inactives', stats['inactiveRooms'].toString(), colorError),
                ),
                Expanded(
                  child: _buildStatItem('Moyenne', stats['averagePlayersPerRoom'], colorAccent),
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: colorText,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActionsCard() {
    return Card(
      color: colorBg2.withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🛠️ Actions',
              style: TextStyle(
                color: colorAccent,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildActionButton(
                  'Nettoyer Rooms',
                  Icons.cleaning_services,
                  colorWarning,
                  _cleanupInactiveRooms,
                ),
                _buildActionButton(
                  'Nettoyer Joueurs',
                  Icons.person_remove,
                  colorWarning,
                  _cleanupInactivePlayers,
                ),
                _buildActionButton(
                  'Sauvegarder',
                  Icons.save,
                  colorSuccess,
                  _backupDatabase,
                ),
                _buildActionButton(
                  'Rapport',
                  Icons.description,
                  colorAccent,
                  _generateReport,
                ),
                _buildActionButton(
                  'Tout Supprimer',
                  Icons.delete_forever,
                  colorError,
                  _clearAllData,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildIssuesCard() {
    final issues = _analysis!['issues'] as List<Map<String, dynamic>>;

    return Card(
      color: colorBg2.withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '⚠️ Problèmes',
                  style: TextStyle(
                    color: colorAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: issues.isEmpty ? colorSuccess : colorError,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    issues.length.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (issues.isEmpty)
              const Text(
                '✅ Aucun problème détecté',
                style: TextStyle(color: colorSuccess),
              )
            else
              ...issues.map((issue) => _buildIssueItem(issue)),
          ],
        ),
      ),
    );
  }

  Widget _buildIssueItem(Map<String, dynamic> issue) {
    Color severityColor;
    switch (issue['severity']) {
      case 'high':
        severityColor = colorError;
        break;
      case 'medium':
        severityColor = colorWarning;
        break;
      default:
        severityColor = colorAccent;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: severityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: severityColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                color: severityColor,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  issue['message'],
                  style: const TextStyle(color: colorText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Suggestion: ${issue['suggestion']}',
            style: TextStyle(
              color: colorText.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonitoringCard() {
    return Card(
      color: colorBg2.withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  '👁️ Monitoring',
                  style: TextStyle(
                    color: colorAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _toggleMonitoring,
                  icon: Icon(_isMonitoring ? Icons.stop : Icons.play_arrow),
                  label: Text(_isMonitoring ? 'Arrêter' : 'Démarrer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isMonitoring ? colorError.withOpacity(0.2) : colorSuccess.withOpacity(0.2),
                    foregroundColor: _isMonitoring ? colorError : colorSuccess,
                    side: BorderSide(
                      color: _isMonitoring ? colorError.withOpacity(0.5) : colorSuccess.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_monitoringEvents.isEmpty)
              Text(
                _isMonitoring ? 'En attente d\'événements...' : 'Monitoring arrêté',
                style: TextStyle(color: colorText.withOpacity(0.7)),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: _monitoringEvents.length,
                  itemBuilder: (context, index) {
                    final event = _monitoringEvents[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorBg1.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            event['type'] == 'rooms_update' ? Icons.meeting_room : Icons.person,
                            color: colorAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${event['type']} - ${event['timestamp']}',
                              style: const TextStyle(
                                color: colorText,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
