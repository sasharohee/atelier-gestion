-- ============================================================================
-- TEST COMPLET DES FONCTIONS BRAND APRÈS CORRECTION COMPLÈTE
-- ============================================================================

SELECT '=== TEST COMPLET DES FONCTIONS BRAND ===' as section;

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
    data_type
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

-- 5. VÉRIFIER LA VUE BRAND_WITH_CATEGORIES
-- ============================================================================
SELECT '=== VÉRIFICATION DE LA VUE ===' as section;

-- Vérifier que la vue existe
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_name = 'brand_with_categories'
AND table_schema = 'public';

-- Vérifier les permissions sur la vue
SELECT 
    table_name,
    grantee,
    privilege_type
FROM information_schema.table_privileges 
WHERE table_name = 'brand_with_categories'
AND table_schema = 'public'
ORDER BY grantee, privilege_type;

-- Tester la vue (si des données existent)
SELECT COUNT(*) as nombre_de_marques_dans_la_vue FROM public.brand_with_categories;

-- 6. VÉRIFIER LES CONTRAINTES DE CLÉ ÉTRANGÈRE
-- ============================================================================
SELECT '=== VÉRIFICATION DES CONTRAINTES ===' as section;

SELECT 
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND (tc.table_name = 'device_models' OR tc.table_name = 'brand_categories')
AND tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_name;

-- 7. VÉRIFIER LES DONNÉES EXISTANTES
-- ============================================================================
SELECT '=== VÉRIFICATION DES DONNÉES ===' as section;

-- Compter les marques existantes
SELECT COUNT(*) as nombre_de_marques FROM public.device_brands;

-- Compter les catégories existantes
SELECT COUNT(*) as nombre_de_categories FROM public.device_categories;

-- Compter les associations marque-catégorie
SELECT COUNT(*) as nombre_d_associations FROM public.brand_categories;

-- Compter les modèles existants
SELECT COUNT(*) as nombre_de_modeles FROM public.device_models;

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

-- 9. TEST DE LA VUE BRAND_WITH_CATEGORIES
-- ============================================================================
SELECT '=== TEST DE LA VUE ===' as section;

-- Vérifier que la vue peut être interrogée
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_name = 'brand_with_categories'
            AND table_schema = 'public'
            AND table_type = 'VIEW'
        ) THEN '✅ Vue brand_with_categories existe'
        ELSE '❌ Vue brand_with_categories manquante'
    END as vue_status;

-- Tester une requête simple sur la vue
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM public.brand_with_categories) >= 0 
        THEN '✅ Vue brand_with_categories fonctionne'
        ELSE '❌ Vue brand_with_categories ne fonctionne pas'
    END as vue_fonctionnelle;

-- 10. TEST DES FONCTIONS RPC (si un utilisateur est connecté)
-- ============================================================================
SELECT '=== TEST DES FONCTIONS RPC ===' as section;

-- Note: Ces tests ne fonctionneront que si un utilisateur est authentifié
-- Décommentez les lignes suivantes pour tester :

-- Test de la fonction upsert_brand_simple
-- SELECT 'Test upsert_brand_simple...' as test_step;
-- SELECT public.upsert_brand_simple('test_simple_' || extract(epoch from now()), 'Test Simple', 'Description test', '');

-- Test de la fonction create_brand_basic
-- SELECT 'Test create_brand_basic...' as test_step;
-- SELECT public.create_brand_basic('test_basic_' || extract(epoch from now()), 'Test Basic', 'Description test', '');

-- Test de la fonction update_brand_categories
-- SELECT 'Test update_brand_categories...' as test_step;
-- SELECT public.update_brand_categories('test_brand_123', ARRAY['category_id_1', 'category_id_2']);

-- 11. RÉSUMÉ DES TESTS
-- ============================================================================
SELECT '=== RÉSUMÉ DES TESTS ===' as section;

-- Compter les éléments vérifiés
SELECT 
    (SELECT COUNT(*) FROM information_schema.routines 
     WHERE routine_name IN ('upsert_brand', 'upsert_brand_simple', 'create_brand_basic', 'update_brand_categories')
     AND routine_schema = 'public') as fonctions_rpc_trouvees,
    
    (SELECT COUNT(*) FROM information_schema.tables 
     WHERE table_name = 'brand_with_categories'
     AND table_schema = 'public'
     AND table_type = 'VIEW') as vues_trouvees,
    
    (SELECT COUNT(*) FROM information_schema.table_constraints 
     WHERE constraint_type = 'FOREIGN KEY' 
     AND table_schema = 'public'
     AND (table_name = 'device_models' OR table_name = 'brand_categories')) as contraintes_trouvees;

SELECT '=== TESTS COMPLETS TERMINÉS ===' as section;


