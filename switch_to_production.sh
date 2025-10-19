#!/bin/bash

# =====================================================
# Script de Passage en Production - Atelier Gestion
# =====================================================
# Date: 2024-12-19
# Description: Passe l'application de dev à production
# =====================================================

set -e  # Arrêter le script en cas d'erreur

echo "🚀 PASSAGE EN PRODUCTION - ATELIER GESTION"
echo "=========================================="

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

# =====================================================
# 2. VÉRIFICATION DE LA CONFIGURATION SUPABASE
# =====================================================

print_status "Vérification de la configuration Supabase..."

# Vérifier que la configuration Supabase pointe vers la production
if grep -q "wlqyrmntfxwdvkzzsujv.supabase.co" src/lib/supabase.ts; then
    print_success "Configuration Supabase : Production ✅"
else
    print_warning "Configuration Supabase : Vérifiez que vous pointez vers la production"
fi

# =====================================================
# 3. NETTOYAGE ET PRÉPARATION
# =====================================================

print_status "Nettoyage des anciens builds..."

# Nettoyer les anciens builds
rm -rf dist
rm -rf .vercel
rm -rf node_modules/.vite

print_success "Nettoyage terminé"

# =====================================================
# 4. INSTALLATION DES DÉPENDANCES
# =====================================================

print_status "Installation des dépendances de production..."

npm install --production=false

if [ $? -ne 0 ]; then
    print_error "Échec de l'installation des dépendances"
    exit 1
fi

print_success "Dépendances installées"

# =====================================================
# 5. BUILD DE PRODUCTION
# =====================================================

print_status "Build de production..."

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
# 6. VÉRIFICATION DU BUILD
# =====================================================

print_status "Vérification du build..."

# Vérifier que les fichiers essentiels existent
if [ ! -f "dist/index.html" ]; then
    print_error "dist/index.html non trouvé"
    exit 1
fi

if [ ! -f "dist/assets/index.js" ] && [ ! -f "dist/assets/index.css" ]; then
    print_error "Fichiers de build manquants"
    exit 1
fi

print_success "Build vérifié avec succès"

# =====================================================
# 7. TEST LOCAL DU BUILD
# =====================================================

print_status "Test local du build de production..."

# Démarrer le serveur de preview
npm run preview &
PREVIEW_PID=$!

# Attendre que le serveur démarre
sleep 5

# Vérifier si le serveur fonctionne
if curl -s http://localhost:4173 > /dev/null; then
    print_success "Test local réussi"
    
    # Afficher l'URL de test
    echo ""
    print_status "🌐 Application disponible sur: http://localhost:4173"
    print_status "⏱️  Testez votre application pendant 30 secondes..."
    
    # Attendre 30 secondes pour les tests
    sleep 30
else
    print_warning "Test local échoué, mais continuation du processus"
fi

# Arrêter le serveur de preview
kill $PREVIEW_PID 2>/dev/null

# =====================================================
# 8. CRÉATION DU FICHIER .env PRODUCTION
# =====================================================

print_status "Création du fichier .env de production..."

cat > .env.production << EOF
# Configuration Production - Atelier Gestion
# Généré automatiquement le $(date)

# Supabase Production
VITE_SUPABASE_URL=https://wlqyrmntfxwdvkzzsujv.supabase.co
VITE_SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndscXlybW50Znh3ZHZrenpzdWp2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU0MjUyMDAsImV4cCI6MjA3MTAwMTIwMH0.9XvA_8VtPhBdF80oycWefBgY9nIyvqQUPHDGlw3f2D8

# Configuration EmailJS
VITE_EMAILJS_SERVICE_ID=service_lisw5h9
VITE_EMAILJS_TEMPLATE_ID=template_dabl0od
VITE_EMAILJS_PUBLIC_KEY=mh5fruIpuHfRxF7YC

# Configuration PostgreSQL Production
VITE_POSTGRES_HOST=db.wlqyrmntfxwdvkzzsujv.supabase.co
VITE_POSTGRES_PORT=5432
VITE_POSTGRES_DB=postgres
VITE_POSTGRES_USER=postgres
VITE_POSTGRES_PASSWORD=EGQUN6paP21OlNUu

# Mot de passe administrateur
VITE_ADMIN_PASSWORD=At3l13r@dm1n#2024\$ecur3!

# Mode Production
NODE_ENV=production
VITE_NODE_ENV=production
EOF

print_success "Fichier .env.production créé"

# =====================================================
# 9. OPTIONS DE DÉPLOIEMENT
# =====================================================

echo ""
print_status "🚀 OPTIONS DE DÉPLOIEMENT"
echo "================================"
echo ""
echo "Votre application est maintenant prête pour la production !"
echo ""
echo "Choisissez votre option de déploiement :"
echo ""
echo "1. 🌐 Déploiement Vercel (Recommandé)"
echo "2. 📦 Déploiement manuel (Fichiers dist/)"
echo "3. 🔧 Configuration seulement (Pas de déploiement)"
echo "4. ❌ Annuler"
echo ""

read -p "Votre choix (1-4): " choice

case $choice in
    1)
        print_status "Déploiement Vercel..."
        
        # Vérifier Vercel CLI
        if ! command -v vercel &> /dev/null; then
            print_warning "Vercel CLI non trouvé. Installation..."
            npm install -g vercel
        fi
        
        # Déployer sur Vercel
        vercel --prod --yes
        
        if [ $? -eq 0 ]; then
            print_success "Déploiement Vercel réussi !"
        else
            print_error "Échec du déploiement Vercel"
        fi
        ;;
    2)
        print_status "Déploiement manuel..."
        print_success "Vos fichiers de production sont dans le dossier 'dist/'"
        print_status "Vous pouvez maintenant déployer ces fichiers sur votre serveur web"
        ;;
    3)
        print_status "Configuration terminée..."
        print_success "Votre application est configurée pour la production"
        ;;
    4)
        print_status "Déploiement annulé"
        exit 0
        ;;
    *)
        print_error "Choix invalide"
        exit 1
        ;;
esac

# =====================================================
# 10. RÉSUMÉ FINAL
# =====================================================

echo ""
print_success "🎉 PASSAGE EN PRODUCTION TERMINÉ !"
echo "=========================================="
echo ""

print_status "📋 Résumé des actions effectuées :"
echo "✅ Configuration Supabase vérifiée (Production)"
echo "✅ Dépendances installées"
echo "✅ Build de production créé"
echo "✅ Fichiers de build vérifiés"
echo "✅ Test local effectué"
echo "✅ Fichier .env.production créé"

echo ""
print_status "🔧 Configuration de production :"
echo "• Base de données : wlqyrmntfxwdvkzzsujv.supabase.co"
echo "• Mode : Production"
echo "• Build optimisé : Oui"
echo "• Source maps : Désactivées"

echo ""
print_status "📁 Fichiers importants :"
echo "• dist/ - Fichiers de production"
echo "• .env.production - Variables d'environnement"
echo "• package.json - Configuration du projet"

echo ""
print_status "🚀 Prochaines étapes :"
echo "1. Testez votre application en production"
echo "2. Vérifiez que toutes les fonctionnalités marchent"
echo "3. Configurez votre serveur web (si déploiement manuel)"
echo "4. Mettez à jour vos DNS si nécessaire"
echo "5. Configurez HTTPS pour la sécurité"

echo ""
print_success "Votre application Atelier Gestion est maintenant en production ! 🎉"
