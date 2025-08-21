#!/bin/bash

# Script de déploiement automatisé pour Vercel
# Atelier Gestion Application

echo "🚀 Déploiement Vercel - Atelier Gestion"
echo "========================================"

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
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

# Vérifier si on est dans le bon répertoire
if [ ! -f "package.json" ]; then
    print_error "package.json non trouvé. Assurez-vous d'être dans le répertoire du projet."
    exit 1
fi

print_status "Vérification de l'environnement..."

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

# Nettoyer les anciens builds
print_status "Nettoyage des anciens builds..."
rm -rf dist
rm -rf .vercel

# Installer les dépendances
print_status "Installation des dépendances..."
npm install

if [ $? -ne 0 ]; then
    print_error "Échec de l'installation des dépendances"
    exit 1
fi

print_success "Dépendances installées"

# Exécuter le diagnostic
print_status "Exécution du diagnostic..."
node diagnostic-vercel.js

if [ $? -ne 0 ]; then
    print_warning "Le diagnostic a détecté des problèmes. Vérifiez la configuration."
fi

# Build de production
print_status "Build de production..."
npm run build

if [ $? -ne 0 ]; then
    print_error "Échec du build de production"
    exit 1
fi

print_success "Build de production réussi"

# Vérifier que le build a créé les fichiers nécessaires
if [ ! -f "dist/index.html" ]; then
    print_error "Le fichier dist/index.html n'a pas été créé"
    exit 1
fi

print_success "Fichiers de build vérifiés"

# Test local du build
print_status "Test local du build..."
npm run preview &
PREVIEW_PID=$!

# Attendre que le serveur démarre
sleep 3

# Vérifier si le serveur fonctionne
if curl -s http://localhost:4173 > /dev/null; then
    print_success "Test local réussi"
else
    print_warning "Test local échoué, mais continuation du déploiement"
fi

# Arrêter le serveur de preview
kill $PREVIEW_PID 2>/dev/null

# Déploiement Vercel
print_status "Déploiement sur Vercel..."

# Vérifier si l'utilisateur est connecté à Vercel
if ! vercel whoami &> /dev/null; then
    print_warning "Vous n'êtes pas connecté à Vercel"
    print_status "Connexion à Vercel..."
    vercel login
fi

# Déployer
vercel --prod --yes

if [ $? -ne 0 ]; then
    print_error "Échec du déploiement Vercel"
    exit 1
fi

print_success "Déploiement Vercel réussi!"

# Afficher les informations finales
echo ""
echo "🎉 Déploiement terminé avec succès!"
echo ""
echo "📋 Prochaines étapes:"
echo "1. Vérifiez votre application sur Vercel"
echo "2. Testez toutes les fonctionnalités"
echo "3. Vérifiez les variables d'environnement"
echo "4. Configurez Supabase si nécessaire"
echo ""
echo "🔗 Liens utiles:"
echo "- Vercel Dashboard: https://vercel.com/dashboard"
echo "- Supabase Dashboard: https://supabase.com/dashboard"
echo "- Guide de déploiement: GUIDE_DEPLOIEMENT_VERCEL.md"
echo ""

print_success "Script de déploiement terminé!"
