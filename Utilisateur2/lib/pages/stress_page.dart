import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'page3_crossword.dart';
import 'package:torch_light/torch_light.dart';
import '../services/global_score_service.dart';
import '../widgets/score_display_widget.dart';

class StressPage extends StatefulWidget {
  const StressPage({super.key});

  @override
  State<StressPage> createState() => _StressPageState();
}

class _StressPageState extends State<StressPage> {
  final GlobalScoreService _scoreService = GlobalScoreService();
  
  StreamSubscription<AccelerometerEvent>? _accelSub;
  double _currentIntensity = 0.0; // 0..1 normalized "stress"
  double _peakIntensity = 0.0;
  bool _torchOn = false;
  bool _thresholdReached = false;
  double _lastIntensityForHaptics = 0.0;
  bool _calmMode = true; // reduce flashing/FX if true (enabled by default)
  bool _celebrated = false; // confetti burst once on unlock

  // Tunables
  static const double gravity = 9.80665; // m/s^2
  static const double noiseFloor = 0.25; // g units; ignore tiny shakes
  static const double smoothing = 0.15; // EMA smoothing factor
  static const double triggerThreshold = 0.65; // intensity to unlock button

  double _ema = 0.0; // exponential moving average of intensity

  // Web-only activity tracking
  double _webMotionAccumulator = 0.0;
  DateTime _lastActivityAt = DateTime.now();
  Timer? _webTicker;

  // Game timer / score
  final DateTime _startedAt = DateTime.now();
  Timer? _uiTicker; // drives particles and timer repaint
  int _elapsedMs = 0;
  double _score = 0.0; // accumulate intensity over time

  // Particles
  final List<_Particle> _particles = <_Particle>[];
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _scoreService.startPage('Stress');
    _startListening();
    _startUiTicker();
  }

  @override
  void dispose() {
    _scoreService.endPage('Stress');
    _stopListening();
    super.dispose();
  }

  void _startListening() {
    if (kIsWeb) {
      _startWebTicker();
      return;
    }
    _accelSub = accelerometerEvents.listen((event) async {
      final double ax = event.x.toDouble();
      final double ay = event.y.toDouble();
      final double az = event.z.toDouble();

      // Remove gravity magnitude to estimate motion intensity
      final double mag = math.sqrt(ax * ax + ay * ay + az * az);
      final double motion = (mag - gravity).abs() / gravity; // in g units

      // Ignore tiny movements
      final double clamped = math.max(0.0, motion - noiseFloor);

      // Smooth intensity using EMA
      _ema = smoothing * clamped + (1.0 - smoothing) * _ema;
      final double intensity = _ema.clamp(0.0, 1.5);

      // Normalize into 0..1 window (cap at 1 for UI)
      final double normalized = (intensity / 1.0).clamp(0.0, 1.0);

      bool shouldUnlock = normalized >= triggerThreshold;

      // Torch feedback: flicker stronger with intensity
      await _updateTorch(normalized);

      final bool wasUnlocked = _thresholdReached;
      setState(() {
        _currentIntensity = normalized;
        _peakIntensity = math.max(_peakIntensity, normalized);
        _thresholdReached = _thresholdReached || shouldUnlock;
      });
      if (!wasUnlocked && _thresholdReached && !_celebrated) {
        _burstParticles();
        _celebrated = true;
      }

      _maybeHaptic();
    });
  }

  void _startWebTicker() {
    _webTicker = Timer.periodic(const Duration(milliseconds: 50), (_) {
      // Convert accumulated motion into an intensity sample
      // Heuristic: more/faster pointer/keyboard activity -> higher intensity
      final double recent = _webMotionAccumulator;
      _webMotionAccumulator = 0.0;

      // Decay over time if no activity
      final Duration idle = DateTime.now().difference(_lastActivityAt);
      final double idlePenalty = (idle.inMilliseconds / 1200.0).clamp(0.0, 1.0);

      // Normalize: assume ~50 px per tick is "high" activity
      final double sample = (recent / 50.0).clamp(0.0, 1.5);

      _ema = smoothing * sample + (1.0 - smoothing) * _ema;
      double normalized = _ema - idlePenalty * 0.35; // decay with idle
      normalized = normalized.clamp(0.0, 1.0);

      final bool shouldUnlock = normalized >= triggerThreshold;

      final bool wasUnlocked = _thresholdReached;
      setState(() {
        _currentIntensity = normalized;
        _peakIntensity = math.max(_peakIntensity, normalized);
        _thresholdReached = _thresholdReached || shouldUnlock;
      });
      if (!wasUnlocked && _thresholdReached && !_celebrated) {
        _burstParticles();
        _celebrated = true;
      }
      _maybeHaptic();
    });
  }

  void _startUiTicker() {
    _uiTicker = Timer.periodic(const Duration(milliseconds: 33), (_) {
      // Update timer
      _elapsedMs = DateTime.now().difference(_startedAt).inMilliseconds;
      // Score scales with intensity; faster gain at higher intensity
      _score += _currentIntensity * 0.033; // ~ per frame seconds
      
      // Ajouter des points basés sur l'intensité
      if (_currentIntensity > 0.5) {
        _scoreService.addScore((_currentIntensity * 2).round(), 'Stress intense');
      }

      // Update particles
      _updateParticles();

      if (mounted) setState(() {});
    });
  }

  Future<void> _updateTorch(double intensity) async {
    if (kIsWeb || _calmMode) return; // disable torch on web or in calm mode
    try {
      // Turn on torch above a small cue, off otherwise
      final bool wantOn = intensity > 0.15;
      if (wantOn && !_torchOn) {
        await TorchLight.enableTorch();
        _torchOn = true;
      } else if (!wantOn && _torchOn) {
        await TorchLight.disableTorch();
        _torchOn = false;
      }
    } catch (_) {
      // Torch not available or permission denied; ignore silently for UX
    }
  }

  void _stopListening() {
    _accelSub?.cancel();
    _accelSub = null;
    _webTicker?.cancel();
    _webTicker = null;
    _uiTicker?.cancel();
    _uiTicker = null;
    if (_torchOn) {
      TorchLight.disableTorch().catchError((_) {});
      _torchOn = false;
    }
  }

  void _maybeHaptic() {
    if (kIsWeb) return;
    final double delta = _currentIntensity - _lastIntensityForHaptics;
    _lastIntensityForHaptics = _currentIntensity;
    if (delta > 0.15 && _currentIntensity > 0.25) {
      HapticFeedback.lightImpact();
    }
    if (_thresholdReached && delta > 0) {
      HapticFeedback.mediumImpact();
    }
  }

  void _updateParticles() {
    // Spawn rate scales with intensity
    final double spawnScale = _calmMode ? 0.5 : 1.0;
    final int toSpawn = (_currentIntensity * 6 * spawnScale).round();
    for (int i = 0; i < toSpawn; i++) {
      _particles.add(_Particle.spawn(_rng));
    }
    // Update and cull
    for (int i = _particles.length - 1; i >= 0; i--) {
      final _Particle p = _particles[i];
      p.update(decay: 0.96, speedScale: 0.5 + _currentIntensity * 1.5);
      if (p.life <= 0) {
        _particles.removeAt(i);
      }
    }
    // Cap
    if (_particles.length > 250) {
      _particles.removeRange(0, _particles.length - 250);
    }
  }

  void _burstParticles() {
    for (int i = 0; i < 120; i++) {
      _particles.add(_Particle.spawn(_rng)..life = 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color progressColor = _thresholdReached
        ? Colors.green
        : (_currentIntensity >= triggerThreshold ? Colors.orange : Colors.red);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Salle 2 — Détecteur de stress'),
        backgroundColor: Colors.black,
        actions: [
          const ScoreDisplayWidget(compact: true),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Listener(
          onPointerMove: kIsWeb
              ? (evt) {
                  final double delta = (evt.delta.dx.abs() + evt.delta.dy.abs());
                  _webMotionAccumulator += delta;
                  _lastActivityAt = DateTime.now();
                }
              : null,
          child: Focus(
            autofocus: true,
            onKeyEvent: kIsWeb
                ? (node, event) {
                    _webMotionAccumulator += 20.0;
                    _lastActivityAt = DateTime.now();
                    return KeyEventResult.handled;
                  }
                : null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Animated reactive background
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(
                        (_currentIntensity * 2.0 - 1.0).clamp(-0.9, 0.9),
                        (1.0 - _currentIntensity * 2.0).clamp(-0.9, 0.9),
                      ),
                      radius: 1.2,
                      colors: _calmMode
                          ? [
                              Colors.black,
                              Color.lerp(Colors.indigo.shade900, Colors.purple.shade900, _currentIntensity * 0.5)!,
                              Color.lerp(Colors.indigo, Colors.purple, _currentIntensity * 0.5)!,
                            ]
                          : [
                              Colors.black,
                              Color.lerp(Colors.deepPurple.shade900, Colors.red.shade900, _currentIntensity)!,
                              Color.lerp(Colors.deepPurple, Colors.red, _currentIntensity)!,
                            ],
                      stops: const [0.2, 0.65, 1.0],
                    ),
                  ),
                ),
                // Epilepsy warning bar
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.65),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.yellowAccent.withOpacity(0.9), width: 1.2),
                    ),
                    child: const Text(
                      'Attention: effets lumineux pouvant déclencher une crise (épilepsie) — jouer prudemment',
                      style: TextStyle(color: Colors.yellowAccent, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                // Center gauge and text
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StressGauge(value: _currentIntensity, color: progressColor),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          kIsWeb
                              ? 'Bouge vite la souris, défile, tape au clavier pour faire monter le stress.'
                              : 'Secoue le téléphone pour faire monter le stress. Le flash réagit à l’intensité.',
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                // Particles overlay
                IgnorePointer(
                  child: CustomPaint(
                    painter: _ParticlesPainter(_particles),
                    size: Size.infinite,
                  ),
                ),

                // HUD: score
                Positioned(
                  top: 8,
                  right: 8,
                  child: _HudChip(
                    icon: Icons.stacked_line_chart,
                    label: 'Score ${(1000 * _score).round()}',
                  ),
                ),

                

                // Bottom status + animated unlock button
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Intensité: ${(_currentIntensity * 100).toStringAsFixed(0)}%   •   Pic: ${(_peakIntensity * 100).toStringAsFixed(0)}%   •   Seuil: ${(triggerThreshold * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        AnimatedScale(
                          scale: _thresholdReached
                              ? 1.0
                              : (_currentIntensity >= triggerThreshold * 0.85
                                  ? 0.95 + 0.05 * (0.5 + 0.5 * math.sin(_elapsedMs / 160))
                                  : 0.95),
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutBack,
                          child: AnimatedOpacity(
                            opacity: _thresholdReached ? 1.0 : 0.4,
                            duration: const Duration(milliseconds: 250),
                            child: _NeonActionButton(
                              enabled: _thresholdReached,
                              primaryLabel: _thresholdReached ? 'Passe à l’étape prochaine' : 'T’es presque !',
                              secondaryLabel: !_thresholdReached
                                  ? 'Encore ${(math.max(0, (triggerThreshold - _currentIntensity) * 100)).toStringAsFixed(0)}%'
                                  : null,
                              onTap: _thresholdReached
                                  ? () {
                                      // Appeler le callback si fourni
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => const Page3Crossword(),
                                        ),
                                      );
                                    }
                                  : null,
                              pulseT: _elapsedMs.toDouble(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Removed placeholder; real navigation goes to Page5Notifications.

class _StressGauge extends StatelessWidget {
  final double value; // 0..1
  final Color color;
  const _StressGauge({required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final double clamped = value.clamp(0.0, 1.0);
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.35), blurRadius: 40, spreadRadius: 8),
              ],
            ),
          ),
          // Background ring
          SizedBox(
            width: 200,
            height: 200,
            child: CustomPaint(
              painter: _RingPainter(baseColor: Colors.white12),
            ),
          ),
          // Foreground progress ring
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: clamped),
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            builder: (context, v, _) {
              return SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: _ProgressPainter(progress: v, color: color),
                ),
              );
            },
          ),
          // Center content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(clamped * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 36,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'STRESS',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, letterSpacing: 3),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final Color baseColor;
  const _RingPainter({required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    final Rect rect = Offset.zero & size;
    final double start = -math.pi / 2;
    canvas.drawArc(rect.deflate(8), start, math.pi * 2, false, paint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) => false;
}

class _ProgressPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;
  const _ProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final double start = -math.pi / 2;
    final double sweep = (math.pi * 2) * progress.clamp(0.0, 1.0);
    if (sweep <= 0.001) {
      // Avoid zero-sweep gradients which can crash CanvasKit on web.
      return;
    }

    // Gradient stroke for progress
    final Paint paint = Paint()
      ..shader = SweepGradient(
        startAngle: start,
        endAngle: start + sweep,
        colors: [
          color.withOpacity(0.2),
          color.withOpacity(0.6),
          color,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect.deflate(8), start, sweep, false, paint);
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

class _Particle {
  double x;
  double y;
  double vx;
  double vy;
  double life;
  Color color;

  _Particle({required this.x, required this.y, required this.vx, required this.vy, required this.life, required this.color});

  factory _Particle.spawn(math.Random rng) {
    final double angle = rng.nextDouble() * math.pi * 2;
    final double speed = 0.8 + rng.nextDouble() * 1.8;
    return _Particle(
      x: 0.5,
      y: 0.5,
      vx: math.cos(angle) * speed * 0.001,
      vy: math.sin(angle) * speed * 0.001,
      life: 1.0,
      color: Colors.primaries[rng.nextInt(Colors.primaries.length)].withOpacity(0.8),
    );
  }

  void update({required double decay, required double speedScale}) {
    x += vx * speedScale;
    y += vy * speedScale;
    life *= decay;
  }
}

class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  const _ParticlesPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (final _Particle p in particles) {
      final Offset pos = Offset(p.x * size.width, p.y * size.height);
      final double radius = 2 + 6 * p.life;
      final Paint paint = Paint()..color = p.color.withOpacity(p.life.clamp(0.0, 1.0));
      canvas.drawCircle(pos, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
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
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

 

class _NeonActionButton extends StatelessWidget {
  final bool enabled;
  final String primaryLabel;
  final String? secondaryLabel;
  final VoidCallback? onTap;
  final double pulseT; // milliseconds for animation phase

  const _NeonActionButton({
    required this.enabled,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.onTap,
    required this.pulseT,
  });

  @override
  Widget build(BuildContext context) {
    final double phase = math.sin(pulseT / 180);
    final double glow = enabled ? 24 : 10 + 4 * (phase + 1) * 0.5;
    final Color base = enabled ? Colors.limeAccent : Colors.cyanAccent;
    final Color border = enabled ? Colors.greenAccent : Colors.cyanAccent.shade100;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: enabled
                ? [base.withOpacity(0.9), base.withOpacity(0.75)]
                : [base.withOpacity(0.35), base.withOpacity(0.2)],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border.withOpacity(enabled ? 0.9 : 0.5), width: 1.6),
          boxShadow: [
            BoxShadow(color: base.withOpacity(enabled ? 0.55 : 0.25), blurRadius: glow, spreadRadius: 1),
            BoxShadow(color: base.withOpacity(enabled ? 0.35 : 0.15), blurRadius: glow * 0.6, spreadRadius: 0.5),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              primaryLabel,
              style: TextStyle(
                color: Colors.black.withOpacity(enabled ? 0.9 : 0.75),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
            if (secondaryLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  secondaryLabel!,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


