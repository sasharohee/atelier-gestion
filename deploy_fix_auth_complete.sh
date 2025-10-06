#!/bin/bash

# Script de déploiement pour corriger l'authentification et RLS
echo "🔧 Correction complète de l'authentification et RLS..."

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Vérifier que Supabase CLI est installé
if ! command -v supabase &> /dev/null; then
    print_error "Supabase CLI n'est pas installé. Installez-le d'abord."
    echo "npm install -g supabase"
    exit 1
fi

# Vérifier la connexion à Supabase
echo "🔍 Vérification de la connexion Supabase..."
if ! supabase status &> /dev/null; then
    print_error "Impossible de se connecter à Supabase. Vérifiez votre configuration."
    echo "Assurez-vous d'être dans le bon répertoire et que Supabase est initialisé."
    exit 1
fi

print_status "Connexion Supabase OK"

# Obtenir l'URL de la base de données
DB_URL=$(supabase status | grep 'DB URL' | awk '{print $3}')
if [ -z "$DB_URL" ]; then
    print_error "Impossible d'obtenir l'URL de la base de données"
    exit 1
fi

print_status "URL de la base de données: $DB_URL"

# Appliquer la correction
echo "📝 Application de la correction complète..."
if psql "$DB_URL" -f fix_auth_and_rls_complete.sql; then
    print_status "Correction appliquée avec succès !"
else
    print_error "Erreur lors de l'application de la correction."
    exit 1
fi

# Vérifier que la correction a fonctionné
echo "🔍 Vérification de la correction..."
if psql "$DB_URL" -c "SELECT 'Test de connexion' as status;" &> /dev/null; then
    print_status "Connexion à la base de données OK"
else
    print_warning "Problème de connexion à la base de données"
fi

# Afficher les informations de test
echo ""
echo "🧪 INFORMATIONS DE TEST :"
echo "📧 Email: test2@yopmail.com"
echo "🔑 Mot de passe: password123"
echo ""
echo "🌐 Votre application: https://atelier-gestion-3ad1jtmfp-sasharohees-projects.vercel.app"
echo ""
print_status "Déploiement terminé !"
echo ""
echo "📋 PROCHAINES ÉTAPES :"
echo "1. Allez sur votre site Vercel"
echo "2. Connectez-vous avec test2@yopmail.com / password123"
echo "3. Vérifiez que la page réglages fonctionne"
echo "4. Testez la sauvegarde des paramètres"
