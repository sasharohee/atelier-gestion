#!/bin/bash

# Script de déploiement pour corriger l'erreur de récursion infinie RLS
echo "🔧 Déploiement de la correction RLS récursion infinie..."

# Vérifier que Supabase CLI est installé
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "supabase/config.toml" ]; then
    echo "❌ Fichier supabase/config.toml non trouvé. Assurez-vous d'être dans le bon répertoire."
    exit 1
fi

# Appliquer la correction SQL
echo "📝 Application de la correction RLS..."
supabase db reset --linked

# Exécuter le script de correction
echo "🔧 Exécution du script de correction..."
supabase db push --linked

# Appliquer le script SQL spécifique
echo "📋 Application du script fix_rls_recursion_infinite.sql..."
supabase db push --linked --file fix_rls_recursion_infinite.sql

echo "✅ Correction RLS récursion infinie déployée avec succès!"
echo "🌐 L'application devrait maintenant fonctionner sans erreur 500."

# Vérifier le statut
echo "🔍 Vérification du statut..."
supabase status
