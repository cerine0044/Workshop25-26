import 'dart:io';

void main() async {
  print('🌐 Pandora Box - Mode Multijoueur avec Tunnel');
  print('==============================================');
  
  print('📱 Cette solution utilise ngrok pour créer un tunnel public');
  print('🔗 L\'autre PC pourra se connecter via une URL publique');
  print('');
  print('🚀 Démarrage de l\'application...');
  print('================================');
  
  // Démarrer Flutter en mode web
  final flutterProcess = await Process.start(
    'flutter',
    ['run', '-d', 'web-server', '--web-port', '8081'],
    mode: ProcessStartMode.inheritStdio,
  );
  
  // Attendre un peu que Flutter démarre
  await Future.delayed(Duration(seconds: 10));
  
  print('');
  print('🌐 Démarrage du tunnel ngrok...');
  print('================================');
  
  // Démarrer ngrok
  final ngrokProcess = await Process.start(
    'ngrok',
    ['http', '8081'],
    mode: ProcessStartMode.inheritStdio,
  );
  
  print('');
  print('✅ Tunnel créé !');
  print('📱 Partagez l\'URL ngrok avec l\'autre PC');
  print('🔗 Exemple: https://abc123.ngrok.io');
  print('');
  print('Appuyez sur Ctrl+C pour arrêter');
  
  // Attendre que l'un des processus se termine
  await Future.any([
    flutterProcess.exitCode,
    ngrokProcess.exitCode,
  ]);
}
