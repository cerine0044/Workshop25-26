import 'dart:io';

void main() async {
  print('🎮 Pandora Box - Mode Multijoueur');
  print('================================');
  
  // Obtenir l'IP locale
  String localIP = _getLocalIP();
  
  print('📱 Adresse de cette machine: http://$localIP:8080');
  print('🔗 Partagez cette adresse avec les autres joueurs');
  print('🌐 Ou utilisez localhost si vous testez sur la même machine');
  print('');
  print('🚀 Démarrage de l\'application...');
  print('================================');
  
  // Démarrer Flutter en mode web
  final process = await Process.start(
    'flutter',
    ['run', '-d', 'web-server', '--web-port', '8080', '--web-hostname', '0.0.0.0'],
    mode: ProcessStartMode.inheritStdio,
  );
  
  await process.exitCode;
}

String _getLocalIP() {
  for (var interface in NetworkInterface.list()) {
    for (var addr in interface.addresses) {
      if (addr.type == InternetAddressType.IPv4 && 
          !addr.isLoopback && 
          !addr.address.startsWith('169.254')) {
        return addr.address;
      }
    }
  }
  return 'localhost';
}
