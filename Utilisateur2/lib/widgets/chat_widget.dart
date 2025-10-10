import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/firebase_chat_service.dart';

class ChatWidget extends StatefulWidget {
  final String roomCode;
  final String playerId;
  final String playerName;
  final bool isHost;

  const ChatWidget({
    super.key,
    required this.roomCode,
    required this.playerId,
    required this.playerName,
    required this.isHost,
  });

  @override
  State<ChatWidget> createState() => _ChatWidgetState();
}

class _ChatWidgetState extends State<ChatWidget> with TickerProviderStateMixin {
  final FirebaseChatService _chatService = FirebaseChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  // Animations
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeChat();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideController.forward();
    _fadeController.forward();
  }

  void _initializeChat() async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _chatService.initializeChat(
        roomCode: widget.roomCode,
        playerId: widget.playerId,
        playerName: widget.playerName,
      );

      // Écouter les messages
      _chatService.chatMessagesStream.listen((messages) {
        if (mounted) {
          setState(() {
            _messages = messages;
          });
          _scrollToBottom();
        }
      });

      setState(() {
        _isLoading = false;
      });

      // Envoyer un message de bienvenue
      await _chatService.sendSystemMessage('${widget.playerName} a rejoint le chat');
      
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur initialisation chat: $e';
      });
    }
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || !_chatService.canSendMessage()) return;

    try {
      await _chatService.sendMessage(message);
      _messageController.clear();
      HapticFeedback.lightImpact();
      
      // Démarrer le cooldown
      _startCooldown();
      
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      HapticFeedback.heavyImpact();
      
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _errorMessage = null;
          });
        }
      });
    }
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownSeconds = _chatService.getRemainingCooldown().inSeconds;
    
    if (_cooldownSeconds > 0) {
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _cooldownSeconds--;
          });
          
          if (_cooldownSeconds <= 0) {
            timer.cancel();
          }
        }
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _showErrorMessage(String message) {
    setState(() {
      _errorMessage = message;
    });
    
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _errorMessage = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _cooldownTimer?.cancel();
    
    // Fermer proprement le chat avec gestion d'erreur
    try {
      _chatService.dispose();
    } catch (e) {
      print('⚠️ Erreur fermeture chat: $e');
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Header du chat
              _buildChatHeader(),
              
              // Messages
              Expanded(
                child: _isLoading 
                  ? _buildLoadingIndicator()
                  : _buildMessagesList(),
              ),
              
              // Zone de saisie
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade600.withOpacity(0.2),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(Icons.chat, color: Colors.blue.shade400, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Chat de la Room',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (_cooldownSeconds > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_cooldownSeconds}s',
                style: TextStyle(
                  color: Colors.orange.shade300,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          SizedBox(height: 16),
          Text(
            'Connexion au chat...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
    return Column(
      children: [
        // Messages
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(_messages[index]);
                  },
                ),
        ),
        
        // Message d'erreur
        if (_errorMessage != null)
          _buildErrorMessage(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: Colors.white.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun message pour le moment',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Soyez le premier à écrire !',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isCurrentPlayer = message.playerId == widget.playerId;
    final isSystem = message.isSystemMessage;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isCurrentPlayer ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isCurrentPlayer && !isSystem)
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.blue.shade400,
              child: Text(
                message.playerName.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          
          const SizedBox(width: 8),
          
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSystem 
                    ? Colors.orange.withOpacity(0.2)
                    : isCurrentPlayer 
                        ? Colors.blue.shade600.withOpacity(0.8)
                        : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: isSystem 
                    ? Border.all(color: Colors.orange.withOpacity(0.3))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isSystem)
                    Text(
                      message.playerName,
                      style: TextStyle(
                        color: isCurrentPlayer ? Colors.white : Colors.blue.shade300,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isSystem ? Colors.orange.shade200 : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error, color: Colors.red.shade400, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red.shade300,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _cooldownSeconds > 0 
                    ? 'Attendez ${_cooldownSeconds}s...'
                    : 'Tapez votre message...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              enabled: _cooldownSeconds == 0,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: _cooldownSeconds > 0 
                  ? Colors.grey.shade600
                  : Colors.blue.shade600,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              onPressed: _cooldownSeconds > 0 ? null : _sendMessage,
              icon: Icon(
                Icons.send,
                color: _cooldownSeconds > 0 
                    ? Colors.grey.shade400
                    : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Maintenant';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}
