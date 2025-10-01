#!/bin/bash

# Script de démarrage pour le développement local
# Atelier Gestion - Mode développement local

echo "🚀 Démarrage de l'application en mode développement local..."
echo "============================================================="

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

# Vérifier si Supabase CLI est installé
if ! command -v supabase &> /dev/null; then
    print_warning "Supabase CLI n'est pas installé. Installation..."
    npm install -g supabase
fi

# Vérifier si Supabase est en cours d'exécution
print_status "Vérification de Supabase local..."
if ! curl -s http://127.0.0.1:54321/health > /dev/null; then
    print_warning "Supabase local n'est pas en cours d'exécution. Démarrage..."
    npx supabase start
else
    print_success "Supabase local est en cours d'exécution"
fi

# Afficher les informations de connexion Supabase
print_status "Informations de connexion Supabase:"
echo "  API URL: http://127.0.0.1:54321"
echo "  Studio URL: http://127.0.0.1:54323"
echo "  DB URL: postgresql://postgres:postgres@127.0.0.1:54322/postgres"

# Nettoyer le cache npm
print_status "Nettoyage du cache npm..."
npm cache clean --force

# Installer les dépendances
print_status "Installation des dépendances..."
npm install

# Nettoyer le cache de build
print_status "Nettoyage du cache de build..."
rm -rf dist/
rm -rf build/
rm -rf node_modules/.vite/

# Démarrer le serveur de développement
print_status "Démarrage du serveur de développement..."
print_success "Application disponible sur: http://localhost:5173"
print_success "Supabase Studio disponible sur: http://127.0.0.1:54323"
print_warning "Appuyez sur Ctrl+C pour arrêter le serveur"

# Démarrer Vite avec les options de développement
npm run dev -- --host --port 5173

print_status "Serveur arrêté."

