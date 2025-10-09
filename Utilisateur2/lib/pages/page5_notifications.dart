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
    _PopupAlert(title: 'CITATION', message: '\"Ce que tu pratiques grandit.\"', color: Colors.indigoAccent, icon: Icons.format_quote),
    _PopupAlert(title: 'MÉTÉO', message: 'Ouvre la fenêtre 30s, respire l\'air frais.', color: Colors.blueGrey, icon: Icons.sunny_snowing),
    _PopupAlert(title: 'APPLIS', message: 'Désactive 1 notification non essentielle.', color: Colors.purpleAccent, icon: Icons.notifications_off),
    _PopupAlert(title: 'SANTÉ', message: 'Étirer nuque et poignets 20s.', color: Colors.greenAccent, icon: Icons.health_and_safety),
    _PopupAlert(title: 'ARGENT', message: 'Regarde ton solde sans juger. Juste regarder.', color: Colors.redAccent, icon: Icons.account_balance_wallet),
    // Extra set (doublé)
    _PopupAlert(title: 'RESPIRATION 2', message: 'Fais 3 respirations profondes maintenant.', color: Colors.redAccent, icon: Icons.air),
    _PopupAlert(title: 'EAU 2', message: 'Une gorgée d\'eau en plus.', color: Colors.orange, icon: Icons.local_drink),
    _PopupAlert(title: 'ÉCRAN', message: 'Baisse légèrement la luminosité.', color: Colors.redAccent, icon: Icons.settings_display),
    _PopupAlert(title: 'RACCROCHE', message: 'Dis \"non\" à 1 interruption aujourd\'hui.', color: Colors.pink, icon: Icons.do_not_disturb_alt),
    _PopupAlert(title: 'SOCIAL', message: 'Envoie un message gentil à quelqu\'un.', color: Colors.deepPurple, icon: Icons.favorite),
    _PopupAlert(title: 'SOMMEIL', message: 'Prépare ton heure de coucher ce soir.', color: Colors.lightBlue, icon: Icons.bedtime),
    _PopupAlert(title: 'CITATION 2', message: '\"Moins mais mieux.\" — Dieter Rams', color: Colors.amber, icon: Icons.short_text),
    _PopupAlert(title: 'EMAIL 2', message: 'Désabonne-toi d\'une newsletter.', color: Colors.red, icon: Icons.unsubscribe),
    _PopupAlert(title: 'ORDRE', message: 'Range 1 objet. Un seul.', color: Colors.cyan, icon: Icons.checklist),
    _PopupAlert(title: 'MOT DE PASSE', message: 'Active un gestionnaire de mots de passe.', color: Colors.teal, icon: Icons.password),
    _PopupAlert(title: 'CITATION 3', message: '\"Le calme est une compétence.\"', color: Colors.indigo, icon: Icons.psychology),
    _PopupAlert(title: 'AIR', message: 'Prends 10s pour regarder au loin.', color: Colors.blueGrey, icon: Icons.landscape),
    _PopupAlert(title: 'NOTIFS', message: 'Coupe 1 alerte en double (mail + app).', color: Colors.purple, icon: Icons.notifications_paused),
    _PopupAlert(title: 'CALME', message: 'Ferme les yeux 30s. Respire.', color: Colors.green, icon: Icons.spa),
    _PopupAlert(title: 'DÉCONNEXION', message: 'Éteins ton téléphone 1h ce soir.', color: Colors.red, icon: Icons.phone_disabled),
    _PopupAlert(title: 'GRATITUDE', message: 'Note 3 choses positives de ta journée.', color: Colors.orange, icon: Icons.favorite),
  ];

  // Game state
  int _score = 0;
  int _dismissedCount = 0;
  bool _gameCompleted = false;
  Timer? _notificationTimer;
  int _notificationInterval = 3; // secondes entre les notifications
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _fxController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _startGameSession();
    _startNotificationTimer();
  }

  @override
  void dispose() {
    _fxController.dispose();
    _notificationTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _startGameSession() {
    if (!_statsService.isSessionActive) {
      _statsService.startGameSession(
        playerName: 'Joueur Solo',
        gameRoom: 'Gestion des Notifications',
      );
    }
  }

  void _startNotificationTimer() {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(
      Duration(seconds: _notificationInterval),
      (timer) {
        _addRandomNotification();
      },
    );
    
    // Première notification immédiate
    _addRandomNotification();
  }

  void _addRandomNotification() {
    if (_dismissedCount >= 20) { // Objectif de 20 notifications
      _endGame();
      return;
    }

    final randomNotification = _popups[math.Random().nextInt(_popups.length)];
    
    setState(() {
      _popups.insert(0, randomNotification);
    });

    // Accélérer le rythme des notifications
    if (_notificationInterval > 1) {
      _notificationInterval--;
      _notificationTimer?.cancel();
      _startNotificationTimer();
    }
  }

  void _dismissNotification(int index) {
    if (index >= _popups.length) return;
    
    setState(() {
      _popups[index].dismissed = true;
      _dismissedCount++;
      _score += 5;
    });

    // Animation et son
    _fxController.forward().then((_) => _fxController.reverse());
    
    // Supprimer la notification après animation
    Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _popups.removeAt(index);
        });
        
        // Vérifier si l'objectif est atteint après suppression
        if (_dismissedCount >= 20) {
          _endGame();
        }
      }
    });
  }

  void _endGame() async {
    _notificationTimer?.cancel();
    
    setState(() {
      _gameCompleted = true;
    });
    
    await _statsService.endGameSession(
      completed: true,
      score: _score,
      additionalData: {
        'notificationsDismissed': _dismissedCount,
        'totalNotifications': _popups.length + _dismissedCount,
        'efficiency': _dismissedCount / (_popups.length + _dismissedCount) * 100,
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
          '🎉 Session terminée !',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Vous avez géré $_dismissedCount notifications',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              'Score: $_score points',
              style: const TextStyle(
                color: Colors.green,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Efficacité: ${(_dismissedCount / (_popups.length + _dismissedCount) * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.cyan,
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
                MaterialPageRoute(builder: (context) => const CalmSuccessPage()),
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
    if (_gameCompleted) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // En-tête avec chronomètre et score
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gestion des Notifications',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Notifications traitées: $_dismissedCount/20',
                          style: const TextStyle(
                            color: Colors.cyan,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Score: $_score',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const GameTimerWidget(),
                ],
              ),
            ),
            
            // Liste des notifications
            Positioned(
              top: 100,
              left: 0,
              right: 0,
              bottom: 0,
              child: _popups.isEmpty
                  ? const Center(
                      child: Text(
                        'Aucune notification pour le moment...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _popups.length,
                      itemBuilder: (context, index) {
                        final notification = _popups[index];
                        
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => _dismissNotification(index),
                              borderRadius: BorderRadius.circular(12),
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: notification.dismissed ? 0.0 : 1.0,
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: notification.color.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: notification.color.withOpacity(0.3),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: notification.color.withOpacity(0.2),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: notification.color.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          notification.icon,
                                          color: notification.color,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              notification.title,
                                              style: TextStyle(
                                                color: notification.color,
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              notification.message,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.close,
                                        color: notification.color,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            
            // Barre de progression
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: LinearProgressIndicator(
                value: _dismissedCount / 20, // Objectif de 20 notifications
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(
                  _dismissedCount >= 20 ? Colors.green : Colors.cyan,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopupAlert {
  final String title;
  final String message;
  final Color color;
  final IconData icon;
  bool dismissed;

  _PopupAlert({
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
    this.dismissed = false,
  });
}