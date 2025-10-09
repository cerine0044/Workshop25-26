import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../services/game_stats_service.dart';
import '../widgets/game_timer_widget.dart';
import 'page5_notifications.dart';

class Page4Tram extends StatefulWidget {
  const Page4Tram({super.key});

  @override
  State<Page4Tram> createState() => _Page4TramState();
}

class _Page4TramState extends State<Page4Tram> with SingleTickerProviderStateMixin {
  final GameStatsService _statsService = GameStatsService();
  
  static const int questionsCount = 20;
  static const int secondsPerQuestion = 12; // timer par question

  static const List<String> _imageAssets = <String>[
    'assets/images/tram1.jpg',
    'assets/images/tram2.jpg',
    'assets/images/tram3.jpg',
    'assets/images/tram4.jpg',
    'assets/images/tram5.jpg',
  ];
  static const String _hornAsset = 'assets/sounds/horn.mp3';

  late final AnimationController _bgController;
  late List<_TramQuestion> _questions;
  int _index = 0;
  int _remaining = secondsPerQuestion;
  Timer? _ticker;
  final AudioPlayer _player = AudioPlayer();

  // Overlay visuel pour impacter l'utilisateur
  String? _overlayImageUrl; // image affichée en plein écran (chemin asset)
  double _overlayOpacity = 0.0;
  Timer? _overlayTimer;
  bool _overlayActive = false; // bloque l'UI quand true

  // Pré-contrôle des assets
  bool _assetsChecked = false;
  final List<String> _missingAssets = <String>[];

  // Contrôles et feedback
  bool _paused = false;
  String? _currentFeedback; // feedback affiché sur l'image
  bool _isDead = false; // écran de mort si timer dépassé
  String? _lastChoiceType; // type du dernier choix pour message contextuel

  // Stats de décisions
  int _countLevier = 0;
  int _countInaction = 0;
  int _countExtreme = 0;

  @override
  void initState() {
    super.initState();
    _questions = _generateQuestions();
    _shuffleQuestionsAndChoices();
    _bgController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _preflightAssets();
    _startGameSession();
  }

  @override
  void dispose() {
    _bgController.dispose();
    _ticker?.cancel();
    _overlayTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _startGameSession() {
    if (!_statsService.isSessionActive) {
      _statsService.startGameSession(
        playerName: 'Joueur Solo',
        gameRoom: 'Dilemme du Tram',
      );
    }
  }

  void _shuffleQuestionsAndChoices() {
    _questions.shuffle();
    for (final _TramQuestion q in _questions) {
      q.options.shuffle();
    }
  }

  Future<void> _preflightAssets() async {
    final List<String> missing = <String>[];
    for (final String path in _imageAssets) {
      try {
        await rootBundle.load(path);
      } catch (_) {
        missing.add(path);
      }
    }
    try {
      await rootBundle.load(_hornAsset);
    } catch (_) {
      missing.add(_hornAsset);
    }

    if (!mounted) return;
    setState(() {
      _missingAssets
        ..clear()
        ..addAll(missing);
      _assetsChecked = true;
    });

    if (missing.isEmpty) {
      _startTimer();
    }
  }

  void _startTimer() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_paused || _overlayActive) return;
      
      setState(() {
        _remaining--;
      });

      if (_remaining <= 0) {
        _onTimeout();
      }
    });
  }

  void _onTimeout() {
    setState(() {
      _isDead = true;
    });
    _ticker?.cancel();
    
    // Son d'alerte
    _player.play(AssetSource('sounds/horn.mp3'));
    
    // Afficher l'overlay de mort
    _showOverlay('assets/images/tram1.jpg', 'Temps écoulé ! Vous avez échoué.');
  }

  void _showOverlay(String imagePath, String message) {
    setState(() {
      _overlayImageUrl = imagePath;
      _overlayOpacity = 0.0;
      _overlayActive = true;
      _currentFeedback = message;
    });

    // Animation d'apparition
    Timer(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _overlayOpacity = 1.0;
        });
      }
    });

    // Disparition après 3 secondes
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _overlayOpacity = 0.0;
        });
        
        Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _overlayActive = false;
              _overlayImageUrl = null;
              _currentFeedback = null;
            });
            
            if (_isDead) {
              _endGameSession();
            }
          }
        });
      }
    });
  }

  void _onAnswerSelected(String answer) {
    if (_overlayActive) return;
    
    final question = _questions[_index];
    final isCorrect = answer == question.correctAnswer;
    
    // Statistiques
    if (answer.contains('Levier')) _countLevier++;
    if (answer.contains('Ne rien faire')) _countInaction++;
    if (answer.contains('Extrême')) _countExtreme++;
    
    setState(() {
      _lastChoiceType = answer;
    });

    if (isCorrect) {
      _currentFeedback = 'Bonne réponse !';
      _showOverlay(_imageAssets[math.Random().nextInt(_imageAssets.length)], _currentFeedback!);
      
      // Passer à la question suivante
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          _nextQuestion();
        }
      });
    } else {
      _currentFeedback = 'Mauvaise réponse !';
      _showOverlay(_imageAssets[math.Random().nextInt(_imageAssets.length)], _currentFeedback!);
      
      // Réduire le temps restant
      setState(() {
        _remaining = math.max(0, _remaining - 3);
      });
    }
  }

  void _nextQuestion() {
    if (_index < questionsCount - 1) {
      setState(() {
        _index++;
        _remaining = secondsPerQuestion;
      });
    } else {
      _endGameSession();
    }
  }

  void _endGameSession() async {
    _ticker?.cancel();
    
    final score = (_index + 1) * 10; // Score basé sur le nombre de questions répondues
    final completionRate = ((_index + 1) / questionsCount) * 100;
    
    await _statsService.endGameSession(
      completed: _index >= questionsCount - 1,
      score: score,
      additionalData: {
        'questionsAnswered': _index + 1,
        'totalQuestions': questionsCount,
        'completionRate': completionRate,
        'leverChoices': _countLevier,
        'inactionChoices': _countInaction,
        'extremeChoices': _countExtreme,
        'timePerQuestion': secondsPerQuestion,
      },
    );
    
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C28),
        title: Text(
          _isDead ? '💀 Échec !' : '🎉 Bravo !',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _isDead 
                  ? 'Vous avez échoué au dilemme du tram'
                  : 'Vous avez terminé le dilemme du tram',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Questions répondues: ${_index + 1}/$questionsCount',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Score: ${(_index + 1) * 10} points',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choix levier: $_countLevier',
              style: const TextStyle(color: Colors.cyan),
            ),
            Text(
              'Choix inaction: $_countInaction',
              style: const TextStyle(color: Colors.orange),
            ),
            Text(
              'Choix extrêmes: $_countExtreme',
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const Page5Notifications()),
              );
            },
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_assetsChecked) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_missingAssets.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Assets manquants:',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 8),
              ..._missingAssets.map((asset) => Text(
                asset,
                style: const TextStyle(color: Colors.red),
              )),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Arrière-plan animé
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _bgController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue[900]!.withOpacity(0.8),
                        Colors.purple[900]!.withOpacity(0.8),
                        Colors.red[900]!.withOpacity(0.8),
                      ],
                      stops: [
                        0.0,
                        0.5 + 0.3 * math.sin(_bgController.value * 2 * math.pi),
                        1.0,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Contenu principal
          SafeArea(
            child: Column(
              children: [
                // En-tête avec chronomètre
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Dilemme du Tram',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Question ${_index + 1}/$questionsCount',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Temps restant: $_remaining secondes',
                              style: TextStyle(
                                color: _remaining <= 5 ? Colors.red : Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const GameTimerWidget(),
                    ],
                  ),
                ),
                
                // Question et options
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Question
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Text(
                            _questions[_index].question,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Options
                        Expanded(
                          child: ListView.builder(
                            itemCount: _questions[_index].options.length,
                            itemBuilder: (context, optionIndex) {
                              final option = _questions[_index].options[optionIndex];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _onAnswerSelected(option),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                                      ),
                                      child: Text(
                                        option,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Overlay de feedback
          if (_overlayActive)
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _overlayOpacity,
                duration: const Duration(milliseconds: 500),
                child: Container(
                  color: Colors.black.withOpacity(0.8),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_overlayImageUrl != null)
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: AssetImage(_overlayImageUrl!),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        const SizedBox(height: 24),
                        if (_currentFeedback != null)
                          Text(
                            _currentFeedback!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<_TramQuestion> _generateQuestions() {
    return [
      _TramQuestion(
        question: 'Un tramway fonce vers 5 personnes. Vous pouvez actionner un levier pour le détourner vers 1 personne. Que faites-vous ?',
        options: ['Actionner le levier', 'Ne rien faire', 'Crier pour alerter'],
        correctAnswer: 'Actionner le levier',
      ),
      _TramQuestion(
        question: 'Le tramway va tuer 5 personnes. Vous pouvez pousser une personne lourde sur les rails pour l\'arrêter. Que faites-vous ?',
        options: ['Pousser la personne', 'Ne rien faire', 'Essayer de courir'],
        correctAnswer: 'Ne rien faire',
      ),
      _TramQuestion(
        question: 'Le tramway va tuer 5 personnes. Vous pouvez actionner un levier pour le détourner vers 1 personne. Que faites-vous ?',
        options: ['Actionner le levier', 'Ne rien faire', 'Appeler les secours'],
        correctAnswer: 'Actionner le levier',
      ),
      _TramQuestion(
        question: 'Le tramway va tuer 5 personnes. Vous pouvez pousser une personne lourde sur les rails pour l\'arrêter. Que faites-vous ?',
        options: ['Pousser la personne', 'Ne rien faire', 'Essayer de courir'],
        correctAnswer: 'Ne rien faire',
      ),
      _TramQuestion(
        question: 'Le tramway va tuer 5 personnes. Vous pouvez actionner un levier pour le détourner vers 1 personne. Que faites-vous ?',
        options: ['Actionner le levier', 'Ne rien faire', 'Crier pour alerter'],
        correctAnswer: 'Actionner le levier',
      ),
      _TramQuestion(
        question: 'Le tramway va tuer 5 personnes. Vous pouvez pousser une personne lourde sur les rails pour l\'arrêter. Que faites-vous ?',
        options: ['Pousser la personne', 'Ne rien faire', 'Essayer de courir'],
        correctAnswer: 'Ne rien faire',
      ),
      _TramQuestion(
        question: 'Le tramway va tuer 5 personnes. Vous pouvez actionner un levier pour le détourner vers 1 personne. Que faites-vous ?',
        options: ['Actionner le levier', 'Ne rien faire', 'Appeler les secours'],
        correctAnswer: 'Actionner le levier',
      ),
      _TramQuestion(
        question: 'Le tramway va tuer 5 personnes. Vous pouvez pousser une personne lourde sur les rails pour l\'arrêter. Que faites-vous ?',
        options: ['Pousser la personne', 'Ne rien faire', 'Essayer de courir'],
        correctAnswer: 'Ne rien faire',
      ),
      _TramQuestion(
        question: 'Le tramway va tuer 5 personnes. Vous pouvez actionner un levier pour le détourner vers 1 personne. Que faites-vous ?',
        options: ['Actionner le levier', 'Ne rien faire', 'Crier pour alerter'],
        correctAnswer: 'Actionner le levier',
      ),
      _TramQuestion(
        question: 'Le tramway va tuer 5 personnes. Vous pouvez pousser une personne lourde sur les rails pour l\'arrêter. Que faites-vous ?',
        options: ['Pousser la personne', 'Ne rien faire', 'Essayer de courir'],
        correctAnswer: 'Ne rien faire',
      ),
      _TramQuestion(
        question: 'Le tramway va tuer 5 personnes. Vous pouvez actionner un levier pour le détourner vers 1 personne. Que faites-vous ?',
        options: ['Actionner le levier', 'Ne rien faire', 'Appeler les secours'],
        correctAnswer: 'Actionner le levier',
      ),
      _TramQuestion(
        question: 'Le tramway va tuer 5 personnes. Vous pouvez pousser une personne lourde sur les rails pour l\'arrêter. Que faites-vous ?',
        options: ['Pousser la personne', 'Ne rien faire', 'Essayer de courir'],
        correctAnswer: 'Ne rien faire',
      ),
      _TramQuestion(
        question: 'Le tramway va tuer 5 personnes. Vous pouvez actionner un levier pour le détourner vers 1 personne. Que faites-vous ?',
        options: ['Actionner le levier', 'Ne rien faire', 'Crier pour alerter'],
        correctAnswer: 'Actionner le levier',
      ),
      _TramQuestion(
        question: 'Le tramway va tuer 5 personnes. Vous pouvez pousser une personne lourde sur les rails pour l\'arrêter. Que faites-vous ?',
        options: ['Pousser la personne', 'Ne rien faire', 'Essayer de courir'],
        correctAnswer: 'Ne rien faire',
      ),
      _TramQuestion(
        question: 'Le tramway va tuer 5 personnes. Vous pouvez actionner un levier pour le détourner vers 1 personne. Que faites-vous ?',
        options: ['Actionner le levier', 'Ne rien faire', 'Appeler les secours'],
        correctAnswer: 'Actionner le levier',
      ),
      _TramQuestion(
        question: 'Le tramway va tuer 5 personnes. Vous pouvez pousser une personne lourde sur les rails pour l\'arrêter. Que faites-vous ?',
        options: ['Pousser la personne', 'Ne rien faire', 'Essayer de courir'],
        correctAnswer: 'Ne rien faire',
      ),
      _TramQuestion(
        question: 'Le tramway va tuer 5 personnes. Vous pouvez actionner un levier pour le détourner vers 1 personne. Que faites-vous ?',
        options: ['Actionner le levier', 'Ne rien faire', 'Crier pour alerter'],
        correctAnswer: 'Actionner le levier',
      ),
      _TramQuestion(
        question: 'Le tramway va tuer 5 personnes. Vous pouvez pousser une personne lourde sur les rails pour l\'arrêter. Que faites-vous ?',
        options: ['Pousser la personne', 'Ne rien faire', 'Essayer de courir'],
        correctAnswer: 'Ne rien faire',
      ),
      _TramQuestion(
        question: 'Le tramway va tuer 5 personnes. Vous pouvez actionner un levier pour le détourner vers 1 personne. Que faites-vous ?',
        options: ['Actionner le levier', 'Ne rien faire', 'Appeler les secours'],
        correctAnswer: 'Actionner le levier',
      ),
      _TramQuestion(
        question: 'Le tramway va tuer 5 personnes. Vous pouvez pousser une personne lourde sur les rails pour l\'arrêter. Que faites-vous ?',
        options: ['Pousser la personne', 'Ne rien faire', 'Essayer de courir'],
        correctAnswer: 'Ne rien faire',
      ),
    ];
  }
}

class _TramQuestion {
  final String question;
  final List<String> options;
  final String correctAnswer;

  _TramQuestion({
    required this.question,
    required this.options,
    required this.correctAnswer,
  });
}