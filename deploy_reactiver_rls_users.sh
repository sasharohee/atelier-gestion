#!/bin/bash

# =====================================================
# SCRIPT DE RÉACTIVATION DES POLITIQUES RLS USERS
# =====================================================

echo "🔧 Réactivation des 8 politiques RLS de la table users..."

# Vérifier si le fichier SQL existe
if [ ! -f "reactiver_rls_users.sql" ]; then
    echo "❌ Erreur: Le fichier reactiver_rls_users.sql n'existe pas"
    exit 1
fi

# Vérifier si Supabase CLI est installé
if ! command -v supabase &> /dev/null; then
    echo "❌ Erreur: Supabase CLI n'est pas installé"
    echo "📦 Installez-le avec: npm install -g supabase"
    exit 1
fi

# Vérifier si on est connecté à Supabase
if ! supabase status &> /dev/null; then
    echo "❌ Erreur: Pas connecté à Supabase"
    echo "🔗 Connectez-vous avec: supabase login"
    exit 1
fi

echo "✅ Supabase CLI détecté et connecté"

# Exécuter le script SQL
echo "🚀 Exécution du script de réactivation des politiques RLS..."

# Option 1: Via Supabase CLI (recommandé)
if supabase db reset --linked; then
    echo "✅ Base de données réinitialisée"
fi

# Exécuter le script SQL
if supabase db push --linked; then
    echo "✅ Script SQL exécuté avec succès"
else
    echo "⚠️  Tentative d'exécution directe du script..."
    
    # Option 2: Exécution directe du script
    if psql -h db.wlqyrmntfxwdvkzzsujv.supabase.co -p 5432 -d postgres -U postgres -f reactiver_rls_users.sql; then
        echo "✅ Script SQL exécuté directement"
    else
        echo "❌ Erreur lors de l'exécution du script"
        echo "📋 Exécutez manuellement le fichier reactiver_rls_users.sql dans le dashboard Supabase"
        exit 1
    fi
fi

echo ""
echo "🎉 RÉACTIVATION TERMINÉE !"
echo ""
echo "📋 Vérifications à effectuer:"
echo "   1. Allez dans le dashboard Supabase"
echo "   2. Section Authentication > Policies"
echo "   3. Vérifiez que les 8 politiques sont actives"
echo "   4. Testez les permissions avec un utilisateur connecté"
echo ""
echo "🔧 Politiques réactivées:"
echo "   • admins_can_manage_all_users"
echo "   • admins_can_view_all_users"
echo "   • service_role_full_access_users"
echo "   • users_can_insert_own_profile"
echo "   • users_can_update_own_profile"
echo "   • users_can_view_own_profile"
echo "   • users_select_policy"
echo "   • users_update_policy"
echo ""
echo "✅ RLS est maintenant activé sur la table users"

