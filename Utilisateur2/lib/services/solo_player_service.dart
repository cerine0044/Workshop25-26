import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SoloPlayerService {
  static final SoloPlayerService _instance = SoloPlayerService._internal();
  factory SoloPlayerService() => _instance;
  SoloPlayerService._internal();

  static const String _playerNameKey = 'solo_player_name';
  final Uuid _uuid = const Uuid();

  Future<String> getUniquePlayerName() async {
    final prefs = await SharedPreferences.getInstance();
    String? playerName = prefs.getString(_playerNameKey);

    if (playerName == null || playerName.isEmpty) {
      playerName = 'Joueur Solo ${_uuid.v4().substring(0, 4)}';
      await prefs.setString(_playerNameKey, playerName);
    }
    return playerName;
  }

  Future<void> updatePlayerName(String newName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_playerNameKey, newName);
  }

  Future<String?> getCurrentPlayerName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_playerNameKey);
  }
}
