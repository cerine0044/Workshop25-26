import 'package:flutter/material.dart';
import '../services/global_score_service.dart';
import '../widgets/score_display_widget.dart';
import 'page1_puzzle.dart';
import 'stress_page.dart';
import 'page3_crossword.dart';
import 'page4_tram.dart';
import 'page5_notifications.dart';
import 'page5_success.dart';
import 'enhanced_room_page.dart';
import 'final_score_page.dart';

class SimpleHomePage extends StatefulWidget {
  const SimpleHomePage({super.key});

  @override
  State<SimpleHomePage> createState() => _SimpleHomePageState();
}

class _SimpleHomePageState extends State<SimpleHomePage> {
  final GlobalScoreService _scoreService = GlobalScoreService();

  @override
  void initState() {
    super.initState();
    _scoreService.startSession();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          'Pandora Box',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.blue.shade600,
        elevation: 2,
        actions: [
          const ScoreDisplayWidget(compact: true),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // En-tête simple
            _buildHeader(),
            
            const SizedBox(height: 24),
            
            // Section Solo
            _buildSection(
              title: 'Mode Solo',
              subtitle: 'Jouez seul aux différents jeux',
              children: [
                _buildGameCard(
                  title: 'Puzzle',
                  icon: Icons.extension,
                  color: Colors.blue,
                  onTap: () => _navigateToPage('Puzzle', const Page1Puzzle()),
                ),
                _buildGameCard(
                  title: 'Détecteur de Stress',
                  icon: Icons.psychology,
                  color: Colors.red,
                  onTap: () => _navigateToPage('Stress', const StressPage()),
                ),
                _buildGameCard(
                  title: 'Mots Croisés',
                  icon: Icons.grid_on,
                  color: Colors.green,
                  onTap: () => _navigateToPage('Mots Croisés', const Page3Crossword()),
                ),
                _buildGameCard(
                  title: 'Jeu du Tram',
                  icon: Icons.train,
                  color: Colors.orange,
                  onTap: () => _navigateToPage('Tram', const Page4Tram()),
                ),
                _buildGameCard(
                  title: 'Notifications',
                  icon: Icons.notifications,
                  color: Colors.purple,
                  onTap: () => _navigateToPage('Notifications', const Page5Notifications()),
                ),
                _buildGameCard(
                  title: 'Page de Succès',
                  icon: Icons.emoji_events,
                  color: Colors.amber,
                  onTap: () => _navigateToPage('Succès', const CalmSuccessPage()),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Section Multijoueur
            _buildSection(
              title: 'Mode Multijoueur',
              subtitle: 'Jouez avec d\'autres joueurs',
              children: [
                _buildGameCard(
                  title: 'Salles de Jeu',
                  icon: Icons.people,
                  color: Colors.teal,
                  onTap: () => _navigateToPage('Multijoueur', const EnhancedRoomPage()),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Section Scores
            _buildSection(
              title: 'Scores et Statistiques',
              subtitle: 'Consultez vos performances',
              children: [
                _buildGameCard(
                  title: 'Scores Finaux',
                  icon: Icons.analytics,
                  color: Colors.indigo,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const FinalScorePage()),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.games,
            size: 48,
            color: Colors.blue.shade600,
          ),
          const SizedBox(height: 12),
          Text(
            'Bienvenue dans Pandora Box',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Choisissez votre mode de jeu et amusez-vous !',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          children: children,
        ),
      ],
    );
  }

  Widget _buildGameCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToPage(String pageName, Widget page) {
    _scoreService.startPage(pageName);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    ).then((_) {
      _scoreService.endPage(pageName);
    });
  }
}
