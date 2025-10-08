import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'page5.dart';

class Page4Tram extends StatefulWidget {
  const Page4Tram({super.key});

  @override
  State<Page4Tram> createState() => _Page4TramState();
}

class _Page4TramState extends State<Page4Tram> with SingleTickerProviderStateMixin {
  static const int questionsCount = 20;
  static const int secondsPerQuestion = 12; // timer par question

  late final AnimationController _bgController;
  late List<_TramQuestion> _questions;
  int _index = 0;
  int _remaining = secondsPerQuestion;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _questions = _generateQuestions();
    _bgController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _startTimer();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _bgController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _ticker?.cancel();
    _remaining = secondsPerQuestion;
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        _remaining--;
        if (_remaining <= 0) {
          _advance();
        }
      });
    });
  }

  void _advance() {
    _ticker?.cancel();
    if (_index < questionsCount - 1) {
      setState(() {
        _index++;
      });
      _startTimer();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const Page5()),
      );
    }
  }

  void _onChoiceTap() {
    _advance();
  }

  @override
  Widget build(BuildContext context) {
    final _TramQuestion q = _questions[_index];
    final double t = _bgController.value;
    final Color accent = _colorForIndex(_index);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Salle 4 — Dilemme du tramway'),
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

            // Contenu principal
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Barre supérieur: question x/20 + timer
                  Row(
                    children: [
                      _HudChip(icon: Icons.directions_railway, label: 'Q ${_index + 1}/$questionsCount'),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _TimerBar(
                          remainingSeconds: _remaining,
                          totalSeconds: secondsPerQuestion,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Enoncé
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      q.prompt,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Choix (les réponses n'ont pas d'importance)
                  _ChoiceButton(label: q.options[0], color: accent, onTap: _onChoiceTap),
                  const SizedBox(height: 10),
                  _ChoiceButton(label: q.options[1], color: accent, onTap: _onChoiceTap),
                  if (q.options.length > 2) ...[
                    const SizedBox(height: 10),
                    _ChoiceButton(label: q.options[2], color: accent, onTap: _onChoiceTap),
                  ],

                  const Spacer(),

                  // BoutonFinal4 quand fini
                  if (_index == questionsCount - 1 && _remaining <= 0)
                    Center(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const Page5()),
                          );
                        },
                        child: const Text('BoutonFinal4 — Continuer (Page 5)'),
                      ),
                    ),
                ],
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
        'Actionner le levier',
        'Ne rien faire',
        'Alternative risquée',
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

class _TimerBar extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final Color color;
  const _TimerBar({required this.remainingSeconds, required this.totalSeconds, required this.color});

  @override
  Widget build(BuildContext context) {
    final double p = (remainingSeconds / totalSeconds).clamp(0, 1).toDouble();
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          Container(height: 16, color: Colors.white10),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: MediaQuery.of(context).size.width * p,
            height: 16,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.9), color.withOpacity(0.5)]),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Text(
                '${remainingSeconds}s',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
          ),
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


