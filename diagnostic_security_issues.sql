-- Script de diagnostic des problèmes de sécurité
-- Ce script identifie les triggers et fonctions problématiques

-- 1. VÉRIFIER LES TRIGGERS ACTIFS
SELECT '=== TRIGGERS ACTIFS ===' as etape;

SELECT 
    schemaname,
    tablename,
    triggername,
    tgtype,
    tgenabled
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public'
AND c.relname IN ('loyalty_tiers_advanced', 'loyalty_config', 'loyalty_points_history', 'client_loyalty_points', 'referrals')
ORDER BY tablename, triggername;

-- 2. VÉRIFIER LES FONCTIONS PROBLÉMATIQUES
SELECT '=== FONCTIONS PROBLÉMATIQUES ===' as etape;

SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_function_arguments(p.oid) as arguments,
    pg_get_function_result(p.oid) as return_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname LIKE '%workshop_id%'
ORDER BY p.proname;

-- 3. VÉRIFIER LES POLITIQUES RLS
SELECT '=== POLITIQUES RLS ===' as etape;

SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('loyalty_tiers_advanced', 'loyalty_config', 'loyalty_points_history', 'client_loyalty_points', 'referrals')
ORDER BY tablename, policyname;

-- 4. VÉRIFIER L'ÉTAT RLS DES TABLES
SELECT '=== ÉTAT RLS DES TABLES ===' as etape;

SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_actif,
    relforcerowsecurity as rls_force
FROM pg_tables t
JOIN pg_class c ON c.relname = t.tablename
WHERE schemaname = 'public'
AND tablename IN ('loyalty_tiers_advanced', 'loyalty_config', 'loyalty_points_history', 'client_loyalty_points', 'referrals')
ORDER BY tablename;

-- 5. VÉRIFIER LES PERMISSIONS
SELECT '=== PERMISSIONS ===' as etape;

SELECT 
    table_schema,
    table_name,
    privilege_type,
    grantee
FROM information_schema.table_privileges
WHERE table_schema = 'public'
AND table_name IN ('loyalty_tiers_advanced', 'loyalty_config', 'loyalty_points_history', 'client_loyalty_points', 'referrals')
ORDER BY table_name, privilege_type;

-- 6. RECOMMANDATIONS
SELECT '=== RECOMMANDATIONS ===' as etape;

SELECT 
    'Si des triggers sont actifs, utilisez fix_loyalty_bypass_security.sql' as recommandation_1,
    'Si des fonctions workshop_id existent, elles doivent être supprimées' as recommandation_2,
    'Si RLS est actif, il peut bloquer les insertions' as recommandation_3,
    'Utilisez fix_loyalty_simple.sql pour une approche directe' as recommandation_4;
