import 'package:flutter/material.dart';
import '../pages/start_page.dart';
import '../pages/page1_puzzle.dart';
import '../pages/stress_page.dart';
import '../pages/page3_crossword.dart';
import '../pages/page4_tram.dart';
import '../pages/page5_notifications.dart';
import '../pages/page5_success.dart';

class GameNavigation {
  static const String startRoute = '/start';
  static const String page1Route = '/page1';
  static const String page2Route = '/page2';
  static const String page3Route = '/page3';
  static const String page4Route = '/page4';
  static const String page5Route = '/page5';
  static const String successRoute = '/success';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case startRoute:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => StartPage(
            isMultiplayer: args?['isMultiplayer'] ?? false,
            roomId: args?['roomId'],
          ),
        );
      
      case page1Route:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => Page1Puzzle(
            isMultiplayer: args?['isMultiplayer'] ?? false,
            roomId: args?['roomId'],
          ),
        );
      
      case page2Route:
        return MaterialPageRoute(
          builder: (_) => const StressPage(),
        );
      
      case page3Route:
        return MaterialPageRoute(
          builder: (_) => const Page3Crossword(),
        );
      
      case page4Route:
        return MaterialPageRoute(
          builder: (_) => const Page4Tram(),
        );
      
      case page5Route:
        return MaterialPageRoute(
          builder: (_) => const Page5Notifications(),
        );
      
      case successRoute:
        return MaterialPageRoute(
          builder: (_) => const CalmSuccessPage(),
        );
      
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Page non trouvée'),
            ),
          ),
        );
    }
  }

  // Méthodes utilitaires pour naviguer entre les pages
  static void goToStart(BuildContext context, {bool isMultiplayer = false, String? roomId}) {
    Navigator.of(context).pushReplacementNamed(
      startRoute,
      arguments: {'isMultiplayer': isMultiplayer, 'roomId': roomId},
    );
  }

  static void goToPage1(BuildContext context, {bool isMultiplayer = false, String? roomId}) {
    Navigator.of(context).pushReplacementNamed(
      page1Route,
      arguments: {'isMultiplayer': isMultiplayer, 'roomId': roomId},
    );
  }

  static void goToPage2(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(page2Route);
  }

  static void goToPage3(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(page3Route);
  }

  static void goToPage4(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(page4Route);
  }

  static void goToPage5(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(page5Route);
  }

  static void goToSuccess(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(successRoute);
  }

  // Méthode pour obtenir le nom de la page actuelle
  static String getPageName(String routeName) {
    switch (routeName) {
      case startRoute:
        return 'Page de démarrage';
      case page1Route:
        return 'Page 1 - Boutons cachés';
      case page2Route:
        return 'Page 2 - Détecteur de stress';
      case page3Route:
        return 'Page 3 - Mots fléchés RGPD';
      case page4Route:
        return 'Page 4 - Dilemme du tramway';
      case page5Route:
        return 'Page 5 - Notifications';
      case successRoute:
        return 'Page de succès';
      default:
        return 'Page inconnue';
    }
  }
}
