import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../firebase_options.dart';

/// Service de gestion complète de la base de données Firebase
/// Fournit des outils pour administrer, nettoyer et analyser la BDD
class FirebaseDatabaseManager {
  static final FirebaseDatabaseManager _instance = FirebaseDatabaseManager._internal();
  factory FirebaseDatabaseManager() => _instance;
  FirebaseDatabaseManager._internal();

  FirebaseDatabase? _database;
  FirebaseAuth? _auth;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('🔥 Initialisation Firebase Database Manager...');
      
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      _database = FirebaseDatabase.instance;
      _auth = FirebaseAuth.instance;
      
      _isInitialized = true;
      print('✅ Firebase Database Manager initialisé');
      
    } catch (e) {
      print('❌ Erreur initialisation Database Manager: $e');
      throw Exception('Erreur d\'initialisation: $e');
    }
  }

  /// === ANALYSE DE LA BASE DE DONNÉES ===

  /// Analyse complète de la structure de la BDD
  Future<Map<String, dynamic>> analyzeDatabase() async {
    if (!_isInitialized) await initialize();
    
    print('📊 Analyse de la base de données...');
    
    final analysis = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'rooms': await _analyzeRooms(),
      'players': await _analyzePlayers(),
      'statistics': await _getStatistics(),
      'issues': await _detectIssues(),
    };
    
    print('✅ Analyse terminée');
    return analysis;
  }

  Future<Map<String, dynamic>> _analyzeRooms() async {
    try {
      final snapshot = await _database!.ref('rooms').get();
      final rooms = <String, dynamic>{};
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          rooms['total'] = data.length;
          rooms['active'] = 0;
          rooms['inactive'] = 0;
          rooms['details'] = <Map<String, dynamic>>[];
          
          data.forEach((key, value) {
            if (value is Map<dynamic, dynamic>) {
              final room = Map<String, dynamic>.from(value);
              final isActive = room['gameState'] == 'waiting' || room['gameState'] == 'playing';
              
              if (isActive) {
                rooms['active']++;
              } else {
                rooms['inactive']++;
              }
              
              rooms['details'].add({
                'id': key,
                'name': room['name'] ?? 'Sans nom',
                'code': room['code'] ?? 'N/A',
                'hostId': room['hostId'] ?? 'N/A',
                'gameState': room['gameState'] ?? 'unknown',
                'playerCount': room['players'] != null ? (room['players'] as Map).length : 0,
                'createdAt': room['createdAt'] ?? 'N/A',
                'lastActivity': room['lastActivity'] ?? 'N/A',
              });
            }
          });
        }
      } else {
        rooms['total'] = 0;
        rooms['active'] = 0;
        rooms['inactive'] = 0;
        rooms['details'] = <Map<String, dynamic>>[];
      }
      
      return rooms;
    } catch (e) {
      print('❌ Erreur analyse rooms: $e');
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _analyzePlayers() async {
    try {
      final snapshot = await _database!.ref('players').get();
      final players = <String, dynamic>{};
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          players['total'] = data.length;
          players['online'] = 0;
          players['offline'] = 0;
          players['details'] = <Map<String, dynamic>>[];
          
          data.forEach((key, value) {
            if (value is Map<dynamic, dynamic>) {
              final player = Map<String, dynamic>.from(value);
              final isOnline = player['isOnline'] == true;
              
              if (isOnline) {
                players['online']++;
              } else {
                players['offline']++;
              }
              
              players['details'].add({
                'id': key,
                'name': player['name'] ?? 'Sans nom',
                'isOnline': isOnline,
                'lastSeen': player['lastSeen'] ?? 'N/A',
                'currentRoom': player['currentRoom'] ?? 'N/A',
              });
            }
          });
        }
      } else {
        players['total'] = 0;
        players['online'] = 0;
        players['offline'] = 0;
        players['details'] = <Map<String, dynamic>>[];
      }
      
      return players;
    } catch (e) {
      print('❌ Erreur analyse players: $e');
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _getStatistics() async {
    try {
      final roomsSnapshot = await _database!.ref('rooms').get();
      final playersSnapshot = await _database!.ref('players').get();
      
      int totalRooms = 0;
      int totalPlayers = 0;
      int activeRooms = 0;
      
      if (roomsSnapshot.exists) {
        final roomsData = roomsSnapshot.value as Map<dynamic, dynamic>?;
        if (roomsData != null) {
          totalRooms = roomsData.length;
          roomsData.forEach((key, value) {
            if (value is Map<dynamic, dynamic>) {
              final room = Map<String, dynamic>.from(value);
              if (room['gameState'] == 'waiting' || room['gameState'] == 'playing') {
                activeRooms++;
              }
            }
          });
        }
      }
      
      if (playersSnapshot.exists) {
        final playersData = playersSnapshot.value as Map<dynamic, dynamic>?;
        if (playersData != null) {
          totalPlayers = playersData.length;
        }
      }
      
      return {
        'totalRooms': totalRooms,
        'totalPlayers': totalPlayers,
        'activeRooms': activeRooms,
        'inactiveRooms': totalRooms - activeRooms,
        'averagePlayersPerRoom': totalRooms > 0 ? (totalPlayers / totalRooms).toStringAsFixed(2) : '0',
      };
    } catch (e) {
      print('❌ Erreur statistiques: $e');
      return {'error': e.toString()};
    }
  }

  Future<List<Map<String, dynamic>>> _detectIssues() async {
    final issues = <Map<String, dynamic>>[];
    
    try {
      // Vérifier les rooms orphelines
      final roomsSnapshot = await _database!.ref('rooms').get();
      if (roomsSnapshot.exists) {
        final roomsData = roomsSnapshot.value as Map<dynamic, dynamic>?;
        if (roomsData != null) {
          roomsData.forEach((key, value) {
            if (value is Map<dynamic, dynamic>) {
              final room = Map<String, dynamic>.from(value);
              
              // Room sans joueurs
              if (room['players'] == null || (room['players'] as Map).isEmpty) {
                issues.add({
                  'type': 'empty_room',
                  'severity': 'medium',
                  'roomId': key,
                  'message': 'Room vide sans joueurs',
                  'suggestion': 'Supprimer cette room',
                });
              }
              
              // Room inactive depuis trop longtemps
              final lastActivity = room['lastActivity'];
              if (lastActivity != null) {
                try {
                  final lastActivityDate = DateTime.parse(lastActivity);
                  final now = DateTime.now();
                  final diff = now.difference(lastActivityDate);
                  
                  if (diff.inHours > 24) {
                    issues.add({
                      'type': 'inactive_room',
                      'severity': 'low',
                      'roomId': key,
                      'message': 'Room inactive depuis ${diff.inHours}h',
                      'suggestion': 'Nettoyer cette room',
                    });
                  }
                } catch (e) {
                  issues.add({
                    'type': 'invalid_date',
                    'severity': 'low',
                    'roomId': key,
                    'message': 'Date de dernière activité invalide',
                    'suggestion': 'Corriger la date',
                  });
                }
              }
            }
          });
        }
      }
      
      // Vérifier les joueurs orphelins
      final playersSnapshot = await _database!.ref('players').get();
      if (playersSnapshot.exists) {
        final playersData = playersSnapshot.value as Map<dynamic, dynamic>?;
        if (playersData != null) {
          playersData.forEach((key, value) {
            if (value is Map<dynamic, dynamic>) {
              final player = Map<String, dynamic>.from(value);
              
              // Joueur hors ligne depuis trop longtemps
              final lastSeen = player['lastSeen'];
              if (lastSeen != null && player['isOnline'] != true) {
                try {
                  final lastSeenDate = DateTime.parse(lastSeen);
                  final now = DateTime.now();
                  final diff = now.difference(lastSeenDate);
                  
                  if (diff.inDays > 7) {
                    issues.add({
                      'type': 'inactive_player',
                      'severity': 'low',
                      'playerId': key,
                      'message': 'Joueur hors ligne depuis ${diff.inDays} jours',
                      'suggestion': 'Supprimer ce joueur',
                    });
                  }
                } catch (e) {
                  // Date invalide, ignorer
                }
              }
            }
          });
        }
      }
      
    } catch (e) {
      issues.add({
        'type': 'analysis_error',
        'severity': 'high',
        'message': 'Erreur lors de l\'analyse: $e',
        'suggestion': 'Vérifier la connexion Firebase',
      });
    }
    
    return issues;
  }

  /// === NETTOYAGE DE LA BASE DE DONNÉES ===

  /// Nettoie les rooms inactives
  Future<Map<String, dynamic>> cleanupInactiveRooms({int maxHoursInactive = 24}) async {
    if (!_isInitialized) await initialize();
    
    print('🧹 Nettoyage des rooms inactives...');
    
    final result = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'deletedRooms': <String>[],
      'errors': <String>[],
      'totalDeleted': 0,
    };
    
    try {
      final snapshot = await _database!.ref('rooms').get();
      if (snapshot.exists) {
        final roomsData = snapshot.value as Map<dynamic, dynamic>?;
        if (roomsData != null) {
          final now = DateTime.now();
          
          for (final entry in roomsData.entries) {
            try {
              final room = Map<String, dynamic>.from(entry.value);
              final lastActivity = room['lastActivity'];
              
              if (lastActivity != null) {
                final lastActivityDate = DateTime.parse(lastActivity);
                final diff = now.difference(lastActivityDate);
                
                if (diff.inHours > maxHoursInactive) {
                  await _database!.ref('rooms/${entry.key}').remove();
                  result['deletedRooms'].add(entry.key);
                  result['totalDeleted']++;
                  print('🗑️ Room supprimée: ${entry.key} (inactive depuis ${diff.inHours}h)');
                }
              }
            } catch (e) {
              result['errors'].add('Erreur room ${entry.key}: $e');
            }
          }
        }
      }
      
      print('✅ Nettoyage terminé: ${result['totalDeleted']} rooms supprimées');
      
    } catch (e) {
      print('❌ Erreur nettoyage: $e');
      result['errors'].add('Erreur générale: $e');
    }
    
    return result;
  }

  /// Nettoie les joueurs inactifs
  Future<Map<String, dynamic>> cleanupInactivePlayers({int maxDaysInactive = 7}) async {
    if (!_isInitialized) await initialize();
    
    print('🧹 Nettoyage des joueurs inactifs...');
    
    final result = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'deletedPlayers': <String>[],
      'errors': <String>[],
      'totalDeleted': 0,
    };
    
    try {
      final snapshot = await _database!.ref('players').get();
      if (snapshot.exists) {
        final playersData = snapshot.value as Map<dynamic, dynamic>?;
        if (playersData != null) {
          final now = DateTime.now();
          
          for (final entry in playersData.entries) {
            try {
              final player = Map<String, dynamic>.from(entry.value);
              final lastSeen = player['lastSeen'];
              final isOnline = player['isOnline'] == true;
              
              if (!isOnline && lastSeen != null) {
                final lastSeenDate = DateTime.parse(lastSeen);
                final diff = now.difference(lastSeenDate);
                
                if (diff.inDays > maxDaysInactive) {
                  await _database!.ref('players/${entry.key}').remove();
                  result['deletedPlayers'].add(entry.key);
                  result['totalDeleted']++;
                  print('🗑️ Joueur supprimé: ${entry.key} (hors ligne depuis ${diff.inDays} jours)');
                }
              }
            } catch (e) {
              result['errors'].add('Erreur joueur ${entry.key}: $e');
            }
          }
        }
      }
      
      print('✅ Nettoyage terminé: ${result['totalDeleted']} joueurs supprimés');
      
    } catch (e) {
      print('❌ Erreur nettoyage: $e');
      result['errors'].add('Erreur générale: $e');
    }
    
    return result;
  }

  /// Supprime toutes les données (ATTENTION: DESTRUCTIF!)
  Future<Map<String, dynamic>> clearAllData() async {
    if (!_isInitialized) await initialize();
    
    print('⚠️ ATTENTION: Suppression de toutes les données!');
    
    final result = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'deletedNodes': <String>[],
      'errors': <String>[],
    };
    
    try {
      // Supprimer toutes les rooms
      await _database!.ref('rooms').remove();
      result['deletedNodes'].add('rooms');
      print('🗑️ Toutes les rooms supprimées');
      
      // Supprimer tous les joueurs
      await _database!.ref('players').remove();
      result['deletedNodes'].add('players');
      print('🗑️ Tous les joueurs supprimés');
      
      print('✅ Toutes les données supprimées');
      
    } catch (e) {
      print('❌ Erreur suppression: $e');
      result['errors'].add('Erreur générale: $e');
    }
    
    return result;
  }

  /// === SAUVEGARDE ET RESTAURATION ===

  /// Sauvegarde complète de la base de données
  Future<Map<String, dynamic>> backupDatabase() async {
    if (!_isInitialized) await initialize();
    
    print('💾 Sauvegarde de la base de données...');
    
    final backup = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
      'data': <String, dynamic>{},
    };
    
    try {
      // Sauvegarder les rooms
      final roomsSnapshot = await _database!.ref('rooms').get();
      if (roomsSnapshot.exists) {
        backup['data']['rooms'] = roomsSnapshot.value;
      }
      
      // Sauvegarder les joueurs
      final playersSnapshot = await _database!.ref('players').get();
      if (playersSnapshot.exists) {
        backup['data']['players'] = playersSnapshot.value;
      }
      
      // Sauvegarder dans un fichier local
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'firebase_backup_$timestamp.json';
      final file = File(filename);
      await file.writeAsString(jsonEncode(backup));
      
      print('✅ Sauvegarde terminée: $filename');
      
      return {
        'success': true,
        'filename': filename,
        'size': backup.toString().length,
        'timestamp': backup['timestamp'],
      };
      
    } catch (e) {
      print('❌ Erreur sauvegarde: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Restaure la base de données depuis un fichier de sauvegarde
  Future<Map<String, dynamic>> restoreDatabase(String filename) async {
    if (!_isInitialized) await initialize();
    
    print('🔄 Restauration de la base de données depuis $filename...');
    
    final result = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'restoredNodes': <String>[],
      'errors': <String>[],
    };
    
    try {
      final file = File(filename);
      if (!await file.exists()) {
        throw Exception('Fichier de sauvegarde introuvable: $filename');
      }
      
      final content = await file.readAsString();
      final backup = jsonDecode(content) as Map<String, dynamic>;
      final data = backup['data'] as Map<String, dynamic>;
      
      // Restaurer les rooms
      if (data.containsKey('rooms')) {
        await _database!.ref('rooms').set(data['rooms']);
        result['restoredNodes'].add('rooms');
        print('✅ Rooms restaurées');
      }
      
      // Restaurer les joueurs
      if (data.containsKey('players')) {
        await _database!.ref('players').set(data['players']);
        result['restoredNodes'].add('players');
        print('✅ Joueurs restaurés');
      }
      
      print('✅ Restauration terminée');
      
    } catch (e) {
      print('❌ Erreur restauration: $e');
      result['errors'].add(e.toString());
    }
    
    return result;
  }

  /// === MONITORING EN TEMPS RÉEL ===

  /// Surveille les changements en temps réel
  Stream<Map<String, dynamic>> monitorDatabase() async* {
    if (!_isInitialized) await initialize();
    
    print('👁️ Surveillance de la base de données activée...');
    
    final roomsController = StreamController<Map<String, dynamic>>.broadcast();
    final playersController = StreamController<Map<String, dynamic>>.broadcast();
    
    // Surveiller les rooms
    _database!.ref('rooms').onValue.listen((event) {
      final data = event.snapshot.value;
      roomsController.add({
        'type': 'rooms_update',
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
      });
    });
    
    // Surveiller les joueurs
    _database!.ref('players').onValue.listen((event) {
      final data = event.snapshot.value;
      playersController.add({
        'type': 'players_update',
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
      });
    });
    
    // Combiner les streams
    await for (final event in Stream.merge([roomsController.stream, playersController.stream])) {
      yield event;
    }
  }

  /// === UTILITAIRES ===

  /// Génère un rapport complet
  Future<String> generateReport() async {
    final analysis = await analyzeDatabase();
    
    final report = StringBuffer();
    report.writeln('=== RAPPORT DE BASE DE DONNÉES FIREBASE ===');
    report.writeln('Généré le: ${analysis['timestamp']}');
    report.writeln();
    
    // Statistiques générales
    final stats = analysis['statistics'] as Map<String, dynamic>;
    report.writeln('📊 STATISTIQUES GÉNÉRALES:');
    report.writeln('  • Total rooms: ${stats['totalRooms']}');
    report.writeln('  • Rooms actives: ${stats['activeRooms']}');
    report.writeln('  • Rooms inactives: ${stats['inactiveRooms']}');
    report.writeln('  • Total joueurs: ${stats['totalPlayers']}');
    report.writeln('  • Moyenne joueurs/room: ${stats['averagePlayersPerRoom']}');
    report.writeln();
    
    // Détails des rooms
    final rooms = analysis['rooms'] as Map<String, dynamic>;
    report.writeln('🏠 DÉTAILS DES ROOMS:');
    report.writeln('  • Total: ${rooms['total']}');
    report.writeln('  • Actives: ${rooms['active']}');
    report.writeln('  • Inactives: ${rooms['inactive']}');
    report.writeln();
    
    // Problèmes détectés
    final issues = analysis['issues'] as List<Map<String, dynamic>>;
    if (issues.isNotEmpty) {
      report.writeln('⚠️ PROBLÈMES DÉTECTÉS:');
      for (final issue in issues) {
        report.writeln('  • ${issue['type']}: ${issue['message']}');
        report.writeln('    Suggestion: ${issue['suggestion']}');
      }
      report.writeln();
    } else {
      report.writeln('✅ Aucun problème détecté');
      report.writeln();
    }
    
    return report.toString();
  }

  /// Ferme les connexions
  void dispose() {
    _roomStateController?.close();
    _availableRoomsController?.close();
    _roomSubscription?.cancel();
    _availableRoomsSubscription?.cancel();
  }
}
