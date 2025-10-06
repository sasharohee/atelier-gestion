#!/bin/bash

# Script de diagnostic pour identifier le problème frontend
echo "🔍 Diagnostic du problème frontend..."

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo "🔍 Recherche des fichiers problématiques..."

# Rechercher les fichiers qui contiennent le message problématique
echo "📝 Recherche de 'Aucune donnée utilisateur en attente'..."
if grep -r "Aucune donnée utilisateur en attente" src/ 2>/dev/null; then
    print_warning "Message trouvé dans le code source"
else
    print_info "Message non trouvé dans le code source (probablement dans les logs)"
fi

# Rechercher les fichiers qui contiennent systemSettingsService
echo "📝 Recherche de 'systemSettingsService'..."
if grep -r "systemSettingsService" src/ 2>/dev/null; then
    print_warning "systemSettingsService trouvé dans le code"
    grep -r "systemSettingsService" src/ 2>/dev/null
else
    print_info "systemSettingsService non trouvé dans le code source"
fi

# Rechercher les fichiers qui contiennent getAllUsers
echo "📝 Recherche de 'getAllUsers'..."
if grep -r "getAllUsers" src/ 2>/dev/null; then
    print_warning "getAllUsers trouvé dans le code"
    grep -r "getAllUsers" src/ 2>/dev/null
else
    print_info "getAllUsers non trouvé dans le code source"
fi

# Rechercher les hooks useEffect
echo "📝 Recherche de 'useEffect'..."
if grep -r "useEffect" src/ 2>/dev/null; then
    print_info "useEffect trouvé dans le code"
    grep -r "useEffect" src/ 2>/dev/null | head -10
else
    print_info "useEffect non trouvé dans le code source"
fi

# Rechercher les boucles while
echo "📝 Recherche de boucles 'while'..."
if grep -r "while" src/ 2>/dev/null; then
    print_warning "Boucles while trouvées dans le code"
    grep -r "while" src/ 2>/dev/null
else
    print_info "Boucles while non trouvées dans le code source"
fi

# Rechercher les appels à Supabase
echo "📝 Recherche d'appels Supabase..."
if grep -r "supabase" src/ 2>/dev/null; then
    print_info "Appels Supabase trouvés dans le code"
    grep -r "supabase" src/ 2>/dev/null | head -10
else
    print_info "Appels Supabase non trouvés dans le code source"
fi

# Afficher la structure du projet
echo "📁 Structure du projet src/:"
if [ -d "src" ]; then
    find src -type f -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" | head -20
else
    print_error "Dossier src/ non trouvé"
fi

echo ""
echo "🧪 DIAGNOSTIC TERMINÉ"
echo ""
echo "📋 PROCHAINES ÉTAPES :"
echo "1. Vérifiez les fichiers identifiés ci-dessus"
echo "2. Cherchez les boucles infinies dans le code React"
echo "3. Ajoutez des conditions de sortie"
echo "4. Testez la connexion sans rechargement"
echo ""
print_warning "NOTE: Le problème vient probablement d'une boucle infinie dans le code React, pas de la base de données."
