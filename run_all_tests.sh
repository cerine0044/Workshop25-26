#!/bin/bash

echo "🧪 SUITE DE TESTS COMPLÈTE PANDORA BOX"
echo "======================================"
echo ""

# Couleurs pour les résultats
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables pour les résultats
totalTests=0
passedTests=0

# Fonction pour exécuter un test
run_test() {
    local testName="$1"
    local testFile="$2"
    local description="$3"
    
    echo -e "${BLUE}🔍 Exécution: $testName${NC}"
    echo "Description: $description"
    echo "Fichier: $testFile"
    echo ""
    
    if [ -f "$testFile" ]; then
        if dart "$testFile"; then
            echo -e "${GREEN}✅ $testName - RÉUSSI${NC}"
            ((passedTests++))
        else
            echo -e "${RED}❌ $testName - ÉCHOUÉ${NC}"
        fi
    else
        echo -e "${RED}❌ Fichier de test non trouvé: $testFile${NC}"
    fi
    
    ((totalTests++))
    echo ""
    echo "----------------------------------------"
    echo ""
}

# Vérifier que le serveur est démarré
echo "🔧 Vérification du serveur..."
if curl -s http://localhost:5001/ > /dev/null; then
    echo -e "${GREEN}✅ Serveur HTTP actif (port 5001)${NC}"
else
    echo -e "${RED}❌ Serveur HTTP non accessible${NC}"
    echo "Démarrez le serveur avec: dart serveur_multijoueur_ameliore.dart"
    exit 1
fi

echo ""

# Test 1: Tests complets de l'interface moderne
run_test "Tests Interface Moderne" "test_complet_interface_moderne.dart" "Tests complets de toutes les fonctionnalités de l'interface moderne"

# Test 2: Tests Flutter
run_test "Tests Application Flutter" "test_flutter_moderne.dart" "Vérification de l'application Flutter moderne"

# Test 3: Tests de performance
run_test "Tests de Performance" "test_performance.dart" "Tests de performance et charge du système"

# Test 4: Tests de synchronisation temps réel
run_test "Tests Synchronisation" "test_synchronisation_temps_reel.dart" "Tests de synchronisation temps réel entre joueurs"

# Test 5: Tests de connectivité
run_test "Tests Connectivité" "test_connectivite_complete.dart" "Tests de connectivité réseau et serveurs"

# Test 6: Tests interface web
run_test "Tests Interface Web" "test_interface_moderne.dart" "Tests de l'interface web moderne"

# Résultats finaux
echo "📊 RÉSULTATS FINAUX"
echo "==================="
echo "Tests exécutés: $totalTests"
echo "Tests réussis: $passedTests"
echo "Tests échoués: $((totalTests - passedTests))"

if [ $passedTests -eq $totalTests ]; then
    echo -e "${GREEN}🎉 TOUS LES TESTS SONT PASSÉS !${NC}"
    echo -e "${GREEN}L'interface moderne Pandora Box fonctionne parfaitement !${NC}"
    echo ""
    echo "🚀 PRÊT POUR LA PRODUCTION !"
    echo "📱 Application Flutter: http://localhost:8080"
    echo "🖥️  Interface Web: http://localhost:5001"
    echo "🔌 Serveur WebSocket: ws://localhost:5002"
elif [ $passedTests -gt $((totalTests / 2)) ]; then
    echo -e "${YELLOW}⚠️  LA MAJORITÉ DES TESTS SONT PASSÉS${NC}"
    echo -e "${YELLOW}L'interface fonctionne mais quelques améliorations sont possibles${NC}"
else
    echo -e "${RED}❌ NOMBREUX TESTS ONT ÉCHOUÉ${NC}"
    echo -e "${RED}Vérifiez les logs ci-dessus et corrigez les problèmes${NC}"
fi

echo ""
echo "📋 RAPPORTS DISPONIBLES:"
echo "• GUIDE_INTERFACE_MODERNE.md - Guide d'utilisation"
echo "• RAPPORT_DEBUG_FINAL.md - Rapport de débogage"
echo "• demo_interface_moderne.sh - Script de démonstration"
echo ""
echo "🔧 COMMANDES UTILES:"
echo "• dart serveur_multijoueur_ameliore.dart - Démarrer le serveur"
echo "• flutter run --web-port=8080 - Lancer l'app Flutter"
echo "• ./demo_interface_moderne.sh - Démonstration complète"
