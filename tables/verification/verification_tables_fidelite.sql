-- DIAGNOSTIC : VÉRIFIER L'EXISTENCE DES TABLES DE FIDÉLITÉ
-- Exécutez ce script dans Supabase SQL Editor pour voir l'état actuel

-- 1. VÉRIFIER LES TABLES DE FIDÉLITÉ
SELECT '🔍 VÉRIFICATION DES TABLES DE FIDÉLITÉ' as diagnostic;

SELECT 
    table_name,
    CASE 
        WHEN table_name IN ('loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history') 
        THEN '✅ Table de fidélité'
        ELSE '📋 Table système'
    END as type_table,
    'Existe' as status
FROM information_schema.tables 
WHERE table_name IN (
    'loyalty_config',
    'loyalty_tiers_advanced', 
    'loyalty_points_history',
    'clients',
    'sales',
    'repairs'
)
AND table_schema = 'public'
ORDER BY table_name;

-- 2. VÉRIFIER LES FONCTIONS DE FIDÉLITÉ
SELECT '🔧 VÉRIFICATION DES FONCTIONS DE FIDÉLITÉ' as diagnostic;

SELECT 
    routine_name,
    'Fonction de fidélité' as type,
    CASE 
        WHEN routine_name IN (
            'calculate_loyalty_points',
            'auto_add_loyalty_points_from_purchase',
            'auto_add_loyalty_points_from_sale',
            'auto_add_loyalty_points_from_repair',
            'get_loyalty_statistics'
        ) THEN '✅ Fonction de fidélité'
        ELSE '📋 Autre fonction'
    END as status
FROM information_schema.routines 
WHERE routine_name IN (
    'calculate_loyalty_points',
    'auto_add_loyalty_points_from_purchase',
    'auto_add_loyalty_points_from_sale',
    'auto_add_loyalty_points_from_repair',
    'get_loyalty_statistics'
)
AND routine_schema = 'public'
ORDER BY routine_name;

-- 3. VÉRIFIER LES VUES DE FIDÉLITÉ
SELECT '📊 VÉRIFICATION DES VUES DE FIDÉLITÉ' as diagnostic;

SELECT 
    table_name,
    'Vue de fidélité' as type,
    'Existe' as status
FROM information_schema.views 
WHERE table_name IN ('loyalty_dashboard')
AND table_schema = 'public'
ORDER BY table_name;

-- 4. VÉRIFIER LES DONNÉES DANS LES TABLES (si elles existent)
SELECT '📋 VÉRIFICATION DES DONNÉES' as diagnostic;

-- Vérifier loyalty_config
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'loyalty_config' AND table_schema = 'public') THEN
        RAISE NOTICE '✅ Table loyalty_config existe - % lignes', (SELECT COUNT(*) FROM loyalty_config);
    ELSE
        RAISE NOTICE '❌ Table loyalty_config n''existe pas';
    END IF;
END $$;

-- Vérifier loyalty_tiers_advanced
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'loyalty_tiers_advanced' AND table_schema = 'public') THEN
        RAISE NOTICE '✅ Table loyalty_tiers_advanced existe - % lignes', (SELECT COUNT(*) FROM loyalty_tiers_advanced);
    ELSE
        RAISE NOTICE '❌ Table loyalty_tiers_advanced n''existe pas';
    END IF;
END $$;

-- 5. RÉSUMÉ DES ACTIONS NÉCESSAIRES
SELECT '📋 ACTIONS NÉCESSAIRES' as diagnostic;

SELECT 
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'loyalty_config' AND table_schema = 'public')
        AND EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'loyalty_tiers_advanced' AND table_schema = 'public')
        THEN '✅ Système de fidélité déjà installé - Vérifiez les permissions RLS'
        ELSE '❌ Système de fidélité manquant - Exécutez le script systeme_fidelite_automatique.sql'
    END as action_requise;

-- 6. VÉRIFIER LES PERMISSIONS RLS
SELECT '🔒 VÉRIFICATION DES PERMISSIONS RLS' as diagnostic;

SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_active
FROM pg_tables 
WHERE tablename IN ('loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history')
AND schemaname = 'public';





