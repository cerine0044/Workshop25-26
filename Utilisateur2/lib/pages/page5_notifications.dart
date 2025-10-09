import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../services/game_stats_service.dart';
import '../widgets/game_timer_widget.dart';
import 'page5_success.dart';

class Page5Notifications extends StatefulWidget {
  const Page5Notifications({super.key});

  @override
  State<Page5Notifications> createState() => _Page5NotificationsState();
}

class _Page5NotificationsState extends State<Page5Notifications>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fxController;
  final GameStatsService _statsService = GameStatsService();

  // Fullscreen popup alerts (stacked). Closing one reduces noise.
  final List<_PopupAlert> _popups = <_PopupAlert>[
    _PopupAlert(title: 'RESPIRATION', message: 'Inspire 4s, bloque 4s, expire 6s — répète 4×.', color: Colors.redAccent, icon: Icons.self_improvement),
    _PopupAlert(title: 'EAU', message: 'Bois un grand verre d\'eau maintenant.', color: Colors.orangeAccent, icon: Icons.water_drop),
    _PopupAlert(title: 'POSTURE', message: 'Redresse ton dos, détends les épaules.', color: Colors.red, icon: Icons.accessibility_new),
    _PopupAlert(title: 'PAUSE YEUX', message: 'Règle 20-20-20: regarde à 20m pendant 20s toutes les 20min.', color: Colors.pinkAccent, icon: Icons.visibility),
    _PopupAlert(title: 'RANGEMENT', message: 'Ferme 1 onglet inutile. Respire.', color: Colors.deepPurpleAccent, icon: Icons.close_fullscreen),
    _PopupAlert(title: 'MARCHE', message: 'Lève-toi 1 minute. Fais 20 pas.', color: Colors.lightBlueAccent, icon: Icons.directions_walk),
    _PopupAlert(title: 'AGENDA', message: 'Note 1 tâche importante pour aujourd\'hui.', color: Colors.amberAccent, icon: Icons.event_note),
    _PopupAlert(title: 'EMAIL', message: 'Archive 1 mail. Pas besoin d\'être parfait.', color: Colors.redAccent, icon: Icons.mark_email_read),
    _PopupAlert(title: 'SOURIRE', message: 'Souris légèrement. Ça aide vraiment.', color: Colors.cyanAccent, icon: Icons.emoji_emotions),
    _PopupAlert(title: 'SÉCURITÉ', message: 'Active la 2FA d\'un compte cette semaine.', color: Colors.tealAccent, icon: Icons.shield),
    _PopupAlert(title: 'CITATION', message: '"Ce que tu pratiques grandit."', color: Colors.indigoAccent, icon: Icons.format_quote),
    _PopupAlert(title: 'MÉTÉO', message: 'Ouvre la fenêtre 30s, respire l\'air frais.', color: Colors.blueGrey, icon: Icons.sunny_snowing),
    _PopupAlert(title: 'APPLIS', message: 'Désactive 1 notification non essentielle.', color: Colors.purpleAccent, icon: Icons.notifications_off),
    _PopupAlert(title: 'SANTÉ', message: 'Étirer nuque et poignets 20s.', color: Colors.greenAccent, icon: Icons.health_and_safety),
    _PopupAlert(title: 'ARGENT', message: 'Regarde ton solde sans juger. Juste regarder.', color: Colors.redAccent, icon: Icons.account_balance_wallet),
    // Extra set (doublé)
    _PopupAlert(title: 'RESPIRATION 2', message: 'Fais 3 respirations profondes maintenant.', color: Colors.redAccent, icon: Icons.air),
    _PopupAlert(title: 'EAU 2', message: 'Une gorgée d\'eau en plus.', color: Colors.orange, icon: Icons.local_drink),
    _PopupAlert(title: 'ÉCRAN', message: 'Baisse légèrement la luminosité.', color: Colors.redAccent, icon: Icons.settings_display),
    _PopupAlert(title: 'RACCROCHE', message: 'Dis "non" à 1 interruption aujourd\'hui.', color: Colors.pink, icon: Icons.do_not_disturb_alt),
    _PopupAlert(title: 'SOCIAL', message: 'Envoie un message gentil à quelqu\'un.', color: Colors.deepPurple, icon: Icons.favorite),
    _PopupAlert(title: 'SOMMEIL', message: 'Prépare ton heure de coucher ce soir.', color: Colors.lightBlue, icon: Icons.bedtime),
    _PopupAlert(title: 'CITATION 2', message: '"Moins mais mieux." — Dieter Rams', color: Colors.amber, icon: Icons.short_text),
    _PopupAlert(title: 'EMAIL 2', message: 'Désabonne-toi d\'une newsletter.', color: Colors.red, icon: Icons.unsubscribe),
    _PopupAlert(title: 'ORDRE', message: 'Range 1 objet. Un seul.', color: Colors.cyan, icon: Icons.checklist),
    _PopupAlert(title: 'MOT DE PASSE', message: 'Active un gestionnaire de mots de passe.', color: Colors.teal, icon: Icons.password),
    _PopupAlert(title: 'CITATION 3', message: '"Le calme est une compétence."', color: Colors.indigo, icon: Icons.psychology),
    _PopupAlert(title: 'AIR', message: 'Prends 10s pour regarder au loin.', color: Colors.blueGrey, icon: Icons.landscape),
    _PopupAlert(title: 'NOTIFS', message: 'Coupe 1 alerte en double (mail + app).', color: Colors.purple, icon: Icons.notifications_paused),
    _PopupAlert(title: 'SANTÉ 2', message: 'Booste-toi: 10 squats ou 10 pompes.', color: Colors.green, icon: Icons.fitness_center),
    _PopupAlert(title: 'ARGENT 2', message: 'Mets 1€ dans l\'épargne auto si possible.', color: Colors.redAccent, icon: Icons.savings),
  ];

  // Multiple layered players for extreme stressful mix.
  late final AudioPlayer _loopHorn;
  late final AudioPlayer _loopSiren;
  late final AudioPlayer _loopAlarm;
  Timer? _randomBeeps;
  final math.Random _rng = math.Random(42);
  final Map<_PopupAlert, Offset> _positions = <_PopupAlert, Offset>{};
  final Map<_PopupAlert, Size> _sizes = <_PopupAlert, Size>{};
  int _initialTotal = 0;

  double _intensity = 1.0; // 0..1 based on remaining popups

  @override
  void initState() {
    super.initState();
    _startGameSession();
    _fxController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _loopHorn = AudioPlayer();
    _loopSiren = AudioPlayer();
    _loopAlarm = AudioPlayer();
    _startLayers();
    _startBeeps();
    _initialTotal = _popups.length;
  }

  void _startGameSession() {
    if (!_statsService.isSessionActive) {
      _statsService.startGameSession(
        playerName: 'Joueur Solo',
        gameRoom: 'Gestion des Notifications',
      );
    }
  }

  @override
  void dispose() {
    _randomBeeps?.cancel();
    _fxController.dispose();
    _loopHorn.dispose();
    _loopSiren.dispose();
    _loopAlarm.dispose();
    super.dispose();
  }

  Future<void> _startLayers() async {
    try {
      // Boat horn (deep, continuous)
      await _loopHorn.setReleaseMode(ReleaseMode.loop);
      await _loopHorn.play(
        UrlSource('https://actions.google.com/sounds/v1/transportation/boat_horn.ogg'),
        volume: _intensity,
      );
    } catch (_) {}
    try {
      // Police/ambulance style siren
      await _loopSiren.setReleaseMode(ReleaseMode.loop);
      await _loopSiren.play(
        UrlSource('https://actions.google.com/sounds/v1/alarms/police_siren_single.ogg'),
        volume: (_intensity * 0.9).clamp(0, 1),
      );
    } catch (_) {}
    try {
      // Industrial alarm
      await _loopAlarm.setReleaseMode(ReleaseMode.loop);
      await _loopAlarm.play(
        UrlSource('https://actions.google.com/sounds/v1/alarms/air_raid_siren.ogg'),
        volume: (_intensity * 0.8).clamp(0, 1),
      );
    } catch (_) {}
  }

  void _startBeeps() {
    _randomBeeps?.cancel();
    _randomBeeps = Timer.periodic(const Duration(milliseconds: 850), (_) async {
      if (_intensity <= 0.02) return;
      final AudioPlayer p = AudioPlayer();
      try {
        final List<String> urls = <String>[
          'https://actions.google.com/sounds/v1/alarms/beep_short.ogg',
          'https://actions.google.com/sounds/v1/alarms/alarm_clock.ogg',
          'https://actions.google.com/sounds/v1/cartoon/clang_and_wobble.ogg',
        ];
        await p.play(UrlSource(urls[DateTime.now().millisecond % urls.length]), volume: (_intensity * 0.8).clamp(0, 1));
      } catch (_) {} finally {
        // Dispose the one-shot player after a short delay
        Future<void>.delayed(const Duration(seconds: 3), () => p.dispose());
      }
    });
  }

  void _updateIntensity() {
    final int remaining = _popups.length;
    final int total = _initialTotal == 0 ? _popups.length : _initialTotal;
    final double t = total == 0 ? 0.0 : remaining / total; // 1..0
    _intensity = Curves.easeInOut.transform(t);
    _loopHorn.setVolume(_intensity).ignore();
    _loopSiren.setVolume((_intensity * 0.9).clamp(0, 1)).ignore();
    _loopAlarm.setVolume((_intensity * 0.8).clamp(0, 1)).ignore();
    if (remaining == 0) {
      // Terminer la session de jeu
      _endGameSession();
      
      // brief pause before calm page
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (!mounted) return;
        
        // Appeler le callback si fourni
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CalmSuccessPage()),
        );
      });
    }
  }

  void _endGameSession() async {
    final closedCount = _initialTotal - _popups.length;
    final score = closedCount * 10;
    
    await _statsService.endGameSession(
      completed: true,
      score: score,
      additionalData: {
        'notificationsClosed': closedCount,
        'totalNotifications': _initialTotal,
        'completionRate': (closedCount / _initialTotal) * 100,
        'finalIntensity': _intensity,
      },
    );
  }

  void _closeTopPopup() {
    if (_popups.isEmpty) return;
    setState(() {
      _popups.removeLast();
      _updateIntensity();
    });
  }

  @override
  Widget build(BuildContext context) {
    final double flash = 0.25 + 0.75 * _intensity;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salle 5 — Débranche les notifications'),
        backgroundColor: Colors.black,
        actions: [
          const GameTimerWidget(),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Pulsing, stressful background
          AnimatedBuilder(
            animation: _fxController,
            builder: (context, _) {
              final double t = _fxController.value * 2 * math.pi;
              final double pulse = (math.sin(t * (1.2 + _intensity * 2.2)) * 0.5 + 0.5) * flash;
              return Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(math.sin(t) * 0.4, math.cos(t) * 0.4),
                    radius: 1.0 + 0.3 * _intensity,
                    colors: [
                      Colors.black,
                      Color.lerp(Colors.red.shade900, Colors.orange.shade900, _intensity)!,
                      Color.lerp(Colors.deepPurple, Colors.redAccent, pulse)!,
                    ],
                    stops: const [0.15, 0.6, 1.0],
                  ),
                ),
              );
            },
          ),
          // Stacked scattered popups (topmost is interactive)
          LayoutBuilder(
            builder: (context, constraints) {
              final double maxW = constraints.maxWidth;
              final double maxH = constraints.maxHeight;
              return Stack(
                children: _popups.asMap().entries.map((entry) {
                  final int i = entry.key;
                  final _PopupAlert alert = entry.value;
                  final double depthOpacity = (0.55 + 0.45 * (i + 1) / _popups.length).clamp(0.55, 1.0);
                  // Assign random size/pos once per alert
                  _sizes.putIfAbsent(alert, () {
                    final double w = 320 + _rng.nextInt(220).toDouble();
                    final double h = 160 + _rng.nextInt(120).toDouble();
                    return Size(w, h);
                  });
                  final Size sz = _sizes[alert]!;
                  _positions.putIfAbsent(alert, () {
                    final double left = (_rng.nextDouble() * (maxW - sz.width)).clamp(0, (maxW - sz.width).clamp(0, maxW));
                    final double top = (_rng.nextDouble() * (maxH - sz.height - 80)).clamp(0, (maxH - sz.height - 80).clamp(0, maxH));
                    return Offset(left, top);
                  });
                  final Offset pos = _positions[alert]!;
                  final double rot = (_rng.nextDouble() - 0.5) * 0.12; // small rotation
                  return Positioned(
                    left: pos.dx,
                    top: pos.dy,
                    width: sz.width,
                    height: sz.height,
                    child: IgnorePointer(
                      ignoring: i != _popups.length - 1,
                      child: Transform.rotate(
                        angle: rot,
                        child: _PopupWidget(alert: alert, opacity: depthOpacity, onClose: _closeTopPopup),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          // Footer status
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                _popups.isEmpty
                    ? 'Silence. Paix.'
                    : 'Ferme toutes les fenêtres pour apaiser le bruit (${_popups.length} restantes)'.toUpperCase(),
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PopupAlert {
  final String title;
  final String message;
  final Color color;
  final IconData icon;
  _PopupAlert({required this.title, required this.message, required this.color, required this.icon});
}

class _PopupWidget extends StatelessWidget {
  final _PopupAlert alert;
  final double opacity;
  final VoidCallback onClose;
  const _PopupWidget({required this.alert, required this.opacity, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: opacity,
      child: Container(
        color: alert.color.withOpacity(0.12),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Material(
              color: Colors.black.withOpacity(0.85),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: alert.color.withOpacity(0.9), width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(alert.icon, color: alert.color, size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            alert.title,
                            style: TextStyle(color: alert.color, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.2),
                          ),
                        ),
                        IconButton(
                          onPressed: onClose,
                          icon: const Icon(Icons.close, color: Colors.white70),
                          tooltip: 'Fermer',
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      alert.message,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: onClose,
                          icon: const Icon(Icons.notifications_off),
                          label: const Text('Désactiver'),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                          onPressed: onClose,
                          child: const Text('Fermer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}