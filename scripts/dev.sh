#!/bin/bash

# Script pour lancer le serveur de développement
# Usage: ./scripts/dev.sh [vite|react]

echo "🚀 Lancement du serveur de développement"
echo "========================================"

# Vérifier si un argument est fourni
if [ -z "$1" ]; then
    echo "📝 Aucun serveur spécifié, utilisation de Vite par défaut"
    SERVER="vite"
else
    SERVER=$1
fi

case $SERVER in
    "vite")
        echo "⚡ Lancement avec Vite (recommandé)"
        echo "   - Hot reload ultra rapide"
        echo "   - Build optimisé"
        echo "   - Support TypeScript natif"
        echo ""
        npm run dev
        ;;
    "react")
        echo "⚛️  Lancement avec React Scripts"
        echo "   - Serveur de développement classique"
        echo "   - Compatibilité maximale"
        echo ""
        npm start
        ;;
    *)
        echo "❌ Serveur non reconnu: $SERVER"
        echo "   Options disponibles: vite, react"
        echo ""
        echo "Exemples:"
        echo "  ./scripts/dev.sh vite    # Lance avec Vite"
        echo "  ./scripts/dev.sh react   # Lance avec React Scripts"
        exit 1
        ;;
esac

