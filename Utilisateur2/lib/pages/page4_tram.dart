import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../services/game_stats_service.dart';
import '../services/solo_player_service.dart';
import '../widgets/game_timer_widget.dart';
import 'page5_notifications.dart';

class Page4Tram extends StatefulWidget {
  const Page4Tram({super.key});

  @override
  State<Page4Tram> createState() => _Page4TramState();
}

class _Page4TramState extends State<Page4Tram> with SingleTickerProviderStateMixin {
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

  final GameStatsService _statsService = GameStatsService();
  final SoloPlayerService _soloPlayerService = SoloPlayerService();

  @override
  void initState() {
    super.initState();
    _startGameSession();
    _questions = _generateQuestions();
    _shuffleQuestionsAndChoices();
    _bgController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _preflightAssets();
  }

  void _startGameSession() async {
    if (!_statsService.isSessionActive) {
      final playerName = await _soloPlayerService.getUniquePlayerName();
      _statsService.startGameSession(
        playerName: playerName,
        gameRoom: 'Dilemme du Tramway',
        gameMode: 'solo',
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

  @override
  void dispose() {
    _ticker?.cancel();
    _overlayTimer?.cancel();
    _bgController.dispose();
    _player.dispose();
    super.dispose();
  }

  void _startTimer() {
    _ticker?.cancel();
    _remaining = secondsPerQuestion;
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _paused) return;
      setState(() {
        _remaining--;
        if (_remaining <= 0) {
          _showDeathScreen();
        }
      });
    });
  }

  void _showDeathScreen() {
    _ticker?.cancel();
    _playHorn();
    setState(() {
      _isDead = true;
    });
    
    // Auto-retour après 3 secondes
    Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _isDead = false;
        _remaining = secondsPerQuestion;
      });
      _startTimer();
    });
  }

  void _advance() {
    _ticker?.cancel();
    if (_index < questionsCount - 1) {
      setState(() {
        _index++;
        _currentFeedback = null;
        _lastChoiceType = null;
      });
      _startTimer();
    } else {
      _showSummaryThenGoNext();
    }
  }

  void _onChoiceTap(String label) {
    if (_overlayActive || !_assetsChecked || _missingAssets.isNotEmpty) return; // pas prêt

    // Comptage selon libellé
    if (label.toLowerCase().contains('aiguillage') || label.toLowerCase().contains('dévier')) {
      _countLevier++;
      _lastChoiceType = 'levier';
      _currentFeedback = 'Vous avez dévié: 1 écrasé, 5 sauvés';
    } else if (label.toLowerCase().contains('ne rien faire') || label.toLowerCase().contains('continue')) {
      _countInaction++;
      _lastChoiceType = 'inaction';
      _currentFeedback = 'Inaction: 5 écrasés';
    } else {
      _countExtreme++;
      _lastChoiceType = 'extreme';
      _currentFeedback = 'Intervention extrême: issue incertaine';
    }

    _playHorn();
    _showImpactImageFor(_index);

    // Affiche 2s en plein écran, puis avance
    _ticker?.cancel();
    _overlayActive = true;
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() {
        _overlayOpacity = 0.0;
        _overlayActive = false;
      });
      _advance();
    });
    setState(() {});
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
    });
  }

  void _skipQuestion() {
    if (!_assetsChecked || _missingAssets.isNotEmpty) return;
    _advance();
  }

  Future<void> _showSummaryThenGoNext() async {
    // Terminer la session de jeu
    await _statsService.endGameSession(
      completed: true,
      score: (_countLevier * 10) + (_countInaction * 5) + (_countExtreme * 20),
      additionalData: {
        'totalQuestions': questionsCount,
        'decisionsLevier': _countLevier,
        'decisionsInaction': _countInaction,
        'decisionsExtreme': _countExtreme,
        'completionRate': 100.0,
      },
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text('Résumé de vos décisions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Aiguillage (dévier): $_countLevier', style: const TextStyle(color: Colors.white70)),
                Text('Inaction: $_countInaction', style: const TextStyle(color: Colors.white70)),
                Text('Intervention extrême: $_countExtreme', style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                const Divider(color: Colors.white24),
                const SizedBox(height: 16),
                const Text(
                  'Le Dilemme du Tramway',
                  style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ce test explore vos intuitions morales face à des choix impossibles. Il révèle comment nous pesons les vies humaines et les conséquences de nos actions.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Dévier = Agir activement pour sauver plus de vies\n• Ne rien faire = Laisser le destin suivre son cours\n• Intervention extrême = Prendre des risques supplémentaires',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Il n\'y a pas de "bonne" réponse - seulement votre façon personnelle de naviguer l\'éthique.',
                  style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Continuer', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    
    // Appeler le callback si fourni
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const Page5Notifications()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final _TramQuestion q = _questions[_index];
    final double t = _bgController.value;
    final Color accent = _colorForIndex(_index);
    final double progress = (_index + 1) / questionsCount;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Salle 4 — Dilemme du tramway'),
        actions: [
          const GameTimerWidget(),
          const SizedBox(width: 8),
          IconButton(
            tooltip: _paused ? 'Reprendre' : 'Pause',
            icon: Icon(_paused ? Icons.play_arrow : Icons.pause),
            onPressed: _togglePause,
          ),
          IconButton(
            tooltip: 'Passer',
            icon: const Icon(Icons.skip_next),
            onPressed: _skipQuestion,
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Fond animé stressant
            AnimatedBuilder(
              animation: _bgController,
              builder: (context, _) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(
                        math.sin(t * math.pi * 2) * 0.5,
                        math.cos(t * math.pi * 2) * 0.5,
                      ),
                      radius: 1.1,
                      colors: [
                        Colors.black,
                        Color.lerp(Colors.deepPurple.shade900, Colors.red.shade900, (0.5 + 0.5 * math.sin(t * 8)).clamp(0.0, 1.0))!,
                        Color.lerp(Colors.indigo, Colors.redAccent, (0.5 + 0.5 * math.cos(t * 7)).clamp(0.0, 1.0))!,
                      ],
                      stops: const [0.2, 0.65, 1.0],
                    ),
                  ),
                );
              },
            ),

            if (!_assetsChecked)
              const Center(
                child: CircularProgressIndicator(),
              )
            else if (_missingAssets.isNotEmpty)
              _MissingAssetsScreen(missing: _missingAssets)
            else if (_isDead)
              _DeathScreen()
            else
              // Contenu principal
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Barre supérieur: progression circulaire + anneau timer
                    Row(
                      children: [
                        Expanded(
                          child: _QuestionProgressCircles(
                            currentIndex: _index,
                            totalQuestions: questionsCount,
                            accentColor: accent,
                          ),
                        ),
                        const SizedBox(width: 16),
                        _TimerRing(secondsRemaining: _remaining, totalSeconds: secondsPerQuestion),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Enoncé
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 18, spreadRadius: 2)],
                      ),
                      child: Text(
                        q.prompt,
                        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.35),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Choix (les réponses n'ont pas d'importance)
                    _ChoiceButton(label: q.options[0], color: accent, onTap: () => _onChoiceTap(q.options[0])),
                    const SizedBox(height: 12),
                    _ChoiceButton(label: q.options[1], color: accent, onTap: () => _onChoiceTap(q.options[1])),
                    if (q.options.length > 2) ...[
                      const SizedBox(height: 12),
                      _ChoiceButton(label: q.options[2], color: accent, onTap: () => _onChoiceTap(q.options[2])),
                    ],


                    const Spacer(),

                    // BoutonFinal4 quand fini (ne s'affiche plus; résumé avant navigation)
                  ],
                ),
              ),

            // Overlay d'image impact visuel avec feedback
            if (_overlayImageUrl != null)
              IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 140),
                  opacity: _overlayOpacity,
                  child: Container(
                    color: Colors.black.withOpacity(0.9),
                    child: Stack(
                      children: [
                        // Image de fond
                        Center(
                          child: Transform.rotate(
                            angle: (math.sin(_bgController.value * math.pi * 2) * 0.02),
                            child: Image.asset(
                              _overlayImageUrl!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) {
                                return Icon(Icons.warning_amber_rounded, size: 160, color: Colors.redAccent.withOpacity(0.9));
                              },
                            ),
                          ),
                        ),
                        // Feedback sur l'image
                        if (_currentFeedback != null)
                          Positioned(
                            bottom: 100,
                            left: 20,
                            right: 20,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                              ),
                              child: Text(
                                _currentFeedback!,
                                style: const TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<_TramQuestion> _generateQuestions() {
    final dilemmas = [
      // Questions faciles (1-5) - Dilemmes basiques
      _TramQuestion(
        prompt: 'Un tramway hors contrôle fonce vers 5 personnes. Vous pouvez actionner un aiguillage pour le dévier vers 1 personne. Que faites-vous ?',
        options: ['Actionner l\'aiguillage', 'Ne rien faire'],
        difficulty: 1,
      ),
      _TramQuestion(
        prompt: 'Un tramway fonce vers 5 personnes anonymes. Vous pouvez le dévier vers 1 personne anonyme. Que faites-vous ?',
        options: ['Dévier vers 1 personne', 'Laisser faire'],
        difficulty: 1,
      ),
      _TramQuestion(
        prompt: 'Un tramway fonce vers 5 personnes. Vous pouvez le dévier vers 1 personne. Que faites-vous ?',
        options: ['Actionner l\'aiguillage', 'Ne pas intervenir'],
        difficulty: 1,
      ),
      _TramQuestion(
        prompt: 'Un tramway fonce vers 5 personnes. Vous pouvez le dévier vers 1 personne. Que faites-vous ?',
        options: ['Dévier vers 1 personne', 'Laisser le destin agir'],
        difficulty: 1,
      ),
      _TramQuestion(
        prompt: 'Un tramway fonce vers 5 personnes. Vous pouvez le dévier vers 1 personne. Que faites-vous ?',
        options: ['Actionner l\'aiguillage', 'Ne rien faire'],
        difficulty: 1,
      ),

      // Questions moyennes (6-10) - Dilemmes avec caractéristiques
      _TramQuestion(
        prompt: 'Un tramway fonce vers 5 enfants. Vous pouvez le dévier vers 1 adulte. Que faites-vous ?',
        options: ['Sauver les enfants', 'Ne pas intervenir'],
        difficulty: 2,
      ),
      _TramQuestion(
        prompt: 'Un tramway fonce vers 5 personnes âgées. Vous pouvez le dévier vers 1 jeune. Que faites-vous ?',
        options: ['Dévier vers le jeune', 'Laisser le destin agir'],
        difficulty: 2,
      ),
      _TramQuestion(
        prompt: 'Un tramway fonce vers 5 personnes handicapées. Vous pouvez le dévier vers 1 personne valide. Que faites-vous ?',
        options: ['Dévier vers la personne valide', 'Laisser faire'],
        difficulty: 2,
      ),
      _TramQuestion(
        prompt: 'Un tramway fonce vers 5 personnes. Vous pouvez le dévier vers 1 personne qui porte un bébé. Que faites-vous ?',
        options: ['Dévier vers la personne avec bébé', 'Ne rien faire'],
        difficulty: 2,
      ),
      _TramQuestion(
        prompt: 'Un tramway fonce vers 5 personnes. Vous pouvez le dévier vers 1 personne qui semble malade. Que faites-vous ?',
        options: ['Dévier vers la personne malade', 'Laisser faire'],
        difficulty: 2,
      ),

      // Questions difficiles (11-15) - Dilemmes personnels
      _TramQuestion(
        prompt: 'Un tramway fonce vers votre famille (3 personnes). Vous pouvez le dévier vers des inconnus (2 personnes). Que faites-vous ?',
        options: ['Dévier vers les inconnus', 'Laisser faire'],
        difficulty: 3,
      ),
      _TramQuestion(
        prompt: 'Un tramway fonce vers 5 personnes. Vous pouvez le dévier vers votre meilleur ami. Que faites-vous ?',
        options: ['Dévier vers votre ami', 'Ne rien faire'],
        difficulty: 3,
      ),
      _TramQuestion(
        prompt: 'Un tramway fonce vers 5 personnes. Vous pouvez le dévier vers 1 personne qui vous a sauvé la vie. Que faites-vous ?',
        options: ['Dévier vers votre sauveur', 'Ne pas intervenir'],
        difficulty: 3,
      ),
      _TramQuestion(
        prompt: 'Un tramway fonce vers 5 personnes. Vous pouvez le dévier vers 1 personne qui vous a fait du mal. Que faites-vous ?',
        options: ['Dévier vers cette personne', 'Laisser le destin agir'],
        difficulty: 3,
      ),
      _TramQuestion(
        prompt: 'Un tramway fonce vers 5 personnes. Vous pouvez le dévier vers 1 personne qui semble riche. Que faites-vous ?',
        options: ['Dévier vers la personne riche', 'Ne pas intervenir'],
        difficulty: 3,
      ),

      // Questions très difficiles (16-20) - Dilemmes moraux complexes
      _TramQuestion(
        prompt: 'Un tramway fonce vers 5 personnes. Vous pouvez le dévier vers 1 personne qui semble méchante. Que faites-vous ?',
        options: ['Dévier vers la personne méchante', 'Ne rien faire'],
        difficulty: 4,
      ),
      _TramQuestion(
        prompt: 'Un tramway fonce vers 5 personnes. Vous pouvez le dévier vers 1 personne qui semble intelligente. Que faites-vous ?',
        options: ['Dévier vers la personne intelligente', 'Ne pas intervenir'],
        difficulty: 4,
      ),
      _TramQuestion(
        prompt: 'Un tramway fonce vers 5 personnes. Vous pouvez le dévier vers 1 personne qui semble belle. Que faites-vous ?',
        options: ['Dévier vers la personne belle', 'Ne rien faire'],
        difficulty: 4,
      ),
      _TramQuestion(
        prompt: 'Un tramway fonce vers 5 personnes. Vous pouvez le dévier vers 1 personne qui semble forte. Que faites-vous ?',
        options: ['Dévier vers la personne forte', 'Ne pas intervenir'],
        difficulty: 4,
      ),
      _TramQuestion(
        prompt: 'Un tramway fonce vers 5 personnes. Vous pouvez le dévier vers 1 personne qui semble faible. Que faites-vous ?',
        options: ['Dévier vers la personne faible', 'Laisser le destin agir'],
        difficulty: 4,
      ),
    ];

    // Mélange les dilemmes pour éviter la répétition
    dilemmas.shuffle();
    return dilemmas.take(questionsCount).toList();
  }

  Color _colorForIndex(int i) {
    final List<Color> palette = [
      Colors.redAccent,
      Colors.deepOrangeAccent,
      Colors.amberAccent,
      Colors.limeAccent,
      Colors.lightGreenAccent,
      Colors.cyanAccent,
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.pinkAccent,
    ];
    return palette[i % palette.length];
  }

  Future<void> _playHorn() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/horn.mp3'));
    } catch (_) {}
  }

  void _showImpactImageFor(int questionIndex) {
    _overlayTimer?.cancel();
    setState(() {
      _overlayImageUrl = _imageAssets[questionIndex % _imageAssets.length];
      _overlayOpacity = 1.0;
    });
  }

  Color _getContextualColor() {
    switch (_lastChoiceType) {
      case 'levier':
        return Colors.greenAccent;
      case 'inaction':
        return Colors.orangeAccent;
      case 'extreme':
        return Colors.purpleAccent;
      default:
        return Colors.grey;
    }
  }

  String _getContextualMessage() {
    switch (_lastChoiceType) {
      case 'levier':
        return 'Vous avez choisi l\'action directe précédemment';
      case 'inaction':
        return 'Vous avez choisi la passivité précédemment';
      case 'extreme':
        return 'Vous avez choisi l\'intervention extrême précédemment';
      default:
        return '';
    }
  }
}

class _TimerRing extends StatelessWidget {
  final int secondsRemaining;
  final int totalSeconds;
  const _TimerRing({required this.secondsRemaining, required this.totalSeconds});

  @override
  Widget build(BuildContext context) {
    final int sr = secondsRemaining.clamp(0, totalSeconds);
    final double p = (sr / totalSeconds).clamp(0.0, 1.0);
    final bool warn = sr <= 3;
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: p,
            strokeWidth: 6,
            backgroundColor: Colors.white12,
            valueColor: AlwaysStoppedAnimation<Color>(warn ? Colors.redAccent : Colors.cyanAccent),
          ),
          Text(
            '$sr',
            style: TextStyle(color: warn ? Colors.redAccent : Colors.white, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _DeathScreen extends StatelessWidget {
  const _DeathScreen();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'TU ES MORT',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                shadows: [
                  Shadow(
                    color: Colors.redAccent.withOpacity(0.8),
                    blurRadius: 20,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'ÉCRASÉ',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                letterSpacing: 6,
                shadows: [
                  Shadow(
                    color: Colors.redAccent.withOpacity(0.8),
                    blurRadius: 15,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Le train t\'a écrasé par manque de décision',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingAssetsScreen extends StatelessWidget {
  final List<String> missing;
  const _MissingAssetsScreen({required this.missing});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Assets manquants',
                style: TextStyle(color: Colors.redAccent, fontSize: 22, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 12),
              const Text(
                'Veuillez ajouter les fichiers suivants au projet puis relancer:',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              ...missing.map((m) => Text('- $m', style: const TextStyle(color: Colors.white))),
            ],
          ),
        ),
      ),
    );
  }
}

class _TramQuestion {
  final String prompt;
  final List<String> options;
  final int difficulty;
  _TramQuestion({required this.prompt, required this.options, required this.difficulty});
}

class _QuestionProgressCircles extends StatelessWidget {
  final int currentIndex;
  final int totalQuestions;
  final Color accentColor;
  
  const _QuestionProgressCircles({
    required this.currentIndex,
    required this.totalQuestions,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre avec numéro actuel
        Row(
          children: [
            Text(
              'Question ',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${currentIndex + 1}',
              style: TextStyle(
                color: accentColor,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              ' / $totalQuestions',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        // Cercles de progression
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: totalQuestions,
            itemBuilder: (context, index) {
              final bool isCompleted = index < currentIndex;
              final bool isCurrent = index == currentIndex;
              final bool isPending = index > currentIndex;
              
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: _ProgressCircle(
                  questionNumber: index + 1,
                  isCompleted: isCompleted,
                  isCurrent: isCurrent,
                  isPending: isPending,
                  accentColor: accentColor,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProgressCircle extends StatelessWidget {
  final int questionNumber;
  final bool isCompleted;
  final bool isCurrent;
  final bool isPending;
  final Color accentColor;
  
  const _ProgressCircle({
    required this.questionNumber,
    required this.isCompleted,
    required this.isCurrent,
    required this.isPending,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    Color circleColor;
    Color textColor;
    double circleSize = 36;
    
    if (isCompleted) {
      circleColor = accentColor;
      textColor = Colors.white;
    } else if (isCurrent) {
      circleColor = accentColor.withOpacity(0.3);
      textColor = accentColor;
      circleSize = 40; // Légèrement plus grand pour la question actuelle
    } else {
      circleColor = Colors.white.withOpacity(0.1);
      textColor = Colors.white.withOpacity(0.4);
    }
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: circleSize,
      height: circleSize,
      decoration: BoxDecoration(
        color: circleColor,
        shape: BoxShape.circle,
        border: isCurrent ? Border.all(color: accentColor, width: 2) : null,
        boxShadow: isCurrent ? [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ] : null,
      ),
      child: Center(
        child: Text(
          '$questionNumber',
          style: TextStyle(
            color: textColor,
            fontSize: isCurrent ? 16 : 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ChoiceButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.8), width: 1.4),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.25), blurRadius: 16, spreadRadius: 1),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.bolt, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            Icon(Icons.chevron_right, color: color),
          ],
        ),
      ),
    );
  }
}