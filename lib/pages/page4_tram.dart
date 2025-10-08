import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'page5.dart';

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
  String? _lastFeedback; // micro feedback post-choix
  bool _isDead = false; // écran de mort si timer dépassé

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
        _lastFeedback = null;
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
      _lastFeedback = 'Vous avez dévié: 1 écrasé, 5 sauvés';
    } else if (label.toLowerCase().contains('ne rien faire') || label.toLowerCase().contains('continue')) {
      _countInaction++;
      _lastFeedback = 'Inaction: 5 écrasés';
    } else {
      _countExtreme++;
      _lastFeedback = 'Intervention extrême: issue incertaine';
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
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: const Text('Résumé de vos décisions', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Aiguillage (dévier): $_countLevier', style: const TextStyle(color: Colors.white70)),
              Text('Inaction: $_countInaction', style: const TextStyle(color: Colors.white70)),
              Text('Intervention extrême: $_countExtreme', style: const TextStyle(color: Colors.white70)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w800)),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const Page5()),
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
                    // Barre supérieur: progression + anneau timer + pause/passer dans AppBar
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Question ${_index + 1}/$questionsCount', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: Colors.white10,
                                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
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

                    if (_lastFeedback != null) ...[
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          _lastFeedback!,
                          style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],

                    const Spacer(),

                    // BoutonFinal4 quand fini (ne s'affiche plus; résumé avant navigation)
                  ],
                ),
              ),

            // Overlay d'image impact visuel
            if (_overlayImageUrl != null)
              IgnorePointer(
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 140),
                  opacity: _overlayOpacity,
                  child: Container(
                    color: Colors.black.withOpacity(0.9),
                    child: Center(
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
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<_TramQuestion> _generateQuestions() {
    final List<String> base = [
      "Le tram fonce sur 5 personnes. Actionner un levier le dévie vers 1 personne.",
      "Tu peux pousser une personne très corpulente pour stopper le tram et sauver 5 autres.",
      "Le tram sauvera 5 médecins si tu sacrifies 1 enfant en changeant d’aiguillage.",
      "Sauver 3 proches ou 5 inconnus en actionnant un bouton.",
      "1 personne âgée vs 4 jeunes adultes: changer la trajectoire?",
      "Levier: sauver 5 prisonniers ou 2 sauveteurs?",
      "Dévier le tram vers un robot autonome ou percuter 3 humains?",
      "Sacrifier ton animal de compagnie ou 3 inconnus?",
      "Sacrifier un politicien influent pour sauver 5 citoyens ordinaires?",
      "Sauver 1 scientifique clé ou 4 artistes?",
      "Le tram détruit un pont si tu ne le dévies pas: 2 ouvriers sur la voie alternative.",
      "Dévier vers 1 conducteur dans sa voiture arrêtée ou laisser 3 piétons?",
      "Levier bloqué: pousser une personne à la main pour le débloquer et sauver 5.",
      "Dévier vers 1 personne qui t’a sauvé la vie autrefois ou laisser 4 inconnus?",
      "Sauver 5 aujourd’hui ou laisser 1 blessé grave mourir pour sauver potentiellement 10 demain.",
      "Le tram menace un hôpital. Dévier vers 2 travailleurs d’entretien?",
      "Sacrifier un criminel recherché pour en sauver 4 innocents?",
      "Dévier vers un véhicule autonome (sans passagers) mais risquer une explosion, ou 2 piétons?",
      "Sauver 5 enfants ou 3 chercheurs d’un vaccin?",
      "Dévier vers 1 personne inconsciente attachée à la voie ou laisser 4 personnes conscientes?",
    ];
    return List<_TramQuestion>.generate(questionsCount, (i) {
      final String p = base[i % base.length];
      final List<String> opts = [
        'Actionner l’aiguillage: le train écrase 1 pour en épargner 5',
        'Ne rien faire: le train continue et écrase 5 personnes',
        'Option extrême: intervention directe, risque d’écraser 1 ou plus',
      ];
      return _TramQuestion(prompt: p, options: opts);
    });
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
  _TramQuestion({required this.prompt, required this.options});
}

class _HudChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _HudChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
        ],
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


