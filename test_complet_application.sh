#!/bin/bash

echo "🎮 TEST COMPLET APPLICATION FLUTTER PANDORA BOX"
echo "=============================================="

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages colorés
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Variables
SERVER_PID=""
FLUTTER_PID=""

# Fonction de nettoyage
cleanup() {
    print_status "Nettoyage des processus..."
    
    if [ ! -z "$SERVER_PID" ]; then
        kill $SERVER_PID 2>/dev/null
        print_success "Serveur arrêté"
    fi
    
    if [ ! -z "$FLUTTER_PID" ]; then
        kill $FLUTTER_PID 2>/dev/null
        print_success "Flutter arrêté"
    fi
    
    # Tuer tous les processus dart en cours
    pkill -f "dart.*serveur_test" 2>/dev/null
    pkill -f "flutter.*run" 2>/dev/null
}

# Gestion des signaux pour le nettoyage
trap cleanup EXIT INT TERM

# Test 1: Vérifications préliminaires
test_prerequisites() {
    print_status "Vérifications préliminaires..."
    
    # Vérifier Dart
    if command -v dart &> /dev/null; then
        print_success "Dart installé: $(dart --version | head -n 1)"
    else
        print_error "Dart non installé!"
        exit 1
    fi
    
    # Vérifier Flutter
    if command -v flutter &> /dev/null; then
        print_success "Flutter installé: $(flutter --version | head -n 1)"
    else
        print_error "Flutter non installé!"
        exit 1
    fi
    
    # Vérifier les fichiers
    local files=(
        "lib/main.dart"
        "lib/pages/home_page.dart"
        "lib/pages/room_management_page.dart"
        "lib/pages/page1_puzzle.dart"
        "lib/services/http_game_service.dart"
        "serveur_test_simplifie.dart"
    )
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            print_success "Fichier $file présent"
        else
            print_error "Fichier $file manquant"
        fi
    done
}

# Test 2: Démarrage du serveur
start_server() {
    print_status "Démarrage du serveur de test..."
    
    dart serveur_test_simplifie.dart &
    SERVER_PID=$!
    
    # Attendre que le serveur démarre
    sleep 3
    
    # Vérifier si le serveur fonctionne
    if kill -0 $SERVER_PID 2>/dev/null; then
        print_success "Serveur démarré (PID: $SERVER_PID)"
        
        # Tester la connectivité
        if nc -z localhost 5001 2>/dev/null; then
            print_success "Port 5001 accessible"
        else
            print_error "Port 5001 inaccessible"
        fi
        
        if nc -z localhost 5002 2>/dev/null; then
            print_success "Port 5002 accessible"
        else
            print_error "Port 5002 inaccessible"
        fi
    else
        print_error "Serveur n'a pas démarré"
        exit 1
    fi
}

# Test 3: Tests de connectivité
test_connectivity() {
    print_status "Tests de connectivité..."
    
    # Test HTTP
    if curl -s http://localhost:5001/ > /dev/null; then
        print_success "Serveur HTTP accessible"
    else
        print_error "Serveur HTTP inaccessible"
    fi
    
    # Test WebSocket (simulation)
    if nc -z localhost 5002 2>/dev/null; then
        print_success "Serveur WebSocket accessible"
    else
        print_error "Serveur WebSocket inaccessible"
    fi
}

# Test 4: Tests des jeux
test_games() {
    print_status "Tests des jeux..."
    
    # Test Page 1 - Puzzle
    if [ -f "lib/pages/page1_puzzle.dart" ]; then
        print_success "Page 1 - Puzzle disponible"
        
        # Vérifier les méthodes critiques
        if grep -q "class Page1Puzzle" lib/pages/page1_puzzle.dart; then
            print_success "Classe Page1Puzzle trouvée"
        else
            print_error "Classe Page1Puzzle manquante"
        fi
        
        if grep -q "_startGame" lib/pages/page1_puzzle.dart; then
            print_success "Méthode _startGame trouvée"
        else
            print_error "Méthode _startGame manquante"
        fi
    else
        print_error "Page 1 - Puzzle manquante"
    fi
    
    # Test Page 2 - Stress
    if [ -f "lib/pages/stress_page.dart" ]; then
        print_success "Page 2 - Stress disponible"
    else
        print_error "Page 2 - Stress manquante"
    fi
    
    # Test Page 3 - Crossword
    if [ -f "lib/pages/page3_crossword.dart" ]; then
        print_success "Page 3 - Mots croisés disponible"
    else
        print_error "Page 3 - Mots croisés manquante"
    fi
    
    # Test Page 4 - Tram
    if [ -f "lib/pages/page4_tram.dart" ]; then
        print_success "Page 4 - Tram disponible"
    else
        print_error "Page 4 - Tram manquante"
    fi
    
    # Test Page 5 - Notifications
    if [ -f "lib/pages/page5_notifications.dart" ]; then
        print_success "Page 5 - Notifications disponible"
    else
        print_error "Page 5 - Notifications manquante"
    fi
}

# Test 5: Tests de gestion des rooms
test_room_management() {
    print_status "Tests de gestion des rooms..."
    
    # Test création de room
    local room_response=$(curl -s -X POST http://localhost:5001/rooms \
        -H "Content-Type: application/json" \
        -d '{"name":"Test Room","host":"test_user","hostName":"Test User"}')
    
    if echo "$room_response" | grep -q "id"; then
        print_success "Création de room réussie"
        
        # Extraire l'ID de la room
        local room_id=$(echo "$room_response" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
        print_status "Room ID: $room_id"
        
        # Test récupération de room
        local room_data=$(curl -s http://localhost:5001/room/$room_id)
        if echo "$room_data" | grep -q "Test Room"; then
            print_success "Récupération de room réussie"
        else
            print_error "Récupération de room échouée"
        fi
        
        # Test ajout de joueur
        local join_response=$(curl -s -X PUT http://localhost:5001/room/$room_id \
            -H "Content-Type: application/json" \
            -d '{"players":{"player2":{"name":"Player 2","isHost":false,"isReady":false,"joinedAt":"'$(date -u +%Y-%m-%dT%H:%M:%S.000Z)'"}}}')
        
        if echo "$join_response" | grep -q "Room updated"; then
            print_success "Ajout de joueur réussi"
        else
            print_error "Ajout de joueur échoué"
        fi
        
    else
        print_error "Création de room échouée"
    fi
}

# Test 6: Test de compilation Flutter
test_flutter_build() {
    print_status "Test de compilation Flutter..."
    
    # Installer les dépendances
    if flutter pub get > /dev/null 2>&1; then
        print_success "Dépendances installées"
    else
        print_error "Erreur installation dépendances"
        return 1
    fi
    
    # Analyser le code
    if flutter analyze > /dev/null 2>&1; then
        print_success "Code analysé sans erreurs"
    else
        print_warning "Erreurs d'analyse détectées"
        flutter analyze
    fi
    
    # Test de compilation (sans lancer)
    if flutter build web --no-sound-null-safety > /dev/null 2>&1; then
        print_success "Compilation web réussie"
    else
        print_warning "Erreur compilation web"
    fi
}

# Test 7: Test multijoueur complet
test_multiplayer_complete() {
    print_status "Test multijoueur complet..."
    
    # Simuler deux clients
    local client1_room=$(curl -s -X POST http://localhost:5001/rooms \
        -H "Content-Type: application/json" \
        -d '{"name":"Multiplayer Test","host":"client1","hostName":"Client 1"}')
    
    if echo "$client1_room" | grep -q "id"; then
        print_success "Client 1: Room créée"
        
        local room_id=$(echo "$client1_room" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
        
        # Client 2 rejoint
        local client2_join=$(curl -s -X PUT http://localhost:5001/room/$room_id \
            -H "Content-Type: application/json" \
            -d '{"players":{"client2":{"name":"Client 2","isHost":false,"isReady":false,"joinedAt":"'$(date -u +%Y-%m-%dT%H:%M:%S.000Z)'"}}}')
        
        if echo "$client2_join" | grep -q "Room updated"; then
            print_success "Client 2: Room rejointe"
            
            # Vérifier l'état final
            local final_state=$(curl -s http://localhost:5001/room/$room_id)
            local player_count=$(echo "$final_state" | grep -o '"players"' | wc -l)
            
            if [ "$player_count" -ge 2 ]; then
                print_success "Test multijoueur réussi (2+ joueurs)"
            else
                print_error "Test multijoueur échoué (moins de 2 joueurs)"
            fi
        else
            print_error "Client 2: Erreur rejoindre room"
        fi
    else
        print_error "Client 1: Erreur création room"
    fi
}

# Test 8: Test de l'application Flutter
test_flutter_app() {
    print_status "Test de l'application Flutter..."
    
    # Démarrer Flutter en mode web
    flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0 &
    FLUTTER_PID=$!
    
    # Attendre que Flutter démarre
    sleep 10
    
    # Vérifier si Flutter fonctionne
    if kill -0 $FLUTTER_PID 2>/dev/null; then
        print_success "Flutter démarré (PID: $FLUTTER_PID)"
        
        # Tester l'accès web
        if curl -s http://localhost:8080 > /dev/null; then
            print_success "Application Flutter accessible sur le web"
        else
            print_warning "Application Flutter non accessible sur le web"
        fi
    else
        print_error "Flutter n'a pas démarré"
    fi
}

# Fonction principale
main() {
    echo "Démarrage des tests complets..."
    echo
    
    # Tests séquentiels
    test_prerequisites
    echo
    
    start_server
    echo
    
    test_connectivity
    echo
    
    test_games
    echo
    
    test_room_management
    echo
    
    test_flutter_build
    echo
    
    test_multiplayer_complete
    echo
    
    test_flutter_app
    echo
    
    # Résumé final
    print_success "Tests complets terminés!"
    print_status "Serveur: http://localhost:5001"
    print_status "Application Flutter: http://localhost:8080"
    print_status "Consultez les logs ci-dessus pour les détails"
    
    # Garder les processus en vie pour les tests manuels
    print_status "Processus en cours d'exécution..."
    print_status "Appuyez sur Ctrl+C pour arrêter"
    
    # Attendre indéfiniment
    while true; do
        sleep 1
    done
}

# Exécution
main "$@"
