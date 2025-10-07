import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'stress_page.dart';

class Page1Puzzle extends StatefulWidget {
  const Page1Puzzle({super.key});

  @override
  State<Page1Puzzle> createState() => _Page1PuzzleState();
}

class _Page1PuzzleState extends State<Page1Puzzle> {
  final List<Offset> _draggables = [
    const Offset(40, 120),
    const Offset(240, 180),
    const Offset(140, 340),
  ];
  final List<bool> _found = [false, false, false, false];
  final math.Random _rng = math.Random();

  @override
  Widget build(BuildContext context) {
    final bool unlocked = _found.where((v) => v).length >= 4;
    return Scaffold(
      appBar: AppBar(title: const Text('Salle 1 — Trouve les 4 boutons')),
      body: SafeArea(
        child: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.indigo.shade900, Colors.deepPurple.shade900],
                  ),
                ),
              ),
            ),

            // Hidden buttons (tap zones)
            ...List.generate(4, (i) => _buildHiddenButton(i)),

            // Draggable cover objects
            ..._draggables.asMap().entries.map((e) => _buildDraggable(e.key)),

            // Progress + Final button
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Boutons trouvés: ${_found.where((v) => v).length}/4',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: unlocked
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const StressPage()),
                              );
                            }
                          : null,
                      child: const Text('BoutonFinal — Aller à la Salle 2'),
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

  Widget _buildHiddenButton(int index) {
    final double x = 40 + index * 70;
    final double y = 120 + (index.isEven ? 60 : 140);
    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _found[index] = true;
          });
        },
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: _found[index] ? 1.0 : 0.2,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _found[index] ? Colors.greenAccent : Colors.white24,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white30),
            ),
            child: const Icon(Icons.circle, color: Colors.black54, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildDraggable(int i) {
    return Positioned(
      left: _draggables[i].dx,
      top: _draggables[i].dy,
      child: Draggable<int>(
        data: i,
        feedback: _coverWidget(opacity: 0.8),
        childWhenDragging: const SizedBox.shrink(),
        child: GestureDetector(
          onDoubleTap: () {
            setState(() {
              // Shuffle position on double tap to add chaos
              _draggables[i] = Offset(20 + _rng.nextInt(260).toDouble(), 80 + _rng.nextInt(400).toDouble());
            });
          },
          child: _coverWidget(),
        ),
        onDragEnd: (details) {
          setState(() {
            _draggables[i] = Offset(
              (details.offset.dx).clamp(0, MediaQuery.of(context).size.width - 80),
              (details.offset.dy - kToolbarHeight - MediaQuery.of(context).padding.top).clamp(0, MediaQuery.of(context).size.height - 160),
            );
          });
        },
      ),
    );
  }

  Widget _coverWidget({double opacity = 1.0}) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.blueGrey.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white30),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 10, spreadRadius: 2),
          ],
        ),
        child: const Icon(Icons.drag_indicator, color: Colors.white70),
      ),
    );
  }
}


