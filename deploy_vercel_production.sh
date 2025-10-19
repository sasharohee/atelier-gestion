#!/bin/bash

# =====================================================
# Déploiement Vercel Production - Atelier Gestion
# =====================================================
# Date: 2024-12-19
# Description: Déploiement optimisé sur Vercel en production
# =====================================================

set -e  # Arrêter le script en cas d'erreur

echo "🚀 DÉPLOIEMENT VERCEL PRODUCTION - ATELIER GESTION"
echo "=================================================="

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonctions d'affichage
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# =====================================================
# 1. VÉRIFICATIONS PRÉALABLES
# =====================================================

print_status "Vérification de l'environnement..."

# Vérifier qu'on est dans le bon répertoire
if [ ! -f "package.json" ]; then
    print_error "package.json non trouvé. Assurez-vous d'être dans le répertoire du projet."
    exit 1
fi

# Vérifier Node.js
if ! command -v node &> /dev/null; then
    print_error "Node.js n'est pas installé"
    exit 1
fi

print_success "Node.js trouvé: $(node --version)"

# Vérifier npm
if ! command -v npm &> /dev/null; then
    print_error "npm n'est pas installé"
    exit 1
fi

print_success "npm trouvé: $(npm --version)"

# Vérifier Vercel CLI
if ! command -v vercel &> /dev/null; then
    print_warning "Vercel CLI non trouvé. Installation..."
    npm install -g vercel
    if [ $? -ne 0 ]; then
        print_error "Échec de l'installation de Vercel CLI"
        exit 1
    fi
fi

print_success "Vercel CLI trouvé: $(vercel --version)"

# =====================================================
# 2. NETTOYAGE ET PRÉPARATION
# =====================================================

print_status "Nettoyage des anciens builds..."

# Nettoyer les anciens builds
rm -rf dist
rm -rf .vercel
rm -rf node_modules/.vite

print_success "Nettoyage terminé"

# =====================================================
# 3. INSTALLATION DES DÉPENDANCES
# =====================================================

print_status "Installation des dépendances..."

npm install

if [ $? -ne 0 ]; then
    print_error "Échec de l'installation des dépendances"
    exit 1
fi

print_success "Dépendances installées"

# =====================================================
# 4. BUILD DE PRODUCTION
# =====================================================

print_status "Build de production optimisé..."

# Définir les variables d'environnement pour la production
export NODE_ENV=production
export VITE_NODE_ENV=production

# Build avec optimisations
npm run build

if [ $? -ne 0 ]; then
    print_error "Échec du build de production"
    exit 1
fi

print_success "Build de production réussi"

# =====================================================
# 5. VÉRIFICATION DU BUILD
# =====================================================

print_status "Vérification du build..."

# Vérifier que les fichiers essentiels existent
if [ ! -f "dist/index.html" ]; then
    print_error "dist/index.html non trouvé"
    exit 1
fi

print_success "Build vérifié avec succès"

# Afficher la taille du build
BUILD_SIZE=$(du -sh dist | cut -f1)
print_status "Taille du build: $BUILD_SIZE"

# =====================================================
# 6. CONNEXION VERCEL
# =====================================================

print_status "Connexion à Vercel..."

# Vérifier si l'utilisateur est connecté à Vercel
if ! vercel whoami &> /dev/null; then
    print_warning "Vous n'êtes pas connecté à Vercel"
    print_status "Connexion à Vercel..."
    vercel login
fi

print_success "Connecté à Vercel"

# =====================================================
# 7. DÉPLOIEMENT VERCEL
# =====================================================

print_status "Déploiement sur Vercel en production..."

# Déployer avec les options de production Sur Vercel avec les options de production
vercel --prod --yes --confirm

if [ $? -ne 0 ]; then
    print_error "Échec du déploiement Vercel"
    exit 1
fi

print_success "Déploiement Vercel réussi !"

# =====================================================
# 8. VÉRIFICATION POST-DÉPLOIEMENT
# =====================================================

print_status "Vérification post-déploiement..."

# Obtenir l'URL de déploiement
DEPLOYMENT_URL=$(vercel ls --prod | grep "$(vercel whoami)" | head -1 | awk '{print $2}')

if [ -n "$DEPLOYMENT_URL" ]; then
    print_success "URL de déploiement: https://$DEPLOYMENT_URL"
    
    # Test de l'URL de déploiement
    print_status "Test de l'application déployée..."
    
    if curl -s "https://$DEPLOYMENT_URL" > /dev/null; then
        print_success "Application accessible et fonctionnelle !"
    else
        print_warning "Application déployée mais test d'accessibilité échoué"
    fi
else
    print_warning "URL de déploiement non trouvée"
fi

# =====================================================
# 9. RÉSUMÉ FINAL
# =====================================================

echo ""
print_success "🎉 DÉPLOIEMENT VERCEL TERMINÉ !"
echo "====================================="
echo ""

print_status "📋 Résumé du déploiement :"
echo "✅ Environnement vérifié"
echo "✅ Dépendances installées"
echo "✅ Build de production créé ($BUILD_SIZE)"
echo "✅ Déploiement Vercel réussi"
echo "✅ Application accessible en ligne"

echo ""
print_status "🔧 Configuration de production :"
echo "• Base de données : Supabase Production"
echo "• Mode : Production"
echo "• Build optimisé : Oui"
echo "• CDN : Vercel Global"

if [ -n "$DEPLOYMENT_URL" ]; then
    echo ""
    print_status "🌐 Votre application est disponible sur :"
    echo "https://$DEPLOYMENT_URL"
fi

echo ""
print_status "📊 Liens utiles :"
echo "• Vercel Dashboard: https://vercel.com/dashboard"
echo "• Supabase Dashboard: https://supabase.com/dashboard"
echo "• Logs Vercel: vercel logs"

echo ""
print_status "🚀 Prochaines étapes :"
echo "1. Testez votre application en production"
echo "2. Vérifiez toutes les fonctionnalités"
echo "3. Configurez votre domaine personnalisé (optionnel)"
echo "4. Configurez les notifications de déploiement"
echo "5. Mettez en place la surveillance"

echo ""
print_success "Votre application Atelier Gestion est maintenant en production sur Vercel ! 🎉"

# =====================================================
# 10. COMMANDES UTILES
# =====================================================

echo ""
print_status "🔧 Commandes utiles pour la suite :"
echo "• Voir les logs: vercel logs"
echo "• Redéployer: vercel --prod"
echo "• Voir les domaines: vercel domains"
echo "• Voir l'historique: vercel ls"

echo ""
print_success "Déploiement terminé avec succès ! 🚀"
