import 'dart:io';
import 'dart:convert';

void main() async {
  print('🌐 Pandora Box - Accès Distant');
  print('==============================');
  
  // Obtenir l'IP locale
  final interfaces = await NetworkInterface.list();
  String? localIP;
  
  for (var interface in interfaces) {
    for (var addr in interface.addresses) {
      if (addr.type == InternetAddressType.IPv4 && 
          !addr.isLoopback && 
          !addr.address.startsWith('169.254') &&
          !addr.address.startsWith('127.')) {
        localIP = addr.address;
        break;
      }
    }
    if (localIP != null) break;
  }
  
  if (localIP == null) {
    localIP = '192.0.0.2'; // IP par défaut du hotspot
  }
  
  print('📱 IP détectée: $localIP');
  print('🌐 URL à partager: http://$localIP:8081');
  print('');
  print('🎮 Instructions pour l\'autre PC:');
  print('1. Connectez-vous au même réseau WiFi');
  print('2. Ouvrez un navigateur sur l\'autre PC');
  print('3. Allez à: http://$localIP:8081');
  print('4. L\'application Pandora Box devrait s\'ouvrir');
  print('');
  print('🚀 Démarrage de l\'application Flutter...');
  print('========================================');
  
  // Démarrer Flutter en mode web avec accès distant
  final process = await Process.start(
    'flutter',
    [
      'run', 
      '-d', 'web-server', 
      '--web-port', '8081', 
      '--web-hostname', '0.0.0.0',
      '--web-browser-flag', '--disable-web-security',
      '--web-browser-flag', '--disable-features=VizDisplayCompositor'
    ],
    mode: ProcessStartMode.inheritStdio,
  );
  
  // Attendre que le processus se termine
  await process.exitCode;
}
