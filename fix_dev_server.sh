#!/bin/bash

# Script de nettoyage et redémarrage du serveur de développement
echo "🧹 Nettoyage du serveur de développement..."

# Arrêter tous les processus Node.js
echo "🛑 Arrêt des processus Node.js..."
pkill -f "node.*vite" 2>/dev/null || true
pkill -f "npm.*dev" 2>/dev/null || true

# Nettoyer les caches
echo "🗑️ Nettoyage des caches..."
rm -rf node_modules/.vite 2>/dev/null || true
rm -rf dist 2>/dev/null || true
rm -rf .vite 2>/dev/null || true

# Nettoyer le cache npm
echo "🧹 Nettoyage du cache npm..."
npm cache clean --force

# Réinstaller les dépendances si nécessaire
echo "📦 Vérification des dépendances..."
npm install

# Redémarrer le serveur
echo "🚀 Redémarrage du serveur de développement..."
npm run dev

