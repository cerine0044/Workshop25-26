import 'dart:async';
import 'dart:math' as math;
import 'dart:collection';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/game_stats_service.dart';
import '../widgets/game_timer_widget.dart';
import 'page4_tram.dart';

/// Salle 3 — Liste des mots (Word Bank)
/// Un seul fichier, sans dépendances externes.
/// - Chrono et jauge de stress (0–100)
/// - Recherche/filtre/mélange
/// - Animations légères (opacity/size/container/switcher)
/// - Responsive: ListView (mobile) / GridView (large)

class WordItem {
  final String word;
  final String definition;
  bool used;

  WordItem({required this.word, required this.definition, this.used = false});
}

class Page3Words extends StatefulWidget {
  const Page3Words({super.key});

  static const String route = '/page3_words';

  @override
  State<Page3Words> createState() => _Page3WordsState();
}

class _Page3WordsState extends State<Page3Words> {
  final GameStatsService _statsService = GameStatsService();
  
  // Palette
  // Pandora-like deep purple/blue gradient
  static const Color colorBg1 = Color(0xFF15162B); // deep indigo
  static const Color colorBg2 = Color(0xFF1D2453); // midnight purple
  static const Color colorBg3 = Color(0xFF0F1E3A); // deep navy
  static const Color colorText = Color(0xFFECF0F1);
  static const Color colorAccent = Color(0xFF66FCF1);

  // Stress levels colors
  static const Color colorStressLow = Color(0xFF66FCF1); // 0–39
  static const Color colorStressMid = Color(0xFFF1C40F); // 40–69
  static const Color colorStressHigh = Color(0xFFE74C3C); // 70–100

  // Timers/state
  Timer? _ticker;
  int _elapsedSeconds = 0;
  int _stress = 0; // 0–100

  // Data/state
  final List<WordItem> _allItems = [];
  String _query = '';
  bool _hideUsed = false;
  bool _showAllDefinitions = false;

  // Association (drag-and-drop) mode
  bool _associationMode = true;
  final Set<int> _wrongFlashTargets = <int>{}; // target absolute indexes with wrong drop flash
  // Shuffled pool order for left words list
  List<int> _poolOrder = <int>[];

  // Definition visibility and first-time tracking
  final Set<int> _shownDefinitionIndexes = <int>{};
  final Set<int> _seenDefinitionIndexes = <int>{};

  // Pulse animation when marking used
  final Set<int> _pulseIndexes = <int>{};
  // Cyan halo/glow highlight when correct
  final Set<int> _haloIndexes = <int>{};
  // Hover states for subtle scale/glow
  final Set<int> _hoverChipIndexes = <int>{};
  final Set<int> _hoverTargetIndexes = <int>{};
  // Bounce indices on wrong drop
  final Set<int> _bounceTargets = <int>{};

  // Shuffle penalty control (second+ shuffle within 10s)
  DateTime? _lastShuffleTime;

  // Shake when stress >= 90
  bool _shake = false;

  // Conseils personnalisés par mot (affichés quand trouvé)
  late final Map<String, String> _adviceByWord = <String, String>{
    'STRESS': 'Conseil: fais une pause de 2 minutes et respire profondément.',
    'SOMMEIL': 'Conseil: essaie de garder des heures de coucher régulières.',
    'ECRAN': 'Conseil: fais des pauses 20-20-20 pour reposer tes yeux.',
    'AMIS': 'Conseil: parle à un ami de confiance quand ça ne va pas.',
    'RGPD': 'Conseil: vérifie les autorisations des applis avant d\'accepter.',
    'DONNEES': 'Conseil: partage le minimum nécessaire en ligne.',
    'PRIVEE': 'Conseil: rends tes profils privés si possible.',
    'HARCELER': 'Conseil: signale et bloque, ne reste pas seul face au harcèlement.',
    'CONFIANCE': 'Conseil: note 3 qualités de toi pour la renforcer.',
    'SECURITE': 'Conseil: active la double authentification.',
    'PAUSE': 'Conseil: étire-toi et hydrate-toi régulièrement.',
    'FOCUS': 'Conseil: coupe les notifications 25 minutes pour te concentrer.',
    'RESPIRE': 'Conseil: inspire 4s, retiens 4s, expire 6s (x5).',
    'RESEAU': 'Conseil: choisis des communautés positives.',
    'DIGITAL': 'Conseil: limite ton temps d\'écran à 2h par jour.',
    'BIENVEILLANCE': 'Conseil: sois bienveillant envers toi-même d\'abord.',
    'EQUILIBRE': 'Conseil: trouve un équilibre entre travail et repos.',
    'MINDFULNESS': 'Conseil: pratique la méditation 10 minutes par jour.',
    'CYBERBULLYING': 'Conseil: ne participe jamais au harcèlement en ligne.',
    'PRIVACY': 'Conseil: protège ta vie privée comme un trésor.',
  };

  @override
  void initState() {
    super.initState();
    _initializeData();
    _startGameSession();
    _startTimer();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startGameSession() {
    if (!_statsService.isSessionActive) {
      _statsService.startGameSession(
        playerName: 'Joueur Solo',
        gameRoom: 'Mots Croisés',
      );
    }
  }

  void _initializeData() {
    _allItems.clear();
    _allItems.addAll([
      WordItem(word: 'STRESS', definition: 'État de tension psychologique'),
      WordItem(word: 'SOMMEIL', definition: 'État de repos naturel'),
      WordItem(word: 'ECRAN', definition: 'Surface d\'affichage numérique'),
      WordItem(word: 'AMIS', definition: 'Personnes proches et bienveillantes'),
      WordItem(word: 'RGPD', definition: 'Règlement général sur la protection des données'),
      WordItem(word: 'DONNEES', definition: 'Informations numériques personnelles'),
      WordItem(word: 'PRIVEE', definition: 'Qui appartient à la vie intime'),
      WordItem(word: 'HARCELER', definition: 'Soumettre à des pressions répétées'),
      WordItem(word: 'CONFIANCE', definition: 'Sentiment de sécurité envers quelqu\'un'),
      WordItem(word: 'SECURITE', definition: 'Protection contre les dangers'),
      WordItem(word: 'PAUSE', definition: 'Arrêt temporaire d\'une activité'),
      WordItem(word: 'FOCUS', definition: 'Concentration sur un objectif'),
      WordItem(word: 'RESPIRE', definition: 'Inspirer et expirer de l\'air'),
      WordItem(word: 'RESEAU', definition: 'Ensemble de connexions'),
      WordItem(word: 'DIGITAL', definition: 'Relatif aux technologies numériques'),
      WordItem(word: 'BIENVEILLANCE', definition: 'Disposition à vouloir le bien'),
      WordItem(word: 'EQUILIBRE', definition: 'État de stabilité'),
      WordItem(word: 'MINDFULNESS', definition: 'Pleine conscience du moment présent'),
      WordItem(word: 'CYBERBULLYING', definition: 'Harcèlement en ligne'),
      WordItem(word: 'PRIVACY', definition: 'Vie privée et intimité'),
    ]);
    
    _shufflePool();
  }

  void _startTimer() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
        // Augmenter le stress progressivement
        if (_elapsedSeconds % 10 == 0) {
          _stress = math.min(100, _stress + 2);
        }
      });
    });
  }

  void _shufflePool() {
    _poolOrder = List.generate(_allItems.length, (i) => i);
    _poolOrder.shuffle(math.Random());
  }

  void _onWordUsed(int index) {
    if (_allItems[index].used) return;
    
    setState(() {
      _allItems[index].used = true;
      _pulseIndexes.add(index);
      // Réduire le stress quand on trouve un mot
      _stress = math.max(0, _stress - 5);
    });

    // Animation de succès
    HapticFeedback.lightImpact();
    
    // Retirer l'animation après un délai
    Timer(const Duration(milliseconds: 600), () {
      if (mounted) {
    setState(() {
          _pulseIndexes.remove(index);
        });
      }
    });

    // Vérifier si le jeu est terminé
    _checkGameCompletion();
  }

  void _checkGameCompletion() {
    final usedCount = _allItems.where((item) => item.used).length;
    if (usedCount >= _allItems.length * 0.8) { // 80% des mots trouvés
      _endGameSession();
    }
  }

  void _endGameSession() async {
    _ticker?.cancel();
    
    final usedCount = _allItems.where((item) => item.used).length;
    final score = usedCount * 10;
    
    await _statsService.endGameSession(
      completed: true,
      score: score,
      additionalData: {
        'wordsFound': usedCount,
        'totalWords': _allItems.length,
        'completionRate': (usedCount / _allItems.length) * 100,
        'stressLevel': _stress,
        'timeSpent': _elapsedSeconds,
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
            title: const Text(
          '🎉 Bravo !',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
              children: [
            Text(
              'Vous avez trouvé ${_allItems.where((item) => item.used).length} mots sur ${_allItems.length}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Score: ${_allItems.where((item) => item.used).length * 10} points',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Niveau de stress final: $_stress%',
              style: TextStyle(
                color: _stress < 40 ? Colors.green : _stress < 70 ? Colors.orange : Colors.red,
                fontSize: 16,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const Page4Tram()),
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
    return Scaffold(
      backgroundColor: colorBg1,
      body: SafeArea(
        child: Stack(
      children: [
            // Arrière-plan avec gradient
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colorBg1, colorBg2, colorBg3],
                  ),
                ),
              ),
            ),
            
            // Contenu principal
            Column(
              children: [
                // En-tête avec chronomètre et stress
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                            const Text(
                              'Mots Croisés',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Stress: $_stress%',
                      style: TextStyle(
                                color: _stress < 40 ? colorStressLow : _stress < 70 ? colorStressMid : colorStressHigh,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            LinearProgressIndicator(
                              value: _stress / 100,
                              backgroundColor: Colors.grey[800],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _stress < 40 ? colorStressLow : _stress < 70 ? colorStressMid : colorStressHigh,
                              ),
                  ),
                ],
              ),
                      ),
                      const GameTimerWidget(),
            ],
          ),
        ),
                
                // Barre de recherche
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _query = value.toLowerCase();
                      });
                    },
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un mot...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
                      FilterChip(
                        label: const Text('Masquer utilisés'),
                        selected: _hideUsed,
                        onSelected: (selected) {
                          setState(() {
                            _hideUsed = selected;
                          });
                        },
                        selectedColor: colorAccent.withOpacity(0.3),
                        checkmarkColor: colorAccent,
                      ),
                      const SizedBox(width: 12),
                      FilterChip(
                        label: const Text('Mode Association'),
                        selected: _associationMode,
                        onSelected: (selected) {
                          setState(() {
                            _associationMode = selected;
                          });
                        },
                        selectedColor: colorAccent.withOpacity(0.3),
                        checkmarkColor: colorAccent,
          ),
        ],
      ),
                ),
                
                const SizedBox(height: 16),
                
                // Liste des mots
                Expanded(
                  child: _buildWordsList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWordsList() {
    final filteredItems = _allItems.where((item) {
      if (_hideUsed && item.used) return false;
      if (_query.isNotEmpty && !item.word.toLowerCase().contains(_query)) return false;
      return true;
    }).toList();

    if (filteredItems.isEmpty) {
      return const Center(
            child: Text(
          'Aucun mot trouvé',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredItems.length,
      itemBuilder: (context, index) {
        final item = filteredItems[index];
        final originalIndex = _allItems.indexOf(item);
        final isUsed = item.used;
        final isPulsing = _pulseIndexes.contains(originalIndex);
        final isHovered = _hoverChipIndexes.contains(originalIndex);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Colors.transparent,
            child: InkWell(
              onTap: () => _onWordUsed(originalIndex),
              onHover: (hovered) {
                setState(() {
                  if (hovered) {
                    _hoverChipIndexes.add(originalIndex);
                  } else {
                    _hoverChipIndexes.remove(originalIndex);
                  }
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
                  color: isUsed 
                      ? Colors.green.withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isUsed 
                        ? Colors.green
                        : isHovered 
                            ? colorAccent
                            : Colors.white.withOpacity(0.1),
                    width: isHovered ? 2 : 1,
                  ),
                  boxShadow: isPulsing ? [
              BoxShadow(
                      color: colorAccent.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ] : null,
                ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                            item.word,
                            style: TextStyle(
                              color: isUsed ? Colors.green : Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              decoration: isUsed ? TextDecoration.lineThrough : null,
                            ),
                          ),
                          const SizedBox(height: 4),
                      Text(
                            item.definition,
                            style: TextStyle(
                              color: isUsed ? Colors.green.withOpacity(0.7) : Colors.grey[400],
                              fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                    if (isUsed)
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 24,
                      ),
                  ],
          ),
          ),
        ),
      ),
    );
      },
    );
  }
}