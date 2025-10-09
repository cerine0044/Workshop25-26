#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Script de gestion Firebase depuis le terminal (version simplifiée)
/// Usage: dart firebase_cli_simple.dart [command] [options]
void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    _showHelp();
    return;
  }

  try {
    // Configuration Firebase simplifiée
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyAUxg49zSnarmKRkuAQFG6dBhTiCcy2AMo',
        appId: '1:519180282303:web:57de096e5374398fc8190a',
        messagingSenderId: '519180282303',
        projectId: 'pandora-box-user2',
        authDomain: 'pandora-box-user2.firebaseapp.com',
        databaseURL: 'https://pandora-box-user2-default-rtdb.europe-west1.firebasedatabase.app',
        storageBucket: 'pandora-box-user2.firebasestorage.app',
      ),
    );

    final database = FirebaseDatabase.instance;
    final auth = FirebaseAuth.instance;

    final command = arguments[0];
    
    switch (command) {
      case 'analyze':
        await _analyzeDatabase(database);
        break;
      case 'cleanup':
        await _cleanupDatabase(database, arguments);
        break;
      case 'backup':
        await _backupDatabase(database);
        break;
      case 'restore':
        if (arguments.length < 2) {
          print('❌ Usage: dart firebase_cli_simple.dart restore <filename>');
          return;
        }
        await _restoreDatabase(database, arguments[1]);
        break;
      case 'clear':
        await _clearDatabase(database);
        break;
      case 'monitor':
        await _monitorDatabase(database);
        break;
      case 'stats':
        await _showStats(database);
        break;
      default:
        print('❌ Commande inconnue: $command');
        _showHelp();
    }

  } catch (e) {
    print('❌ Erreur: $e');
    exit(1);
  }
}

void _showHelp() {
  print('''
🔥 Firebase CLI Simple - Gestionnaire de base de données

COMMANDES DISPONIBLES:
  analyze     - Analyser la structure de la BDD
  cleanup     - Nettoyer les données inactives
  backup      - Créer une sauvegarde
  restore     - Restaurer depuis une sauvegarde
  clear       - Supprimer toutes les données
  monitor     - Surveiller en temps réel
  stats       - Afficher les statistiques

EXEMPLES:
  dart firebase_cli_simple.dart analyze
  dart firebase_cli_simple.dart cleanup --rooms 24 --players 7
  dart firebase_cli_simple.dart backup
  dart firebase_cli_simple.dart restore backup_1234567890.json
  dart firebase_cli_simple.dart clear
  dart firebase_cli_simple.dart monitor
  dart firebase_cli_simple.dart stats

OPTIONS:
  --rooms <hours>    - Heures d'inactivité pour nettoyer les rooms (défaut: 24)
  --players <days>    - Jours d'inactivité pour nettoyer les joueurs (défaut: 7)
  --force            - Forcer l'opération sans confirmation
''');
}

Future<void> _analyzeDatabase(FirebaseDatabase database) async {
  print('📊 Analyse de la base de données...');
  
  try {
    // Analyser les rooms
    final roomsSnapshot = await database.ref('rooms').get();
    int totalRooms = 0;
    int activeRooms = 0;
    int emptyRooms = 0;
    
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
            
            if (room['players'] == null || (room['players'] as Map).isEmpty) {
              emptyRooms++;
            }
          }
        });
      }
    }
    
    // Analyser les joueurs
    final playersSnapshot = await database.ref('players').get();
    int totalPlayers = 0;
    int onlinePlayers = 0;
    
    if (playersSnapshot.exists) {
      final playersData = playersSnapshot.value as Map<dynamic, dynamic>?;
      if (playersData != null) {
        totalPlayers = playersData.length;
        
        playersData.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            final player = Map<String, dynamic>.from(value);
            if (player['isOnline'] == true) {
              onlinePlayers++;
            }
          }
        });
      }
    }
    
    print('✅ Analyse terminée:');
    print('   📊 Rooms: $totalRooms total, $activeRooms actives, $emptyRooms vides');
    print('   👥 Joueurs: $totalPlayers total, $onlinePlayers en ligne');
    
  } catch (e) {
    print('❌ Erreur d\'analyse: $e');
  }
}

Future<void> _cleanupDatabase(FirebaseDatabase database, List<String> arguments) async {
  int maxHoursRooms = 24;
  int maxDaysPlayers = 7;
  bool force = false;
  
  // Parser les arguments
  for (int i = 1; i < arguments.length; i++) {
    switch (arguments[i]) {
      case '--rooms':
        if (i + 1 < arguments.length) {
          maxHoursRooms = int.tryParse(arguments[i + 1]) ?? 24;
          i++;
        }
        break;
      case '--players':
        if (i + 1 < arguments.length) {
          maxDaysPlayers = int.tryParse(arguments[i + 1]) ?? 7;
          i++;
        }
        break;
      case '--force':
        force = true;
        break;
    }
  }
  
  print('🧹 Nettoyage de la base de données...');
  print('   • Rooms inactives depuis: ${maxHoursRooms}h');
  print('   • Joueurs inactifs depuis: ${maxDaysPlayers} jours');
  
  if (!force) {
    print('⚠️ Cette opération va supprimer des données. Continuer ? (y/N)');
    final input = stdin.readLineSync();
    if (input?.toLowerCase() != 'y') {
      print('❌ Opération annulée');
      return;
    }
  }
  
  try {
    int deletedRooms = 0;
    int deletedPlayers = 0;
    
    // Nettoyer les rooms
    final roomsSnapshot = await database.ref('rooms').get();
    if (roomsSnapshot.exists) {
      final roomsData = roomsSnapshot.value as Map<dynamic, dynamic>?;
      if (roomsData != null) {
        final now = DateTime.now();
        
        for (final entry in roomsData.entries) {
          try {
            final room = Map<String, dynamic>.from(entry.value);
            final lastActivity = room['lastActivity'];
            
            if (lastActivity != null) {
              final lastActivityDate = DateTime.parse(lastActivity);
              final diff = now.difference(lastActivityDate);
              
              if (diff.inHours > maxHoursRooms) {
                await database.ref('rooms/${entry.key}').remove();
                deletedRooms++;
                print('🗑️ Room supprimée: ${entry.key}');
              }
            }
          } catch (e) {
            print('⚠️ Erreur room ${entry.key}: $e');
          }
        }
      }
    }
    
    // Nettoyer les joueurs
    final playersSnapshot = await database.ref('players').get();
    if (playersSnapshot.exists) {
      final playersData = playersSnapshot.value as Map<dynamic, dynamic>?;
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
              
              if (diff.inDays > maxDaysPlayers) {
                await database.ref('players/${entry.key}').remove();
                deletedPlayers++;
                print('🗑️ Joueur supprimé: ${entry.key}');
              }
            }
          } catch (e) {
            print('⚠️ Erreur joueur ${entry.key}: $e');
          }
        }
      }
    }
    
    print('✅ Nettoyage terminé:');
    print('   • Rooms supprimées: $deletedRooms');
    print('   • Joueurs supprimés: $deletedPlayers');
    
  } catch (e) {
    print('❌ Erreur de nettoyage: $e');
  }
}

Future<void> _backupDatabase(FirebaseDatabase database) async {
  print('💾 Création de sauvegarde...');
  
  try {
    final backup = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
      'data': <String, dynamic>{},
    };
    
    // Sauvegarder les rooms
    final roomsSnapshot = await database.ref('rooms').get();
    if (roomsSnapshot.exists) {
      backup['data']['rooms'] = roomsSnapshot.value;
    }
    
    // Sauvegarder les joueurs
    final playersSnapshot = await database.ref('players').get();
    if (playersSnapshot.exists) {
      backup['data']['players'] = playersSnapshot.value;
    }
    
    // Sauvegarder dans un fichier
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final filename = 'firebase_backup_$timestamp.json';
    final file = File(filename);
    await file.writeAsString(jsonEncode(backup));
    
    print('✅ Sauvegarde créée: $filename');
    print('   • Taille: ${file.lengthSync()} bytes');
    
  } catch (e) {
    print('❌ Erreur de sauvegarde: $e');
  }
}

Future<void> _restoreDatabase(FirebaseDatabase database, String filename) async {
  print('🔄 Restauration depuis $filename...');
  
  try {
    final file = File(filename);
    if (!await file.exists()) {
      print('❌ Fichier de sauvegarde introuvable: $filename');
      return;
    }
    
    print('⚠️ Cette opération va remplacer toutes les données. Continuer ? (y/N)');
    final input = stdin.readLineSync();
    if (input?.toLowerCase() != 'y') {
      print('❌ Opération annulée');
      return;
    }
    
    final content = await file.readAsString();
    final backup = jsonDecode(content) as Map<String, dynamic>;
    final data = backup['data'] as Map<String, dynamic>;
    
    // Restaurer les rooms
    if (data.containsKey('rooms')) {
      await database.ref('rooms').set(data['rooms']);
      print('✅ Rooms restaurées');
    }
    
    // Restaurer les joueurs
    if (data.containsKey('players')) {
      await database.ref('players').set(data['players']);
      print('✅ Joueurs restaurés');
    }
    
    print('✅ Restauration terminée');
    
  } catch (e) {
    print('❌ Erreur de restauration: $e');
  }
}

Future<void> _clearDatabase(FirebaseDatabase database) async {
  print('⚠️ ATTENTION: Cette opération va supprimer TOUTES les données !');
  print('Êtes-vous sûr ? Tapez "DELETE" pour confirmer:');
  
  final input = stdin.readLineSync();
  if (input != 'DELETE') {
    print('❌ Opération annulée');
    return;
  }
  
  try {
    await database.ref('rooms').remove();
    await database.ref('players').remove();
    print('✅ Toutes les données supprimées');
    
  } catch (e) {
    print('❌ Erreur de suppression: $e');
  }
}

Future<void> _monitorDatabase(FirebaseDatabase database) async {
  print('👁️ Surveillance de la base de données (Ctrl+C pour arrêter)...');
  
  // Surveiller les rooms
  database.ref('rooms').onValue.listen((event) {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] 📊 Rooms mises à jour');
  });
  
  // Surveiller les joueurs
  database.ref('players').onValue.listen((event) {
    final timestamp = DateTime.now().toIso8601String();
    print('[$timestamp] 👥 Joueurs mis à jour');
  });
  
  // Attendre indéfiniment
  await Future.delayed(Duration(days: 365));
}

Future<void> _showStats(FirebaseDatabase database) async {
  print('📊 Statistiques de la base de données...');
  
  try {
    final roomsSnapshot = await database.ref('rooms').get();
    final playersSnapshot = await database.ref('players').get();
    
    int totalRooms = 0;
    int activeRooms = 0;
    int totalPlayers = 0;
    int onlinePlayers = 0;
    
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
        
        playersData.forEach((key, value) {
          if (value is Map<dynamic, dynamic>) {
            final player = Map<String, dynamic>.from(value);
            if (player['isOnline'] == true) {
              onlinePlayers++;
            }
          }
        });
      }
    }
    
    print('✅ Statistiques:');
    print('   📊 Rooms: $totalRooms total, $activeRooms actives');
    print('   👥 Joueurs: $totalPlayers total, $onlinePlayers en ligne');
    print('   📈 Taux d\'activité: ${totalRooms > 0 ? ((activeRooms / totalRooms) * 100).toStringAsFixed(1) : 0}%');
    
  } catch (e) {
    print('❌ Erreur de statistiques: $e');
  }
}
