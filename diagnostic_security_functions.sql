-- Script de diagnostic pour identifier toutes les fonctions de sécurité problématiques
-- Ce script liste toutes les fonctions qui peuvent bloquer la sauvegarde

-- 1. IDENTIFIER TOUTES LES FONCTIONS LIÉES À LA SÉCURITÉ
SELECT '=== FONCTIONS DE SÉCURITÉ IDENTIFIÉES ===' as etape;

SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_function_result(p.oid) as return_type,
    pg_get_function_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
AND (p.proname LIKE '%workshop_id%' 
     OR p.proname LIKE '%set_workshop%' 
     OR p.proname LIKE '%loyalty%'
     OR p.proname LIKE '%authenticate%'
     OR p.proname LIKE '%permission%'
     OR p.proname LIKE '%security%')
ORDER BY p.proname;

-- 2. IDENTIFIER TOUS LES TRIGGERS LIÉS À LA SÉCURITÉ
SELECT '=== TRIGGERS DE SÉCURITÉ IDENTIFIÉS ===' as etape;

SELECT 
    n.nspname as schema_name,
    c.relname as table_name,
    t.tgname as trigger_name,
    CASE 
        WHEN t.tgenabled = 'O' THEN 'ACTIF'
        WHEN t.tgenabled = 'D' THEN 'DÉSACTIVÉ'
        ELSE 'INCONNU'
    END as statut,
    pg_get_triggerdef(t.oid) as definition
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public' 
AND c.relname IN ('loyalty_tiers_advanced', 'loyalty_config', 'loyalty_points_history', 'client_loyalty_points', 'referrals')
AND (t.tgname LIKE '%workshop%' 
     OR t.tgname LIKE '%loyalty%'
     OR t.tgname LIKE '%security%'
     OR t.tgname LIKE '%authenticate%')
ORDER BY c.relname, t.tgname;

-- 3. IDENTIFIER TOUTES LES POLITIQUES RLS
SELECT '=== POLITIQUES RLS IDENTIFIÉES ===' as etape;

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

-- 4. VÉRIFIER LE STATUT RLS
SELECT '=== STATUT RLS ===' as etape;

SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_actif,
    forcerowsecurity as rls_force
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('loyalty_tiers_advanced', 'loyalty_config', 'loyalty_points_history', 'client_loyalty_points', 'referrals')
ORDER BY tablename;

-- 5. TESTER LES OPÉRATIONS DE BASE
SELECT '=== TEST DES OPÉRATIONS DE BASE ===' as etape;

-- Test de lecture
SELECT 
    COUNT(*) as nombre_niveaux,
    string_agg(name, ', ' ORDER BY points_required) as niveaux_disponibles
FROM loyalty_tiers_advanced;

-- Test de mise à jour (sans modifier les données)
SELECT 
    name,
    description,
    updated_at
FROM loyalty_tiers_advanced 
WHERE name = 'Bronze' 
LIMIT 1;

-- 6. IDENTIFIER LES CONTRAINTES
SELECT '=== CONTRAINTES IDENTIFIÉES ===' as etape;

SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_schema = 'public'
AND tc.table_name IN ('loyalty_tiers_advanced', 'loyalty_config', 'loyalty_points_history', 'client_loyalty_points', 'referrals')
ORDER BY tc.table_name, tc.constraint_type;

-- 7. MESSAGE DE DIAGNOSTIC
SELECT '=== DIAGNOSTIC TERMINÉ ===' as etape;
SELECT 'Vérifiez les résultats ci-dessus pour identifier les fonctions problématiques.' as message;
SELECT 'Utilisez le script fix_loyalty_remove_all_security.sql pour supprimer les fonctions identifiées.' as action;
