import 'package:flutter/material.dart';
import '../services/game_stats_service.dart';

/// Widget de chronomètre pour afficher le temps écoulé dans les jeux
class GameTimerWidget extends StatefulWidget {
  final Color? textColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final EdgeInsets? padding;

  const GameTimerWidget({
    super.key,
    this.textColor,
    this.fontSize,
    this.fontWeight,
    this.padding,
  });

  @override
  State<GameTimerWidget> createState() => _GameTimerWidgetState();
}

class _GameTimerWidgetState extends State<GameTimerWidget> {
  final GameStatsService _statsService = GameStatsService();
  Duration _currentDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _statsService.addDurationListener(_updateDuration);
    _currentDuration = _statsService.currentDuration;
  }

  @override
  void dispose() {
    _statsService.removeDurationListener(_updateDuration);
    super.dispose();
  }

  void _updateDuration() {
    if (mounted) {
      setState(() {
        _currentDuration = _statsService.currentDuration;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_statsService.isSessionActive) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.timer,
            color: widget.textColor ?? Colors.white,
            size: (widget.fontSize ?? 16) * 0.8,
          ),
          const SizedBox(width: 6),
          Text(
            _formatDuration(_currentDuration),
            style: TextStyle(
              color: widget.textColor ?? Colors.white,
              fontSize: widget.fontSize ?? 16,
              fontWeight: widget.fontWeight ?? FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }
}

/// Widget pour afficher les informations de session actuelle
class GameSessionInfoWidget extends StatefulWidget {
  final Color? textColor;
  final double? fontSize;

  const GameSessionInfoWidget({
    super.key,
    this.textColor,
    this.fontSize,
  });

  @override
  State<GameSessionInfoWidget> createState() => _GameSessionInfoWidgetState();
}

class _GameSessionInfoWidgetState extends State<GameSessionInfoWidget> {
  final GameStatsService _statsService = GameStatsService();
  String? _playerName;
  String? _gameRoom;

  @override
  void initState() {
    super.initState();
    _statsService.addStatsListener(_updateSessionInfo);
    _updateSessionInfo();
  }

  @override
  void dispose() {
    _statsService.removeStatsListener(_updateSessionInfo);
    super.dispose();
  }

  void _updateSessionInfo() {
    if (mounted) {
      setState(() {
        _playerName = _statsService.currentPlayerName;
        _gameRoom = _statsService.currentGameRoom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_statsService.isSessionActive || _playerName == null || _gameRoom == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person,
            color: widget.textColor ?? Colors.white,
            size: (widget.fontSize ?? 14) * 0.8,
          ),
          const SizedBox(width: 6),
          Text(
            '$_playerName',
            style: TextStyle(
              color: widget.textColor ?? Colors.white,
              fontSize: widget.fontSize ?? 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.room,
            color: widget.textColor ?? Colors.white,
            size: (widget.fontSize ?? 14) * 0.8,
          ),
          const SizedBox(width: 6),
          Text(
            _gameRoom!,
            style: TextStyle(
              color: widget.textColor ?? Colors.white,
              fontSize: widget.fontSize ?? 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
