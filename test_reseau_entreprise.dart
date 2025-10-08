import 'dart:io';
import 'dart:convert';

void main() async {
  print('🌐 Test de connectivité réseau d\'entreprise');
  print('==========================================');
  
  final serverIP = '10.151.18.84';
  final httpPort = 5001;
  final wsPort = 5002;
  
  print('📡 Serveur: $serverIP');
  print('🌐 HTTP: http://$serverIP:$httpPort');
  print('🔌 WebSocket: ws://$serverIP:$wsPort');
  print('');
  
  // Test HTTP
  print('📡 Test HTTP...');
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://$serverIP:$httpPort'));
    final response = await request.close();
    
    if (response.statusCode == 200) {
      print('✅ Serveur HTTP accessible');
      
      // Lire le contenu pour vérifier
      final content = await response.transform(utf8.decoder).join();
      if (content.contains('WebSocket')) {
        print('✅ Page WebSocket détectée');
      }
    } else {
      print('❌ Serveur HTTP répond avec le code: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Erreur HTTP: $e');
    print('💡 Vérifiez que le serveur est démarré et que vous êtes sur le même réseau');
  }
  
  // Test WebSocket
  print('');
  print('🔌 Test WebSocket...');
  try {
    final webSocket = await WebSocket.connect('ws://$serverIP:$wsPort');
    print('✅ Connexion WebSocket établie');
    
    // Envoyer un message de test
    final testMessage = {
      'type': 'connect',
      'userId': 'test_user_${DateTime.now().millisecondsSinceEpoch}',
    };
    
    webSocket.add(jsonEncode(testMessage));
    print('📤 Message envoyé: ${jsonEncode(testMessage)}');
    
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
  
  print('');
  print('🎯 Instructions pour le deuxième PC:');
  print('1. Ouvrez http://$serverIP:$httpPort dans un navigateur');
  print('2. Créez une room de test');
  print('3. Sur l\'autre PC, rejoignez la room');
  print('4. Les mises à jour seront en temps réel !');
  print('');
  print('📱 Pour Flutter:');
  print('- HTTP: http://$serverIP:$httpPort');
  print('- WebSocket: ws://$serverIP:$wsPort');
}
