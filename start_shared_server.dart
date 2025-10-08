import 'dart:io';
import 'lib/services/shared_local_service.dart';

void main() async {
  print('🚀 Démarrage du serveur partagé pour Pandora Box...');
  
  final service = SharedLocalService();
  await service.initialize();
  
  print('✅ Serveur démarré !');
  print('📱 Les autres PC peuvent maintenant se connecter à cette machine');
  print('🌐 Adresse: http://${_getLocalIP()}:8080');
  print('🔧 Port du serveur de données: 8081');
  print('\nAppuyez sur Ctrl+C pour arrêter le serveur');
  
  // Garder le programme en vie
  await Process.run('flutter', ['run', '-d', 'web-server', '--web-port', '8080']);
}

String _getLocalIP() {
  for (var interface in NetworkInterface.list()) {
    for (var addr in interface.addresses) {
      if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
        return addr.address;
      }
    }
  }
  return 'localhost';
}
