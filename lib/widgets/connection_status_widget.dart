import 'package:flutter/material.dart';
import 'dart:async';

class ConnectionStatusWidget extends StatefulWidget {
  final String serverUrl;
  final VoidCallback? onReconnect;

  const ConnectionStatusWidget({
    super.key,
    required this.serverUrl,
    this.onReconnect,
  });

  @override
  State<ConnectionStatusWidget> createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _shakeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shakeAnimation;
  
  ConnectionStatus _status = ConnectionStatus.disconnected;
  Timer? _checkTimer;
  String _statusText = 'Déconnecté';
  Color _statusColor = Colors.red;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startConnectionCheck();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _shakeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticOut,
    ));
  }

  void _startConnectionCheck() {
    _checkTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkConnection();
    });
    
    // Vérification immédiate
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    try {
      // Simuler une vérification de connexion
      // Dans une vraie implémentation, vous feriez un ping au serveur
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Pour la démo, on simule une connexion réussie
      _updateStatus(ConnectionStatus.connected);
    } catch (e) {
      _updateStatus(ConnectionStatus.error);
    }
  }

  void _updateStatus(ConnectionStatus newStatus) {
    if (_status != newStatus) {
      setState(() {
        _status = newStatus;
        
        switch (newStatus) {
          case ConnectionStatus.connected:
            _statusText = 'Connecté';
            _statusColor = Colors.green;
            _pulseController.repeat(reverse: true);
            break;
          case ConnectionStatus.connecting:
            _statusText = 'Connexion...';
            _statusColor = Colors.orange;
            _pulseController.repeat(reverse: true);
            break;
          case ConnectionStatus.error:
            _statusText = 'Erreur';
            _statusColor = Colors.red;
            _shakeController.forward().then((_) => _shakeController.reverse());
            break;
          case ConnectionStatus.disconnected:
            _statusText = 'Déconnecté';
            _statusColor = Colors.grey;
            _pulseController.stop();
            break;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseAnimation, _shakeAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _status == ConnectionStatus.connected ? _pulseAnimation.value : 1.0,
          child: Transform.translate(
            offset: Offset(
              _status == ConnectionStatus.error ? 
                _shakeAnimation.value * 5 * math.sin(_shakeAnimation.value * math.pi * 10) : 0,
              0,
            ),
            child: GestureDetector(
              onTap: _status == ConnectionStatus.error || _status == ConnectionStatus.disconnected
                  ? () {
                      _updateStatus(ConnectionStatus.connecting);
                      widget.onReconnect?.call();
                      _checkConnection();
                    }
                  : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _statusColor,
                    width: 1.5,
                  ),
                  boxShadow: _status == ConnectionStatus.connected ? [
                    BoxShadow(
                      color: _statusColor.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ] : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _statusColor,
                        shape: BoxShape.circle,
                        boxShadow: _status == ConnectionStatus.connected ? [
                          BoxShadow(
                            color: _statusColor.withOpacity(0.5),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ] : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _statusText,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_status == ConnectionStatus.connecting) ...[
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _checkTimer?.cancel();
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }
}

enum ConnectionStatus {
  connected,
  connecting,
  disconnected,
  error,
}

// Import pour math
import 'dart:math' as math;
