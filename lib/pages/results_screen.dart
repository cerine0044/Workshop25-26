import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/bluetooth_game_manager.dart';
import 'certificate_page.dart';

class ResultsScreen extends StatefulWidget {
  final Map<String, dynamic> playerStats;
  final BluetoothGameManager? bluetoothManager;
  
  const ResultsScreen({
    super.key,
    required this.playerStats,
    this.bluetoothManager,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  
  Map<String, dynamic>? _opponentStats;
  bool _waitingForOpponent = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    ));
    
    _animationController.forward();
    _listenForOpponentData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _listenForOpponentData() {
    if (widget.bluetoothManager != null) {
      widget.bluetoothManager!.gameDataStream.listen((data) {
        if (data['action'] == 'complete' && data['playerName'] != widget.playerStats['playerName']) {
          setState(() {
            _opponentStats = data['data'];
            _waitingForOpponent = false;
          });
        }
      });
    } else {
      // Mode test - simuler des données d'opposant
      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          _opponentStats = {
            'playerName': 'Joueur 2',
            'totalTime': const Duration(minutes: 8, seconds: 32),
            'pageTimes': {
              'Page1': const Duration(minutes: 1, seconds: 15),
              'Page2': const Duration(minutes: 2, seconds: 8),
              'Page3': const Duration(minutes: 3, seconds: 45),
              'Page4': const Duration(minutes: 1, seconds: 24),
            },
          };
          _waitingForOpponent = false;
        });
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  String _getWinnerMessage() {
    if (_opponentStats == null) return '';
    
    Duration playerTime = widget.playerStats['totalTime'] ?? Duration.zero;
    Duration opponentTime = _opponentStats!['totalTime'] ?? Duration.zero;
    
    if (playerTime < opponentTime) {
      return '${widget.playerStats['playerName']} remporte la victoire !';
    } else if (playerTime > opponentTime) {
      return '${_opponentStats!['playerName']} remporte la victoire !';
    } else {
      return 'Match nul ! Temps identiques.';
    }
  }

  Color _getWinnerColor() {
    if (_opponentStats == null) return Colors.white;
    
    Duration playerTime = widget.playerStats['totalTime'] ?? Duration.zero;
    Duration opponentTime = _opponentStats!['totalTime'] ?? Duration.zero;
    
    if (playerTime < opponentTime) {
      return Colors.greenAccent;
    } else if (playerTime > opponentTime) {
      return Colors.redAccent;
    } else {
      return Colors.amberAccent;
    }
  }

  Widget _buildPlayerCard(Map<String, dynamic> stats, bool isCurrentPlayer) {
    Duration totalTime = stats['totalTime'] ?? Duration.zero;
    String playerName = stats['playerName'] ?? 'Joueur';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCurrentPlayer 
          ? Colors.blueAccent.withOpacity(0.2)
          : Colors.greenAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentPlayer 
            ? Colors.blueAccent.withOpacity(0.5)
            : Colors.greenAccent.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Nom du joueur
          Text(
            playerName,
            style: TextStyle(
              color: isCurrentPlayer ? Colors.blueAccent : Colors.greenAccent,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Temps total
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.timer,
                  color: Colors.white70,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDuration(totalTime),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Text(
                  'Temps total',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Détails par page
          if (stats['pageTimes'] != null) ...[
            const Text(
              'Détails par épreuve',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...stats['pageTimes'].entries.map<Widget>((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      _formatDuration(entry.value),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Résultats'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(_slideAnimation),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Titre
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.emoji_events,
                              color: Colors.amber,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'COMPARAISON FINALE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                            if (!_waitingForOpponent) ...[
                              const SizedBox(height: 8),
                              Text(
                                _getWinnerMessage(),
                                style: TextStyle(
                                  color: _getWinnerColor(),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Contenu principal
                      Expanded(
                        child: _waitingForOpponent
                          ? _buildWaitingScreen()
                          : _buildResultsScreen(),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Boutons d'action
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => CertificatePage(
                                    playerStats: widget.playerStats,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.card_membership),
                            label: const Text('Mon Certificat'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                            },
                            icon: const Icon(Icons.home),
                            label: const Text('Accueil'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.greenAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildWaitingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bluetooth_searching,
            color: Colors.blueAccent,
            size: 64,
          ),
          const SizedBox(height: 24),
          const Text(
            'En attente de ton partenaire...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Ton partenaire termine sa session.\n'
            'Les résultats seront comparés automatiquement.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(
            color: Colors.blueAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Cartes des joueurs
          Row(
            children: [
              Expanded(
                child: _buildPlayerCard(widget.playerStats, true),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildPlayerCard(_opponentStats!, false),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Analyse comparative
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'ANALYSE COMPARATIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                _buildComparisonItem(
                  'Temps total',
                  widget.playerStats['totalTime'] ?? Duration.zero,
                  _opponentStats!['totalTime'] ?? Duration.zero,
                ),
                const SizedBox(height: 12),
                _buildComparisonItem(
                  'Épreuves complétées',
                  Duration(seconds: (widget.playerStats['pageTimes']?.length ?? 0)),
                  Duration(seconds: (_opponentStats!['pageTimes']?.length ?? 0)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonItem(String label, Duration playerValue, Duration opponentValue) {
    bool playerWins = playerValue < opponentValue;
    
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: playerWins 
                ? Colors.greenAccent.withOpacity(0.2)
                : Colors.redAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: playerWins 
                  ? Colors.greenAccent.withOpacity(0.5)
                  : Colors.redAccent.withOpacity(0.5),
              ),
            ),
            child: Text(
              label.contains('Temps') 
                ? _formatDuration(playerValue)
                : '${playerValue.inSeconds}',
              style: TextStyle(
                color: playerWins ? Colors.greenAccent : Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: BoxDecoration(
              color: !playerWins 
                ? Colors.greenAccent.withOpacity(0.2)
                : Colors.redAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: !playerWins 
                  ? Colors.greenAccent.withOpacity(0.5)
                  : Colors.redAccent.withOpacity(0.5),
              ),
            ),
            child: Text(
              label.contains('Temps') 
                ? _formatDuration(opponentValue)
                : '${opponentValue.inSeconds}',
              style: TextStyle(
                color: !playerWins ? Colors.greenAccent : Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
