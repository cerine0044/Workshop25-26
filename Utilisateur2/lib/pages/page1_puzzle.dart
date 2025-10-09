import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'stress_page.dart';

class Page1Puzzle extends StatefulWidget {
  const Page1Puzzle({super.key});

  @override
  State<Page1Puzzle> createState() => _Page1PuzzleState();
}

class _Page1PuzzleState extends State<Page1Puzzle> {
  bool _showHome = true;
  bool _won = false;
  final math.Random _rand = math.Random();

  bool _split = false; // Le bouton invisible est-il actif ?
  Offset _decoyOffset = Offset.zero; // Position du bouton leurre

  void _onAttemptMoveDecoy() {
    // Active le bouton invisible au premier mouvement
    if (!_split) {
      setState(() {
        _split = true;
      });
    }

    // Déplace le bouton leurre vers une position aléatoire
    final double dx = (_rand.nextDouble() * 600) - 300; // -300 à +300
    final double dy = (_rand.nextDouble() * 400) - 200; // -200 à +200

    setState(() {
      _decoyOffset = Offset(dx, dy);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101018),
      body: SafeArea(
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _showHome ? _buildHome() : _buildResult(),
          ),
        ),
      ),
    );
  }

  Widget _buildHome() {
    return SizedBox(
      key: const ValueKey('home'),
      width: 800,
      height: 600,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Question centrée au milieu de la page
          const Positioned(
            left: 0,
            right: 0,
            top: 225,
            child: Text(
              'Es-tu stressé ?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // Boutons centrés en dessous de la question
          Positioned(
            left: 0,
            right: 0,
            top: 300,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Bouton OUI (toujours visible et fonctionnel)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showHome = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 16,
                    ),
                  ),
                  child: const Text('OUI', style: TextStyle(fontSize: 18)),
                ),

                const SizedBox(width: 20),

                // Espace pour le bouton NON initial (qui deviendra invisible)
                SizedBox(
                  width: 100,
                  height: 50,
                  child: Stack(
                    children: [
                      // Bouton NON invisible (actif après premier mouvement)
                      if (_split)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () async {
                            setState(() {
                              _won = true;
                            });
                            await _showWinDialog();
                            if (mounted) {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(builder: (context) => const StressPage()),
                              );
                            }
                          },
                          child: Container(
                            width: 100,
                            height: 50,
                            color: Colors.transparent,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bouton NON leurre (se déplace)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            // Position relative au centre du Stack
            left: 350 + _decoyOffset.dx, // Position initiale à côté du OUI
            top: 250 + _decoyOffset.dy,
            child: MouseRegion(
              onHover: (_) => _onAttemptMoveDecoy(),
              child: GestureDetector(
                onTapDown: (_) => _onAttemptMoveDecoy(),
                child: Container(
                  width: 200, // Zone de détection élargie
                  height: 100,
                  alignment: Alignment.center,
                  child: ElevatedButton(
                    onPressed: _onAttemptMoveDecoy,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('NON', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult() {
    return Column(
      key: const ValueKey('result'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _won ? 'Bravo, tu as gagné !' : 'Reviens plus tard',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _won = false;
              _showHome = true;
              _split = false;
              _decoyOffset = Offset.zero;
            });
          },
          icon: const Icon(Icons.home),
          label: const Text('Retour à l\'accueil'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _showWinDialog() async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1C1C28),
          title:
              const Text('Victoire !', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Tu as trouvé le véritable bouton. Bien joué !',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}