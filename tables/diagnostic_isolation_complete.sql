-- =====================================================
-- DIAGNOSTIC ISOLATION COMPLÈTE
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

-- 2. Diagnostic des politiques RLS
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

-- 3. Diagnostic des colonnes d'isolation
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

-- 4. Diagnostic des données par workshop
SELECT '=== DONNÉES PAR WORKSHOP ===' as etape;

-- Clients
SELECT 
    'clients' as table_name,
    COUNT(*) as total,
    COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) as avec_workshop_id,
    COUNT(CASE WHEN workshop_id IS NULL THEN 1 END) as sans_workshop_id
FROM clients
UNION ALL
-- Appointments
SELECT 
    'appointments' as table_name,
    COUNT(*) as total,
    COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) as avec_workshop_id,
    COUNT(CASE WHEN workshop_id IS NULL THEN 1 END) as sans_workshop_id
FROM appointments
UNION ALL
-- Products
SELECT 
    'products' as table_name,
    COUNT(*) as total,
    COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) as avec_workshop_id,
    COUNT(CASE WHEN workshop_id IS NULL THEN 1 END) as sans_workshop_id
FROM products
UNION ALL
-- Sales
SELECT 
    'sales' as table_name,
    COUNT(*) as total,
    COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) as avec_workshop_id,
    COUNT(CASE WHEN workshop_id IS NULL THEN 1 END) as sans_workshop_id
FROM sales
UNION ALL
-- Device Models
SELECT 
    'device_models' as table_name,
    COUNT(*) as total,
    COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) as avec_workshop_id,
    COUNT(CASE WHEN workshop_id IS NULL THEN 1 END) as sans_workshop_id
FROM device_models;

-- 5. Diagnostic des paramètres système
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

-- 6. Test d'accès aux tables importantes
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
SELECT '✅ Diagnostic complet effectué' as message;
SELECT '✅ Vérifiez les résultats ci-dessus' as verification;
SELECT '⚠️ Si l''isolation ne fonctionne pas, exécutez le script de correction' as next_step;
