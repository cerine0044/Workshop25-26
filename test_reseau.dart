import 'dart:io';

void main() async {
  print('🔍 Test de Connectivité Réseau - Pandora Box');
  print('============================================');
  
  // Obtenir toutes les interfaces réseau
  final interfaces = await NetworkInterface.list();
  String? localIP;
  
  print('📡 Interfaces réseau détectées:');
  for (var interface in interfaces) {
    print('  Interface: ${interface.name}');
    for (var addr in interface.addresses) {
      if (addr.type == InternetAddressType.IPv4) {
        print('    IP: ${addr.address} (${addr.isLoopback ? 'localhost' : 'réseau'})');
        if (!addr.isLoopback && 
            !addr.address.startsWith('169.254') &&
            !addr.address.startsWith('127.')) {
          localIP = addr.address;
        }
      }
    }
  }
  
  if (localIP == null) {
    print('❌ Aucune IP réseau détectée');
    return;
  }
  
  print('');
  print('🌐 IP réseau principale: $localIP');
  print('');
  
  // Tester la connectivité sur différents ports
  final ports = [8085, 5002, 3000];
  
  for (int port in ports) {
    print('🔍 Test du port $port...');
    try {
      final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      print('✅ Port $port disponible');
      server.close();
    } catch (e) {
      print('❌ Port $port occupé: $e');
    }
  }
  
  print('');
  print('📋 Instructions pour l\'autre PC:');
  print('1. Vérifiez que vous êtes sur le même réseau WiFi');
  print('2. Essayez ces URLs dans l\'ordre:');
  print('   - http://$localIP:8085 (Application Flutter)');
  print('   - http://$localIP:5002 (API Backend)');
  print('   - http://$localIP:3000 (Test de connectivité)');
  print('');
  print('3. Si aucune ne fonctionne:');
  print('   - Vérifiez le firewall sur ce PC');
  print('   - Vérifiez que les deux PC sont sur le même réseau');
  print('   - Essayez de redémarrer le routeur WiFi');
  print('');
  print('4. Test depuis l\'autre PC:');
  print('   - Ouvrez un terminal sur l\'autre PC');
  print('   - Tapez: ping $localIP');
  print('   - Si ça marche, le problème est le firewall');
  print('   - Si ça ne marche pas, le problème est le réseau');
}
