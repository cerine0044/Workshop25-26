import 'dart:io';
import 'dart:convert';

void main() async {
  print('🧪 Test de connectivité WebSocket');
  print('================================');
  
  // Test de connectivité HTTP
  print('📡 Test HTTP...');
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://192.0.0.2:5001'));
    final response = await request.close();
    
    if (response.statusCode == 200) {
      print('✅ Serveur HTTP accessible sur le port 5001');
    } else {
      print('❌ Serveur HTTP répond avec le code: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Erreur HTTP: $e');
  }
  
  // Test de connectivité WebSocket
  print('🔌 Test WebSocket...');
  try {
    final webSocket = await WebSocket.connect('ws://192.0.0.2:5002');
    print('✅ Connexion WebSocket établie');
    
    // Envoyer un message de test
    webSocket.add(jsonEncode({
      'type': 'connect',
      'userId': 'test_user_${DateTime.now().millisecondsSinceEpoch}',
    }));
    
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
    await Future.delayed(Duration(seconds: 3));
    
    // Fermer la connexion
    await webSocket.close();
    print('✅ Test WebSocket terminé avec succès');
    
  } catch (e) {
    print('❌ Erreur WebSocket: $e');
  }
  
  print('');
  print('🎯 Résumé:');
  print('- Serveur HTTP: http://192.0.0.2:5001');
  print('- Serveur WebSocket: ws://192.0.0.2:5002');
  print('- Votre application Flutter peut maintenant utiliser WebSocket !');
}
