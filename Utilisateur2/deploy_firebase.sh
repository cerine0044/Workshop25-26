#!/bin/bash

# Script de déploiement et configuration Firebase
# Usage: ./deploy_firebase.sh [command]

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIREBASE_PROJECT="pandora-box-user2"

# Couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Fonction d'aide
show_help() {
    echo "🔥 Firebase Deployment Script"
    echo ""
    echo "COMMANDES DISPONIBLES:"
    echo "  setup       - Configuration initiale Firebase"
    echo "  deploy      - Déployer l'application"
    echo "  rules       - Déployer les règles de sécurité"
    echo "  backup      - Créer une sauvegarde"
    echo "  restore     - Restaurer depuis une sauvegarde"
    echo "  cleanup     - Nettoyer la base de données"
    echo "  monitor     - Surveiller la base de données"
    echo "  status      - Afficher le statut"
    echo "  logs        - Afficher les logs"
    echo "  maintenance - Démarrer la maintenance automatique"
    echo ""
    echo "EXEMPLES:"
    echo "  ./deploy_firebase.sh setup"
    echo "  ./deploy_firebase.sh deploy"
    echo "  ./deploy_firebase.sh backup"
    echo "  ./deploy_firebase.sh cleanup"
}

# Vérifier les prérequis
check_prerequisites() {
    log_info "Vérification des prérequis..."
    
    if ! command -v firebase &> /dev/null; then
        log_error "Firebase CLI n'est pas installé"
        log_info "Installez-le avec: npm install -g firebase-tools"
        exit 1
    fi
    
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter n'est pas installé"
        exit 1
    fi
    
    if ! command -v dart &> /dev/null; then
        log_error "Dart n'est pas installé"
        exit 1
    fi
    
    log_success "Tous les prérequis sont installés"
}

# Configuration initiale
setup_firebase() {
    log_info "Configuration initiale Firebase..."
    
    cd "$PROJECT_DIR"
    
    # Vérifier si Firebase est déjà configuré
    if [ -f "firebase.json" ]; then
        log_warning "Firebase est déjà configuré"
        return
    fi
    
    # Initialiser Firebase
    firebase init --project "$FIREBASE_PROJECT"
    
    # Déployer les règles de sécurité
    deploy_rules
    
    log_success "Configuration Firebase terminée"
}

# Déployer l'application
deploy_app() {
    log_info "Déploiement de l'application..."
    
    cd "$PROJECT_DIR"
    
    # Build Flutter
    log_info "Build Flutter..."
    flutter build web --release
    
    # Déployer sur Firebase Hosting
    log_info "Déploiement sur Firebase Hosting..."
    firebase deploy --only hosting --project "$FIREBASE_PROJECT"
    
    log_success "Application déployée avec succès"
    log_info "URL: https://$FIREBASE_PROJECT.web.app"
}

# Déployer les règles de sécurité
deploy_rules() {
    log_info "Déploiement des règles de sécurité..."
    
    cd "$PROJECT_DIR"
    
    if [ ! -f "database.rules.json" ]; then
        log_error "Fichier database.rules.json introuvable"
        exit 1
    fi
    
    firebase deploy --only database --project "$FIREBASE_PROJECT"
    
    log_success "Règles de sécurité déployées"
}

# Créer une sauvegarde
backup_database() {
    log_info "Création d'une sauvegarde..."
    
    cd "$PROJECT_DIR"
    
    # Utiliser le script CLI
    dart firebase_cli.dart backup
    
    log_success "Sauvegarde créée"
}

# Restaurer depuis une sauvegarde
restore_database() {
    if [ -z "$2" ]; then
        log_error "Usage: ./deploy_firebase.sh restore <filename>"
        exit 1
    fi
    
    log_info "Restauration depuis $2..."
    
    cd "$PROJECT_DIR"
    
    if [ ! -f "$2" ]; then
        log_error "Fichier de sauvegarde introuvable: $2"
        exit 1
    fi
    
    # Utiliser le script CLI
    dart firebase_cli.dart restore "$2"
    
    log_success "Restauration terminée"
}

# Nettoyer la base de données
cleanup_database() {
    log_info "Nettoyage de la base de données..."
    
    cd "$PROJECT_DIR"
    
    # Utiliser le script CLI avec options
    dart firebase_cli.dart cleanup --rooms 24 --players 7 --force
    
    log_success "Nettoyage terminé"
}

# Surveiller la base de données
monitor_database() {
    log_info "Surveillance de la base de données (Ctrl+C pour arrêter)..."
    
    cd "$PROJECT_DIR"
    
    # Utiliser le script CLI
    dart firebase_cli.dart monitor
}

# Afficher le statut
show_status() {
    log_info "Statut de la base de données..."
    
    cd "$PROJECT_DIR"
    
    # Utiliser le script CLI
    dart firebase_cli.dart stats
    
    # Afficher les informations du projet
    log_info "Informations du projet:"
    firebase projects:list --project "$FIREBASE_PROJECT"
}

# Afficher les logs
show_logs() {
    log_info "Logs Firebase..."
    
    cd "$PROJECT_DIR"
    
    firebase functions:log --project "$FIREBASE_PROJECT"
}

# Démarrer la maintenance automatique
start_maintenance() {
    log_info "Démarrage de la maintenance automatique..."
    
    cd "$PROJECT_DIR"
    
    # Créer un service systemd ou utiliser cron
    log_info "Configuration de la maintenance automatique..."
    
    # Exemple avec cron (à adapter selon l'OS)
    log_info "Ajoutez cette ligne à votre crontab pour une maintenance toutes les 6h:"
    log_info "0 */6 * * * cd $PROJECT_DIR && dart firebase_cli.dart cleanup --rooms 24 --players 7 --force"
    
    log_success "Maintenance automatique configurée"
}

# Fonction principale
main() {
    case "${1:-help}" in
        "setup")
            check_prerequisites
            setup_firebase
            ;;
        "deploy")
            check_prerequisites
            deploy_app
            ;;
        "rules")
            check_prerequisites
            deploy_rules
            ;;
        "backup")
            check_prerequisites
            backup_database
            ;;
        "restore")
            check_prerequisites
            restore_database "$@"
            ;;
        "cleanup")
            check_prerequisites
            cleanup_database
            ;;
        "monitor")
            check_prerequisites
            monitor_database
            ;;
        "status")
            check_prerequisites
            show_status
            ;;
        "logs")
            check_prerequisites
            show_logs
            ;;
        "maintenance")
            check_prerequisites
            start_maintenance
            ;;
        "help"|*)
            show_help
            ;;
    esac
}

# Exécuter la fonction principale
main "$@"
