import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Service pour gérer le nom du joueur
class PlayerNameService {
  static final PlayerNameService _instance = PlayerNameService._internal();
  factory PlayerNameService() => _instance;
  PlayerNameService._internal();

  static const String _playerNameKey = 'player_name';
  String? _currentPlayerName;

  /// Obtenir le nom du joueur actuel
  String? get currentPlayerName => _currentPlayerName;

  /// Vérifier si un nom de joueur est défini
  bool get hasPlayerName => _currentPlayerName != null && _currentPlayerName!.isNotEmpty;

  /// Initialiser le service et charger le nom depuis le stockage local
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentPlayerName = prefs.getString(_playerNameKey);
      debugPrint('👤 Nom du joueur chargé: $_currentPlayerName');
    } catch (e) {
      debugPrint('❌ Erreur chargement nom joueur: $e');
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

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_playerNameKey, trimmedName);
      
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
    return _currentPlayerName ?? defaultName;
  }

  /// Valider un nom de joueur
  bool isValidPlayerName(String name) {
    if (name.trim().isEmpty) return false;
    if (name.trim().length < 2) return false;
    if (name.trim().length > 20) return false;
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
