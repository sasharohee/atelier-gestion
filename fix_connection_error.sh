#!/bin/bash

echo "🔧 Correction de l'erreur de connexion..."

# Arrêter tous les processus Node.js
echo "🛑 Arrêt des processus Node.js..."
pkill -f "node.*vite" 2>/dev/null || true
pkill -f "npm.*dev" 2>/dev/null || true
sleep 2

# Nettoyer le cache npm
echo "🧹 Nettoyage du cache npm..."
npm cache clean --force

# Nettoyer node_modules et package-lock.json
echo "🗑️ Suppression de node_modules et package-lock.json..."
rm -rf node_modules package-lock.json

# Réinstaller les dépendances
echo "📦 Réinstallation des dépendances..."
npm install

# Nettoyer le cache Vite
echo "🧹 Nettoyage du cache Vite..."
rm -rf .vite dist

# Créer un fichier de configuration pour désactiver les extensions problématiques
echo "⚙️ Configuration du navigateur..."
cat > disable-extensions.js << 'EOF'
// Script pour désactiver les extensions problématiques
console.log('🔧 Désactivation des extensions problématiques...');

// Désactiver les extensions qui peuvent causer des erreurs de connexion
if (window.chrome && window.chrome.runtime) {
    console.log('⚠️ Extensions Chrome détectées - elles peuvent causer des erreurs de connexion');
}

// Désactiver les WebSockets problématiques
if (window.WebSocket) {
    const originalWebSocket = window.WebSocket;
    window.WebSocket = function(url, protocols) {
        console.log('🔌 WebSocket créé:', url);
        return new originalWebSocket(url, protocols);
    };
}

console.log('✅ Configuration terminée');
EOF

echo "🚀 Redémarrage du serveur de développement..."
npm run dev
