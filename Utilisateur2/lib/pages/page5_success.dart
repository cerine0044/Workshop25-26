import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/global_score_service.dart';
import 'final_score_page.dart';

class CalmSuccessPage extends StatefulWidget {
  const CalmSuccessPage({super.key});

  @override
  State<CalmSuccessPage> createState() => _CalmSuccessPageState();
}

class _CalmSuccessPageState extends State<CalmSuccessPage> {
  final GlobalScoreService _scoreService = GlobalScoreService();
  bool _scoresRecorded = false;

  @override
  void initState() {
    super.initState();
    _recordScores();
  }

  void _recordScores() {
    if (!_scoresRecorded) {
      // Enregistrer automatiquement les scores quand on atteint la page de succès
      _scoreService.endPage('Page de Succès');
      _scoresRecorded = true;
      
      // Feedback haptique pour la réussite
      HapticFeedback.heavyImpact();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Scores enregistrés automatiquement !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

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
                children: [
                  const Icon(Icons.self_improvement, size: 64, color: Colors.black87),
                  const SizedBox(height: 16),
                  const Text(
                    'Bravo.',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'En décochant le vacarme, tu viens de choisir la paix.\nTu peux le faire chaque jour: décide quelles notifications méritent vraiment ton attention.',
                    style: TextStyle(color: Colors.black54, fontSize: 16, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Section des scores
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.green,
                          size: 32,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Scores enregistrés !',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Durée totale: ${_scoreService.sessionDuration.inSeconds}s',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          'Jeux joués: ${_scoreService.pageSessions.length}',
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Boutons d'action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const FinalScorePage()),
                          );
                        },
                        icon: const Icon(Icons.bar_chart),
                        label: const Text('Voir Scores'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                        },
                        icon: const Icon(Icons.home),
                        label: const Text('Accueil'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
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


