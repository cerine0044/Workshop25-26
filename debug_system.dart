import 'dart:io';
import 'dart:convert';

void main() async {
  print('🔍 Débogage Système Multijoueur WebSocket');
  print('========================================');
  
  // 1. Vérifier l'IP réseau
  print('📡 1. Vérification de l\'IP réseau...');
  final interfaces = await NetworkInterface.list();
  String? networkIP;
  
  for (var interface in interfaces) {
    for (var addr in interface.addresses) {
      if (addr.type == InternetAddressType.IPv4 && 
          !addr.isLoopback && 
          !addr.address.startsWith('169.254') &&
          !addr.address.startsWith('127.')) {
        networkIP = addr.address;
        print('✅ IP réseau détectée: $networkIP');
        break;
      }
    }
    if (networkIP != null) break;
  }
  
  if (networkIP == null) {
    print('❌ Aucune IP réseau détectée');
    return;
  }
  
  // 2. Vérifier les ports
  print('\n🔌 2. Vérification des ports...');
  final ports = [
    {'port': 5001, 'service': 'Serveur HTTP'},
    {'port': 5002, 'service': 'Serveur WebSocket'},
    {'port': 8080, 'service': 'Flutter PC1'},
    {'port': 8081, 'service': 'Flutter PC2'},
    {'port': 8082, 'service': 'Flutter PC1 Alt'},
  ];
  
  for (final portInfo in ports) {
    final port = portInfo['port'] as int;
    final service = portInfo['service'] as String;
    
    try {
      final socket = await Socket.connect('localhost', port, timeout: Duration(seconds: 1));
      socket.destroy();
      print('✅ Port $port ($service): OCCUPÉ');
    } catch (e) {
      print('❌ Port $port ($service): LIBRE');
    }
  }
  
  // 3. Test de connectivité serveur
  print('\n🌐 3. Test de connectivité serveur...');
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://$networkIP:5001'));
    final response = await request.close();
    
    if (response.statusCode == 200) {
      print('✅ Serveur HTTP accessible sur $networkIP:5001');
      
      // Lire le contenu pour vérifier
      final content = await response.transform(utf8.decoder).join();
      if (content.contains('WebSocket')) {
        print('✅ Page WebSocket détectée');
      }
    } else {
      print('❌ Serveur HTTP répond avec code: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Serveur HTTP non accessible: $e');
    print('💡 Le serveur WebSocket n\'est probablement pas démarré');
  }
  
  // 4. Test WebSocket
  print('\n🔌 4. Test WebSocket...');
  try {
    final webSocket = await WebSocket.connect('ws://$networkIP:5002');
    print('✅ Connexion WebSocket établie');
    
    // Envoyer un message de test
    webSocket.add('{"type":"ping"}');
    print('📤 Message ping envoyé');
    
    // Écouter les réponses
    webSocket.listen(
      (message) {
        print('📨 Message reçu: $message');
      },
      onError: (error) {
        print('❌ Erreur WebSocket: $error');
      },
      onDone: () {
        print('🔌 Connexion WebSocket fermée');
      },
    );
    
    // Attendre quelques secondes
    await Future.delayed(Duration(seconds: 2));
    
    // Fermer la connexion
    await webSocket.close();
    print('✅ Test WebSocket terminé avec succès');
    
  } catch (e) {
    print('❌ Erreur WebSocket: $e');
    print('💡 Vérifiez que le serveur WebSocket est démarré');
  }
  
  // 5. Instructions
  print('\n📋 5. Instructions de débogage:');
  print('==============================');
  
  if (networkIP != null) {
    print('🌐 IP du réseau: $networkIP');
    print('📡 Serveur HTTP: http://$networkIP:5001');
    print('🔌 Serveur WebSocket: ws://$networkIP:5002');
    print('');
    print('🚀 Pour démarrer le serveur:');
    print('   dart websocket_server.dart');
    print('');
    print('📱 Pour démarrer le client PC1:');
    print('   dart lanceur.dart complet');
    print('');
    print('📱 Pour démarrer le client PC2:');
    print('   dart client_seul.dart');
    print('');
    print('🧪 Pour tester la connectivité:');
    print('   dart test_reseau_entreprise.dart');
  }
  
  print('\n✅ Débogage terminé');
}
