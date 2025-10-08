import 'dart:io';

void main() async {
  print('🔍 Serveur de Test de Connectivité');
  print('===================================');
  
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
    localIP = '192.0.0.2';
  }
  
  print('📱 IP détectée: $localIP');
  print('🌐 URL de test: http://$localIP:3000');
  print('');
  print('📋 Instructions pour l\'autre PC:');
  print('1. Ouvrez un navigateur sur l\'autre PC');
  print('2. Allez à: http://$localIP:3000');
  print('3. Si vous voyez la page de test, le réseau fonctionne !');
  print('4. Si vous ne voyez rien, le problème est le firewall');
  print('');
  print('🚀 Démarrage du serveur de test...');
  
  final server = await HttpServer.bind(InternetAddress.anyIPv4, 3000);
  print('✅ Serveur de test démarré sur le port 3000');
  print('📱 Testez avec: http://$localIP:3000');
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
    <title>Test Connectivité - Pandora Box</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            text-align: center; 
            padding: 50px; 
            background: linear-gradient(135deg, #4CAF50 0%, #45a049 100%);
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
        <h1 class="success">🎉 Connexion Réussie !</h1>
        <p class="info">Le réseau fonctionne parfaitement entre les PC</p>
        
        <div class="info">
            <p><strong>IP du serveur:</strong> $localIP</p>
            <p><strong>Port:</strong> 3000</p>
            <p><strong>Timestamp:</strong> ${DateTime.now()}</p>
        </div>
        
        <div class="info">
            <p><strong>✅ Prochaines étapes:</strong></p>
            <p>1. Le réseau fonctionne, le problème était le firewall</p>
            <p>2. Maintenant vous pouvez utiliser l'application</p>
            <p>3. Allez à: <a href="http://$localIP:8085" style="color: #4CAF50;">http://$localIP:8085</a></p>
        </div>
        
        <div class="info">
            <p><strong>🔧 Si l'application ne marche toujours pas:</strong></p>
            <p>1. Désactivez temporairement le firewall</p>
            <p>2. Ou ajoutez une exception pour les ports 8085 et 5002</p>
        </div>
    </div>
</body>
</html>
    ''');
    request.response.close();
  }
}
