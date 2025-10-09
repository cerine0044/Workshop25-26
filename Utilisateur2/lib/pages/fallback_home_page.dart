import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'page1_puzzle.dart';
import 'stress_page.dart';
import 'page3_crossword.dart';
import 'page4_tram.dart';
import 'page5_notifications.dart';
import 'page5_success.dart';
import 'final_score_page.dart';

class FallbackHomePage extends StatefulWidget {
  const FallbackHomePage({super.key});

  @override
  State<FallbackHomePage> createState() => _FallbackHomePageState();
}

class _FallbackHomePageState extends State<FallbackHomePage>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _glitchController;
  
  late Animation<double> _pulseAnimation;
  late Animation<double> _glitchAnimation;
  
  bool _isGlitching = false;
  Timer? _glitchTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startGlitchSimulation();
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
  }
  
  void _startGlitchSimulation() {
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
          // Arrière-plan
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Colors.black,
                  Color(0xFF1A1A1A),
                  Color(0xFF0A0A0A),
                ],
                stops: [0.0, 0.6, 1.0],
              ),
            ),
          ),
          
          // Contenu principal
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  
                  // En-tête
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
                  
                  // Section des jeux
                  _buildGamesSection(),
                  
                  const Spacer(),
                  
                  // Footer
                  _buildFooter(),
                ],
              ),
            ),
          ),
          
          // Effet de glitch
          if (_isGlitching) _buildGlitchEffect(),
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
      animation: _glitchAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _isGlitching ? (math.Random().nextDouble() - 0.5) * 10 : 0,
            _isGlitching ? (math.Random().nextDouble() - 0.5) * 5 : 0,
          ),
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
        );
      },
    );
  }
  
  Widget _buildMainTitle() {
    return Column(
      children: [
        Text(
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
        const SizedBox(height: 8),
        Text(
          'Mode Hors Ligne',
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        '⚠️ Mode hors ligne - Fonctionnalités limitées',
        style: TextStyle(
          fontSize: 16,
          color: Colors.orange.shade300,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  Widget _buildMainButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: ElevatedButton(
            onPressed: () => _showGameMenu(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 8,
              shadowColor: Colors.red.withOpacity(0.5),
            ),
            child: const Text(
              'Jouer Maintenant',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildGamesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          const Text(
            'Jeux Disponibles',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildGameButton('Puzzle', Icons.extension, Colors.blue, () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const Page1Puzzle()),
                );
              }),
              _buildGameButton('Stress', Icons.psychology, Colors.red, () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const StressPage()),
                );
              }),
              _buildGameButton('Mots Croisés', Icons.grid_on, Colors.green, () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const Page3Crossword()),
                );
              }),
              _buildGameButton('Tram', Icons.train, Colors.orange, () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const Page4Tram()),
                );
              }),
              _buildGameButton('Notifications', Icons.notifications, Colors.purple, () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const Page5Notifications()),
                );
              }),
              _buildGameButton('Succès', Icons.emoji_events, Colors.amber, () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CalmSuccessPage()),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildGameButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Text(
                'Mode hors ligne - Multijoueur indisponible',
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Rechargez la page pour réessayer la connexion',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget _buildGlitchEffect() {
    return AnimatedBuilder(
      animation: _glitchAnimation,
      builder: (context, child) {
        return Container(
          color: Colors.cyan.withOpacity(0.1),
        );
      },
    );
  }
  
  void _showGameMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(
            color: Colors.white.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            
            _buildGameOption('Puzzle', Icons.extension, Colors.blue, () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const Page1Puzzle()),
              );
            }),
            
            _buildGameOption('Détecteur de Stress', Icons.psychology, Colors.red, () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const StressPage()),
              );
            }),
            
            _buildGameOption('Mots Croisés', Icons.grid_on, Colors.green, () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const Page3Crossword()),
              );
            }),
            
            _buildGameOption('Jeu du Tram', Icons.train, Colors.orange, () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const Page4Tram()),
              );
            }),
            
            _buildGameOption('Notifications', Icons.notifications, Colors.purple, () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const Page5Notifications()),
              );
            }),
            
            _buildGameOption('Page de Succès', Icons.emoji_events, Colors.amber, () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CalmSuccessPage()),
              );
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
    );
  }
  
  Widget _buildGameOption(String title, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
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
  
  @override
  void dispose() {
    _pulseController.dispose();
    _glitchController.dispose();
    _glitchTimer?.cancel();
    super.dispose();
  }
}
