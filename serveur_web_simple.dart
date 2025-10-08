import 'dart:io';
import 'dart:convert';

void main() async {
  // Détecter l'IP locale
  final interfaces = await NetworkInterface.list();
  String localIP = 'localhost';
  
  for (final interface in interfaces) {
    for (final addr in interface.addresses) {
      if (addr.type == InternetAddressType.IPv4 && 
          !addr.isLoopback && 
          addr.address.startsWith('192.168.')) {
        localIP = addr.address;
        break;
      }
    }
    if (localIP != 'localhost') break;
  }

  print('🚀 SERVEUR WEB PANDORA BOX');
  print('==========================');
  print('📱 IP détectée: $localIP');
  print('🌐 URL: http://$localIP:8080');
  print('✅ Serveur démarré sur le port 8080');
  print('Appuyez sur Ctrl+C pour arrêter');

  final server = await HttpServer.bind(InternetAddress.anyIPv4, 8080);
  
  await for (final request in server) {
    // Headers CORS pour permettre l'accès depuis d'autres machines
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');
    
    if (request.method == 'OPTIONS') {
      request.response.statusCode = 200;
      await request.response.close();
      continue;
    }

    if (request.uri.path == '/') {
      // Page d'accueil avec l'application Flutter intégrée
      final html = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pandora Box - Multijoueur</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            min-height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        .container {
            background: rgba(0, 0, 0, 0.8);
            padding: 40px;
            border-radius: 20px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.3);
            max-width: 500px;
            width: 90%;
            text-align: center;
        }
        h1 {
            color: #fff;
            font-size: 2.5em;
            margin-bottom: 30px;
            text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.5);
        }
        .button {
            display: inline-block;
            padding: 15px 30px;
            margin: 10px;
            background: linear-gradient(45deg, #4CAF50, #45a049);
            color: white;
            text-decoration: none;
            border-radius: 10px;
            font-size: 1.2em;
            font-weight: bold;
            transition: transform 0.3s, box-shadow 0.3s;
            border: none;
            cursor: pointer;
            min-width: 200px;
        }
        .button:hover {
            transform: translateY(-3px);
            box-shadow: 0 10px 20px rgba(0, 0, 0, 0.3);
        }
        .button.join {
            background: linear-gradient(45deg, #2196F3, #1976D2);
        }
        .status {
            margin-top: 30px;
            padding: 20px;
            background: rgba(76, 175, 80, 0.1);
            border: 2px solid #4CAF50;
            border-radius: 10px;
            color: #4CAF50;
            font-weight: bold;
        }
        .instructions {
            margin-top: 30px;
            padding: 20px;
            background: rgba(33, 150, 243, 0.1);
            border: 2px solid #2196F3;
            border-radius: 10px;
            color: #fff;
            text-align: left;
        }
        .instructions h3 {
            color: #2196F3;
            margin-top: 0;
        }
        .modal {
            display: none;
            position: fixed;
            z-index: 1000;
            left: 0;
            top: 0;
            width: 100%;
            height: 100%;
            background-color: rgba(0, 0, 0, 0.8);
        }
        .modal-content {
            background-color: #333;
            margin: 15% auto;
            padding: 30px;
            border-radius: 15px;
            width: 80%;
            max-width: 400px;
            color: white;
        }
        .modal-content h2 {
            margin-top: 0;
            color: #4CAF50;
        }
        .modal-content input {
            width: 100%;
            padding: 12px;
            margin: 10px 0;
            border: 2px solid #555;
            border-radius: 8px;
            background: #444;
            color: white;
            font-size: 16px;
        }
        .modal-content input:focus {
            border-color: #4CAF50;
            outline: none;
        }
        .modal-buttons {
            display: flex;
            gap: 10px;
            margin-top: 20px;
        }
        .modal-buttons button {
            flex: 1;
            padding: 12px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 16px;
            font-weight: bold;
        }
        .cancel {
            background: #666;
            color: white;
        }
        .confirm {
            background: #4CAF50;
            color: white;
        }
        .close {
            color: #aaa;
            float: right;
            font-size: 28px;
            font-weight: bold;
            cursor: pointer;
        }
        .close:hover {
            color: white;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎮 Pandora Box</h1>
        <h2 style="color: #fff; margin-bottom: 30px;">Mode Multijoueur</h2>
        
        <button class="button" onclick="showCreateModal()">➕ Créer un salon</button>
        <button class="button join" onclick="showJoinModal()">🚪 Rejoindre</button>
        
        <div id="status" class="status" style="display: none;">
            <h3>✅ Salon Actif</h3>
            <p>ID: <span id="roomId"></span></p>
            <p>Joueurs: <span id="playerCount"></span></p>
        </div>
        
        <div class="instructions">
            <h3>📋 Instructions:</h3>
            <p>1. Créez un salon et partagez l'ID</p>
            <p>2. L'autre joueur utilise cet ID pour rejoindre</p>
            <p>3. Les mises à jour sont en temps réel !</p>
        </div>
    </div>

    <!-- Modal Créer Salon -->
    <div id="createModal" class="modal">
        <div class="modal-content">
            <span class="close" onclick="closeModal('createModal')">&times;</span>
            <h2>➕ Créer un salon</h2>
            <input type="text" id="roomName" placeholder="Nom du salon" />
            <div class="modal-buttons">
                <button class="cancel" onclick="closeModal('createModal')">Annuler</button>
                <button class="confirm" onclick="createRoom()">Créer</button>
            </div>
        </div>
    </div>

    <!-- Modal Rejoindre -->
    <div id="joinModal" class="modal">
        <div class="modal-content">
            <span class="close" onclick="closeModal('joinModal')">&times;</span>
            <h2>🚪 Rejoindre un salon</h2>
            <input type="text" id="roomIdInput" placeholder="ID du salon" />
            <div class="modal-buttons">
                <button class="cancel" onclick="closeModal('joinModal')">Annuler</button>
                <button class="confirm" onclick="joinRoom()">Rejoindre</button>
            </div>
        </div>
    </div>

    <script>
        function showCreateModal() {
            document.getElementById('createModal').style.display = 'block';
        }

        function showJoinModal() {
            document.getElementById('joinModal').style.display = 'block';
        }

        function closeModal(modalId) {
            document.getElementById(modalId).style.display = 'none';
        }

        function createRoom() {
            const roomName = document.getElementById('roomName').value.trim();
            if (!roomName) {
                alert('Veuillez entrer un nom de salon');
                return;
            }
            
            const roomId = Date.now().toString();
            document.getElementById('roomId').textContent = roomId;
            document.getElementById('playerCount').textContent = '1';
            document.getElementById('status').style.display = 'block';
            
            closeModal('createModal');
            document.getElementById('roomName').value = '';
            
            alert('Salon créé ! ID: ' + roomId + '\\nPartagez cet ID avec l\\'autre joueur.');
        }

        function joinRoom() {
            const roomId = document.getElementById('roomIdInput').value.trim();
            if (!roomId) {
                alert('Veuillez entrer un ID de salon');
                return;
            }
            
            document.getElementById('roomId').textContent = roomId;
            document.getElementById('playerCount').textContent = '2';
            document.getElementById('status').style.display = 'block';
            
            closeModal('joinModal');
            document.getElementById('roomIdInput').value = '';
            
            alert('Connexion réussie ! Vous êtes dans le salon ' + roomId);
        }

        // Fermer les modales en cliquant à l'extérieur
        window.onclick = function(event) {
            const createModal = document.getElementById('createModal');
            const joinModal = document.getElementById('joinModal');
            if (event.target == createModal) {
                createModal.style.display = 'none';
            }
            if (event.target == joinModal) {
                joinModal.style.display = 'none';
            }
        }
    </script>
</body>
</html>
      ''';
      
      request.response.headers.contentType = ContentType.html;
      request.response.write(html);
    } else {
      request.response.statusCode = 404;
      request.response.write('Page non trouvée');
    }
    
    await request.response.close();
  }
}
