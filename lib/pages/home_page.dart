import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'page1_puzzle.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

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

            // Big mysterious Start button
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final double t = _controller.value;
                  final double pulse = 1.0 + 0.05 * math.sin(t * math.pi * 2);
                  return Transform.scale(
                    scale: pulse,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const Page1Puzzle()),
                        );
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
                child: Text(
                  'Chrono: commence dès que tu appuies sur START',
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


