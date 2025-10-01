#!/bin/bash

# Script de démarrage avec corrections appliquées
# Atelier Gestion - Version corrigée

echo "🚀 Démarrage de l'application Atelier Gestion avec corrections..."
echo "================================================================"

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages colorés
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

# Vérifier si Node.js est installé
if ! command -v node &> /dev/null; then
    print_error "Node.js n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

# Vérifier si npm est installé
if ! command -v npm &> /dev/null; then
    print_error "npm n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

print_status "Vérification de l'environnement..."

# Vérifier la version de Node.js
NODE_VERSION=$(node --version)
print_status "Version Node.js: $NODE_VERSION"

# Vérifier la version de npm
NPM_VERSION=$(npm --version)
print_status "Version npm: $NPM_VERSION"

# Nettoyer le cache npm
print_status "Nettoyage du cache npm..."
npm cache clean --force

# Installer les dépendances
print_status "Installation des dépendances..."
npm install

# Vérifier les vulnérabilités
print_status "Vérification des vulnérabilités..."
npm audit --audit-level=high

# Nettoyer le cache de build
print_status "Nettoyage du cache de build..."
rm -rf dist/
rm -rf build/
rm -rf node_modules/.vite/

# Vérifier la configuration Supabase
print_status "Vérification de la configuration Supabase..."
if [ -f ".env" ]; then
    print_success "Fichier .env trouvé"
else
    print_warning "Fichier .env non trouvé, utilisation des valeurs par défaut"
fi

# Démarrer le serveur de développement
print_status "Démarrage du serveur de développement..."
print_success "Application disponible sur: http://localhost:5173"
print_success "Page de test disponible sur: http://localhost:5173/test_application_fix.html"
print_warning "Appuyez sur Ctrl+C pour arrêter le serveur"

# Démarrer Vite avec les options de correction
npm run dev -- --host --port 5173

print_status "Serveur arrêté."

