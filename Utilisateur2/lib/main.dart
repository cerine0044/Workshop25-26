import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'pages/eco_stress_home_page.dart';
import 'pages/fallback_home_page.dart';
import 'pages/error_page.dart';
import 'pages/loading_page.dart';
import 'services/firebase_multiplayer_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  bool firebaseInitialized = false;
  String? errorMessage;
  
  try {
    // Initialiser Firebase d'abord
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Puis initialiser les services
    await FirebaseMultiplayerService().initialize();
    
    firebaseInitialized = true;
    print('✅ Firebase et services initialisés avec succès');
  } catch (e) {
    print('❌ Erreur initialisation Firebase: $e');
    firebaseInitialized = false;
    errorMessage = e.toString();
    
    // Si c'est une erreur de configuration Firebase, on peut continuer en mode fallback
    if (e.toString().contains('configuration-not-found')) {
      print('⚠️ Mode fallback activé - Firebase Auth non configuré');
      firebaseInitialized = true; // On considère que c'est OK pour le mode fallback
      errorMessage = null;
    }
  }
  
  runApp(PandoraBoxApp(
    firebaseInitialized: firebaseInitialized,
    errorMessage: errorMessage,
  ));
}

class PandoraBoxApp extends StatelessWidget {
  final bool firebaseInitialized;
  final String? errorMessage;
  
  const PandoraBoxApp({
    super.key, 
    required this.firebaseInitialized,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pandora Box - Jeu Multijoueur',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B0000), // Rouge foncé
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B0000),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            shadowColor: const Color(0xFF8B0000).withOpacity(0.3),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white.withOpacity(0.05),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.1),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: Color(0xFF8B0000),
              width: 2,
            ),
          ),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
          labelStyle: const TextStyle(color: Colors.white),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 32,
          ),
          headlineMedium: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
          headlineSmall: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          bodyLarge: TextStyle(color: Colors.white, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.white, fontSize: 14),
          bodySmall: TextStyle(color: Colors.white, fontSize: 12),
        ),
      ),
      home: _getHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
  
  Widget _getHomePage() {
    if (firebaseInitialized) {
      return const EcoStressHomePage();
    } else if (errorMessage != null && errorMessage!.contains('configuration-not-found')) {
      // Erreur d'authentification Firebase - utiliser le mode fallback
      return const FallbackHomePage();
    } else if (errorMessage != null) {
      // Autre erreur - afficher la page d'erreur
      return ErrorPage(errorMessage: errorMessage);
    } else {
      // Pas d'erreur mais pas initialisé - afficher la page de chargement
      return const LoadingPage();
    }
  }
}