-- =====================================================
-- DIAGNOSTIC PAGE APPARAILS
-- =====================================================
-- Diagnostic de pourquoi la page appareils ne s'affiche pas
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier l'utilisateur actuel
SELECT '=== UTILISATEUR ACTUEL ===' as etape;

SELECT 
    'Utilisateur connecté' as info,
    auth.uid() as user_id;

-- 2. Vérifier les tables d'appareils
SELECT '=== TABLES APPARAILS ===' as etape;

SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename LIKE '%device%' OR tablename LIKE '%appareil%' OR tablename LIKE '%equipment%'
ORDER BY tablename;

-- 3. Vérifier le contenu de la table devices
SELECT '=== CONTENU TABLE DEVICES ===' as etape;

SELECT 
    'Total appareils' as info,
    COUNT(*) as nombre
FROM devices;

-- 4. Vérifier les appareils par utilisateur
SELECT '=== APPARAILS PAR UTILISATEUR ===' as etape;

SELECT 
    created_by,
    COUNT(*) as nombre_appareils,
    MIN(created_at) as premier_appareil,
    MAX(created_at) as dernier_appareil
FROM devices 
GROUP BY created_by
ORDER BY nombre_appareils DESC;

-- 5. Vérifier les appareils visibles pour l'utilisateur actuel
SELECT '=== APPARAILS VISIBLES ===' as etape;

SELECT 
    'Appareils visibles pour l''utilisateur actuel' as info,
    COUNT(*) as nombre_appareils
FROM devices 
WHERE created_by = auth.uid();

-- 6. Vérifier les politiques RLS sur devices
SELECT '=== POLITIQUES RLS DEVICES ===' as etape;

SELECT 
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'devices'
ORDER BY policyname;

-- 7. Vérifier si l'utilisateur est admin
SELECT '=== VÉRIFICATION ADMIN ===' as etape;

SELECT 
    'Utilisateur dans table users' as info,
    u.id,
    u.role,
    CASE 
        WHEN u.role = 'admin' THEN '✅ Admin'
        ELSE '❌ Pas admin'
    END as statut_admin
FROM auth.users au
LEFT JOIN users u ON au.id = u.id
WHERE au.id = auth.uid();

-- 8. Vérifier les paramètres système
SELECT '=== PARAMÈTRES SYSTÈME ===' as etape;

SELECT 
    key,
    value,
    category
FROM system_settings 
WHERE key IN ('workshop_type', 'workshop_id')
ORDER BY key;

-- 9. Test d'accès direct à devices
SELECT '=== TEST ACCÈS DIRECT ===' as etape;

-- Test sans RLS
SELECT 
    'Test sans RLS' as test,
    COUNT(*) as nombre_appareils
FROM devices;

-- Test avec RLS (ce que l'application voit)
SELECT 
    'Test avec RLS' as test,
    COUNT(*) as nombre_appareils
FROM devices 
WHERE created_by = auth.uid()
   OR EXISTS (
       SELECT 1 FROM system_settings 
       WHERE key = 'workshop_type' 
       AND value = 'gestion'
       LIMIT 1
   );

-- 10. Vérifier les colonnes de la table devices
SELECT '=== STRUCTURE TABLE DEVICES ===' as etape;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name = 'devices'
ORDER BY ordinal_position;

-- 11. Instructions
SELECT '=== INSTRUCTIONS ===' as etape;
SELECT '✅ Diagnostic complet effectué' as message;
SELECT '✅ Vérifiez les résultats ci-dessus' as verification;
SELECT '⚠️ Si 0 appareils visibles, le problème est l''isolation trop stricte' as next_step;
