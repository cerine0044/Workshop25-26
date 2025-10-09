import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/global_score_service.dart';
import '../widgets/score_display_widget.dart';

class FinalScorePage extends StatefulWidget {
  const FinalScorePage({super.key});

  @override
  State<FinalScorePage> createState() => _FinalScorePageState();
}

class _FinalScorePageState extends State<FinalScorePage>
    with TickerProviderStateMixin {
  
  final GlobalScoreService _scoreService = GlobalScoreService();
  late AnimationController _mainController;
  late AnimationController _particleController;
  late AnimationController _glowController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _glowAnimation;
  
  FinalScore? _finalScore;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadFinalScore();
  }
  
  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.elasticOut,
    ));
    
    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOut,
    ));
    
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_particleController);
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }
  
  void _loadFinalScore() {
    setState(() => _isLoading = true);
    
    // Simuler un délai pour l'effet dramatique
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _finalScore = _scoreService.getFinalScore();
        _isLoading = false;
      });
      
      _mainController.forward();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Particules animées en arrière-plan
          _buildParticleBackground(),
          
          // Contenu principal
          SafeArea(
            child: _isLoading
                ? _buildLoadingScreen()
                : _buildScoreScreen(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildParticleBackground() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: ParticlePainter(_particleAnimation.value),
          size: Size.infinite,
        );
      },
    );
  }
  
  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withOpacity(_glowAnimation.value * 0.3),
                  border: Border.all(
                    color: Colors.blue.withOpacity(_glowAnimation.value),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: Colors.white,
                  size: 40,
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          const Text(
            'Calcul des scores...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildScoreScreen() {
    if (_finalScore == null) return const SizedBox.shrink();
    
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(_slideAnimation),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // En-tête
                _buildHeader(),
                
                const SizedBox(height: 30),
                
                // Score principal
                _buildMainScore(),
                
                const SizedBox(height: 30),
                
                // Statistiques
                _buildStatistics(),
                
                const SizedBox(height: 30),
                
                // Détails par page
                _buildPageDetails(),
                
                const SizedBox(height: 30),
                
                // Actions
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withOpacity(_glowAnimation.value * 0.2),
                border: Border.all(
                  color: Colors.blue.withOpacity(_glowAnimation.value),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(_glowAnimation.value * 0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Colors.yellow,
                size: 60,
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'SCORES FINAUX',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Session terminée',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 16,
          ),
        ),
      ],
    );
  }
  
  Widget _buildMainScore() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withOpacity(0.3),
            Colors.purple.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'SCORE TOTAL',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_finalScore!.totalScore}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem('Durée', _finalScore!.formattedDuration),
              _buildStatItem('Pages', '${_finalScore!.pageScores.length}'),
              _buildStatItem('Événements', '${_finalScore!.scoreEvents.length}'),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatistics() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Statistiques',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildStatRow('Score moyen par page', '${_finalScore!.averageScorePerPage.toStringAsFixed(1)}'),
          _buildStatRow('Temps moyen par page', '${_finalScore!.averageTimePerPage.toStringAsFixed(1)}s'),
          _buildStatRow('Score par seconde', '${_finalScore!.scorePerSecond.toStringAsFixed(2)}'),
          if (_finalScore!.bestPage != null)
            _buildStatRow('Meilleure page', '${_finalScore!.bestPage!.pageName} (${_finalScore!.bestPage!.score} pts)'),
          if (_finalScore!.worstPage != null)
            _buildStatRow('Page la plus difficile', '${_finalScore!.worstPage!.pageName} (${_finalScore!.worstPage!.score} pts)'),
        ],
      ),
    );
  }
  
  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPageDetails() {
    if (_finalScore!.pageScores.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Détails par page',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._finalScore!.pageScores.values.map((pageScore) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pageScore.pageName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pageScore.duration.inMinutes}m ${pageScore.duration.inSeconds.remainder(60)}s',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${pageScore.score} pts',
                        style: const TextStyle(
                          color: Colors.yellow,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${pageScore.scorePerSecond.toStringAsFixed(1)} pts/s',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  Widget _buildActions() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            _scoreService.reset();
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          },
          icon: const Icon(Icons.home),
          label: const Text('Retour à l\'accueil'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () {
            _scoreService.startSession();
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          },
          icon: const Icon(Icons.refresh),
          label: const Text('Nouvelle session'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _glowController.dispose();
    super.dispose();
  }
}

class ParticlePainter extends CustomPainter {
  final double animationValue;
  
  ParticlePainter(this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    final random = math.Random(42); // Seed fixe pour des particules cohérentes
    
    for (int i = 0; i < 50; i++) {
      final x = (random.nextDouble() * size.width + animationValue * 100) % size.width;
      final y = (random.nextDouble() * size.height + animationValue * 50) % size.height;
      final radius = random.nextDouble() * 2 + 1;
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
  
  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
