import 'dart:async';
import 'dart:math';
import 'dart:collection';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/game_stats_service.dart';
import '../services/solo_player_service.dart';
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
  final SoloPlayerService _soloPlayerService = SoloPlayerService();
  
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
    'SOURCE': 'Conseil: vérifie au moins 2 sources fiables.',
    'APPLI': 'Conseil: désinstalle celles que tu n\'utilises plus.',
    'TEMPS': 'Conseil: fixe une limite quotidienne d\'écran.',
    'ZEN': 'Conseil: pratique 3 minutes de pleine conscience.',
  };

  @override
  void initState() {
    super.initState();
    _startGameSession();
    _seedData();
    _reshufflePool();
    _startTicker();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _startGameSession() async {
    if (!_statsService.isSessionActive) {
      final playerName = await _soloPlayerService.getUniquePlayerName();
      _statsService.startGameSession(
        playerName: playerName,
        gameRoom: 'Mots Croisés',
        gameMode: 'solo',
      );
    }
  }

  void _seedData() {
    final List<WordItem> raw = [
      WordItem(word: 'STRESS', definition: 'Émotion ressentie quand on est trop sous pression.'),
      WordItem(word: 'SOMMEIL', definition: 'Ce qu\'il faut bien avoir pour récupérer.'),
      WordItem(word: 'ECRAN', definition: 'Surface sur laquelle on regarde ordi ou smartphone.'),
      WordItem(word: 'AMIS', definition: 'Personnes avec qui on aime passer du temps.'),
      WordItem(word: 'RGPD', definition: 'Loi européenne qui protège nos données personnelles.'),
      WordItem(word: 'DONNEES', definition: 'Informations qu\'on partage en ligne sans toujours s\'en rendre compte.'),
      WordItem(word: 'PRIVEE', definition: 'Type de vie qu\'il faut protéger sur Internet.'),
      WordItem(word: 'HARCELER', definition: 'Faire du mal à quelqu\'un de façon répétée.'),
      WordItem(word: 'CONFIANCE', definition: 'Ce qu\'il faut avoir en soi et dans les autres.'),
      WordItem(word: 'SECURITE', definition: 'Ce qui protège nos comptes et nos données.'),
      WordItem(word: 'PAUSE', definition: 'Moment pour se reposer et souffler.'),
      WordItem(word: 'FOCUS', definition: 'Se concentrer sur une seule chose.'),
      WordItem(word: 'RESPIRE', definition: 'Ce qu\'on fait pour se calmer quand on stresse.'),
      WordItem(word: 'RESEAU', definition: 'Ensemble de personnes connectées entre elles.'),
      WordItem(word: 'SOURCE', definition: 'Ce qu\'il faut vérifier avant de croire une info.'),
      WordItem(word: 'APPLI', definition: 'Programme sur téléphone (abréviation).'),
      WordItem(word: 'TEMPS', definition: 'Ce qu\'on passe souvent sur les écrans.'),
      WordItem(word: 'ZEN', definition: 'Être calme et détendu.'),
    ];

    // Deduplicate by word (case-insensitive)
    final Set<String> seen = <String>{};
    for (final w in raw) {
      final key = w.word.trim().toUpperCase();
      if (!seen.contains(key)) {
        seen.add(key);
        _allItems.add(w);
      }
    }
  }

  void _reshufflePool() {
    _poolOrder = List<int>.generate(_allItems.length, (i) => i);
    _poolOrder.shuffle(Random());
  }

  void _startTicker() {
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _elapsedSeconds += 1;
        if (_elapsedSeconds % 8 == 0) {
          _addStress(1); // +1 toutes les 8 secondes
        }
      });
    });
  }

  void _addStress(int delta) {
    final int previous = _stress;
    _stress = (_stress + delta).clamp(0, 100);
    if (_stress >= 90 && previous < 90) {
      _triggerShake();
      // Micro-beep option intentionally skipped (no external deps)
    }
  }

  void _reduceStress(int delta) {
    _stress = (_stress - delta).clamp(0, 100);
  }

  void _triggerShake() {
    setState(() => _shake = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() => _shake = false);
    });
  }

  List<WordItem> get _filteredItems {
    final String q = _query.trim().toLowerCase();
    final Iterable<WordItem> base = _allItems.where((w) {
      if (_hideUsed && w.used) return false;
      if (q.isEmpty) return true;
      final inWord = w.word.toLowerCase().contains(q);
      final inDef = w.definition.toLowerCase().contains(q);
      return inWord || inDef;
    });
    return base.toList();
  }

  bool get _allUsed => _allItems.every((w) => w.used);

  Color get _stressColor {
    if (_stress >= 70) return colorStressHigh;
    if (_stress >= 40) return colorStressMid;
    return colorStressLow;
  }

  String get _mmss {
    final m = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _onToggleUsed(int absoluteIndex, bool value) {
    setState(() {
      _allItems[absoluteIndex].used = value;
      if (value) {
        _reduceStress(6); // -6 quand coché
        _pulseIndexes.add(absoluteIndex);
        Future.delayed(const Duration(milliseconds: 260), () {
          if (!mounted) return;
          setState(() => _pulseIndexes.remove(absoluteIndex));
        });
        // Glow/halo cyan bref
        _haloIndexes.add(absoluteIndex);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() => _haloIndexes.remove(absoluteIndex));
        });
        // Haptique légère (si supporté)
        HapticFeedback.lightImpact();
        // Tip animé (bottom sheet queued)
        _showAdviceFor(absoluteIndex);
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

  void _showAdviceFor(int absoluteIndex) {
    if (!mounted) return;
    final String key = _allItems[absoluteIndex].word.trim().toUpperCase();
    _enqueueTip(key);
  }

  // --- Tips bottom sheet queue ---
  final Set<String> _shownTips = <String>{};
  final Queue<String> _tipQueue = Queue<String>();
  bool _isTipShowing = false;

  void _enqueueTip(String wordKey) {
    final String? advice = _adviceByWord[wordKey];
    if (advice == null || advice.isEmpty) return;
    if (_shownTips.contains(wordKey)) return; // éviter doublons
    _shownTips.add(wordKey);
    _tipQueue.add(wordKey);
    _processTipQueue();
  }

  void _processTipQueue() {
    if (!mounted) return;
    if (_isTipShowing) return;
    if (_tipQueue.isEmpty) return;
    _isTipShowing = true;
    final String wordKey = _tipQueue.removeFirst();
    final String message = _adviceByWord[wordKey] ?? '';
    _showTipCentered(wordKey, message).whenComplete(() {
      if (!mounted) return;
      _isTipShowing = false;
      // Si d'autres tips en attente, afficher le suivant
      Future.microtask(_processTipQueue);
    });
  }

  Future<void> _showTipCentered(String wordKey, String message) async {
    await HapticFeedback.selectionClick();
    if (!mounted) return;
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'tip',
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (ctx, anim, secAnim) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (ctx, anim, secAnim, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOut);
        return Opacity(
          opacity: curved.value,
          child: Transform.translate(
            offset: Offset(0, (1 - curved.value) * 20),
            child: Transform.scale(
              scale: 0.98 + curved.value * 0.02,
              child: Center(
                child: _AnimatedTipCenter(title: wordKey, message: message),
              ),
            ),
          ),
        );
      },
    );
  }

  void _onToggleDefinition(int absoluteIndex, bool shown) {
    setState(() {
      if (shown) {
        _shownDefinitionIndexes.add(absoluteIndex);
        if (!_seenDefinitionIndexes.contains(absoluteIndex)) {
          _seenDefinitionIndexes.add(absoluteIndex);
          _reduceStress(2); // -2 la première fois
        }
      } else {
        _shownDefinitionIndexes.remove(absoluteIndex);
      }
    });
  }

  void _shuffle() {
    setState(() {
      final now = DateTime.now();
      if (_lastShuffleTime != null &&
          now.difference(_lastShuffleTime!).inSeconds < 10) {
        _addStress(5); // pénalité si plusieurs fois en < 10s
      }
      _lastShuffleTime = now;

      _allItems.shuffle(Random());
    });
  }

  void _toggleShowAllDefinitions() {
    setState(() {
      _showAllDefinitions = !_showAllDefinitions;
      if (_showAllDefinitions) {
        // Mark all as shown (and first-time seen reductions only once)
        for (int i = 0; i < _allItems.length; i++) {
          _shownDefinitionIndexes.add(i);
          if (!_seenDefinitionIndexes.contains(i)) {
            _seenDefinitionIndexes.add(i);
            _reduceStress(2);
          }
        }
      } else {
        _shownDefinitionIndexes.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colorAccent,
        brightness: Brightness.dark,
        primary: colorAccent,
      ),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: colorText),
        titleLarge: TextStyle(color: colorText, fontWeight: FontWeight.w700, letterSpacing: 0.6),
      ),
      useMaterial3: true,
    );

    return Theme(
      data: theme,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment(-0.8, -1.0),
            end: Alignment(0.8, 1.0),
            colors: [colorBg1, colorBg2, colorBg3],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            title: const Text(
              'Salle 3 — Liste des mots',
              style: TextStyle(color: colorText, fontWeight: FontWeight.w700, letterSpacing: 0.6),
            ),
            actions: [
              const GameTimerWidget(),
              const SizedBox(width: 12),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox.shrink(),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      if (_associationMode) {
                        return _buildAssociationArea(constraints);
                      }
                      final items = _filteredItems;
                      if (constraints.maxWidth > 1000) {
                        return _buildGrid(items, 3);
                      } else if (constraints.maxWidth > 700) {
                        return _buildGrid(items, 2);
                      }
                      return _buildList(items);
                    },
                  ),
                ),
                _buildBottomProgressBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<WordItem> items) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final absoluteIndex = _allItems.indexOf(items[i]);
        return _buildWordCard(items[i], absoluteIndex);
      },
    );
  }

  Widget _buildGrid(List<WordItem> items, int columns) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 3 / 2,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final absoluteIndex = _allItems.indexOf(items[i]);
        return _buildWordCard(items[i], absoluteIndex);
      },
    );
  }

  Widget _buildAssociationArea(BoxConstraints constraints) {
    final bool wide = constraints.maxWidth > 900;
    // Apply search filter to pool only
    final String q = _query.trim().toLowerCase();
    final List<int> filteredPool = [
      for (final i in _poolOrder)
        if (!_allItems[i].used && (q.isEmpty || _allItems[i].word.toLowerCase().contains(q) || _allItems[i].definition.toLowerCase().contains(q)))
          i
    ];

    final Widget pool = _AssociationPanel(
      title: 'Mots',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final i in filteredPool) _buildDraggableChip(i),
            if (filteredPool.isEmpty)
              const Text('Aucun mot', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );

    final Widget targets = _AssociationPanel(
      title: 'Indices',
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _allItems.length,
        itemBuilder: (context, i) => _buildDropTarget(i),
      ),
    );

    if (wide) {
      return Row(
        children: [
          Expanded(child: pool),
          const SizedBox(width: 12),
          Expanded(child: targets),
        ],
      );
    }

    return Column(
      children: [
        SizedBox(height: min(220, constraints.maxHeight * 0.35), child: pool),
        const SizedBox(height: 12),
        Expanded(child: targets),
      ],
    );
  }

  Widget _buildDraggableChip(int absoluteIndex) {
    final item = _allItems[absoluteIndex];
    final bool hovering = _hoverChipIndexes.contains(absoluteIndex);
    return MouseRegion(
      onEnter: (_) => setState(() => _hoverChipIndexes.add(absoluteIndex)),
      onExit: (_) => setState(() => _hoverChipIndexes.remove(absoluteIndex)),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: hovering ? 1.03 : 1.0,
        curve: Curves.easeOut,
        child: Draggable<int>(
          data: absoluteIndex,
          feedback: Material(
            color: Colors.transparent,
            child: _chipContent(item.word, dragging: true, glow: true),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _chipContent(item.word),
          ),
          child: _chipContent(item.word, glow: hovering),
        ),
      ),
    );
  }

  Widget _chipContent(String label, {bool dragging = false, bool glow = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: dragging ? colorAccent.withOpacity(0.25) : Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: colorAccent.withOpacity(0.25),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: const TextStyle(color: colorText, fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _buildDropTarget(int targetIndex) {
    final WordItem target = _allItems[targetIndex];
    final bool matched = target.used;
    final bool wrongFlash = _wrongFlashTargets.contains(targetIndex);
    final bool halo = _haloIndexes.contains(targetIndex);
    final bool hovering = _hoverTargetIndexes.contains(targetIndex);
    final bool bouncing = _bounceTargets.contains(targetIndex);

    final double scale = bouncing
        ? 1.06
        : (hovering ? 1.02 : 1.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hoverTargetIndexes.add(targetIndex)),
      onExit: (_) => setState(() => _hoverTargetIndexes.remove(targetIndex)),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        scale: scale,
        child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: matched
            ? Colors.green.withOpacity(0.18)
            : wrongFlash
                ? Colors.red.withOpacity(0.14)
                : Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: matched
              ? Colors.greenAccent.withOpacity(0.7)
              : wrongFlash
                  ? Colors.redAccent.withOpacity(0.7)
                  : Colors.white.withOpacity(0.08),
        ),
        boxShadow: halo
            ? [
                BoxShadow(
                  color: colorAccent.withOpacity(0.55),
                  blurRadius: 24,
                  spreadRadius: 1,
                ),
              ]
            : (hovering
                ? [
                    BoxShadow(
                      color: colorAccent.withOpacity(0.18),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ]
                : null),
      ),
      child: DragTarget<int>(
        builder: (context, candidateData, rejectedData) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      target.definition,
                      style: const TextStyle(color: Colors.white70, height: 1.25),
                    ),
                    const SizedBox(height: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 150),
                      child: matched
                          ? Row(
                              key: const ValueKey('matched'),
                              children: const [
                                Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
                                SizedBox(width: 6),
                                Text('Correct', style: TextStyle(color: Colors.greenAccent)),
                              ],
                            )
                          : (candidateData.isNotEmpty)
                              ? Row(
                                  key: const ValueKey('hover'),
                                  children: const [
                                    Icon(Icons.file_download, color: colorAccent, size: 18),
                                    SizedBox(width: 6),
                                    Text('Relachez ici', style: TextStyle(color: colorAccent)),
                                  ],
                                )
                              : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                child: matched
                    ? _chipContent(target.word)
                    : const SizedBox.shrink(),
              ),
            ],
          );
        },
        onWillAccept: (data) => !matched,
        onAccept: (data) {
          if (data == targetIndex) {
            _onToggleUsed(targetIndex, true); // mark matched
            // conseil déjà affiché dans _onToggleUsed
          } else {
            setState(() {
              _wrongFlashTargets.add(targetIndex);
              _bounceTargets.add(targetIndex);
            });
            Future.delayed(const Duration(milliseconds: 300), () {
              if (!mounted) return;
              setState(() {
                _wrongFlashTargets.remove(targetIndex);
                _bounceTargets.remove(targetIndex);
              });
            });
          }
        },
      ),
      ),
      ),
    );
  }

  Widget _buildWordCard(WordItem item, int absoluteIndex) {
    final bool isShown = _showAllDefinitions || _shownDefinitionIndexes.contains(absoluteIndex);
    final bool pulse = _pulseIndexes.contains(absoluteIndex);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: (pulse ? Colors.green.withOpacity(0.18) : Colors.white.withOpacity(0.06)),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _onToggleDefinition(absoluteIndex, !isShown),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 180),
                      style: TextStyle(
                        color: item.used ? Colors.white70 : colorText,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                      child: Text(item.word),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Tooltip(
                    message: 'Marquer comme utilisé',
                    child: Switch(
                      value: item.used,
                      onChanged: (v) => _onToggleUsed(absoluteIndex, v),
                      activeColor: colorAccent,
                    ),
                  ),
                  const SizedBox(width: 6),
                  _InfoToggleButton(
                    isOpen: isShown,
                    onTap: () => _onToggleDefinition(absoluteIndex, !isShown),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                child: ConstrainedBox(
                  constraints: isShown
                      ? const BoxConstraints()
                      : const BoxConstraints(maxHeight: 0),
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: isShown ? 1 : 0,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        item.definition,
                        style: const TextStyle(color: Colors.white70, height: 1.25),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomProgressBar() {
    final int total = _allItems.length;
    final int used = _allItems.where((w) => w.used).length;
    final int remaining = total - used;
    final double progress = total == 0 ? 0 : used / total;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: colorAccent.withOpacity(0.10),
              blurRadius: 20,
              spreadRadius: 1,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$remaining / $total mots restants',
                  style: const TextStyle(color: colorText, fontWeight: FontWeight.w600),
                ),
              ),
              FilledButton(
                onPressed: _allUsed
                    ? () => Navigator.pushNamed(context, '/page4_dilemmas')
                    : null,
                style: FilledButton.styleFrom(
                  backgroundColor: _allUsed ? Colors.greenAccent.shade400 : Colors.green.shade900,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('BoutonFinal3'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: AlwaysStoppedAnimation<Color>(colorAccent),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _InfoToggleButton extends StatelessWidget {
  const _InfoToggleButton({required this.isOpen, required this.onTap});
  final bool isOpen;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isOpen ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            isOpen ? Icons.info : Icons.info_outline,
            size: 18,
            color: _Page3WordsState.colorAccent,
          ),
        ),
      ),
    );
  }
}

class _AssociationPanel extends StatelessWidget {
  const _AssociationPanel({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Text(
              title,
              style: const TextStyle(
                color: _Page3WordsState.colorText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _AnimatedTipCenter extends StatefulWidget {
  const _AnimatedTipCenter({required this.title, required this.message});
  final String title;
  final String message;

  @override
  State<_AnimatedTipCenter> createState() => _AnimatedTipCenterState();
}

class _AnimatedTipCenterState extends State<_AnimatedTipCenter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.98, end: 1.0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _pulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart),
    );
    _controller.forward();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) Navigator.of(context).maybePop();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: Material(
          color: Colors.transparent,
          child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF203A43),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: _Page3WordsState.colorAccent.withOpacity(0.12 + 0.08 * _pulse.value),
                blurRadius: 32 + 8 * _pulse.value,
                spreadRadius: 1 + 1 * _pulse.value,
              ),
            ],
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tips_and_updates, color: _Page3WordsState.colorAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: _Page3WordsState.colorText,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.message,
                        style: const TextStyle(
                          color: _Page3WordsState.colorText,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => Navigator.of(context).maybePop(),
                  borderRadius: BorderRadius.circular(10),
                  child: const Padding(
                    padding: EdgeInsets.all(6.0),
                    child: Icon(Icons.close, color: Colors.white70),
                  ),
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