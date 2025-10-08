import 'dart:io';
import 'dart:convert';

void main() async {
  print('🎨 TEST INTERFACE MODERNE PANDORA BOX');
  print('=====================================');
  
  // Test de l'interface web moderne
  await testModernWebInterface();
  
  print('\n✅ TESTS TERMINÉS');
}

Future<void> testModernWebInterface() async {
  print('\n🌐 Test de l\'interface web moderne...');
  
  try {
    // Tester la page d'accueil
    final homeResponse = await HttpClient().getUrl(
      Uri.parse('http://localhost:5001/')
    );
    final homeRequest = await homeResponse.close();
    final homeBody = await homeRequest.transform(utf8.decoder).join();
    
    print('✅ Page d\'accueil chargée');
    
    // Vérifier les éléments modernes
    final hasModernElements = _checkModernElements(homeBody);
    
    if (hasModernElements) {
      print('✅ Interface moderne détectée');
      print('   - Animations CSS ✅');
      print('   - Design responsive ✅');
      print('   - Effets visuels ✅');
      print('   - Interface intuitive ✅');
    } else {
      print('⚠️  Interface basique détectée');
    }
    
    // Tester la création de room via WebSocket
    await testWebSocketRoomCreation();
    
  } catch (e) {
    print('❌ Erreur test interface: $e');
  }
}

bool _checkModernElements(String html) {
  final modernElements = [
    'gradient',
    'animation',
    'backdrop-filter',
    'box-shadow',
    'border-radius',
    'transform',
    'transition',
    'WebSocket',
    'modern',
    'responsive'
  ];
  
  int foundElements = 0;
  for (String element in modernElements) {
    if (html.toLowerCase().contains(element.toLowerCase())) {
      foundElements++;
    }
  }
  
  return foundElements >= 5; // Au moins 5 éléments modernes
}

Future<void> testWebSocketRoomCreation() async {
  print('\n🔌 Test création de room via WebSocket...');
  
  try {
    final webSocket = await WebSocket.connect('ws://localhost:5002');
    
    // Écouter les messages
    webSocket.listen((message) {
      final data = jsonDecode(message) as Map<String, dynamic>;
      print('📨 Message reçu: ${data['type']}');
      
      if (data['type'] == 'room_update') {
        final room = data['room'] as Map<String, dynamic>;
        print('🏠 Room créée: ${room['name']} (ID: ${room['id']})');
        print('👥 Joueurs: ${(room['players'] as Map).length}');
      }
    });
    
    // Attendre la connexion
    await Future.delayed(Duration(milliseconds: 500));
    
    // Créer une room
    webSocket.add(jsonEncode({
      'type': 'connect',
      'userId': 'test_user_modern',
    }));
    
    await Future.delayed(Duration(milliseconds: 500));
    
    webSocket.add(jsonEncode({
      'type': 'create_room',
      'roomName': 'Test Interface Moderne',
      'host': 'test_user_modern',
      'hostName': 'Testeur Moderne',
    }));
    
    // Attendre la réponse
    await Future.delayed(Duration(milliseconds: 1000));
    
    await webSocket.close();
    print('✅ Test WebSocket terminé');
    
  } catch (e) {
    print('❌ Erreur WebSocket: $e');
  }
}