# 🎮 Pandora Box - Script de Démarrage pour Utilisateur 2 (Windows)
# Ce script vérifie l'installation et guide l'utilisateur

Write-Host "🎮 Pandora Box - Vérification de l'installation..." -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green

# Vérifier Flutter
Write-Host "📱 Vérification de Flutter..." -ForegroundColor Yellow
try {
    $flutterVersion = flutter --version
    Write-Host "✅ Flutter est installé" -ForegroundColor Green
    Write-Host $flutterVersion
} catch {
    Write-Host "❌ Flutter n'est pas installé" -ForegroundColor Red
    Write-Host "📥 Installez Flutter depuis : https://flutter.dev/docs/get-started/install" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Vérifier Dart
Write-Host "🎯 Vérification de Dart..." -ForegroundColor Yellow
try {
    $dartVersion = dart --version
    Write-Host "✅ Dart est installé" -ForegroundColor Green
    Write-Host $dartVersion
} catch {
    Write-Host "❌ Dart n'est pas installé" -ForegroundColor Red
    Write-Host "📥 Dart est normalement inclus avec Flutter" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Installer les dépendances
Write-Host "📦 Installation des dépendances..." -ForegroundColor Yellow
try {
    flutter pub get
    Write-Host "✅ Dépendances installées avec succès" -ForegroundColor Green
} catch {
    Write-Host "❌ Erreur lors de l'installation des dépendances" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Installation terminée !" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Prochaines étapes :" -ForegroundColor Cyan
Write-Host "1. Demandez l'adresse IP du PC principal à l'utilisateur 1" -ForegroundColor White
Write-Host "2. Ouvrez votre navigateur web" -ForegroundColor White
Write-Host "3. Allez à : http://[IP_DU_PC_PRINCIPAL]:8084" -ForegroundColor White
Write-Host "4. Profitez du jeu multijoueur !" -ForegroundColor White
Write-Host ""
Write-Host "📖 Pour plus d'informations, consultez INSTRUCTIONS_UTILISATEUR2.md" -ForegroundColor Cyan
