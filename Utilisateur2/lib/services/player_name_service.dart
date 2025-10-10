import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service pour gérer le nom du joueur avec persistance Firebase
class PlayerNameService {
  static final PlayerNameService _instance = PlayerNameService._internal();
  factory PlayerNameService() => _instance;
  PlayerNameService._internal();

  static const String _playerNameKey = 'player_name';
  static const String _playerIdKey = 'player_id';
  String? _currentPlayerName;
  String? _currentPlayerId;
  
  DatabaseReference? _database;
  FirebaseAuth? _auth;

  /// Obtenir le nom du joueur actuel
  String? get currentPlayerName => _currentPlayerName;
  
  /// Obtenir l'ID du joueur actuel
  String? get currentPlayerId => _currentPlayerId;

  /// Vérifier si un nom de joueur est défini
  bool get hasPlayerName => _currentPlayerName != null && _currentPlayerName!.isNotEmpty;

  /// Initialiser le service et charger le nom depuis le stockage local et Firebase
  Future<void> initialize() async {
    try {
      // Charger depuis le stockage local d'abord
      await _loadFromLocalStorage();
      
      // Initialiser Firebase si disponible
      try {
        _database = FirebaseDatabase.instance.ref();
        _auth = FirebaseAuth.instance;
        
        // Charger depuis Firebase si connecté
        if (_auth!.currentUser != null) {
          await _loadFromFirebase();
        }
      } catch (e) {
        debugPrint('⚠️ Firebase non disponible pour PlayerNameService: $e');
      }
      
      debugPrint('👤 Nom du joueur chargé: $_currentPlayerName (ID: $_currentPlayerId)');
    } catch (e) {
      debugPrint('❌ Erreur chargement nom joueur: $e');
    }
  }

  /// Charger depuis le stockage local
  Future<void> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentPlayerName = prefs.getString(_playerNameKey);
      _currentPlayerId = prefs.getString(_playerIdKey);
    } catch (e) {
      debugPrint('❌ Erreur chargement local: $e');
    }
  }

  /// Charger depuis Firebase
  Future<void> _loadFromFirebase() async {
    if (_database == null || _auth!.currentUser == null) return;
    
    try {
      final userId = _auth!.currentUser!.uid;
      final snapshot = await _database!.child('players/$userId').get();
      
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          final playerName = data['name'] as String?;
          if (playerName != null && playerName.isNotEmpty) {
            _currentPlayerName = playerName;
            _currentPlayerId = userId;
            
            // Sauvegarder localement aussi
            await _saveToLocalStorage();
            debugPrint('✅ Nom chargé depuis Firebase: $playerName');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement Firebase: $e');
    }
  }

  /// Sauvegarder localement
  Future<void> _saveToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentPlayerName != null) {
        await prefs.setString(_playerNameKey, _currentPlayerName!);
      }
      if (_currentPlayerId != null) {
        await prefs.setString(_playerIdKey, _currentPlayerId!);
      }
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde locale: $e');
    }
  }

  /// Sauvegarder sur Firebase
  Future<void> _saveToFirebase() async {
    if (_database == null || _currentPlayerId == null || _currentPlayerName == null) return;
    
    try {
      await _database!.child('players/$_currentPlayerId').set({
        'name': _currentPlayerName,
        'lastUpdated': DateTime.now().toIso8601String(),
        'platform': 'web',
      });
      debugPrint('✅ Nom sauvegardé sur Firebase: $_currentPlayerName');
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde Firebase: $e');
    }
  }

  /// Définir le nom du joueur
  Future<bool> setPlayerName(String name) async {
    try {
      if (name.trim().isEmpty) {
        debugPrint('❌ Nom de joueur vide');
        return false;
      }

      final trimmedName = name.trim();
      _currentPlayerName = trimmedName;
      
      // Générer un ID si nécessaire
      if (_currentPlayerId == null) {
        _currentPlayerId = 'player_${DateTime.now().millisecondsSinceEpoch}';
      }

      // Sauvegarder localement
      await _saveToLocalStorage();
      
      // Sauvegarder sur Firebase
      await _saveToFirebase();
      
      debugPrint('✅ Nom du joueur défini: $trimmedName');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde nom joueur: $e');
      return false;
    }
  }

  /// Supprimer le nom du joueur
  Future<void> clearPlayerName() async {
    try {
      _currentPlayerName = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_playerNameKey);
      debugPrint('🗑️ Nom du joueur supprimé');
    } catch (e) {
      debugPrint('❌ Erreur suppression nom joueur: $e');
    }
  }

  /// Obtenir le nom du joueur ou un nom par défaut
  String getPlayerNameOrDefault({String defaultName = 'Joueur'}) {
    if (_currentPlayerName != null && _currentPlayerName!.isNotEmpty) {
      return _currentPlayerName!;
    }
    
    // Générer un nom par défaut unique
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = timestamp.toString().substring(timestamp.toString().length - 4);
    return '${defaultName}_$randomSuffix';
  }

  /// Valider un nom de joueur
  bool isValidPlayerName(String name) {
    if (name.trim().isEmpty) return false;
    if (name.trim().length < 2) return false;
    if (name.trim().length > 20) return false;
    
    // Vérifier les caractères spéciaux non autorisés
    final specialChars = RegExp(r'[!@#$%^&*()+=\[\]{}|;:,.<>?/~`]');
    if (specialChars.hasMatch(name)) return false;
    
    return true;
  }

  /// Obtenir des suggestions de noms
  List<String> getSuggestedNames() {
    return [
      'Joueur',
      'Gamer',
      'Player',
      'Champion',
      'Master',
      'Pro',
      'Expert',
      'Legend',
    ];
  }
}
