import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:workshop_25_26/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Test de bout en bout - Mode Solo', () {
    testWidgets('Test du menu de sélection des jeux solo', (WidgetTester tester) async {
      // Lance l'application
      app.main();
      await tester.pumpAndSettle();

      // Vérifie que l'application se lance correctement
      expect(find.text('Pandora Box'), findsOneWidget);
      
      // Clique sur le bouton "Jouer Maintenant"
      await tester.tap(find.text('Jouer Maintenant'));
      await tester.pumpAndSettle();

      // Vérifie que le menu de sélection s'ouvre
      expect(find.text('Choisissez un jeu'), findsOneWidget);

      // Vérifie que les nouveaux noms avec emojis sont présents
      expect(find.text('🧩 Défi Puzzle'), findsOneWidget);
      expect(find.text('🧠 Détecteur de Stress'), findsOneWidget);
      expect(find.text('📝 Mots Croisés'), findsOneWidget);
      expect(find.text('🚊 Jeu du Tram'), findsOneWidget);
      expect(find.text('🔔 Notifications'), findsOneWidget);

      // Vérifie que la page succès n'est plus dans le menu
      expect(find.text('Page de Succès'), findsNothing);

      // Vérifie que la section scores est séparée
      expect(find.text('Scores et Statistiques'), findsOneWidget);
      expect(find.text('Voir mes scores'), findsOneWidget);

      // Teste l'accès aux règles du jeu
      await tester.tap(find.text('Règles du jeu'));
      await tester.pumpAndSettle();

      // Vérifie que les règles sont adaptées au mode solo
      expect(find.text('Règles du jeu'), findsOneWidget);
      expect(find.text('Défi Puzzle Solo'), findsOneWidget);
      expect(find.text('Mots Croisés Solo'), findsOneWidget);
      expect(find.text('Simulation Tram Solo'), findsOneWidget);
      expect(find.text('Détecteur de Stress Solo'), findsOneWidget);
      expect(find.text('Gestion Notifications Solo'), findsOneWidget);

      // Vérifie le message sur le mode solo
      expect(find.text('Mode Solo - Temps limité : 3 minutes'), findsOneWidget);
      expect(find.text('Chaque jeu solo vous permet de développer vos compétences individuellement'), findsOneWidget);

      print('✅ Tous les tests de bout en bout sont passés avec succès !');
    });

    testWidgets('Test de navigation vers un jeu solo', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Ouvre le menu de sélection
      await tester.tap(find.text('Jouer Maintenant'));
      await tester.pumpAndSettle();

      // Clique sur le jeu Puzzle
      await tester.tap(find.text('🧩 Défi Puzzle'));
      await tester.pumpAndSettle();

      // Vérifie que la page Puzzle s'ouvre
      expect(find.text('Puzzle'), findsOneWidget);

      print('✅ Navigation vers le jeu Puzzle réussie !');
    });

    testWidgets('Test de la section scores séparée', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Ouvre le menu de sélection
      await tester.tap(find.text('Jouer Maintenant'));
      await tester.pumpAndSettle();

      // Clique sur "Voir mes scores"
      await tester.tap(find.text('Voir mes scores'));
      await tester.pumpAndSettle();

      // Vérifie que la page des scores s'ouvre
      expect(find.text('SCORES FINAUX'), findsOneWidget);

      print('✅ Accès à la section scores réussi !');
    });
  });
}
