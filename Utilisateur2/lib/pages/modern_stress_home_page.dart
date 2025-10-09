import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/global_score_service.dart';
import '../widgets/score_display_widget.dart';
import 'page1_puzzle.dart';
import 'stress_page.dart';
import 'page3_crossword.dart';
import 'page4_tram.dart';
import 'page5_notifications.dart';
import 'page5_success.dart';
import 'enhanced_room_page.dart';
import 'final_score_page.dart';

class ModernStressHomePage extends StatefulWidget {
  const ModernStressHomePage({super.key});

  @override
  State<ModernStressHomePage> createState() => _ModernStressHomePageState();
}

class _ModernStressHomePageState extends State<ModernStressHomePage>
    with TickerProviderStateMixin {
  
  final GlobalScoreService _scoreService = GlobalScoreService();
  
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late AnimationController _glitchController;
  late AnimationController _stressController;
  late AnimationController _particleController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glitchAnimation;
  late Animation<double> _stressAnimation;
  late Animation<double> _particleAnimation;
  
  bool _showMenu = false;
  bool _isGlitching = false;
  double _stressLevel = 0.0;
  Timer? _stressTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStressSimulation();
    _scoreService.startSession();
  }
  
  void _initializeAnimations() {
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _stressController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.easeOut,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: Curves.elasticOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _glitchAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_glitchController);
    
    _stressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_stressController);
    
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_particleController);
    
    _mainController.forward();
  }
  
  void _startStressSimulation() {
    _stressTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _stressLevel = math.Random().nextDouble();
        if (_stressLevel > 0.7) {
          _triggerGlitch();
        }
      });
    });
  }
  
  void _triggerGlitch() {
    setState(() {
      _isGlitching = true;
    });
    
    _glitchController.forward().then((_) {
      _glitchController.reset();
      setState(() {
        _isGlitching = false;
      });
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arrière-plan avec effets de stress
          _buildStressBackground(),
          
          // Particules
          _buildParticles(),
          
          // Contenu principal
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: _showMenu ? _buildMenu() : _buildMainScreen(),
              ),
            ),
          ),
          
          // Widget de score
          Positioned(
            top: 20,
            right: 20,
            child: const ScoreDisplayWidget(compact: true),
          ),
          
          // Effet de glitch
          if (_isGlitching) _buildGlitchEffect(),
        ],
      ),
    );
  }
  
  Widget _buildStressBackground() {
    return AnimatedBuilder(
      animation: _stressAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.5,
              colors: [
                Colors.black,
                Color.lerp(Colors.red.shade900, Colors.orange.shade900, _stressLevel)!,
                Color.lerp(Colors.red.shade700, Colors.yellow.shade700, _stressLevel * 0.5)!,
              ],
              stops: [0.0, 0.7, 1.0],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildParticles() {
    return AnimatedBuilder(
      animation: _particleAnimation,
      builder: (context, child) {
        return CustomPaint(
          painter: StressParticlePainter(_particleAnimation.value, _stressLevel),
          size: Size.infinite,
        );
      },
    );
  }
  
  Widget _buildMainScreen() {
    return Column(
      children: [
        // En-tête avec effet de stress
        Expanded(
          flex: 2,
          child: _buildHeader(),
        ),
        
        // Zone de jeu principale
        Expanded(
          flex: 3,
          child: _buildGameArea(),
        ),
        
        // Actions
        Expanded(
          flex: 1,
          child: _buildActions(),
        ),
      ],
    );
  }
  
  Widget _buildHeader() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo avec effet de stress
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.red.withOpacity(0.3),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.8),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.warning,
                    color: Colors.red,
                    size: 60,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // Titre avec effet de glitch
          AnimatedBuilder(
            animation: _glitchAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(
                  _isGlitching ? (math.Random().nextDouble() - 0.5) * 10 : 0,
                  _isGlitching ? (math.Random().nextDouble() - 0.5) * 5 : 0,
                ),
                child: Text(
                  'PANDORA BOX',
                  style: TextStyle(
                    color: _isGlitching ? Colors.cyan : Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    shadows: [
                      Shadow(
                        color: Colors.red.withOpacity(0.8),
                        blurRadius: 10,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'ENVIRONNEMENT DE STRESS',
            style: TextStyle(
              color: Colors.red.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Barre de stress
          _buildStressBar(),
        ],
      ),
    );
  }
  
  Widget _buildStressBar() {
    return Container(
      width: 200,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: AnimatedBuilder(
        animation: _stressAnimation,
        builder: (context, child) {
          return FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _stressLevel,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green,
                    Colors.yellow,
                    Colors.orange,
                    Colors.red,
                  ],
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildGameArea() {
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showMenu = true;
                });
                _scoreService.addScore(10, 'Menu ouvert');
              },
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.red.withOpacity(0.8),
                      Colors.orange.withOpacity(0.6),
                      Colors.yellow.withOpacity(0.4),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 40,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'START',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            'Scores',
            Icons.analytics,
            Colors.blue,
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FinalScorePage()),
            ),
          ),
          _buildActionButton(
            'Multijoueur',
            Icons.people,
            Colors.green,
            () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EnhancedRoomPage()),
            ),
          ),
          _buildActionButton(
            'Paramètres',
            Icons.settings,
            Colors.grey,
            () => _showSettings(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMenu() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // En-tête du menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MENU PRINCIPAL',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _showMenu = false;
                  });
                },
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Options du menu
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildMenuOption(
                  'Puzzle',
                  Icons.extension,
                  Colors.blue,
                  () => _navigateToPage('Puzzle', const Page1Puzzle()),
                ),
                _buildMenuOption(
                  'Stress',
                  Icons.psychology,
                  Colors.red,
                  () => _navigateToPage('Stress', const StressPage()),
                ),
                _buildMenuOption(
                  'Mots Croisés',
                  Icons.grid_on,
                  Colors.green,
                  () => _navigateToPage('Mots Croisés', const Page3Crossword()),
                ),
                _buildMenuOption(
                  'Tram',
                  Icons.train,
                  Colors.orange,
                  () => _navigateToPage('Tram', const Page4Tram()),
                ),
                _buildMenuOption(
                  'Notifications',
                  Icons.notifications,
                  Colors.purple,
                  () => _navigateToPage('Notifications', const Page5Notifications()),
                ),
                _buildMenuOption(
                  'Succès',
                  Icons.emoji_events,
                  Colors.yellow,
                  () => _navigateToPage('Succès', const CalmSuccessPage()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMenuOption(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.3),
              color.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 40),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGlitchEffect() {
    return AnimatedBuilder(
      animation: _glitchAnimation,
      builder: (context, child) {
        return Container(
          color: Colors.cyan.withOpacity(0.1),
          child: CustomPaint(
            painter: GlitchPainter(_glitchAnimation.value),
            size: Size.infinite,
          ),
        );
      },
    );
  }
  
  void _navigateToPage(String pageName, Widget page) {
    _scoreService.startPage(pageName);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    ).then((_) {
      _scoreService.endPage(pageName);
    });
  }
  
  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: const Text('Paramètres', style: TextStyle(color: Colors.white)),
        content: const Text('Paramètres en cours de développement...', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _glitchController.dispose();
    _stressController.dispose();
    _particleController.dispose();
    _stressTimer?.cancel();
    super.dispose();
  }
}

class StressParticlePainter extends CustomPainter {
  final double animationValue;
  final double stressLevel;
  
  StressParticlePainter(this.animationValue, this.stressLevel);
  
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final particleCount = (50 + stressLevel * 100).round();
    
    for (int i = 0; i < particleCount; i++) {
      final paint = Paint()
        ..color = Color.lerp(
          Colors.white.withOpacity(0.1),
          Colors.red.withOpacity(0.3),
          stressLevel,
        )!
        ..style = PaintingStyle.fill;
      
      final x = (random.nextDouble() * size.width + animationValue * 100) % size.width;
      final y = (random.nextDouble() * size.height + animationValue * 50) % size.height;
      final radius = random.nextDouble() * 3 + 1;
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
  
  @override
  bool shouldRepaint(StressParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.stressLevel != stressLevel;
  }
}

class GlitchPainter extends CustomPainter {
  final double animationValue;
  
  GlitchPainter(this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final random = math.Random(42);
    
    // Lignes de glitch horizontales
    for (int i = 0; i < 10; i++) {
      final y = random.nextDouble() * size.height;
      final height = random.nextDouble() * 5 + 1;
      
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, height),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(GlitchPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
