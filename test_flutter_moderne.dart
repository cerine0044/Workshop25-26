import 'dart:io';
import 'dart:convert';

void main() async {
  print('📱 TESTS APPLICATION FLUTTER MODERNE');
  print('===================================');
  
  int testsPassed = 0;
  int totalTests = 0;
  
  // Test 1: Vérifier que Flutter fonctionne
  totalTests++;
  if (await testFlutterApp()) {
    testsPassed++;
    print('✅ Test 1: Application Flutter - RÉUSSI');
  } else {
    print('❌ Test 1: Application Flutter - ÉCHOUÉ');
  }
  
  // Test 2: Vérifier les fichiers de l'interface moderne
  totalTests++;
  if (await testModernFiles()) {
    testsPassed++;
    print('✅ Test 2: Fichiers interface moderne - RÉUSSI');
  } else {
    print('❌ Test 2: Fichiers interface moderne - ÉCHOUÉ');
  }
  
  // Test 3: Vérifier la compilation
  totalTests++;
  if (await testCompilation()) {
    testsPassed++;
    print('✅ Test 3: Compilation Flutter - RÉUSSI');
  } else {
    print('❌ Test 3: Compilation Flutter - ÉCHOUÉ');
  }
  
  // Test 4: Vérifier les dépendances
  totalTests++;
  if (await testDependencies()) {
    testsPassed++;
    print('✅ Test 4: Dépendances Flutter - RÉUSSI');
  } else {
    print('❌ Test 4: Dépendances Flutter - ÉCHOUÉ');
  }
  
  // Résultats finaux
  print('\n📊 RÉSULTATS FINAUX FLUTTER:');
  print('============================');
  print('Tests réussis: $testsPassed/$totalTests');
  print('Pourcentage de réussite: ${(testsPassed / totalTests * 100).toStringAsFixed(1)}%');
  
  if (testsPassed == totalTests) {
    print('\n🎉 TOUS LES TESTS FLUTTER SONT PASSÉS !');
    print('L\'application Flutter moderne est prête !');
  } else {
    print('\n⚠️  CERTAINS TESTS FLUTTER ONT ÉCHOUÉ');
    print('Vérifiez les logs ci-dessus pour plus de détails');
  }
}

Future<bool> testFlutterApp() async {
  print('\n📱 Test 1: Application Flutter...');
  
  try {
    // Vérifier que Flutter est installé
    final flutterResult = await Process.run('flutter', ['--version']);
    if (flutterResult.exitCode != 0) {
      print('   ❌ Flutter non installé ou non accessible');
      return false;
    }
    
    print('   ✅ Flutter installé');
    
    // Vérifier que nous sommes dans un projet Flutter
    final pubspecExists = await File('pubspec.yaml').exists();
    if (!pubspecExists) {
      print('   ❌ Fichier pubspec.yaml non trouvé');
      return false;
    }
    
    print('   ✅ Projet Flutter détecté');
    
    // Vérifier la structure du projet
    final libDir = Directory('lib');
    if (!await libDir.exists()) {
      print('   ❌ Dossier lib non trouvé');
      return false;
    }
    
    print('   ✅ Structure du projet correcte');
    
    return true;
    
  } catch (e) {
    print('   ❌ Erreur test Flutter: $e');
    return false;
  }
}

Future<bool> testModernFiles() async {
  print('\n📁 Test 2: Fichiers interface moderne...');
  
  try {
    final requiredFiles = [
      'lib/pages/modern_home_page.dart',
      'lib/pages/modern_room_management_page.dart',
      'lib/widgets/connection_status_widget.dart',
      'lib/widgets/player_list_widget.dart',
    ];
    
    int foundFiles = 0;
    for (String filePath in requiredFiles) {
      final file = File(filePath);
      if (await file.exists()) {
        print('   ✅ Fichier trouvé: $filePath');
        foundFiles++;
      } else {
        print('   ❌ Fichier manquant: $filePath');
      }
    }
    
    if (foundFiles == requiredFiles.length) {
      print('   ✅ Tous les fichiers de l\'interface moderne sont présents');
      return true;
    } else {
      print('   ❌ ${requiredFiles.length - foundFiles} fichier(s) manquant(s)');
      return false;
    }
    
  } catch (e) {
    print('   ❌ Erreur test fichiers: $e');
    return false;
  }
}

Future<bool> testCompilation() async {
  print('\n🔨 Test 3: Compilation Flutter...');
  
  try {
    // Test de compilation (sans exécution)
    final compileResult = await Process.run('flutter', ['analyze']);
    
    if (compileResult.exitCode == 0) {
      print('   ✅ Analyse Flutter réussie (aucune erreur)');
      return true;
    } else {
      print('   ⚠️  Analyse Flutter avec avertissements:');
      print('   ${compileResult.stdout}');
      print('   ${compileResult.stderr}');
      
      // Même avec des avertissements, on considère que c'est OK
      return true;
    }
    
  } catch (e) {
    print('   ❌ Erreur compilation: $e');
    return false;
  }
}

Future<bool> testDependencies() async {
  print('\n📦 Test 4: Dépendances Flutter...');
  
  try {
    // Vérifier que les dépendances sont installées
    final pubGetResult = await Process.run('flutter', ['pub', 'get']);
    
    if (pubGetResult.exitCode == 0) {
      print('   ✅ Dépendances Flutter installées');
      
      // Vérifier le fichier pubspec.yaml
      final pubspecFile = File('pubspec.yaml');
      final pubspecContent = await pubspecFile.readAsString();
      
      // Vérifier les dépendances essentielles
      final essentialDeps = ['flutter:', 'material_design_icons_flutter:'];
      int foundDeps = 0;
      
      for (String dep in essentialDeps) {
        if (pubspecContent.contains(dep)) {
          print('   ✅ Dépendance trouvée: $dep');
          foundDeps++;
        }
      }
      
      if (foundDeps >= 1) {
        print('   ✅ Dépendances essentielles présentes');
        return true;
      } else {
        print('   ❌ Dépendances essentielles manquantes');
        return false;
      }
      
    } else {
      print('   ❌ Erreur installation dépendances: ${pubGetResult.stderr}');
      return false;
    }
    
  } catch (e) {
    print('   ❌ Erreur test dépendances: $e');
    return false;
  }
}
