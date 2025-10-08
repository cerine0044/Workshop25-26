#!/bin/bash

# 🎮 Pandora Box - Script de Démarrage pour Utilisateur 2
# Ce script vérifie l'installation et guide l'utilisateur

echo "🎮 Pandora Box - Vérification de l'installation..."
echo "=================================================="

# Vérifier Flutter
echo "📱 Vérification de Flutter..."
if command -v flutter &> /dev/null; then
    echo "✅ Flutter est installé"
    flutter --version
else
    echo "❌ Flutter n'est pas installé"
    echo "📥 Installez Flutter depuis : https://flutter.dev/docs/get-started/install"
    exit 1
fi

echo ""

# Vérifier Dart
echo "🎯 Vérification de Dart..."
if command -v dart &> /dev/null; then
    echo "✅ Dart est installé"
    dart --version
else
    echo "❌ Dart n'est pas installé"
    echo "📥 Dart est normalement inclus avec Flutter"
    exit 1
fi

echo ""

# Installer les dépendances
echo "📦 Installation des dépendances..."
flutter pub get

if [ $? -eq 0 ]; then
    echo "✅ Dépendances installées avec succès"
else
    echo "❌ Erreur lors de l'installation des dépendances"
    exit 1
fi

echo ""
echo "🎉 Installation terminée !"
echo ""
echo "📋 Prochaines étapes :"
echo "1. Demandez l'adresse IP du PC principal à l'utilisateur 1"
echo "2. Ouvrez votre navigateur web"
echo "3. Allez à : http://[IP_DU_PC_PRINCIPAL]:8084"
echo "4. Profitez du jeu multijoueur !"
echo ""
echo "📖 Pour plus d'informations, consultez INSTRUCTIONS_UTILISATEUR2.md"
