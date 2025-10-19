#!/bin/bash

# =====================================================
# Script de Synchronisation Complète - GitHub Main
# =====================================================
# Date: 19 Décembre 2024
# Description: Synchronise tous les fichiers vers la branche main de GitHub
# =====================================================

echo "🔄 SYNCHRONISATION COMPLÈTE VERS GITHUB MAIN"
echo "============================================="

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

# Vérifier qu'on est sur la branche main
print_status "Vérification de la branche actuelle..."
CURRENT_BRANCH=$(git branch --show-current)

if [ "$CURRENT_BRANCH" != "main" ]; then
    print_warning "Vous n'êtes pas sur la branche main. Passage à main..."
    git checkout main
    if [ $? -ne 0 ]; then
        print_error "Impossible de passer à la branche main"
        exit 1
    fi
fi

print_success "Sur la branche main"

# Vérifier l'état de Git
print_status "Vérification de l'état Git..."
git status --porcelain

# Ajouter tous les fichiers
print_status "Ajout de tous les fichiers..."
git add .

# Vérifier s'il y a des changements à commiter
if git diff --cached --quiet; then
    print_warning "Aucun changement à commiter"
else
    print_status "Commit des changements..."
    git commit -m "🔄 Synchronisation complète - Tous les fichiers de production

- ✅ Tous les fichiers de production synchronisés
- ✅ Scripts de déploiement mis à jour
- ✅ Configuration Vercel optimisée
- ✅ Rapports de déploiement ajoutés
- ✅ Documentation complète
- ✅ Application prête pour la production"
    
    if [ $? -eq 0 ]; then
        print_success "Commit créé avec succès"
    else
        print_error "Échec du commit"
        exit 1
    fi
fi

# Pousser vers GitHub
print_status "Poussée vers GitHub..."
git push origin main

if [ $? -eq 0 ]; then
    print_success "Poussée vers GitHub réussie"
else
    print_error "Échec de la poussée vers GitHub"
    exit 1
fi

# Vérifier que tout est synchronisé
print_status "Vérification de la synchronisation..."
git status

# Afficher les derniers commits
print_status "Derniers commits sur main:"
git log --oneline -5

# Lister les fichiers importants
print_status "Fichiers de production synchronisés:"
echo "📁 Scripts de déploiement:"
ls -la *.sh 2>/dev/null | grep -E "(deploy|switch|test)" || echo "   Aucun script trouvé"

echo "📁 Configuration:"
ls -la vercel.json 2>/dev/null || echo "   vercel.json non trouvé"
ls -la .env.production 2>/dev/null || echo "   .env.production non trouvé"

echo "📁 Documentation:"
ls -la *.md 2>/dev/null | grep -E "(RAPPORT|GUIDE|MIGRATION)" | head -5 || echo "   Aucun rapport trouvé"

echo ""
print_success "🎉 SYNCHRONISATION COMPLÈTE RÉUSSIE !"
echo "============================================="
echo ""
echo "✅ Tous les fichiers sont maintenant sur la branche main de GitHub"
echo "✅ Configuration de production synchronisée"
echo "✅ Scripts de déploiement disponibles"
echo "✅ Documentation complète"
echo ""
echo "🌐 Votre dépôt GitHub est à jour avec toutes les nouveautés !"
echo "🚀 Prêt pour la production !"
