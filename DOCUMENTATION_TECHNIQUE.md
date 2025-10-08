# 🔧 Pandora Box - Documentation Technique

## 📋 Architecture Générale

### Stack Technologique
- **Frontend** : Flutter Web (Dart)
- **Backend** : Dart HTTP Server
- **Base de données** : Stockage en mémoire (Map)
- **Communication** : HTTP REST API
- **Synchronisation** : Polling (2 secondes)

## 🗂️ Structure du Projet

```
Workshop25-26/
├── lib/
│   ├── main.dart                    # Point d'entrée de l'application
│   ├── firebase_options.dart        # Configuration Firebase
│   ├── pages/
│   │   ├── home_page.dart          # Page d'accueil
│   │   ├── room_management_page.dart # Gestion des rooms
│   │   └── ...                     # Autres pages
│   └── services/
│       ├── firebase_service.dart    # Service principal (orchestrateur)
│       ├── http_game_service.dart   # Service HTTP pour Flutter Web
│       ├── local_game_service.dart  # Service local (fallback)
│       └── shared_local_service.dart # Service partagé local
├── lancer_complet.dart             # Script de lancement principal
├── simple_server.dart              # Serveur multijoueur simple
└── pubspec.yaml                    # Dépendances du projet
```

## 🏗️ Architecture des Services

### FirebaseService (Orchestrateur)
```dart
class FirebaseService {
  static bool _useHttpService = true;    // Mode HTTP activé
  static bool _useLocalService = false;   // Mode local désactivé
  static HttpGameService _httpService;   // Service HTTP principal
  static LocalGameService _localService; // Service local (fallback)
}
```

**Responsabilités :**
- Délègue les appels au service approprié (HTTP ou Local)
- Gère l'initialisation des services
- Fournit une interface unifiée pour l'application

### HttpGameService (Service Principal)
```dart
class HttpGameService {
  String _serverUrl = 'http://192.0.0.2:5002';
  String? _currentUserId;
  String? _currentRoomId;
}
```

**Fonctionnalités :**
- Communication HTTP avec le serveur backend
- Compatible Flutter Web (utilise `package:http`)
- Polling toutes les 2 secondes pour la synchronisation
- Gestion des erreurs de connexion

**Méthodes principales :**
- `createGameRoom()` - Créer une room
- `joinGameRoom()` - Rejoindre une room
- `getAvailableRooms()` - Récupérer les rooms
- `listenToRoom()` - Écouter les changements d'une room

## 🗄️ Modèle de Données

### Structure d'une Room
```dart
Map<String, dynamic> roomData = {
  'id': 'timestamp_unique',
  'name': 'Nom de la room',
  'host': 'user_id_du_createur',
  'hostName': 'Nom du créateur',
  'players': {
    'user_id_1': {
      'name': 'Nom du joueur',
      'isHost': true,
      'isReady': false,
      'joinedAt': '2024-01-01T12:00:00.000Z',
    },
    'user_id_2': {
      'name': 'Nom du joueur 2',
      'isHost': false,
      'isReady': true,
      'joinedAt': '2024-01-01T12:05:00.000Z',
    }
  },
  'gameState': 'waiting', // waiting, playing, finished
  'createdAt': '2024-01-01T12:00:00.000Z',
  'lastUpdated': '2024-01-01T12:05:00.000Z',
};
```

## 🌐 API Backend

### Serveur HTTP (Port 5002)
```dart
// Serveur principal dans lancer_complet.dart
final server = await HttpServer.bind(InternetAddress.anyIPv4, 5002);
```

### Endpoints Disponibles

#### GET `/` - Page d'accueil
- **Réponse** : Page HTML d'information
- **Usage** : Test de connectivité

#### GET `/rooms` - Liste des rooms
- **Réponse** : `List<Map<String, dynamic>>`
- **Usage** : Récupérer toutes les rooms disponibles

#### POST `/rooms` - Créer une room
- **Body** : `{"name": "Nom", "host": "user_id", "hostName": "Nom"}`
- **Réponse** : `{"id": "room_id", "room": roomData}`
- **Usage** : Créer une nouvelle room

#### GET `/room/{id}` - Détails d'une room
- **Réponse** : `Map<String, dynamic>` ou `null`
- **Usage** : Récupérer les détails d'une room spécifique

#### PUT `/room/{id}` - Mettre à jour une room
- **Body** : Données à mettre à jour
- **Réponse** : `"Room updated"`
- **Usage** : Modifier une room existante

### Headers CORS
```dart
request.response.headers.add('Access-Control-Allow-Origin', '*');
request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
request.response.headers.add('Access-Control-Allow-Headers', 'Content-Type');
```

## 🔄 Synchronisation Temps Réel

### Mécanisme de Polling
```dart
// Dans HttpGameService
Stream<List<Map<String, dynamic>>> getAvailableRoomsStream() async* {
  while (true) {
    try {
      final rooms = await getAvailableRooms();
      yield rooms;
    } catch (e) {
      yield [];
    }
    await Future.delayed(const Duration(seconds: 2));
  }
}
```

**Avantages :**
- Simple à implémenter
- Compatible avec tous les navigateurs
- Pas de WebSocket nécessaire

**Inconvénients :**
- Latence de 2 secondes maximum
- Consommation réseau plus élevée

## 🔐 Gestion des Utilisateurs

### Identification des Utilisateurs
```dart
// Génération d'un ID unique
_currentUserId = 'user_${DateTime.now().millisecondsSinceEpoch}';
```

**Caractéristiques :**
- ID unique basé sur le timestamp
- Pas d'authentification complexe
- Persistance pendant la session

### Rôles dans les Rooms
- **Host** : Créateur de la room, peut la supprimer
- **Player** : Joueur normal, peut rejoindre/quitter

## 🚨 Gestion d'Erreurs

### Erreurs de Connexion
```dart
try {
  final response = await http.get(Uri.parse('$_serverUrl/rooms'));
  // Traitement de la réponse
} catch (e) {
  throw Exception('Erreur de connexion: $e');
}
```

### Erreurs Flutter Web
- **Platform._version** : Résolu en utilisant `package:http` au lieu de `dart:io`
- **CORS** : Headers CORS ajoutés au serveur backend
- **Conflits de ports** : Gestion automatique des ports disponibles

## 📊 Performance

### Métriques Actuelles
- **Latence de synchronisation** : 2 secondes maximum
- **Taille des requêtes** : ~1KB par room
- **Mémoire serveur** : ~1MB pour 1000 rooms
- **CPU serveur** : Minimal (polling simple)

### Optimisations Possibles
- [ ] WebSocket pour la synchronisation temps réel
- [ ] Compression des données
- [ ] Cache côté client
- [ ] Pagination des rooms

## 🔧 Configuration

### Variables d'Environnement
```dart
// Dans HttpGameService
String _serverUrl = 'http://192.0.0.2:5002';
```

### Ports Utilisés
- **8084** : Application Flutter Web
- **5002** : Serveur Backend HTTP

### Dépendances Principales
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0                    # Communication HTTP
  firebase_core: ^3.6.0          # Firebase (non utilisé actuellement)
  firebase_database: ^11.1.0     # Firebase Database (non utilisé)
  firebase_auth: ^5.3.1          # Firebase Auth (non utilisé)
```

## 🚀 Déploiement

### Développement Local
```bash
dart run lancer_complet.dart
```

### Production (Recommandations)
- [ ] Serveur dédié avec base de données persistante
- [ ] HTTPS pour la sécurité
- [ ] Load balancer pour la scalabilité
- [ ] Monitoring et logs

## 🐛 Debug et Logs

### Logs du Serveur
```dart
print('✅ Serveur backend démarré sur le port 5002');
print('📱 Testez avec: http://$localIP:5002');
```

### Logs de l'Application
```dart
print('Erreur lors de la récupération des rooms: $e');
```

### Outils de Debug
- **Flutter Inspector** : Pour l'interface utilisateur
- **Network Tab** : Pour les requêtes HTTP
- **Console** : Pour les logs JavaScript

## 📈 Évolutions Futures

### Court Terme
- [ ] Interface utilisateur améliorée
- [ ] Gestion des erreurs plus robuste
- [ ] Tests unitaires

### Moyen Terme
- [ ] Base de données persistante (PostgreSQL/MongoDB)
- [ ] Authentification utilisateur
- [ ] Système de notifications

### Long Terme
- [ ] Microservices architecture
- [ ] Kubernetes deployment
- [ ] Analytics et monitoring
