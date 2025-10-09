import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/firebase_database_manager.dart';

/// Service de maintenance automatique de la base de données Firebase
class FirebaseMaintenanceService {
  static final FirebaseMaintenanceService _instance = FirebaseMaintenanceService._internal();
  factory FirebaseMaintenanceService() => _instance;
  FirebaseMaintenanceService._internal();

  final FirebaseDatabaseManager _dbManager = FirebaseDatabaseManager();
  Timer? _maintenanceTimer;
  bool _isRunning = false;

  /// Démarrer la maintenance automatique
  Future<void> startAutomaticMaintenance({
    Duration interval = const Duration(hours: 6),
    int maxHoursInactiveRooms = 24,
    int maxDaysInactivePlayers = 7,
  }) async {
    if (_isRunning) return;

    try {
      await _dbManager.initialize();
      _isRunning = true;

      print('🔧 Démarrage de la maintenance automatique Firebase...');
      print('   • Intervalle: ${interval.inHours}h');
      print('   • Rooms inactives: ${maxHoursInactiveRooms}h');
      print('   • Joueurs inactifs: ${maxDaysInactivePlayers} jours');

      _maintenanceTimer = Timer.periodic(interval, (timer) async {
        await _performMaintenance(
          maxHoursInactiveRooms: maxHoursInactiveRooms,
          maxDaysInactivePlayers: maxDaysInactivePlayers,
        );
      });

      // Exécuter immédiatement
      await _performMaintenance(
        maxHoursInactiveRooms: maxHoursInactiveRooms,
        maxDaysInactivePlayers: maxDaysInactivePlayers,
      );

      print('✅ Maintenance automatique démarrée');

    } catch (e) {
      print('❌ Erreur démarrage maintenance: $e');
      _isRunning = false;
    }
  }

  /// Arrêter la maintenance automatique
  void stopAutomaticMaintenance() {
    if (!_isRunning) return;

    _maintenanceTimer?.cancel();
    _maintenanceTimer = null;
    _isRunning = false;

    print('🛑 Maintenance automatique arrêtée');
  }

  /// Effectuer une maintenance manuelle
  Future<Map<String, dynamic>> performManualMaintenance({
    int maxHoursInactiveRooms = 24,
    int maxDaysInactivePlayers = 7,
  }) async {
    return await _performMaintenance(
      maxHoursInactiveRooms: maxHoursInactiveRooms,
      maxDaysInactivePlayers: maxDaysInactivePlayers,
    );
  }

  /// Logique de maintenance
  Future<Map<String, dynamic>> _performMaintenance({
    required int maxHoursInactiveRooms,
    required int maxDaysInactivePlayers,
  }) async {
    final timestamp = DateTime.now();
    print('🔧 Maintenance Firebase - ${timestamp.toIso8601String()}');

    final results = <String, dynamic>{
      'timestamp': timestamp.toIso8601String(),
      'roomsCleanup': <String, dynamic>{},
      'playersCleanup': <String, dynamic>{},
      'backup': <String, dynamic>{},
      'analysis': <String, dynamic>{},
    };

    try {
      // 1. Analyser la base de données
      print('📊 Analyse de la base de données...');
      results['analysis'] = await _dbManager.analyzeDatabase();

      // 2. Nettoyer les rooms inactives
      print('🧹 Nettoyage des rooms inactives...');
      results['roomsCleanup'] = await _dbManager.cleanupInactiveRooms(
        maxHoursInactive: maxHoursInactiveRooms,
      );

      // 3. Nettoyer les joueurs inactifs
      print('🧹 Nettoyage des joueurs inactifs...');
      results['playersCleanup'] = await _dbManager.cleanupInactivePlayers(
        maxDaysInactive: maxDaysInactivePlayers,
      );

      // 4. Créer une sauvegarde si nécessaire
      final stats = results['analysis']['statistics'] as Map<String, dynamic>;
      if (stats['totalRooms'] > 0 || stats['totalPlayers'] > 0) {
        print('💾 Création de sauvegarde...');
        results['backup'] = await _dbManager.backupDatabase();
      }

      // 5. Résumé
      final totalCleaned = (results['roomsCleanup']['totalDeleted'] as int) +
          (results['playersCleanup']['totalDeleted'] as int);

      print('✅ Maintenance terminée:');
      print('   • Rooms supprimées: ${results['roomsCleanup']['totalDeleted']}');
      print('   • Joueurs supprimés: ${results['playersCleanup']['totalDeleted']}');
      print('   • Total nettoyé: $totalCleaned');

      if (results['backup']['success'] == true) {
        print('   • Sauvegarde créée: ${results['backup']['filename']}');
      }

    } catch (e) {
      print('❌ Erreur pendant la maintenance: $e');
      results['error'] = e.toString();
    }

    return results;
  }

  /// Obtenir le statut de la maintenance
  Map<String, dynamic> getStatus() {
    return {
      'isRunning': _isRunning,
      'nextRun': _maintenanceTimer?.isActive == true ? 'Dans ${_getNextRunTime()}' : 'Non programmé',
      'lastRun': _getLastRunTime(),
    };
  }

  String _getNextRunTime() {
    // Cette méthode devrait être implémentée pour calculer le prochain run
    return 'Calcul en cours...';
  }

  String _getLastRunTime() {
    // Cette méthode devrait être implémentée pour stocker la dernière exécution
    return 'Non disponible';
  }

  /// Nettoyer les anciennes sauvegardes
  Future<void> cleanupOldBackups({int maxBackups = 10}) async {
    try {
      final directory = Directory('.');
      final files = directory.listSync()
          .where((file) => file is File && file.path.contains('firebase_backup_'))
          .cast<File>()
          .toList();

      // Trier par date de modification (plus récent en premier)
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      // Supprimer les anciennes sauvegardes
      if (files.length > maxBackups) {
        final filesToDelete = files.skip(maxBackups);
        for (final file in filesToDelete) {
          await file.delete();
          print('🗑️ Sauvegarde supprimée: ${file.path}');
        }
      }

    } catch (e) {
      print('❌ Erreur nettoyage sauvegardes: $e');
    }
  }

  /// Surveiller la santé de la base de données
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final analysis = await _dbManager.analyzeDatabase();
      final issues = analysis['issues'] as List<Map<String, dynamic>>;
      
      final health = <String, dynamic>{
        'status': 'healthy',
        'score': 100,
        'issues': issues.length,
        'recommendations': <String>[],
      };

      // Calculer le score de santé
      int score = 100;
      
      for (final issue in issues) {
        switch (issue['severity']) {
          case 'high':
            score -= 20;
            health['recommendations'].add('🔴 ${issue['suggestion']}');
            break;
          case 'medium':
            score -= 10;
            health['recommendations'].add('🟡 ${issue['suggestion']}');
            break;
          case 'low':
            score -= 5;
            health['recommendations'].add('🟢 ${issue['suggestion']}');
            break;
        }
      }

      // Déterminer le statut
      if (score >= 90) {
        health['status'] = 'excellent';
      } else if (score >= 70) {
        health['status'] = 'good';
      } else if (score >= 50) {
        health['status'] = 'warning';
      } else {
        health['status'] = 'critical';
      }

      health['score'] = score;

      return health;

    } catch (e) {
      return {
        'status': 'error',
        'score': 0,
        'error': e.toString(),
      };
    }
  }

  /// Générer un rapport de maintenance
  Future<String> generateMaintenanceReport() async {
    final analysis = await _dbManager.analyzeDatabase();
    final health = await healthCheck();
    final status = getStatus();

    final report = StringBuffer();
    report.writeln('=== RAPPORT DE MAINTENANCE FIREBASE ===');
    report.writeln('Généré le: ${DateTime.now().toIso8601String()}');
    report.writeln();

    // Statut de la maintenance
    report.writeln('🔧 STATUT DE LA MAINTENANCE:');
    report.writeln('  • Maintenance active: ${status['isRunning'] ? 'Oui' : 'Non'}');
    report.writeln('  • Prochaine exécution: ${status['nextRun']}');
    report.writeln('  • Dernière exécution: ${status['lastRun']}');
    report.writeln();

    // Santé de la base de données
    report.writeln('💚 SANTÉ DE LA BASE DE DONNÉES:');
    report.writeln('  • Statut: ${health['status']}');
    report.writeln('  • Score: ${health['score']}/100');
    report.writeln('  • Problèmes: ${health['issues']}');
    report.writeln();

    if (health['recommendations'] != null && (health['recommendations'] as List).isNotEmpty) {
      report.writeln('📋 RECOMMANDATIONS:');
      for (final recommendation in health['recommendations']) {
        report.writeln('  • $recommendation');
      }
      report.writeln();
    }

    // Statistiques
    final stats = analysis['statistics'] as Map<String, dynamic>;
    report.writeln('📊 STATISTIQUES:');
    report.writeln('  • Total rooms: ${stats['totalRooms']}');
    report.writeln('  • Rooms actives: ${stats['activeRooms']}');
    report.writeln('  • Rooms inactives: ${stats['inactiveRooms']}');
    report.writeln('  • Total joueurs: ${stats['totalPlayers']}');
    report.writeln('  • Moyenne joueurs/room: ${stats['averagePlayersPerRoom']}');
    report.writeln();

    return report.toString();
  }

  void dispose() {
    stopAutomaticMaintenance();
  }
}
