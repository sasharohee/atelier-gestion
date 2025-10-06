-- ============================================================================
-- TEST DES FONCTIONS BRAND APRÈS CORRECTION DU TYPE ID
-- ============================================================================

SELECT '=== TEST DES FONCTIONS BRAND APRÈS CORRECTION ===' as section;

-- 1. VÉRIFIER LES TYPES DE COLONNES
-- ============================================================================
SELECT '=== VÉRIFICATION DES TYPES ===' as section;

SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name IN ('device_brands', 'brand_categories')
AND column_name IN ('id', 'brand_id', 'category_id')
AND table_schema = 'public'
ORDER BY table_name, column_name;

-- 2. VÉRIFIER QUE LES FONCTIONS EXISTENT
-- ============================================================================
SELECT '=== VÉRIFICATION DES FONCTIONS ===' as section;

SELECT 
    routine_name, 
    routine_type, 
    data_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_name IN ('upsert_brand', 'upsert_brand_simple', 'create_brand_basic', 'update_brand_categories')
AND routine_schema = 'public'
ORDER BY routine_name;

-- 3. VÉRIFIER LES PARAMÈTRES DES FONCTIONS
-- ============================================================================
SELECT '=== PARAMÈTRES DES FONCTIONS ===' as section;

SELECT 
    p.routine_name,
    p.parameter_name,
    p.data_type,
    p.parameter_mode,
    p.ordinal_position
FROM information_schema.parameters p
JOIN information_schema.routines r ON p.specific_name = r.specific_name
WHERE r.routine_name IN ('upsert_brand', 'upsert_brand_simple', 'create_brand_basic', 'update_brand_categories')
AND r.routine_schema = 'public'
ORDER BY r.routine_name, p.ordinal_position;

-- 4. VÉRIFIER LES PERMISSIONS
-- ============================================================================
SELECT '=== VÉRIFICATION DES PERMISSIONS ===' as section;

SELECT 
    routine_name,
    grantee,
    privilege_type
FROM information_schema.routine_privileges 
WHERE routine_name IN ('upsert_brand', 'upsert_brand_simple', 'create_brand_basic', 'update_brand_categories')
AND routine_schema = 'public'
ORDER BY routine_name, grantee;

-- 5. TESTER LA FONCTION UPSERT_BRAND (si un utilisateur est connecté)
-- ============================================================================
SELECT '=== TEST DE LA FONCTION UPSERT_BRAND ===' as section;

-- Note: Ce test ne fonctionnera que si un utilisateur est authentifié
-- Décommentez les lignes suivantes pour tester :

-- Test avec des paramètres simples
-- SELECT 'Test avec paramètres simples...' as test_step;
-- SELECT * FROM public.upsert_brand('test_brand_' || extract(epoch from now()), 'Test Brand', 'Description test', '', NULL);

-- Test avec des catégories (si des catégories existent)
-- SELECT 'Test avec catégories...' as test_step;
-- SELECT * FROM public.upsert_brand('test_brand_cat_' || extract(epoch from now()), 'Test Brand avec Catégories', 'Description test', '', ARRAY['category_id_1', 'category_id_2']);

-- 6. VÉRIFIER LA VUE BRAND_WITH_CATEGORIES
-- ============================================================================
SELECT '=== VÉRIFICATION DE LA VUE ===' as section;

-- Vérifier que la vue existe
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name = 'brand_with_categories'
AND table_schema = 'public';

-- Tester la vue (si des données existent)
SELECT COUNT(*) as nombre_de_marques_dans_la_vue FROM public.brand_with_categories;

-- 7. VÉRIFIER LES DONNÉES EXISTANTES
-- ============================================================================
SELECT '=== VÉRIFICATION DES DONNÉES ===' as section;

-- Compter les marques existantes
SELECT COUNT(*) as nombre_de_marques FROM public.device_brands;

-- Compter les catégories existantes
SELECT COUNT(*) as nombre_de_categories FROM public.device_categories;

-- Compter les associations marque-catégorie
SELECT COUNT(*) as nombre_d_associations FROM public.brand_categories;

-- 8. TEST DE COMPATIBILITÉ
-- ============================================================================
SELECT '=== TEST DE COMPATIBILITÉ ===' as section;

-- Vérifier que les types sont cohérents
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'device_brands' 
            AND column_name = 'id' 
            AND data_type = 'text'
            AND table_schema = 'public'
        ) THEN '✅ device_brands.id est de type TEXT'
        ELSE '❌ device_brands.id n''est pas de type TEXT'
    END as device_brands_id_type;

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'brand_categories' 
            AND column_name = 'brand_id' 
            AND data_type = 'text'
            AND table_schema = 'public'
        ) THEN '✅ brand_categories.brand_id est de type TEXT'
        ELSE '❌ brand_categories.brand_id n''est pas de type TEXT'
    END as brand_categories_brand_id_type;

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'brand_categories' 
            AND column_name = 'category_id' 
            AND data_type = 'uuid'
            AND table_schema = 'public'
        ) THEN '✅ brand_categories.category_id est de type UUID'
        ELSE '❌ brand_categories.category_id n''est pas de type UUID'
    END as brand_categories_category_id_type;

SELECT '=== TESTS TERMINÉS ===' as section;




