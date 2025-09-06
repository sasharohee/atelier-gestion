-- =====================================================
-- DIAGNOSTIC ISOLATION SIMPLIFIÉ
-- =====================================================
-- Diagnostic de l'isolation sur toutes les tables
-- Date: 2025-01-23
-- =====================================================

-- 1. Diagnostic des tables avec RLS
SELECT '=== TABLES AVEC RLS ===' as etape;

SELECT 
    schemaname,
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename IN (
    'clients', 'appointments', 'products', 'sales', 'device_models',
    'users', 'system_settings', 'workshop_settings'
)
ORDER BY tablename;

-- 2. Diagnostic des colonnes d'isolation
SELECT '=== COLONNES D''ISOLATION ===' as etape;

SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    CASE 
        WHEN column_name = 'workshop_id' THEN '✅ Colonne isolation'
        WHEN column_name = 'created_by' THEN '✅ Colonne traçabilité'
        ELSE 'ℹ️ Autre colonne'
    END as type_colonne
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name IN (
    'clients', 'appointments', 'products', 'sales', 'device_models',
    'users', 'system_settings', 'workshop_settings'
)
AND column_name IN ('workshop_id', 'created_by')
ORDER BY table_name, column_name;

-- 3. Diagnostic des politiques RLS
SELECT '=== POLITIQUES RLS ===' as etape;

SELECT 
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%workshop_id%' THEN '✅ Isolation par workshop_id'
        WHEN qual = 'true' THEN '⚠️ Permissive'
        WHEN qual IS NULL THEN '❌ Pas de condition'
        ELSE '⚠️ Autre condition'
    END as isolation_type
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN (
    'clients', 'appointments', 'products', 'sales', 'device_models',
    'users', 'system_settings', 'workshop_settings'
)
ORDER BY tablename, policyname;

-- 4. Diagnostic des paramètres système
SELECT '=== PARAMÈTRES SYSTÈME ===' as etape;

SELECT 
    key,
    value,
    category,
    CASE 
        WHEN key = 'workshop_id' THEN '✅ Workshop principal'
        WHEN key = 'workshop_type' THEN '✅ Type d''atelier'
        ELSE 'ℹ️ Autre paramètre'
    END as type_parametre
FROM system_settings 
WHERE key IN ('workshop_id', 'workshop_type')
ORDER BY key;

-- 5. Test d'accès aux tables importantes (sans utiliser workshop_id)
SELECT '=== TEST D''ACCÈS ===' as etape;

-- Test d'accès aux clients
SELECT 
    'clients' as table_name,
    COUNT(*) as nombre_clients_visibles
FROM clients;

-- Test d'accès aux rendez-vous
SELECT 
    'appointments' as table_name,
    COUNT(*) as nombre_rdv_visibles
FROM appointments;

-- Test d'accès aux produits
SELECT 
    'products' as table_name,
    COUNT(*) as nombre_produits_visibles
FROM products;

-- Test d'accès aux ventes
SELECT 
    'sales' as table_name,
    COUNT(*) as nombre_ventes_visibles
FROM sales;

-- Test d'accès aux paramètres système
SELECT 
    'system_settings' as table_name,
    COUNT(*) as nombre_parametres_visibles
FROM system_settings;

-- 6. Vérification des colonnes manquantes
SELECT '=== COLONNES MANQUANTES ===' as etape;

-- Vérifier quelles tables n'ont pas workshop_id
SELECT 
    t.table_name,
    CASE 
        WHEN c.column_name IS NULL THEN '❌ workshop_id manquant'
        ELSE '✅ workshop_id présent'
    END as status_workshop_id,
    CASE 
        WHEN c2.column_name IS NULL THEN '❌ created_by manquant'
        ELSE '✅ created_by présent'
    END as status_created_by
FROM (
    SELECT 'clients' as table_name
    UNION ALL SELECT 'appointments'
    UNION ALL SELECT 'products'
    UNION ALL SELECT 'sales'
    UNION ALL SELECT 'device_models'
) t
LEFT JOIN information_schema.columns c ON 
    c.table_name = t.table_name 
    AND c.column_name = 'workshop_id'
    AND c.table_schema = 'public'
LEFT JOIN information_schema.columns c2 ON 
    c2.table_name = t.table_name 
    AND c2.column_name = 'created_by'
    AND c2.table_schema = 'public'
ORDER BY t.table_name;

-- 7. Résumé du diagnostic
SELECT '=== RÉSUMÉ DIAGNOSTIC ===' as etape;

SELECT 
    'Tables avec RLS activé' as element,
    COUNT(*) as nombre
FROM pg_tables 
WHERE schemaname = 'public'
AND rowsecurity = true
AND tablename IN (
    'clients', 'appointments', 'products', 'sales', 'device_models',
    'users', 'system_settings', 'workshop_settings'
)
UNION ALL
SELECT 
    'Politiques d''isolation' as element,
    COUNT(*) as nombre
FROM pg_policies 
WHERE schemaname = 'public'
AND qual LIKE '%workshop_id%'
AND tablename IN (
    'clients', 'appointments', 'products', 'sales', 'device_models',
    'users', 'system_settings', 'workshop_settings'
)
UNION ALL
SELECT 
    'Colonnes workshop_id' as element,
    COUNT(*) as nombre
FROM information_schema.columns 
WHERE table_schema = 'public'
AND column_name = 'workshop_id'
AND table_name IN (
    'clients', 'appointments', 'products', 'sales', 'device_models',
    'users', 'system_settings', 'workshop_settings'
);

-- 8. Instructions
SELECT '=== INSTRUCTIONS ===' as etape;
SELECT '✅ Diagnostic simplifié effectué' as message;
SELECT '✅ Vérifiez les colonnes manquantes ci-dessus' as verification;
SELECT '⚠️ Si des colonnes manquent, exécutez correction_isolation_complete.sql' as next_step;
