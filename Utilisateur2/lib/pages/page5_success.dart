import 'package:flutter/material.dart';

class CalmSuccessPage extends StatelessWidget {
  const CalmSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.self_improvement, size: 64, color: Colors.black87),
                  SizedBox(height: 16),
                  Text(
                    'Bravo.',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'En décochant le vacarme, tu viens de choisir la paix.\nTu peux le faire chaque jour: décide quelles notifications méritent vraiment ton attention.',
                    style: TextStyle(color: Colors.black54, fontSize: 16, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


