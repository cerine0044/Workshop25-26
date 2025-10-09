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

class EnhancedGameMenuPage extends StatefulWidget {
  const EnhancedGameMenuPage({super.key});

  @override
  State<EnhancedGameMenuPage> createState() => _EnhancedGameMenuPageState();
}

class _EnhancedGameMenuPageState extends State<EnhancedGameMenuPage>
    with TickerProviderStateMixin {
  
  final GlobalScoreService _scoreService = GlobalScoreService();
  
  late AnimationController _pulseController;
  late AnimationController _glitchController;
  late AnimationController _stressController;
  late AnimationController _particleController;
  late AnimationController _menuController;
  late AnimationController _heartbeatController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _glitchAnimation;
  late Animation<double> _stressAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _menuAnimation;
  late Animation<double> _heartbeatAnimation;
  
  bool _isGlitching = false;
  double _stressLevel = 0.0;
  Timer? _stressTimer;
  Timer? _glitchTimer;
  Timer? _heartbeatTimer;
  
  int _selectedIndex = 0;
  final List<GameMenuItem> _menuItems = [
    GameMenuItem('Puzzle', Icons.extension, Colors.blue, 'Résolvez des énigmes complexes'),
    GameMenuItem('Stress Detector', Icons.psychology, Colors.red, 'Mesurez votre niveau de stress'),
    GameMenuItem('Crossword', Icons.grid_on, Colors.green, 'Mots croisés interactifs'),
    GameMenuItem('Tram Game', Icons.train, Colors.orange, 'Jeu de simulation de tram'),
    GameMenuItem('Notifications', Icons.notifications, Colors.purple, 'Gestion des alertes'),
    GameMenuItem('Success Page', Icons.emoji_events, Colors.amber, 'Page de réussite'),
    GameMenuItem('Multiplayer', Icons.people, Colors.teal, 'Mode multijoueur'),
    GameMenuItem('Scores', Icons.analytics, Colors.indigo, 'Statistiques et scores'),
  ];
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStressSimulation();
    _scoreService.startSession();
  }
  
  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _stressController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat();
    
    _menuController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _heartbeatController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat();
    
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
    
    _menuAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _menuController,
      curve: Curves.elasticOut,
    ));
    
    _heartbeatAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _heartbeatController,
      curve: Curves.easeInOut,
    ));
    
    _menuController.forward();
  }
  
  void _startStressSimulation() {
    _stressTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _stressLevel = math.Random().nextDouble();
        if (_stressLevel > 0.7) {
          _triggerGlitch();
        }
      });
    });
    
    _glitchTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (math.Random().nextDouble() > 0.6) {
        _triggerGlitch();
      }
    });
    
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_stressLevel > 0.5) {
        _heartbeatController.forward().then((_) {
          _heartbeatController.reverse();
        });
      }
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
              opacity: _menuAnimation,
              child: _buildGameMenu(),
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
          
          // Effet de battement de cœur
          if (_stressLevel > 0.5) _buildHeartbeatEffect(),
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
              radius: 1.8,
              colors: [
                Colors.black,
                Color.lerp(Colors.red.shade900, Colors.orange.shade900, _stressLevel)!,
                Color.lerp(Colors.red.shade700, Colors.yellow.shade700, _stressLevel * 0.4)!,
                Color.lerp(Colors.red.shade500, Colors.white, _stressLevel * 0.1)!,
              ],
              stops: [0.0, 0.6, 0.8, 1.0],
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
          painter: EnhancedStressParticlePainter(_particleAnimation.value, _stressLevel),
          size: Size.infinite,
        );
      },
    );
  }
  
  Widget _buildGameMenu() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // En-tête du jeu
          _buildGameHeader(),
          
          const SizedBox(height: 30),
          
          // Menu principal
          Expanded(
            child: _buildMainMenu(),
          ),
          
          const SizedBox(height: 20),
          
          // Barre de stress et contrôles
          _buildBottomControls(),
        ],
      ),
    );
  }
  
  Widget _buildGameHeader() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Column(
            children: [
              // Logo du jeu avec effet de battement
              AnimatedBuilder(
                animation: _heartbeatAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _stressLevel > 0.5 ? _heartbeatAnimation.value : 1.0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withOpacity(0.4),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.9),
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.6),
                            blurRadius: 25,
                            spreadRadius: 8,
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
              
              // Titre du jeu avec effet de glitch
              AnimatedBuilder(
                animation: _glitchAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(
                      _isGlitching ? (math.Random().nextDouble() - 0.5) * 12 : 0,
                      _isGlitching ? (math.Random().nextDouble() - 0.5) * 6 : 0,
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
                            color: Colors.red.withOpacity(0.9),
                            blurRadius: 15,
                            offset: const Offset(3, 3),
                          ),
                          Shadow(
                            color: Colors.black.withOpacity(0.8),
                            blurRadius: 20,
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'STRESS ENVIRONMENT',
                style: TextStyle(
                  color: Colors.red.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildMainMenu() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.red.withOpacity(0.6),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'MAIN MENU',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Liste des options de menu
          Expanded(
            child: ListView.builder(
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final isSelected = index == _selectedIndex;
                
                return _buildMenuItem(item, index, isSelected);
              },
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Bouton de sélection
          _buildSelectButton(),
        ],
      ),
    );
  }
  
  Widget _buildMenuItem(GameMenuItem item, int index, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedIndex = index;
            });
            _scoreService.addScore(5, 'Menu item selected');
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isSelected 
                  ? item.color.withOpacity(0.4)
                  : Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected 
                    ? item.color.withOpacity(0.9)
                    : Colors.white.withOpacity(0.3),
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: item.color.withOpacity(0.4),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ] : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: item.color.withOpacity(0.6),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.color,
                    size: 28,
                  ),
                ),
                
                const SizedBox(width: 20),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontSize: 18,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.description,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: item.color,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSelectButton() {
    final selectedItem = _menuItems[_selectedIndex];
    
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: ElevatedButton.icon(
            onPressed: () => _navigateToSelectedItem(),
            icon: Icon(selectedItem.icon, color: Colors.white, size: 24),
            label: Text(
              'SELECT ${selectedItem.title.toUpperCase()}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 16,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedItem.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 12,
              shadowColor: selectedItem.color.withOpacity(0.5),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildBottomControls() {
    return Column(
      children: [
        // Barre de stress
        _buildStressBar(),
        
        const SizedBox(height: 16),
        
        // Indicateurs
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildIndicator('STRESS', _stressLevel, Colors.red),
            _buildIndicator('GLITCH', _isGlitching ? 1.0 : 0.0, Colors.cyan),
            _buildIndicator('HEART', _stressLevel > 0.5 ? 1.0 : 0.0, Colors.pink),
          ],
        ),
      ],
    );
  }
  
  Widget _buildStressBar() {
    return Container(
      width: double.infinity,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withOpacity(0.4)),
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
                    Colors.purple,
                  ],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildIndicator(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: value > 0 ? color.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
            border: Border.all(
              color: value > 0 ? color : Colors.grey,
              width: 2,
            ),
          ),
          child: Center(
            child: Icon(
              _getIndicatorIcon(label),
              color: value > 0 ? color : Colors.grey,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }
  
  IconData _getIndicatorIcon(String label) {
    switch (label) {
      case 'STRESS':
        return Icons.psychology;
      case 'GLITCH':
        return Icons.bug_report;
      case 'HEART':
        return Icons.favorite;
      default:
        return Icons.circle;
    }
  }
  
  Widget _buildGlitchEffect() {
    return AnimatedBuilder(
      animation: _glitchAnimation,
      builder: (context, child) {
        return Container(
          color: Colors.cyan.withOpacity(0.15),
          child: CustomPaint(
            painter: EnhancedGlitchPainter(_glitchAnimation.value),
            size: Size.infinite,
          ),
        );
      },
    );
  }
  
  Widget _buildHeartbeatEffect() {
    return AnimatedBuilder(
      animation: _heartbeatAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.red.withOpacity(_heartbeatAnimation.value * 0.3),
              width: 4,
            ),
          ),
        );
      },
    );
  }
  
  void _navigateToSelectedItem() {
    final selectedItem = _menuItems[_selectedIndex];
    
    switch (selectedItem.title) {
      case 'Puzzle':
        _navigateToPage('Puzzle', const Page1Puzzle());
        break;
      case 'Stress Detector':
        _navigateToPage('Stress', const StressPage());
        break;
      case 'Crossword':
        _navigateToPage('Mots Croisés', const Page3Crossword());
        break;
      case 'Tram Game':
        _navigateToPage('Tram', const Page4Tram());
        break;
      case 'Notifications':
        _navigateToPage('Notifications', const Page5Notifications());
        break;
      case 'Success Page':
        _navigateToPage('Succès', const CalmSuccessPage());
        break;
      case 'Multiplayer':
        _navigateToPage('Multijoueur', const EnhancedRoomPage());
        break;
      case 'Scores':
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const FinalScorePage()),
        );
        break;
    }
  }
  
  void _navigateToPage(String pageName, Widget page) {
    _scoreService.startPage(pageName);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    ).then((_) {
      _scoreService.endPage(pageName);
    });
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _glitchController.dispose();
    _stressController.dispose();
    _particleController.dispose();
    _menuController.dispose();
    _heartbeatController.dispose();
    _stressTimer?.cancel();
    _glitchTimer?.cancel();
    _heartbeatTimer?.cancel();
    super.dispose();
  }
}

class GameMenuItem {
  final String title;
  final IconData icon;
  final Color color;
  final String description;
  
  GameMenuItem(this.title, this.icon, this.color, this.description);
}

class EnhancedStressParticlePainter extends CustomPainter {
  final double animationValue;
  final double stressLevel;
  
  EnhancedStressParticlePainter(this.animationValue, this.stressLevel);
  
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final particleCount = (40 + stressLevel * 60).round();
    
    for (int i = 0; i < particleCount; i++) {
      final paint = Paint()
        ..color = Color.lerp(
          Colors.white.withOpacity(0.1),
          Colors.red.withOpacity(0.4),
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
  bool shouldRepaint(EnhancedStressParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.stressLevel != stressLevel;
  }
}

class EnhancedGlitchPainter extends CustomPainter {
  final double animationValue;
  
  EnhancedGlitchPainter(this.animationValue);
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.cyan.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    
    final random = math.Random(42);
    
    // Lignes de glitch horizontales
    for (int i = 0; i < 12; i++) {
      final y = random.nextDouble() * size.height;
      final height = random.nextDouble() * 4 + 1;
      
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, height),
        paint,
      );
    }
    
    // Lignes de glitch verticales
    for (int i = 0; i < 8; i++) {
      final x = random.nextDouble() * size.width;
      final width = random.nextDouble() * 3 + 1;
      
      canvas.drawRect(
        Rect.fromLTWH(x, 0, width, size.height),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(EnhancedGlitchPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
