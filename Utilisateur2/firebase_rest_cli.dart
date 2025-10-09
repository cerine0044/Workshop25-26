#!/usr/bin/env dart

import 'dart:io';
import 'dart:convert';
import 'dart:async';

/// Script de gestion Firebase via API REST (sans dépendances Flutter)
/// Usage: dart firebase_rest_cli.dart [command] [options]
void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    _showHelp();
    return;
  }

  final command = arguments[0];
  
  switch (command) {
    case 'analyze':
      await _analyzeDatabase();
      break;
    case 'cleanup':
      await _cleanupDatabase(arguments);
      break;
    case 'backup':
      await _backupDatabase();
      break;
    case 'restore':
      if (arguments.length < 2) {
        print('❌ Usage: dart firebase_rest_cli.dart restore <filename>');
        return;
      }
      await _restoreDatabase(arguments[1]);
      break;
    case 'clear':
      await _clearDatabase();
      break;
    case 'stats':
      await _showStats();
      break;
    case 'monitor':
      await _monitorDatabase();
      break;
    default:
      print('❌ Commande inconnue: $command');
      _showHelp();
  }
}

void _showHelp() {
  print('''
🔥 Firebase REST CLI - Gestionnaire de base de données

COMMANDES DISPONIBLES:
  analyze     - Analyser la structure de la BDD
  cleanup     - Nettoyer les données inactives
  backup      - Créer une sauvegarde
  restore     - Restaurer depuis une sauvegarde
  clear       - Supprimer toutes les données
  monitor     - Surveiller en temps réel
  stats       - Afficher les statistiques

EXEMPLES:
  dart firebase_rest_cli.dart analyze
  dart firebase_rest_cli.dart cleanup --rooms 24 --players 7
  dart firebase_rest_cli.dart backup
  dart firebase_rest_cli.dart restore backup_1234567890.json
  dart firebase_rest_cli.dart clear
  dart firebase_rest_cli.dart monitor
  dart firebase_rest_cli.dart stats

OPTIONS:
  --rooms <hours>    - Heures d'inactivité pour nettoyer les rooms (défaut: 24)
  --players <days>    - Jours d'inactivité pour nettoyer les joueurs (défaut: 7)
  --force            - Forcer l'opération sans confirmation
''');
}

// Configuration Firebase
const String _databaseUrl = 'https://pandora-box-user2-default-rtdb.firebaseio.com';
const String _apiKey = 'AIzaSyAUxg49zSnarmKRkuAQFG6dBhTiCcy2AMo';

// Fonction utilitaire pour faire des requêtes HTTP
Future<Map<String, dynamic>?> _makeRequest(String method, String path, {Map<String, dynamic>? data}) async {
  try {
    final url = Uri.parse('$_databaseUrl$path.json?auth=$_apiKey');
    
    HttpClientRequest request;
    switch (method.toUpperCase()) {
      case 'GET':
        request = await HttpClient().getUrl(url);
        break;
      case 'POST':
        request = await HttpClient().postUrl(url);
        break;
      case 'PUT':
        request = await HttpClient().putUrl(url);
        break;
      case 'DELETE':
        request = await HttpClient().deleteUrl(url);
        break;
      default:
        throw Exception('Méthode HTTP non supportée: $method');
    }
    
    if (data != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(data));
    }
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (responseBody.isEmpty) return null;
      return jsonDecode(responseBody) as Map<String, dynamic>?;
    } else {
      throw Exception('Erreur HTTP ${response.statusCode}: $responseBody');
    }
  } catch (e) {
    print('❌ Erreur requête: $e');
    return null;
  }
}

Future<void> _analyzeDatabase() async {
  print('📊 Analyse de la base de données...');
  
  try {
    // Analyser les rooms
    final roomsData = await _makeRequest('GET', '/rooms');
    int totalRooms = 0;
    int activeRooms = 0;
    int emptyRooms = 0;
    
    if (roomsData != null) {
      totalRooms = roomsData.length;
      
      roomsData.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final room = value;
          
          if (room['gameState'] == 'waiting' || room['gameState'] == 'playing') {
            activeRooms++;
          }
          
          if (room['players'] == null || (room['players'] as Map).isEmpty) {
            emptyRooms++;
          }
        }
      });
    }
    
    // Analyser les joueurs
    final playersData = await _makeRequest('GET', '/players');
    int totalPlayers = 0;
    int onlinePlayers = 0;
    
    if (playersData != null) {
      totalPlayers = playersData.length;
      
      playersData.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final player = value;
          if (player['isOnline'] == true) {
            onlinePlayers++;
          }
        }
      });
    }
    
    print('✅ Analyse terminée:');
    print('   📊 Rooms: $totalRooms total, $activeRooms actives, $emptyRooms vides');
    print('   👥 Joueurs: $totalPlayers total, $onlinePlayers en ligne');
    
  } catch (e) {
    print('❌ Erreur d\'analyse: $e');
  }
}

Future<void> _cleanupDatabase(List<String> arguments) async {
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
    final roomsData = await _makeRequest('GET', '/rooms');
    if (roomsData != null) {
      final now = DateTime.now();
      
      for (final entry in roomsData.entries) {
        try {
          final room = entry.value as Map<String, dynamic>;
          final lastActivity = room['lastActivity'];
          
          if (lastActivity != null) {
            final lastActivityDate = DateTime.parse(lastActivity);
            final diff = now.difference(lastActivityDate);
            
            if (diff.inHours > maxHoursRooms) {
              await _makeRequest('DELETE', '/rooms/${entry.key}');
              deletedRooms++;
              print('🗑️ Room supprimée: ${entry.key}');
            }
          }
        } catch (e) {
          print('⚠️ Erreur room ${entry.key}: $e');
        }
      }
    }
    
    // Nettoyer les joueurs
    final playersData = await _makeRequest('GET', '/players');
    if (playersData != null) {
      final now = DateTime.now();
      
      for (final entry in playersData.entries) {
        try {
          final player = entry.value as Map<String, dynamic>;
          final lastSeen = player['lastSeen'];
          final isOnline = player['isOnline'] == true;
          
          if (!isOnline && lastSeen != null) {
            final lastSeenDate = DateTime.parse(lastSeen);
            final diff = now.difference(lastSeenDate);
            
            if (diff.inDays > maxDaysPlayers) {
              await _makeRequest('DELETE', '/players/${entry.key}');
              deletedPlayers++;
              print('🗑️ Joueur supprimé: ${entry.key}');
            }
          }
        } catch (e) {
          print('⚠️ Erreur joueur ${entry.key}: $e');
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

Future<void> _backupDatabase() async {
  print('💾 Création de sauvegarde...');
  
  try {
    final backup = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
      'data': <String, dynamic>{},
    };
    
    // Sauvegarder les rooms
    final roomsData = await _makeRequest('GET', '/rooms');
    if (roomsData != null) {
      backup['data']['rooms'] = roomsData;
    }
    
    // Sauvegarder les joueurs
    final playersData = await _makeRequest('GET', '/players');
    if (playersData != null) {
      backup['data']['players'] = playersData;
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

Future<void> _restoreDatabase(String filename) async {
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
      await _makeRequest('PUT', '/rooms', data: data['rooms']);
      print('✅ Rooms restaurées');
    }
    
    // Restaurer les joueurs
    if (data.containsKey('players')) {
      await _makeRequest('PUT', '/players', data: data['players']);
      print('✅ Joueurs restaurés');
    }
    
    print('✅ Restauration terminée');
    
  } catch (e) {
    print('❌ Erreur de restauration: $e');
  }
}

Future<void> _clearDatabase() async {
  print('⚠️ ATTENTION: Cette opération va supprimer TOUTES les données !');
  print('Êtes-vous sûr ? Tapez "DELETE" pour confirmer:');
  
  final input = stdin.readLineSync();
  if (input != 'DELETE') {
    print('❌ Opération annulée');
    return;
  }
  
  try {
    await _makeRequest('DELETE', '/rooms');
    await _makeRequest('DELETE', '/players');
    print('✅ Toutes les données supprimées');
    
  } catch (e) {
    print('❌ Erreur de suppression: $e');
  }
}

Future<void> _monitorDatabase() async {
  print('👁️ Surveillance de la base de données (Ctrl+C pour arrêter)...');
  print('⚠️ Note: Cette version utilise des requêtes périodiques (pas de temps réel)');
  
  Timer.periodic(Duration(seconds: 5), (timer) async {
    try {
      final roomsData = await _makeRequest('GET', '/rooms');
      final playersData = await _makeRequest('GET', '/players');
      
      final timestamp = DateTime.now().toIso8601String();
      final roomsCount = roomsData?.length ?? 0;
      final playersCount = playersData?.length ?? 0;
      
      print('[$timestamp] 📊 Rooms: $roomsCount, 👥 Joueurs: $playersCount');
    } catch (e) {
      print('❌ Erreur monitoring: $e');
    }
  });
  
  // Attendre indéfiniment
  await Future.delayed(Duration(days: 365));
}

Future<void> _showStats() async {
  print('📊 Statistiques de la base de données...');
  
  try {
    final roomsData = await _makeRequest('GET', '/rooms');
    final playersData = await _makeRequest('GET', '/players');
    
    int totalRooms = 0;
    int activeRooms = 0;
    int totalPlayers = 0;
    int onlinePlayers = 0;
    
    if (roomsData != null) {
      totalRooms = roomsData.length;
      
      roomsData.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final room = value;
          if (room['gameState'] == 'waiting' || room['gameState'] == 'playing') {
            activeRooms++;
          }
        }
      });
    }
    
    if (playersData != null) {
      totalPlayers = playersData.length;
      
      playersData.forEach((key, value) {
        if (value is Map<String, dynamic>) {
          final player = value;
          if (player['isOnline'] == true) {
            onlinePlayers++;
          }
        }
      });
    }
    
    print('✅ Statistiques:');
    print('   📊 Rooms: $totalRooms total, $activeRooms actives');
    print('   👥 Joueurs: $totalPlayers total, $onlinePlayers en ligne');
    print('   📈 Taux d\'activité: ${totalRooms > 0 ? ((activeRooms / totalRooms) * 100).toStringAsFixed(1) : 0}%');
    
  } catch (e) {
    print('❌ Erreur de statistiques: $e');
  }
}
