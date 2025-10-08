import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CertificatePage extends StatefulWidget {
  final Map<String, dynamic> playerStats;
  
  const CertificatePage({super.key, required this.playerStats});

  @override
  State<CertificatePage> createState() => _CertificatePageState();
}

class _CertificatePageState extends State<CertificatePage> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  String _getPersonalizedMessage() {
    Duration totalTime = widget.playerStats['totalTime'] ?? Duration.zero;
    String playerName = widget.playerStats['playerName'] ?? 'Joueur';
    
    if (totalTime.inMinutes < 5) {
      return '$playerName a démontré une capacité exceptionnelle à naviguer les défis éthiques et technologiques en un temps record.';
    } else if (totalTime.inMinutes < 10) {
      return '$playerName a montré une réflexion approfondie face aux dilemmes moraux et technologiques.';
    } else {
      return '$playerName a pris le temps nécessaire pour réfléchir aux enjeux éthiques et technologiques de notre époque.';
    }
  }

  void _shareCertificate() {
    // Simuler le partage du certificat
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Certificat copié dans le presse-papiers !'),
        backgroundColor: Colors.greenAccent,
      ),
    );
    
    // Copier le texte du certificat
    String certificateText = '''
CERTIFICAT DE DÉCONNEXION
PANDORA BOX

${widget.playerStats['playerName']}

Temps total: ${_formatDuration(widget.playerStats['totalTime'] ?? Duration.zero)}

${_getPersonalizedMessage()}

Ce certificat atteste de la capacité à naviguer les défis éthiques et technologiques modernes avec discernement et réflexion.

Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}
    ''';
    
    Clipboard.setData(ClipboardData(text: certificateText));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Certificat principal
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // En-tête du certificat
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.emoji_events,
                                      color: Colors.amber,
                                      size: 48,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'CERTIFICAT DE DÉCONNEXION',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'PANDORA BOX',
                                      style: TextStyle(
                                        color: Colors.blueAccent,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Nom du joueur
                              Text(
                                widget.playerStats['playerName'] ?? 'Joueur',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Statistiques
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      'STATISTIQUES',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        Column(
                                          children: [
                                            const Icon(
                                              Icons.timer,
                                              color: Colors.blueAccent,
                                              size: 24,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              _formatDuration(widget.playerStats['totalTime'] ?? Duration.zero),
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const Text(
                                              'Temps total',
                                              style: TextStyle(
                                                color: Colors.black54,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          children: [
                                            const Icon(
                                              Icons.games,
                                              color: Colors.greenAccent,
                                              size: 24,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              '${widget.playerStats['pageTimes']?.length ?? 0}',
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const Text(
                                              'Épreuves',
                                              style: TextStyle(
                                                color: Colors.black54,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Message personnalisé
                              Text(
                                _getPersonalizedMessage(),
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 16,
                                  height: 1.5,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // Signature
                              Column(
                                children: [
                                  const Text(
                                    'Ce certificat atteste de la capacité à naviguer',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Text(
                                    'les défis éthiques et technologiques modernes',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Text(
                                    'avec discernement et réflexion.',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Container(
                                    width: 200,
                                    height: 2,
                                    color: Colors.black54,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Boutons d'action
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _shareCertificate,
                              icon: const Icon(Icons.share),
                              label: const Text('Partager'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                              },
                              icon: const Icon(Icons.home),
                              label: const Text('Accueil'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.greenAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
