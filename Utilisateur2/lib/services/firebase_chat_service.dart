import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class ChatMessage {
  final String id;
  final String playerId;
  final String playerName;
  final String message;
  final DateTime timestamp;
  final bool isSystemMessage;

  ChatMessage({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.message,
    required this.timestamp,
    this.isSystemMessage = false,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> data, String id) {
    return ChatMessage(
      id: id,
      playerId: data['playerId'] ?? '',
      playerName: data['playerName'] ?? 'Joueur',
      message: data['message'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
      isSystemMessage: data['isSystemMessage'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'playerId': playerId,
      'playerName': playerName,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isSystemMessage': isSystemMessage,
    };
  }
}

class FirebaseChatService {
  static final FirebaseChatService _instance = FirebaseChatService._internal();
  factory FirebaseChatService() => _instance;
  FirebaseChatService._internal();

  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  StreamSubscription<DatabaseEvent>? _chatSubscription;
  final StreamController<List<ChatMessage>> _chatController = StreamController<List<ChatMessage>>.broadcast();
  
  String? _currentRoomCode;
  String? _currentPlayerId;
  String? _currentPlayerName;
  
  // Configuration du chat
  static const int maxMessages = 50; // Limite de messages dans la room
  static const Duration messageCooldown = Duration(seconds: 1); // Cooldown entre messages
  DateTime? _lastMessageTime;

  /// Initialise le service de chat pour une room
  Future<void> initializeChat({
    required String roomCode,
    required String playerId,
    required String playerName,
  }) async {
    try {
      _currentRoomCode = roomCode;
      _currentPlayerId = playerId;
      _currentPlayerName = playerName;
      
      // Écouter les messages de la room
      await _listenToChatMessages();
      
      if (kDebugMode) {
        print('💬 Chat initialisé pour la room $roomCode');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur initialisation chat: $e');
      }
      rethrow;
    }
  }

  /// Écoute les messages de chat en temps réel
  Future<void> _listenToChatMessages() async {
    if (_currentRoomCode == null) return;

    try {
      _chatSubscription?.cancel();
      
      _chatSubscription = _database
          .child('rooms')
          .child(_currentRoomCode!)
          .child('chat')
          .orderByChild('timestamp')
          .limitToLast(maxMessages)
          .onValue
          .listen((event) {
        if (event.snapshot.exists) {
          final Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          final List<ChatMessage> messages = [];
          
          data.forEach((key, value) {
            if (value is Map) {
              messages.add(ChatMessage.fromMap(Map<String, dynamic>.from(value), key));
            }
          });
          
          // Trier par timestamp
          messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          
          _chatController.add(messages);
        } else {
          _chatController.add([]);
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur écoute messages chat: $e');
      }
      rethrow;
    }
  }

  /// Envoie un message dans le chat
  Future<void> sendMessage(String message) async {
    if (_currentRoomCode == null || _currentPlayerId == null || _currentPlayerName == null) {
      throw Exception('Chat non initialisé');
    }

    if (message.trim().isEmpty) {
      throw Exception('Message vide');
    }

    // Vérifier le cooldown
    if (_lastMessageTime != null && 
        DateTime.now().difference(_lastMessageTime!) < messageCooldown) {
      throw Exception('Attendez ${messageCooldown.inSeconds} secondes entre les messages');
    }

    try {
      final messageRef = _database
          .child('rooms')
          .child(_currentRoomCode!)
          .child('chat')
          .push();

      final chatMessage = ChatMessage(
        id: messageRef.key!,
        playerId: _currentPlayerId!,
        playerName: _currentPlayerName!,
        message: message.trim(),
        timestamp: DateTime.now(),
      );

      await messageRef.set(chatMessage.toMap());
      _lastMessageTime = DateTime.now();

      if (kDebugMode) {
        print('💬 Message envoyé: ${message.trim()}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur envoi message: $e');
      }
      rethrow;
    }
  }

  /// Envoie un message système (pour les notifications)
  Future<void> sendSystemMessage(String message) async {
    if (_currentRoomCode == null) {
      throw Exception('Chat non initialisé');
    }

    try {
      final messageRef = _database
          .child('rooms')
          .child(_currentRoomCode!)
          .child('chat')
          .push();

      final systemMessage = ChatMessage(
        id: messageRef.key!,
        playerId: 'system',
        playerName: 'Système',
        message: message,
        timestamp: DateTime.now(),
        isSystemMessage: true,
      );

      await messageRef.set(systemMessage.toMap());

      if (kDebugMode) {
        print('🔔 Message système envoyé: $message');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur envoi message système: $e');
      }
      rethrow;
    }
  }

  /// Stream des messages de chat
  Stream<List<ChatMessage>> get chatMessagesStream => _chatController.stream;

  /// Nettoie les anciens messages (garde seulement les derniers)
  Future<void> cleanupOldMessages() async {
    if (_currentRoomCode == null) return;

    try {
      final snapshot = await _database
          .child('rooms')
          .child(_currentRoomCode!)
          .child('chat')
          .orderByChild('timestamp')
          .once();

      if (snapshot.snapshot.exists) {
        final Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(snapshot.snapshot.value as Map);
        final List<MapEntry<String, dynamic>> sortedMessages = [];
        
        data.forEach((key, value) {
          if (value is Map) {
            sortedMessages.add(MapEntry(key, value));
          }
        });
        
        // Trier par timestamp
        sortedMessages.sort((a, b) {
          final timestampA = a.value['timestamp'] ?? 0;
          final timestampB = b.value['timestamp'] ?? 0;
          return timestampA.compareTo(timestampB);
        });
        
        // Supprimer les anciens messages si on dépasse la limite
        if (sortedMessages.length > maxMessages) {
          final messagesToDelete = sortedMessages.take(sortedMessages.length - maxMessages);
          
          for (final message in messagesToDelete) {
            await _database
                .child('rooms')
                .child(_currentRoomCode!)
                .child('chat')
                .child(message.key)
                .remove();
          }
          
          if (kDebugMode) {
            print('🧹 ${messagesToDelete.length} anciens messages supprimés');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur nettoyage messages: $e');
      }
    }
  }

  /// Vérifie si un joueur peut envoyer un message (cooldown)
  bool canSendMessage() {
    if (_lastMessageTime == null) return true;
    return DateTime.now().difference(_lastMessageTime!) >= messageCooldown;
  }

  /// Obtient le temps restant avant de pouvoir envoyer un autre message
  Duration getRemainingCooldown() {
    if (_lastMessageTime == null) return Duration.zero;
    final elapsed = DateTime.now().difference(_lastMessageTime!);
    return elapsed < messageCooldown ? messageCooldown - elapsed : Duration.zero;
  }

  /// Ferme le chat et nettoie les ressources
  Future<void> dispose() async {
    await _chatSubscription?.cancel();
    await _chatController.close();
    _currentRoomCode = null;
    _currentPlayerId = null;
    _currentPlayerName = null;
    _lastMessageTime = null;
    
    if (kDebugMode) {
      print('💬 Chat service fermé');
    }
  }

  /// Obtient les informations actuelles du chat
  Map<String, String?> get chatInfo => {
    'roomCode': _currentRoomCode,
    'playerId': _currentPlayerId,
    'playerName': _currentPlayerName,
  };
}
