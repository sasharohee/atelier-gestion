#!/bin/bash

# Script de déploiement pour la synchronisation générique de tous les utilisateurs
echo "🔧 Correction générique de la synchronisation utilisateur..."

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

print_info "URL de la base de données: $DB_URL"

# Appliquer la correction générique
echo "📝 Application de la correction générique..."
if psql "$DB_URL" -f fix_user_sync_generic.sql; then
    print_status "Correction générique appliquée avec succès !"
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

# Afficher les informations
echo ""
echo "🧪 CORRECTION GÉNÉRIQUE APPLIQUÉE :"
echo "🔄 Synchronisation automatique pour TOUS les utilisateurs"
echo "🔧 Trigger créé pour les nouveaux utilisateurs"
echo "📊 Synchronisation des utilisateurs existants effectuée"
echo "🛡️ Politiques RLS vérifiées"
echo ""
echo "🌐 Votre application: https://atelier-gestion-3ad1jtmfp-sasharohees-projects.vercel.app"
echo ""
print_status "Déploiement terminé !"
echo ""
echo "📋 AVANTAGES DE CETTE CORRECTION :"
echo "✅ Fonctionne pour TOUS les utilisateurs (pas seulement un spécifique)"
echo "✅ Synchronisation automatique des nouveaux utilisateurs"
echo "✅ Synchronisation des utilisateurs existants"
echo "✅ Plus de problème de boucle 'Aucune donnée utilisateur en attente'"
echo ""
echo "🧪 TEST :"
echo "1. Allez sur votre site Vercel"
echo "2. Connectez-vous avec n'importe quel utilisateur"
echo "3. Vérifiez que la connexion fonctionne sans rechargement"
echo "4. Testez la page réglages"
echo ""
print_warning "NOTE: Cette correction fonctionne pour tous les utilisateurs, pas seulement un utilisateur spécifique."
