#!/bin/bash

echo "🚀 SCRIPT DE TEST AUTOMATISÉ PANDORA BOX"
echo "========================================"

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

# Vérifier si Dart est installé
check_dart() {
    print_status "Vérification de Dart..."
    if command -v dart &> /dev/null; then
        print_success "Dart est installé: $(dart --version)"
    else
        print_error "Dart n'est pas installé!"
        exit 1
    fi
}

# Vérifier si Flutter est installé
check_flutter() {
    print_status "Vérification de Flutter..."
    if command -v flutter &> /dev/null; then
        print_success "Flutter est installé: $(flutter --version | head -n 1)"
    else
        print_error "Flutter n'est pas installé!"
        exit 1
    fi
}

# Tester la connectivité réseau
test_network() {
    print_status "Test de connectivité réseau..."
    
    # Test ping localhost
    if ping -c 1 localhost &> /dev/null; then
        print_success "Localhost accessible"
    else
        print_error "Localhost inaccessible"
    fi
    
    # Test des ports
    local ports=(5001 5002 8081)
    for port in "${ports[@]}"; do
        if nc -z localhost $port 2>/dev/null; then
            print_success "Port $port ouvert"
        else
            print_warning "Port $port fermé"
        fi
    done
}

# Démarrer le serveur WebSocket
start_websocket_server() {
    print_status "Démarrage du serveur WebSocket..."
    
    if [ -f "websocket_server.dart" ]; then
        # Démarrer le serveur en arrière-plan
        dart websocket_server.dart &
        SERVER_PID=$!
        print_success "Serveur WebSocket démarré (PID: $SERVER_PID)"
        
        # Attendre que le serveur démarre
        sleep 3
        
        # Vérifier si le serveur fonctionne
        if kill -0 $SERVER_PID 2>/dev/null; then
            print_success "Serveur WebSocket fonctionne"
        else
            print_error "Serveur WebSocket n'a pas démarré"
        fi
    else
        print_error "Fichier websocket_server.dart introuvable"
    fi
}

# Tester la connectivité complète
test_connectivity() {
    print_status "Test de connectivité complète..."
    
    if [ -f "test_connectivite_complete.dart" ]; then
        dart test_connectivite_complete.dart
    else
        print_error "Fichier test_connectivite_complete.dart introuvable"
    fi
}

# Tester chaque jeu individuellement
test_games() {
    print_status "Test des jeux individuels..."
    
    # Test Page 1 - Puzzle
    print_status "Test Page 1 - Jeu de mémoire..."
    if [ -f "lib/pages/page1_puzzle.dart" ]; then
        print_success "Page 1 - Puzzle disponible"
    else
        print_error "Page 1 - Puzzle introuvable"
    fi
    
    # Test Page 2 - Stress
    print_status "Test Page 2 - Stress..."
    if [ -f "lib/pages/stress_page.dart" ]; then
        print_success "Page 2 - Stress disponible"
    else
        print_error "Page 2 - Stress introuvable"
    fi
    
    # Test Page 3 - Crossword
    print_status "Test Page 3 - Mots croisés..."
    if [ -f "lib/pages/page3_crossword.dart" ]; then
        print_success "Page 3 - Mots croisés disponible"
    else
        print_error "Page 3 - Mots croisés introuvable"
    fi
    
    # Test Page 4 - Tram
    print_status "Test Page 4 - Tram..."
    if [ -f "lib/pages/page4_tram.dart" ]; then
        print_success "Page 4 - Tram disponible"
    else
        print_error "Page 4 - Tram introuvable"
    fi
    
    # Test Page 5 - Notifications
    print_status "Test Page 5 - Notifications..."
    if [ -f "lib/pages/page5_notifications.dart" ]; then
        print_success "Page 5 - Notifications disponible"
    else
        print_error "Page 5 - Notifications introuvable"
    fi
}

# Tester la gestion des rooms
test_room_management() {
    print_status "Test de la gestion des rooms..."
    
    if [ -f "lib/pages/room_management_page.dart" ]; then
        print_success "Page de gestion des rooms disponible"
    else
        print_error "Page de gestion des rooms introuvable"
    fi
    
    if [ -f "lib/services/http_game_service.dart" ]; then
        print_success "Service HTTP de jeu disponible"
    else
        print_error "Service HTTP de jeu introuvable"
    fi
    
    if [ -f "lib/services/websocket_game_service.dart" ]; then
        print_success "Service WebSocket de jeu disponible"
    else
        print_error "Service WebSocket de jeu introuvable"
    fi
}

# Tester la compilation Flutter
test_flutter_build() {
    print_status "Test de compilation Flutter..."
    
    # Vérifier les dépendances
    if [ -f "pubspec.yaml" ]; then
        print_status "Installation des dépendances..."
        flutter pub get
        if [ $? -eq 0 ]; then
            print_success "Dépendances installées"
        else
            print_error "Erreur installation dépendances"
        fi
    fi
    
    # Test de compilation
    print_status "Test de compilation..."
    flutter analyze
    if [ $? -eq 0 ]; then
        print_success "Code analysé sans erreurs"
    else
        print_warning "Erreurs d'analyse détectées"
    fi
}

# Nettoyer les processus
cleanup() {
    print_status "Nettoyage des processus..."
    
    if [ ! -z "$SERVER_PID" ]; then
        kill $SERVER_PID 2>/dev/null
        print_success "Serveur WebSocket arrêté"
    fi
    
    # Tuer tous les processus dart en cours
    pkill -f "dart.*websocket_server" 2>/dev/null
    pkill -f "dart.*test_connectivite" 2>/dev/null
}

# Fonction principale
main() {
    echo "Démarrage des tests automatiques..."
    echo
    
    # Vérifications préliminaires
    check_dart
    check_flutter
    test_network
    
    echo
    
    # Tests de l'application
    test_flutter_build
    test_games
    test_room_management
    
    echo
    
    # Tests de connectivité
    start_websocket_server
    test_connectivity
    
    echo
    
    # Résumé
    print_success "Tests automatiques terminés!"
    print_status "Consultez les logs ci-dessus pour les détails"
    
    # Nettoyage
    cleanup
}

# Gestion des signaux pour le nettoyage
trap cleanup EXIT INT TERM

# Exécution
main "$@"
