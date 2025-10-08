# 🎮 Pandora Box - Rooms Partagées

## 🚀 Solution Complète

**Problème résolu :** Les rooms ne sont plus partagées entre les onglets/PC !

### 📋 **Une Seule Commande :**
```bash
dart run lancer_complet.dart
```

### 🌐 **URLs à Partager :**
- **Application** : `http://192.0.0.2:8080`
- **API Backend** : `http://192.0.0.2:5000`

### 🎯 **Comment ça Marche :**

1. **Serveur Backend** (port 5000) :
   - Stocke toutes les rooms créées
   - Synchronise les données entre tous les PC
   - API REST pour créer/rejoindre les rooms

2. **Application Flutter** (port 8080) :
   - Interface utilisateur
   - Se connecte au serveur backend
   - Affiche les rooms en temps réel

### 📱 **Instructions pour l'Autre PC :**

1. Connectez-vous au même WiFi
2. Ouvrez un navigateur
3. Allez à : `http://192.0.0.2:8080`
4. **Les rooms sont maintenant partagées !** 🎉

### ✅ **Avantages :**
- ✅ Rooms partagées entre tous les PC
- ✅ Synchronisation en temps réel
- ✅ Une seule commande à retenir
- ✅ Pas de configuration complexe

### 🔧 **Si ça ne Marche Pas :**
- Vérifiez que les deux PC sont sur le même WiFi
- Vérifiez que l'IP affichée est correcte
- Redémarrez les deux PC si nécessaire

### 🛑 **Pour Arrêter :**
Appuyez sur `Ctrl+C` dans le terminal
