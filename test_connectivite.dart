import 'dart:io';
import 'dart:convert';

void main() async {
  print('🌐 Test de Connectivité Réseau - Pandora Box');
  print('==========================================');
  
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
    localIP = '10.151.18.84';
  }
  
  print('📱 IP locale détectée: $localIP');
  print('');
  
  // Test des ports
  final ports = [5001, 5002, 8084, 8085];
  print('🔍 Test des ports...');
  
  for (final port in ports) {
    final isOpen = await _testPort(localIP, port);
    final status = isOpen ? '✅ Ouvert' : '❌ Fermé';
    print('   Port $port: $status');
  }
  
  print('');
  
  // Test de connectivité réseau
  print('🌐 Test de connectivité réseau...');
  await _testNetworkConnectivity(localIP);
  
  print('');
  print('📋 Instructions pour tester sur un autre PC:');
  print('1. Connectez-vous au même réseau WiFi');
  print('2. Ouvrez un terminal/command prompt');
  print('3. Testez la connectivité:');
  print('   ping $localIP');
  print('4. Testez les ports:');
  for (final port in ports) {
    print('   telnet $localIP $port');
  }
  print('5. Ou utilisez le client de test:');
  print('   dart run test_client.dart');
  print('');
  print('🎮 URLs à partager:');
  print('   WebSocket: ws://$localIP:5002');
  print('   Application: http://$localIP:8085');
}

Future<bool> _testPort(String host, int port) async {
  try {
    final socket = await Socket.connect(host, port, timeout: Duration(seconds: 3));
    await socket.close();
    return true;
  } catch (e) {
    return false;
  }
}

Future<void> _testNetworkConnectivity(String localIP) async {
  // Test ping local
  try {
    final result = await Process.run('ping', ['-c', '1', localIP]);
    if (result.exitCode == 0) {
      print('✅ Ping local réussi');
    } else {
      print('❌ Ping local échoué');
    }
  } catch (e) {
    print('❌ Erreur ping local: $e');
  }
  
  // Test des interfaces réseau
  print('📡 Interfaces réseau disponibles:');
  final interfaces = await NetworkInterface.list();
  for (final interface in interfaces) {
    print('   ${interface.name}:');
    for (final addr in interface.addresses) {
      if (addr.type == InternetAddressType.IPv4) {
        final type = addr.isLoopback ? 'Loopback' : 'Réseau';
        print('     $type: ${addr.address}');
      }
    }
  }
  
  // Test de résolution DNS
  try {
    final addresses = await InternetAddress.lookup('google.com');
    if (addresses.isNotEmpty) {
      print('✅ Résolution DNS fonctionnelle');
    } else {
      print('❌ Résolution DNS échouée');
    }
  } catch (e) {
    print('❌ Erreur résolution DNS: $e');
  }
}