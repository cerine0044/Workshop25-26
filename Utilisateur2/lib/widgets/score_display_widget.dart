import 'dart:async';
import 'package:flutter/material.dart';
import '../services/global_score_service.dart';

class ScoreDisplayWidget extends StatefulWidget {
  final bool showPageScore;
  final bool showTimer;
  final bool compact;
  
  const ScoreDisplayWidget({
    super.key,
    this.showPageScore = true,
    this.showTimer = true,
    this.compact = false,
  });

  @override
  State<ScoreDisplayWidget> createState() => _ScoreDisplayWidgetState();
}

class _ScoreDisplayWidgetState extends State<ScoreDisplayWidget>
    with TickerProviderStateMixin {
  
  final GlobalScoreService _scoreService = GlobalScoreService();
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;
  
  GlobalScore? _currentScore;
  Duration _currentDuration = Duration.zero;
  StreamSubscription<GlobalScore>? _scoreSubscription;
  StreamSubscription<Duration>? _timerSubscription;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _subscribeToScoreUpdates();
  }
  
  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }
  
  void _subscribeToScoreUpdates() {
    _scoreSubscription = _scoreService.scoreStream.listen((score) {
      setState(() {
        _currentScore = score;
      });
    });
    
    if (widget.showTimer) {
      _timerSubscription = _scoreService.timerStream.listen((duration) {
        setState(() {
          _currentDuration = duration;
        });
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_currentScore == null) {
      return const SizedBox.shrink();
    }
    
    if (widget.compact) {
      return _buildCompactDisplay();
    }
    
    return _buildFullDisplay();
  }
  
  Widget _buildCompactDisplay() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildScoreIcon(),
          const SizedBox(width: 8),
          Text(
            '${_currentScore!.totalScore}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (widget.showTimer) ...[
            const SizedBox(width: 12),
            _buildTimerIcon(),
            const SizedBox(width: 4),
            Text(
              _formatDuration(_currentDuration),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildFullDisplay() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.3),
                  Colors.purple.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildScoreSection(),
                if (widget.showPageScore) ...[
                  const SizedBox(height: 12),
                  _buildPageScoreSection(),
                ],
                if (widget.showTimer) ...[
                  const SizedBox(height: 12),
                  _buildTimerSection(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildScoreSection() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withOpacity(_glowAnimation.value),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildScoreIcon(),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SCORE TOTAL',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${_currentScore!.totalScore}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildPageScoreSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.pageview,
            color: Colors.white70,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            'Page: ${_currentScore!.currentPageScore}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimerSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTimerIcon(),
          const SizedBox(width: 6),
          Text(
            _formatDuration(_currentDuration),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScoreIcon() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(_glowAnimation.value * 0.3),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Icon(
            Icons.star,
            color: Colors.yellow,
            size: 16,
          ),
        );
      },
    );
  }
  
  Widget _buildTimerIcon() {
    return const Icon(
      Icons.timer,
      color: Colors.white70,
      size: 14,
    );
  }
  
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _scoreSubscription?.cancel();
    _timerSubscription?.cancel();
    super.dispose();
  }
}

class FloatingScoreWidget extends StatefulWidget {
  final int points;
  final String reason;
  final Duration duration;
  
  const FloatingScoreWidget({
    super.key,
    required this.points,
    required this.reason,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<FloatingScoreWidget> createState() => _FloatingScoreWidgetState();
}

class _FloatingScoreWidgetState extends State<FloatingScoreWidget>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimation();
  }
  
  void _initializeAnimations() {
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
    ));
  }
  
  void _startAnimation() {
    _controller.forward().then((_) {
      if (mounted) {
        // Optionnel: supprimer le widget après l'animation
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.points > 0 
                      ? Colors.green.withOpacity(0.9)
                      : Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.points > 0 ? Icons.add : Icons.remove,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.points > 0 ? '+' : ''}${widget.points}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.reason,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
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
    _controller.dispose();
    super.dispose();
  }
}
