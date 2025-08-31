-- =====================================================
-- TEST ISOLATION PRODUCT_CATEGORIES
-- =====================================================
-- Script pour tester si l'isolation fonctionne
-- =====================================================

-- TEST 1: VÉRIFIER L'ÉTAT RLS
SELECT 'TEST 1 - ÉTAT RLS' as test_name;
SELECT 
    tablename,
    CASE WHEN rowsecurity THEN '✅ RLS ACTIVÉ' ELSE '❌ RLS DÉSACTIVÉ' END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'product_categories';

-- TEST 2: VÉRIFIER LES POLITIQUES
SELECT 'TEST 2 - POLITIQUES RLS' as test_name;
SELECT 
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%workshop_id%' THEN '✅ Isolation par workshop_id'
        ELSE '⚠️ Autre condition'
    END as isolation_type
FROM pg_policies 
WHERE schemaname = 'public' AND tablename = 'product_categories';

-- TEST 3: VÉRIFIER LES DONNÉES
SELECT 'TEST 3 - DONNÉES' as test_name;
SELECT 
    name,
    workshop_id,
    CASE 
        WHEN workshop_id IS NULL THEN '❌ Pas d''isolation'
        ELSE '✅ Isolé'
    END as isolation_status
FROM public.product_categories
ORDER BY name;

-- TEST 4: VÉRIFIER LE WORKSHOP_ID ACTUEL
SELECT 'TEST 4 - WORKSHOP_ID ACTUEL' as test_name;
SELECT 
    key,
    value
FROM system_settings 
WHERE key = 'workshop_id';

-- TEST 5: TESTER L'ACCÈS DIRECT
SELECT 'TEST 5 - ACCÈS DIRECT' as test_name;
SELECT 
    COUNT(*) as nombre_categories_visibles
FROM public.product_categories;

-- TEST 6: TESTER LA CRÉATION (si possible)
SELECT 'TEST 6 - TEST CRÉATION' as test_name;
-- Note: Ce test nécessite des permissions appropriées
-- Il sera exécuté seulement si l'utilisateur a les droits

-- TEST 7: COMPTAGE PAR WORKSHOP
SELECT 'TEST 7 - COMPTAGE PAR WORKSHOP' as test_name;
SELECT 
    COALESCE(workshop_id::text, 'NULL') as workshop_id,
    COUNT(*) as nombre_categories
FROM public.product_categories
GROUP BY workshop_id
ORDER BY workshop_id;


