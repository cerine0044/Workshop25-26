import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/global_score_service.dart';
import '../widgets/score_display_widget.dart';
import 'page1_puzzle.dart';
import 'stress_page.dart';
import 'page3_words.dart';
import 'page4_tram.dart';
import 'page5_notifications.dart';
import 'page5_success.dart';
import 'working_multiplayer_page.dart';
import 'final_score_page.dart';

class EcoStressHomePage extends StatefulWidget {
  const EcoStressHomePage({super.key});

  @override
  State<EcoStressHomePage> createState() => _EcoStressHomePageState();
}

class _EcoStressHomePageState extends State<EcoStressHomePage>
    with TickerProviderStateMixin {
  
  final GlobalScoreService _scoreService = GlobalScoreService();
  
  late AnimationController _pulseController;
  late AnimationController _stressController;
  late AnimationController _particleController;
  late AnimationController _fadeController;
  late AnimationController _glitchController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _stressAnimation;
  late Animation<double> _particleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _glitchAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  
  double _stressLevel = 0.0;
  bool _isGlitching = false;
  Timer? _stressTimer;
  Timer? _glitchTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startStressSimulation();
    _scoreService.startSession();
    
    // Haptic feedback au démarrage
    HapticFeedback.lightImpact();
  }
  
  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _stressController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
    
    _particleController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _glitchController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _stressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_stressController);
    
    _particleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_particleController);
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));
    
    _glitchAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_glitchController);
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_rotationController);
    
    // Démarrer les animations avec des délais
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      _scaleController.forward();
    });
  }
  
  void _startStressSimulation() {
    _stressTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        _stressLevel = math.Random().nextDouble();
        if (_stressLevel > 0.6) {
          _triggerGlitch();
        }
      });
    });
    
    _glitchTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      if (math.Random().nextDouble() > 0.7) {
        _triggerGlitch();
      }
    });
  }
  
  void _triggerGlitch() {
    setState(() {
      _isGlitching = true;
    });
    
    HapticFeedback.heavyImpact();
    
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
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arrière-plan avec particules
          _buildParticleBackground(),
          
          // Contenu principal
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildMainContent(),
                ),
              ),
            ),
          ),
          
          // Widget de score avec animation
          Positioned(
            top: 20,
            right: 20,
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: const ScoreDisplayWidget(compact: true),
                  ),
                );
              },
            ),
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
          painter: EcoStressParticlePainter(_particleAnimation.value, _stressLevel),
          size: Size.infinite,
        );
      },
    );
  }
  
  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          
          // En-tête avec emojis
          _buildHeader(),
          
          const SizedBox(height: 60),
          
          // Titre principal
          _buildMainTitle(),
          
          const SizedBox(height: 20),
          
          // Sous-titre
          _buildSubtitle(),
          
          const SizedBox(height: 60),
          
          // Bouton principal
          _buildMainButton(),
          
          const SizedBox(height: 40),
          
          // Section multijoueur
          _buildMultiplayerSection(),
          
          const SizedBox(height: 40),
          
          // Bouton des règles
          _buildRulesButton(),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: _buildDangerousEmoji(),
        );
      },
    );
  }
  
  Widget _buildDangerousEmoji() {
    return AnimatedBuilder(
      animation: Listenable.merge([_glitchAnimation, _rotationAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _isGlitching ? (math.Random().nextDouble() - 0.5) * 10 : 0,
            _isGlitching ? (math.Random().nextDouble() - 0.5) * 5 : 0,
          ),
          child: Transform.rotate(
            angle: _isGlitching ? _rotationAnimation.value * 0.1 : 0,
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
              child: Icon(
                Icons.warning,
                color: _isGlitching ? Colors.cyan : Colors.red,
                size: 60,
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildMainTitle() {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: 1 + (_pulseAnimation.value - 1) * 0.1,
              child: Text(
                'Pandora Box',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                  shadows: [
                    Shadow(
                      color: Colors.red.withOpacity(0.5),
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
          'Survivez au stress en 3 minutes',
          style: TextStyle(
            fontSize: 18,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildSubtitle() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1 + (_pulseAnimation.value - 1) * 0.05,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              '⚠️ Environnement de stress intense',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red.shade300,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildMainButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                _showGameMenu();
              },
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade600, Colors.red.shade800],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Text(
                  'Jouer Maintenant',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildMultiplayerSection() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 30 * (1 - _fadeAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _navigateToMultiplayer();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue.shade600, Colors.blue.shade800],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people, color: Colors.white),
                            const SizedBox(width: 12),
                            const Text(
                              'Mode Multijoueur',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  Text(
                    '📝 Consultez la documentation pour activer le multijoueur',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    '📱 Installez l\'app pour jouer hors-ligne !',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildRulesButton() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _fadeAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _showGameRules();
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade600, Colors.purple.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.rule, color: Colors.white),
                      const SizedBox(width: 12),
                      const Text(
                        'Règles du jeu',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  void _showGameMenu() {
    HapticFeedback.lightImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Choisissez un jeu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 20),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildGameOption('Puzzle', Icons.extension, Colors.blue, () {
                      Navigator.pop(context);
                      _navigateToPage('Puzzle', const Page1Puzzle());
                    }),
                    
                    _buildGameOption('Détecteur de Stress', Icons.psychology, Colors.red, () {
                      Navigator.pop(context);
                      _navigateToPage('Stress', const StressPage());
                    }),
                    
                    _buildGameOption('Mots Croisés', Icons.grid_on, Colors.green, () {
                      Navigator.pop(context);
                      _navigateToPage('Mots Croisés', const Page3Words());
                    }),
                    
                    _buildGameOption('Jeu du Tram', Icons.train, Colors.orange, () {
                      Navigator.pop(context);
                      _navigateToPage('Tram', const Page4Tram());
                    }),
                    
                    _buildGameOption('Notifications', Icons.notifications, Colors.purple, () {
                      Navigator.pop(context);
                      _navigateToPage('Notifications', const Page5Notifications());
                    }),
                    
                    _buildGameOption('Page de Succès', Icons.emoji_events, Colors.amber, () {
                      Navigator.pop(context);
                      _navigateToPage('Succès', const CalmSuccessPage());
                    }),
                    
                    _buildGameOption('Scores', Icons.analytics, Colors.indigo, () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const FinalScorePage()),
                      );
                    }),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildGameOption(String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 16),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _navigateToMultiplayer() {
    try {
      HapticFeedback.mediumImpact();
      _scoreService.startPage('Multijoueur');
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const WorkingMultiplayerPage()),
      ).then((_) {
        _scoreService.endPage('Multijoueur');
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur multijoueur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  void _showGameRules() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Règles du jeu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 20),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _buildRuleCard(
                      number: '1',
                      icon: '🧩',
                      title: 'Défi Puzzle',
                      description: 'Résolvez des énigmes complexes - Mode défi avec 2 tentatives + explications pédagogiques ⚠️',
                      color: Colors.blue,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildRuleCard(
                      number: '2',
                      icon: '📝',
                      title: 'Mots Croisés',
                      description: 'Trouvez les mots pour obtenir le code secret en 3 niveaux',
                      color: Colors.green,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildRuleCard(
                      number: '3',
                      icon: '🚊',
                      title: 'Simulation Tram',
                      description: 'Rétablissez l\'équilibre pour sauver le système de transport',
                      color: Colors.orange,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildRuleCard(
                      number: '4',
                      icon: '🧠',
                      title: 'Détecteur de Stress',
                      description: 'Mesurez et gérez votre niveau de stress en temps réel',
                      color: Colors.red,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.timer,
                            color: Colors.red,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Temps limité : 3 minutes',
                            style: TextStyle(
                              color: Colors.red.shade300,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRuleCard({
    required String number,
    required String icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 20),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _navigateToPage(String pageName, Widget page) {
    HapticFeedback.lightImpact();
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
    _stressController.dispose();
    _particleController.dispose();
    _fadeController.dispose();
    _glitchController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    _stressTimer?.cancel();
    _glitchTimer?.cancel();
    super.dispose();
  }
}

class EcoStressParticlePainter extends CustomPainter {
  final double animationValue;
  final double stressLevel;
  
  EcoStressParticlePainter(this.animationValue, this.stressLevel);
  
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final particleCount = (20 + stressLevel * 30).round();
    
    for (int i = 0; i < particleCount; i++) {
      final paint = Paint()
        ..color = Color.lerp(
          Colors.white.withOpacity(0.05),
          Colors.red.withOpacity(0.2),
          stressLevel,
        )!
        ..style = PaintingStyle.fill;
      
      final x = (random.nextDouble() * size.width + animationValue * 60) % size.width;
      final y = (random.nextDouble() * size.height + animationValue * 30) % size.height;
      final radius = random.nextDouble() * 2 + 1;
      
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }
  
  @override
  bool shouldRepaint(EcoStressParticlePainter oldDelegate) {
    return oldDelegate.animationValue != animationValue || oldDelegate.stressLevel != stressLevel;
  }
}