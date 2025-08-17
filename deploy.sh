#!/bin/bash

# Script de déploiement pour Atelier Gestion
# Usage: ./deploy.sh [VOTRE_USERNAME_GITHUB]

echo "🚀 Déploiement de Atelier Gestion sur GitHub Pages"
echo "=================================================="

# Vérifier si un nom d'utilisateur est fourni
if [ -z "$1" ]; then
    echo "❌ Erreur: Veuillez fournir votre nom d'utilisateur GitHub"
    echo "Usage: ./deploy.sh [VOTRE_USERNAME_GITHUB]"
    echo ""
    echo "Exemple: ./deploy.sh john-doe"
    exit 1
fi

USERNAME=$1

echo "👤 Nom d'utilisateur GitHub: $USERNAME"
echo ""

# Mettre à jour l'URL dans package.json
echo "📝 Mise à jour de l'URL GitHub Pages..."
sed -i '' "s/\[VOTRE_USERNAME\]/$USERNAME/g" package.json

# Ajouter le remote GitHub s'il n'existe pas déjà
if ! git remote | grep -q origin; then
    echo "🔗 Ajout du remote GitHub..."
    git remote add origin https://github.com/$USERNAME/atelier-gestion.git
else
    echo "✅ Remote GitHub déjà configuré"
fi

# Pousser les changements
echo "📤 Poussée des changements vers GitHub..."
git add .
git commit -m "Configuration finale pour GitHub Pages"
git push -u origin main

echo ""
echo "✅ Déploiement terminé !"
echo ""
echo "📋 Prochaines étapes :"
echo "1. Allez sur https://github.com/$USERNAME/atelier-gestion"
echo "2. Dans Settings > Pages, configurez :"
echo "   - Source: Deploy from a branch"
echo "   - Branch: gh-pages"
echo "   - Folder: / (root)"
echo "3. Votre application sera accessible à :"
echo "   https://$USERNAME.github.io/atelier-gestion"
echo ""
echo "🎉 Bonne chance avec votre atelier de réparation !"
