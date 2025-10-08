import 'dart:io';

void main(List<String> args) async {
  print('🎮 Pandora Box - Client Multijoueur');
  print('==================================');
  print('📱 Mode: Client uniquement');
  print('🔌 Connexion au serveur WebSocket');
  print('');
  
  // Détecter l'IP du serveur
  String serverIP = '10.151.18.84'; // IP par défaut
  
  if (args.isNotEmpty) {
    serverIP = args[0];
  }
  
  print('📡 Serveur cible: $serverIP');
  print('🌐 URL: http://$serverIP:5001');
  print('🔌 WebSocket: ws://$serverIP:5002');
  print('');
  
  // Test de connectivité rapide
  print('🔍 Test de connectivité...');
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://$serverIP:5001'));
    final response = await request.close();
    
    if (response.statusCode == 200) {
      print('✅ Serveur accessible');
    } else {
      print('❌ Serveur non accessible (code: ${response.statusCode})');
      print('💡 Vérifiez que le serveur est démarré sur le PC 1');
      return;
    }
  } catch (e) {
    print('❌ Impossible de se connecter au serveur: $e');
    print('💡 Vérifiez:');
    print('   - Que le PC 1 a lancé le serveur');
    print('   - Que vous êtes sur le même réseau WiFi');
    print('   - Que l\'IP est correcte: $serverIP');
    return;
  }
  
  print('');
  print('🚀 Lancement du client Flutter...');
  print('📱 L\'application sera accessible sur: http://localhost:8081');
  print('');
  
  // Démarrer Flutter
  final process = await Process.start('flutter', [
    'run', 
    '-d', 
    'web-server', 
    '--web-port', 
    '8081', 
    '--web-hostname', 
    '0.0.0.0'
  ]);
  
  // Afficher la sortie en temps réel
  process.stdout.listen((data) {
    print(String.fromCharCodes(data));
  });
  
  process.stderr.listen((data) {
    print('❌ Erreur: ${String.fromCharCodes(data)}');
  });
  
  // Gérer l'arrêt propre
  ProcessSignal.sigint.watch().listen((signal) {
    print('\n🛑 Arrêt du client...');
    process.kill();
    exit(0);
  });
  
  // Attendre que le processus se termine
  await process.exitCode;
}
