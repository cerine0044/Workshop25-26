import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'page1_puzzle.dart';
import 'stress_page.dart';
import 'page3_words.dart';
import 'page4_tram.dart';
import 'page5_notifications.dart';
import 'page5_success.dart';
import 'firebase_admin_panel.dart';
import 'working_multiplayer_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _showModeSelection = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Mysterious gradient fog
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final double t = _controller.value;
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(
                        math.sin(t * math.pi * 2) * 0.4,
                        math.cos(t * math.pi * 2) * 0.4,
                      ),
                      radius: 1.2,
                      colors: [
                        Colors.black,
                        Color.lerp(Colors.blueGrey.shade900, Colors.deepPurple.shade900, (0.5 + 0.5 * math.sin(t * 6)).clamp(0.0, 1.0))!,
                        Color.lerp(Colors.indigo, Colors.deepPurple, (0.5 + 0.5 * math.cos(t * 5)).clamp(0.0, 1.0))!,
                      ],
                      stops: const [0.2, 0.65, 1.0],
                    ),
                  ),
                );
              },
            ),

            // Title
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'PANDORA BOX',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                        letterSpacing: 6,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Attention: effets lumineux (épilepsie) — jouer prudemment',
                      style: TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),

            // Mode selection or Start button
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final double t = _controller.value;
                  final double pulse = 1.0 + 0.05 * math.sin(t * math.pi * 2);
                  
                  if (_showModeSelection) {
                    return _buildModeSelection();
                  }
                  
                  return Transform.scale(
                    scale: pulse,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _showModeSelection = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 22),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.8), width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.redAccent.withOpacity(0.5 + 0.3 * math.sin(t * 6)), blurRadius: 28, spreadRadius: 2),
                          ],
                          gradient: LinearGradient(
                            colors: [
                              Colors.redAccent.withOpacity(0.85),
                              Colors.deepPurpleAccent.withOpacity(0.6),
                            ],
                          ),
                        ),
                        child: const Text(
                          'START',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Footer subtitle
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _showModeSelection 
                        ? 'Choisis ton mode de jeu'
                        : 'Chrono: commence dès que tu appuies sur START',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                    const SizedBox(height: 16),
                    // Boutons de debug
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildDebugButton('Page 1', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Page1Puzzle()))),
                        _buildDebugButton('Page 2', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StressPage()))),
                        _buildDebugButton('Page 3', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Page3Words()))),
                        _buildDebugButton('Page 4', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Page4Tram()))),
                        _buildDebugButton('Page 5', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Page5Notifications()))),
                        _buildDebugButton('Success', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CalmSuccessPage()))),
                        _buildDebugButton('Admin Firebase', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FirebaseAdminPanel()))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Mode Solo
        _buildModeButton(
          title: 'MODE SOLO',
          subtitle: 'Joue seul',
          icon: Icons.person,
          color: Colors.blueAccent,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const Page1Puzzle()),
            );
          },
        ),
        
        const SizedBox(height: 20),
        
        // Mode Multiplayer
        _buildModeButton(
          title: 'MODE MULTIJOUEUR',
          subtitle: 'Joue avec d\'autres',
          icon: Icons.people,
          color: Colors.greenAccent,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const WorkingMultiplayerPage()),
            );
          },
        ),
        
        const SizedBox(height: 20),
        
        // Retour
        GestureDetector(
          onTap: () {
            setState(() {
              _showModeSelection = false;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
            ),
            child: const Text(
              'RETOUR',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModeButton({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.8), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.8),
              color.withOpacity(0.4),
            ],
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugButton(String label, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.3),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white.withOpacity(0.5)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}


