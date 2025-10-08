import 'dart:io';

void main() async {
  print('🧪 Test de connectivité - Ports disponibles');
  print('==========================================');
  
  // Vérifier les ports utilisés
  print('📡 Vérification des ports...');
  
  final ports = [5001, 5002, 8080, 8081, 8082];
  
  for (final port in ports) {
    try {
      final socket = await Socket.connect('localhost', port, timeout: Duration(seconds: 1));
      socket.destroy();
      print('✅ Port $port: OCCUPÉ');
    } catch (e) {
      print('❌ Port $port: LIBRE');
    }
  }
  
  print('');
  print('🌐 Test de connectivité serveur...');
  
  try {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse('http://10.151.18.84:5001'));
    final response = await request.close();
    
    if (response.statusCode == 200) {
      print('✅ Serveur WebSocket accessible');
    } else {
      print('❌ Serveur répond avec code: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Serveur non accessible: $e');
  }
  
  print('');
  print('📋 Résumé des ports:');
  print('- 5001: Serveur HTTP');
  print('- 5002: Serveur WebSocket');
  print('- 8080: Flutter PC1 (complet)');
  print('- 8081: Flutter PC2 (client seul)');
  print('- 8082: Flutter PC1 (client seulement)');
}
