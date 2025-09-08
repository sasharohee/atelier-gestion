-- Script de diagnostic SQL pour la sauvegarde des niveaux de fidélité
-- Ce script vérifie tous les aspects de la base de données

-- 1. VÉRIFIER L'EXISTENCE DES TABLES
SELECT '=== VÉRIFICATION DES TABLES ===' as etape;

SELECT 
    schemaname,
    tablename,
    tableowner,
    hasindexes,
    hasrules,
    hastriggers
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('loyalty_tiers_advanced', 'loyalty_config', 'loyalty_points_history', 'client_loyalty_points', 'referrals')
ORDER BY tablename;

-- 2. VÉRIFIER LES TRIGGERS
SELECT '=== VÉRIFICATION DES TRIGGERS ===' as etape;

SELECT 
    n.nspname as schema_name,
    c.relname as table_name,
    t.tgname as trigger_name,
    CASE 
        WHEN t.tgenabled = 'O' THEN 'ACTIF'
        WHEN t.tgenabled = 'D' THEN 'DÉSACTIVÉ'
        WHEN t.tgenabled = 'R' THEN 'RÉPLICA'
        WHEN t.tgenabled = 'A' THEN 'TOUJOURS'
        ELSE 'INCONNU'
    END as statut,
    pg_get_triggerdef(t.oid) as definition
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public' 
AND c.relname IN ('loyalty_tiers_advanced', 'loyalty_config', 'loyalty_points_history', 'client_loyalty_points', 'referrals')
ORDER BY c.relname, t.tgname;

-- 3. VÉRIFIER LES POLITIQUES RLS
SELECT '=== VÉRIFICATION DES POLITIQUES RLS ===' as etape;

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
SELECT '=== VÉRIFICATION DU STATUT RLS ===' as etape;

SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_actif,
    forcerowsecurity as rls_force
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('loyalty_tiers_advanced', 'loyalty_config', 'loyalty_points_history', 'client_loyalty_points', 'referrals')
ORDER BY tablename;

-- 5. VÉRIFIER LES PERMISSIONS
SELECT '=== VÉRIFICATION DES PERMISSIONS ===' as etape;

SELECT 
    n.nspname as schema_name,
    c.relname as table_name,
    c.relacl as permissions
FROM pg_class c
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public' 
AND c.relname IN ('loyalty_tiers_advanced', 'loyalty_config', 'loyalty_points_history', 'client_loyalty_points', 'referrals')
ORDER BY c.relname;

-- 6. VÉRIFIER LES NIVEAUX EXISTANTS
SELECT '=== VÉRIFICATION DES NIVEAUX ===' as etape;

SELECT 
    COUNT(*) as nombre_niveaux,
    COUNT(CASE WHEN is_active = true THEN 1 END) as niveaux_actifs,
    COUNT(CASE WHEN is_active = false THEN 1 END) as niveaux_inactifs,
    string_agg(name, ', ' ORDER BY points_required) as niveaux_disponibles
FROM loyalty_tiers_advanced;

-- 7. VÉRIFIER LES CONFIGURATIONS
SELECT '=== VÉRIFICATION DES CONFIGURATIONS ===' as etape;

SELECT 
    COUNT(*) as nombre_configurations,
    string_agg(key, ', ') as configurations_disponibles
FROM loyalty_config;

-- 8. TEST DE MISE À JOUR SIMPLE
SELECT '=== TEST DE MISE À JOUR ===' as etape;

-- Sauvegarder l'état actuel
CREATE TEMP TABLE temp_loyalty_backup AS 
SELECT * FROM loyalty_tiers_advanced WHERE name = 'Bronze';

-- Tester la mise à jour
UPDATE loyalty_tiers_advanced 
SET description = 'Test diagnostic - ' || NOW()::text
WHERE name = 'Bronze' AND id = '11111111-1111-1111-1111-111111111111';

-- Vérifier le résultat
SELECT 
    name,
    description,
    updated_at,
    CASE 
        WHEN description LIKE 'Test diagnostic%' THEN '✅ MISE À JOUR RÉUSSIE'
        ELSE '❌ MISE À JOUR ÉCHOUÉE'
    END as statut
FROM loyalty_tiers_advanced 
WHERE name = 'Bronze' AND id = '11111111-1111-1111-1111-111111111111';

-- Restaurer l'état original
UPDATE loyalty_tiers_advanced 
SET description = temp_loyalty_backup.description
FROM temp_loyalty_backup
WHERE loyalty_tiers_advanced.id = temp_loyalty_backup.id;

-- 9. TEST D'INSERTION
SELECT '=== TEST D''INSERTION ===' as etape;

-- Insérer un niveau de test
INSERT INTO loyalty_tiers_advanced (
    id, name, description, points_required, discount_percentage, color, is_active, created_at, updated_at
) VALUES (
    'test-diagnostic-' || extract(epoch from now())::text,
    'Test Diagnostic',
    'Niveau de test pour diagnostic',
    999,
    25.0,
    '#FF0000',
    true,
    NOW(),
    NOW()
);

-- Vérifier l'insertion
SELECT 
    name,
    description,
    points_required,
    discount_percentage,
    CASE 
        WHEN name = 'Test Diagnostic' THEN '✅ INSERTION RÉUSSIE'
        ELSE '❌ INSERTION ÉCHOUÉE'
    END as statut
FROM loyalty_tiers_advanced 
WHERE name = 'Test Diagnostic';

-- Supprimer le niveau de test
DELETE FROM loyalty_tiers_advanced WHERE name = 'Test Diagnostic';

-- 10. VÉRIFIER LES FONCTIONS
SELECT '=== VÉRIFICATION DES FONCTIONS ===' as etape;

SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_function_result(p.oid) as return_type,
    pg_get_function_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
AND p.proname LIKE '%loyalty%'
ORDER BY p.proname;

-- 11. VÉRIFIER LES CONTRAINTES
SELECT '=== VÉRIFICATION DES CONTRAINTES ===' as etape;

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

-- 12. VÉRIFIER LES INDEX
SELECT '=== VÉRIFICATION DES INDEX ===' as etape;

SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes 
WHERE schemaname = 'public' 
AND tablename IN ('loyalty_tiers_advanced', 'loyalty_config', 'loyalty_points_history', 'client_loyalty_points', 'referrals')
ORDER BY tablename, indexname;

-- 13. MESSAGE DE FIN
SELECT '=== DIAGNOSTIC TERMINÉ ===' as etape;
SELECT 'Vérifiez les résultats ci-dessus pour identifier les problèmes de sauvegarde.' as message;
