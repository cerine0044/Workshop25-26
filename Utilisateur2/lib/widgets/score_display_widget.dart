import 'dart:async';
import 'package:flutter/material.dart';
import '../services/global_score_service.dart';

class TimerDisplayWidget extends StatefulWidget {
  final bool showPageTimer;
  final bool compact;
  
  const TimerDisplayWidget({
    super.key,
    this.showPageTimer = true,
    this.compact = false,
  });

  @override
  State<TimerDisplayWidget> createState() => _TimerDisplayWidgetState();
}

class _TimerDisplayWidgetState extends State<TimerDisplayWidget>
    with TickerProviderStateMixin {
  
  final GlobalScoreService _scoreService = GlobalScoreService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  SessionInfo? _currentSession;
  Duration _currentDuration = Duration.zero;
  StreamSubscription<SessionInfo>? _sessionSubscription;
  StreamSubscription<Duration>? _timerSubscription;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _subscribeToUpdates();
  }
  
  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }
  
  void _subscribeToUpdates() {
    _sessionSubscription = _scoreService.sessionStream.listen((session) {
      setState(() {
        _currentSession = session;
      });
    });
    
    _timerSubscription = _scoreService.timerStream.listen((duration) {
      setState(() {
        _currentDuration = duration;
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_currentSession == null) {
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
          _buildTimerIcon(),
          const SizedBox(width: 8),
          Text(
            _formatDuration(_currentDuration),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
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
                _buildTimerSection(),
                if (widget.showPageTimer) ...[
                  const SizedBox(height: 12),
                  _buildPageTimerSection(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildTimerSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTimerIcon(),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TEMPS TOTAL',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                _formatDuration(_currentDuration),
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
  }
  
  Widget _buildPageTimerSection() {
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
            'Page: ${_formatDuration(_currentSession!.currentPageDuration)}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTimerIcon() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(
        Icons.timer,
        color: Colors.cyan,
        size: 16,
      ),
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
    _sessionSubscription?.cancel();
    _timerSubscription?.cancel();
    super.dispose();
  }
}
