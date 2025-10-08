import 'dart:io';

void main(List<String> args) async {
  print('🎮 Pandora Box - Lanceur Multijoueur');
  print('===================================');
  
  if (args.isEmpty) {
    print('📋 Usage:');
    print('  dart lanceur.dart serveur    # Lance le serveur WebSocket');
    print('  dart lanceur.dart client     # Lance le client Flutter');
    print('  dart lanceur.dart complet    # Lance serveur + client');
    print('');
    print('💡 Exemple:');
    print('  PC1: dart lanceur.dart complet');
    print('  PC2: dart lanceur.dart client');
    return;
  }
  
  final mode = args[0].toLowerCase();
  
  switch (mode) {
    case 'serveur':
      await _lancerServeur();
      break;
    case 'client':
      await _lancerClient();
      break;
    case 'complet':
      await _lancerComplet();
      break;
    default:
      print('❌ Mode invalide: $mode');
      print('Modes disponibles: serveur, client, complet');
  }
}

Future<void> _lancerServeur() async {
  print('🚀 Lancement du serveur WebSocket...');
  print('📡 Le serveur sera accessible sur le réseau');
  print('🔌 Les autres PC pourront se connecter');
  print('');
  
  // Démarrer le serveur WebSocket
  final process = await Process.start('dart', ['websocket_server.dart']);
  
  // Afficher la sortie en temps réel
  process.stdout.listen((data) {
    print(String.fromCharCodes(data));
  });
  
  process.stderr.listen((data) {
    print('❌ Erreur: ${String.fromCharCodes(data)}');
  });
  
  // Attendre que le processus se termine
  await process.exitCode;
}

Future<void> _lancerClient() async {
  print('📱 Lancement du client Flutter...');
  print('🔌 Connexion au serveur WebSocket...');
  print('');
  
  // Démarrer Flutter
  final process = await Process.start('flutter', ['run', '-d', 'web-server', '--web-port', '8082', '--web-hostname', '0.0.0.0']);
  
  // Afficher la sortie en temps réel
  process.stdout.listen((data) {
    print(String.fromCharCodes(data));
  });
  
  process.stderr.listen((data) {
    print('❌ Erreur: ${String.fromCharCodes(data)}');
  });
  
  // Attendre que le processus se termine
  await process.exitCode;
}

Future<void> _lancerComplet() async {
  print('🎯 Lancement complet: Serveur + Client');
  print('=====================================');
  print('');
  
  print('🚀 Étape 1: Démarrage du serveur WebSocket...');
  
  // Démarrer le serveur en arrière-plan
  final serveurProcess = await Process.start('dart', ['websocket_server.dart']);
  
  // Attendre un peu que le serveur démarre
  await Future.delayed(Duration(seconds: 3));
  
  print('✅ Serveur WebSocket démarré');
  print('');
  
  print('📱 Étape 2: Démarrage du client Flutter...');
  
  // Démarrer Flutter
  final clientProcess = await Process.start('flutter', ['run', '-d', 'web-server', '--web-port', '8082', '--web-hostname', '0.0.0.0']);
  
  // Afficher la sortie du client
  clientProcess.stdout.listen((data) {
    print(String.fromCharCodes(data));
  });
  
  clientProcess.stderr.listen((data) {
    print('❌ Erreur Flutter: ${String.fromCharCodes(data)}');
  });
  
  // Gérer l'arrêt propre
  ProcessSignal.sigint.watch().listen((signal) {
    print('\n🛑 Arrêt en cours...');
    serveurProcess.kill();
    clientProcess.kill();
    exit(0);
  });
  
  // Attendre que le client se termine
  await clientProcess.exitCode;
  
  // Arrêter le serveur quand le client s'arrête
  serveurProcess.kill();
}
