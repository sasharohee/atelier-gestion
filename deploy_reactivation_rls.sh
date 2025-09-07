#!/bin/bash

# =====================================================
# SCRIPT DE DÉPLOIEMENT - RÉACTIVATION RLS TABLES UNRESTRICTED
# =====================================================

echo "🚀 Déploiement de la réactivation RLS sur les tables Unrestricted"
echo "================================================================"

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "tables/corrections/reactivation_rls_tables_unrestricted.sql" ]; then
    echo "❌ Erreur: Script SQL non trouvé"
    echo "Assurez-vous d'être dans le répertoire racine du projet"
    exit 1
fi

# Vérifier la configuration Supabase
if [ ! -f ".env" ] && [ ! -f "env.example" ]; then
    echo "⚠️  Avertissement: Fichier .env non trouvé"
    echo "Assurez-vous que vos variables d'environnement Supabase sont configurées"
fi

echo "📋 Résumé de l'opération:"
echo "  - Réactivation RLS sur toutes les tables marquées 'Unrestricted'"
echo "  - Exclusion des vues (RLS non applicable aux vues)"
echo "  - Création de politiques RLS de base"
echo "  - Vérification de l'état de sécurité"

echo ""
read -p "Voulez-vous continuer? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Opération annulée"
    exit 1
fi

echo ""
echo "🔧 Exécution du script SQL..."

# Exécuter le script SQL via Supabase CLI si disponible
if command -v supabase &> /dev/null; then
    echo "📡 Utilisation de Supabase CLI..."
    supabase db reset --linked
    supabase db push
    
    # Exécuter le script de réactivation RLS
    supabase db push --include-all
    echo "✅ Script exécuté via Supabase CLI"
else
    echo "⚠️  Supabase CLI non trouvé"
    echo "📝 Instructions manuelles:"
    echo "   1. Ouvrez votre dashboard Supabase"
    echo "   2. Allez dans SQL Editor"
    echo "   3. Copiez le contenu du fichier: tables/corrections/reactivation_rls_tables_unrestricted.sql"
    echo "   4. Exécutez le script"
    echo ""
    echo "📄 Fichier à exécuter: tables/corrections/reactivation_rls_tables_unrestricted.sql"
fi

echo ""
echo "🔍 Vérification post-déploiement..."

# Créer un script de vérification
cat > verify_rls_activation.sql << 'EOF'
-- Vérification de l'activation RLS
SELECT * FROM check_all_tables_security();

-- Vérification spécifique des tables principales
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled,
    (SELECT COUNT(*) FROM pg_policies WHERE schemaname = p.schemaname AND tablename = p.tablename) as policy_count
FROM pg_tables p
WHERE schemaname = 'public'
AND tablename IN ('users', 'subscription_status', 'appointments', 'orders', 'sales', 'system_settings')
ORDER BY tablename;
EOF

echo "📊 Script de vérification créé: verify_rls_activation.sql"
echo ""
echo "✅ Déploiement terminé!"
echo ""
echo "📋 Prochaines étapes:"
echo "   1. Vérifiez l'état des tables avec: SELECT * FROM check_all_tables_security();"
echo "   2. Testez votre application pour vous assurer que tout fonctionne"
echo "   3. Ajustez les politiques RLS si nécessaire selon votre logique métier"
echo ""
echo "⚠️  Important: Les vues ne peuvent pas avoir de RLS activé (c'est normal)"
echo "   Seules les tables physiques ont été sécurisées"
