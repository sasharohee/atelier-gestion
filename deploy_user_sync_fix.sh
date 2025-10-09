#!/bin/bash

# Script de déploiement pour la correction de synchronisation des utilisateurs
# Applique automatiquement la correction via Supabase CLI

set -e  # Arrêter le script en cas d'erreur

echo "======================================================"
echo "  CORRECTION SYNCHRONISATION UTILISATEURS"
echo "======================================================"
echo ""

# Vérifier que Supabase CLI est installé
if ! command -v supabase &> /dev/null; then
    echo "❌ Erreur: Supabase CLI n'est pas installé"
    echo "   Installation: npm install -g supabase"
    exit 1
fi

echo "✅ Supabase CLI trouvé"
echo ""

# Vérifier que le fichier SQL existe
if [ ! -f "fix_user_sync_complete.sql" ]; then
    echo "❌ Erreur: Le fichier fix_user_sync_complete.sql est introuvable"
    exit 1
fi

echo "✅ Fichier SQL trouvé"
echo ""

# Demander confirmation
read -p "⚠️  Voulez-vous appliquer la correction ? (o/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[OoYy]$ ]]; then
    echo "❌ Opération annulée"
    exit 0
fi

echo ""
echo "📤 Application de la correction..."
echo ""

# Appliquer le script SQL via Supabase CLI
if supabase db execute --file fix_user_sync_complete.sql; then
    echo ""
    echo "======================================================"
    echo "  ✅ CORRECTION APPLIQUÉE AVEC SUCCÈS"
    echo "======================================================"
    echo ""
    echo "📋 Actions effectuées :"
    echo "   • Triggers de synchronisation créés"
    echo "   • Tous les utilisateurs existants synchronisés"
    echo "   • Système de logging activé"
    echo ""
    echo "🔍 Pour vérifier l'état :"
    echo "   SELECT * FROM check_sync_status_detailed();"
    echo ""
    echo "🔧 Pour réparer manuellement :"
    echo "   SELECT * FROM repair_missing_users();"
    echo ""
else
    echo ""
    echo "======================================================"
    echo "  ❌ ERREUR LORS DE L'APPLICATION"
    echo "======================================================"
    echo ""
    echo "Solutions possibles :"
    echo "1. Vérifier que vous êtes connecté à Supabase (supabase login)"
    echo "2. Vérifier que votre projet est lié (supabase link)"
    echo "3. Appliquer manuellement via l'interface Supabase SQL Editor"
    echo ""
    exit 1
fi

