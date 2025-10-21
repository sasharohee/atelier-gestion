-- ============================================================================
-- TEST DE LA FONCTION UPSERT_BRAND CORRIGÉE
-- ============================================================================

SELECT '=== TEST DE LA FONCTION UPSERT_BRAND ===' as section;

-- 1. VÉRIFIER QUE LA FONCTION EXISTE
-- ============================================================================
SELECT 
    routine_name, 
    routine_type, 
    data_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'upsert_brand'
AND routine_schema = 'public';

-- 2. VÉRIFIER LES PARAMÈTRES DE LA FONCTION
-- ============================================================================
SELECT 
    parameter_name,
    data_type,
    parameter_mode
FROM information_schema.parameters 
WHERE specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_name = 'upsert_brand'
    AND routine_schema = 'public'
)
ORDER BY ordinal_position;

-- 3. TESTER LA FONCTION (si un utilisateur est connecté)
-- ============================================================================
-- Note: Ce test ne fonctionnera que si un utilisateur est authentifié
SELECT '=== TEST DE LA FONCTION (nécessite une authentification) ===' as section;

-- Test avec des paramètres simples
SELECT 'Test avec paramètres simples...' as test_step;
-- SELECT * FROM public.upsert_brand('test_brand_123', 'Test Brand', 'Description test', '', NULL);

-- 4. VÉRIFIER LES PERMISSIONS
-- ============================================================================
SELECT 
    routine_name,
    grantee,
    privilege_type
FROM information_schema.routine_privileges 
WHERE routine_name = 'upsert_brand'
AND routine_schema = 'public';

SELECT '=== TEST TERMINÉ ===' as section;















