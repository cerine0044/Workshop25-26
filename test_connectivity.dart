import 'dart:io';

void main() async {
  print('🔍 Test de Connectivité - Pandora Box');
  print('=====================================');
  
  // Obtenir l'IP locale
  final interfaces = await NetworkInterface.list();
  String? hotspotIP;
  
  for (var interface in interfaces) {
    for (var addr in interface.addresses) {
      if (addr.type == InternetAddressType.IPv4 && 
          !addr.isLoopback && 
          !addr.address.startsWith('169.254') &&
          !addr.address.startsWith('127.')) {
        hotspotIP = addr.address;
        break;
      }
    }
    if (hotspotIP != null) break;
  }
  
  if (hotspotIP == null) {
    hotspotIP = '192.0.0.2'; // IP par défaut du hotspot
  }
  
  print('📱 IP détectée: $hotspotIP');
  print('🌐 URL à partager: http://$hotspotIP:3000');
  print('');
  print('🎮 Instructions pour tester depuis un autre PC:');
  print('1. Connectez-vous au même réseau WiFi');
  print('2. Ouvrez un navigateur sur l\'autre PC');
  print('3. Allez à: http://$hotspotIP:3000');
  print('4. Vous devriez voir la page de test');
  print('');
  
  // Démarrer un serveur de test simple
  print('🚀 Démarrage du serveur de test...');
  
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 3000);
  print('✅ Serveur démarré sur le port 3000');
  print('📱 Testez avec: http://$hotspotIP:3000');
  print('');
  print('Appuyez sur Ctrl+C pour arrêter');
  
  await for (HttpRequest request in server) {
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');
    
    if (request.method == 'OPTIONS') {
      request.response.statusCode = 200;
      request.response.close();
      continue;
    }
    
    request.response.statusCode = 200;
    request.response.headers.contentType = ContentType.html;
    request.response.write('''
<!DOCTYPE html>
<html>
<head>
    <title>Test Pandora Box - Connectivité</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            text-align: center; 
            padding: 50px; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            margin: 0;
        }
        .container {
            max-width: 600px;
            margin: 0 auto;
            background: rgba(255,255,255,0.1);
            padding: 30px;
            border-radius: 15px;
            backdrop-filter: blur(10px);
        }
        .success { color: #4CAF50; font-size: 24px; }
        .info { color: #81C784; margin: 20px 0; }
        .button {
            background: #4CAF50;
            color: white;
            padding: 15px 30px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 16px;
            margin: 10px;
            text-decoration: none;
            display: inline-block;
        }
        .button:hover { background: #45a049; }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="success">✅ Connexion Réussie !</h1>
        <p class="info">Le serveur Pandora Box fonctionne correctement</p>
        
        <div class="info">
            <p><strong>IP:</strong> $hotspotIP</p>
            <p><strong>Port:</strong> 3000</p>
            <p><strong>Timestamp:</strong> ${DateTime.now()}</p>
        </div>
        
        <div class="info">
            <p><strong>Prochaines étapes:</strong></p>
            <p>1. Si vous voyez cette page depuis un autre PC, la connectivité fonctionne !</p>
            <p>2. Maintenant vous pouvez lancer l'application Flutter</p>
            <p>3. Utilisez: dart run start_remote_access.dart</p>
        </div>
        
        <a href="http://$hotspotIP:8080" class="button" target="_blank">
            🚀 Ouvrir Pandora Box (si disponible)
        </a>
    </div>
</body>
</html>
    ''');
    request.response.close();
  }
}
