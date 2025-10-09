import 'dart:async';
import 'package:flutter/material.dart';

class EnhancedConnectionWidget extends StatefulWidget {
  final bool isConnected;
  final String? connectionStatus;
  final VoidCallback? onRetry;
  
  const EnhancedConnectionWidget({
    super.key,
    required this.isConnected,
    this.connectionStatus,
    this.onRetry,
  });

  @override
  State<EnhancedConnectionWidget> createState() => _EnhancedConnectionWidgetState();
}

class _EnhancedConnectionWidgetState extends State<EnhancedConnectionWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _rotationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.linear,
    ));
    
    if (!widget.isConnected) {
      _pulseController.repeat(reverse: true);
      _rotationController.repeat();
    }
  }
  
  @override
  void didUpdateWidget(EnhancedConnectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.isConnected != oldWidget.isConnected) {
      if (widget.isConnected) {
        _pulseController.stop();
        _rotationController.stop();
        _pulseController.forward();
      } else {
        _pulseController.repeat(reverse: true);
        _rotationController.repeat();
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isConnected 
            ? Colors.green.withOpacity(0.2)
            : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isConnected ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusIcon(),
          const SizedBox(width: 8),
          _buildStatusText(),
          if (!widget.isConnected && widget.onRetry != null) ...[
            const SizedBox(width: 8),
            _buildRetryButton(),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStatusIcon() {
    if (widget.isConnected) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: const Icon(
              Icons.wifi,
              color: Colors.green,
              size: 16,
            ),
          );
        },
      );
    } else {
      return AnimatedBuilder(
        animation: _rotationAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationAnimation.value * 2 * 3.14159,
            child: const Icon(
              Icons.wifi_off,
              color: Colors.red,
              size: 16,
            ),
          );
        },
      );
    }
  }
  
  Widget _buildStatusText() {
    return Text(
      widget.isConnected 
          ? (widget.connectionStatus ?? 'Connecté')
          : (widget.connectionStatus ?? 'Déconnecté'),
      style: TextStyle(
        color: widget.isConnected ? Colors.green : Colors.red,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
    );
  }
  
  Widget _buildRetryButton() {
    return GestureDetector(
      onTap: widget.onRetry,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.refresh,
          color: Colors.red,
          size: 12,
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _rotationController.dispose();
    super.dispose();
  }
}

class ConnectionStatusBanner extends StatefulWidget {
  final bool isConnected;
  final String? message;
  final VoidCallback? onRetry;
  
  const ConnectionStatusBanner({
    super.key,
    required this.isConnected,
    this.message,
    this.onRetry,
  });

  @override
  State<ConnectionStatusBanner> createState() => _ConnectionStatusBannerState();
}

class _ConnectionStatusBannerState extends State<ConnectionStatusBanner>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  bool _isVisible = true;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    if (widget.isConnected) {
      // Masquer automatiquement après 3 secondes si connecté
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          _hideBanner();
        }
      });
    }
  }
  
  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOut,
    ));
    
    _slideController.forward();
  }
  
  void _hideBanner() {
    if (!_isVisible) return;
    
    setState(() => _isVisible = false);
    _slideController.reverse().then((_) {
      if (mounted) {
        // Optionnel: supprimer le widget du tree
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();
    
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.isConnected 
              ? Colors.green.withOpacity(0.9)
              : Colors.red.withOpacity(0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(
              widget.isConnected ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.message ?? (widget.isConnected ? 'Connexion établie' : 'Connexion perdue'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (!widget.isConnected && widget.onRetry != null)
              TextButton(
                onPressed: widget.onRetry,
                child: const Text(
                  'Réessayer',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            IconButton(
              onPressed: _hideBanner,
              icon: const Icon(
                Icons.close,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }
}
