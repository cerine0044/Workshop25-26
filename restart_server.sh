#!/bin/bash

# Script de redémarrage automatique du serveur Pandora Box
# Ce script est appelé automatiquement en cas d'erreur

echo "🔄 Redémarrage automatique du serveur Pandora Box..."
echo "=================================================="

# Arrêter tous les processus existants
echo "🛑 Arrêt des processus existants..."
pkill -f "dart run lancer_complet.dart" 2>/dev/null || true
pkill -f "flutter run" 2>/dev/null || true
sleep 3

# Nettoyer les ports
echo "🧹 Nettoyage des ports..."
lsof -ti:8085 | xargs kill -9 2>/dev/null || true
lsof -ti:5002 | xargs kill -9 2>/dev/null || true
sleep 2

# Redémarrer le serveur
echo "🚀 Redémarrage du serveur..."
cd "$(dirname "$0")"
dart run lancer_complet.dart &

echo "✅ Serveur redémarré avec succès!"
echo "🌐 Application disponible sur: http://192.168.1.20:8085"
echo "🔧 API disponible sur: http://192.168.1.20:5002"
