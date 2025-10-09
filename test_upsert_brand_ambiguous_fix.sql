-- ============================================================================
-- TEST DE LA FONCTION UPSERT_BRAND APRÈS CORRECTION DE L'AMBIGUÏTÉ
-- ============================================================================

SELECT '=== TEST DE LA FONCTION UPSERT_BRAND APRÈS CORRECTION ===' as section;

-- 1. VÉRIFIER QUE LA FONCTION EXISTE
-- ============================================================================
SELECT '=== VÉRIFICATION DE LA FONCTION ===' as section;

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
SELECT '=== PARAMÈTRES DE LA FONCTION ===' as section;

SELECT 
    parameter_name,
    data_type,
    parameter_mode,
    ordinal_position
FROM information_schema.parameters 
WHERE specific_name IN (
    SELECT specific_name 
    FROM information_schema.routines 
    WHERE routine_name = 'upsert_brand'
    AND routine_schema = 'public'
)
ORDER BY ordinal_position;

-- 3. VÉRIFIER LES PERMISSIONS
-- ============================================================================
SELECT '=== VÉRIFICATION DES PERMISSIONS ===' as section;

SELECT 
    routine_name,
    grantee,
    privilege_type
FROM information_schema.routine_privileges 
WHERE routine_name = 'upsert_brand'
AND routine_schema = 'public'
ORDER BY grantee;

-- 4. VÉRIFIER LA DÉFINITION DE LA FONCTION
-- ============================================================================
SELECT '=== DÉFINITION DE LA FONCTION ===' as section;

-- Vérifier que la fonction contient les alias explicites
SELECT 
    CASE 
        WHEN routine_definition LIKE '%brand_id%' 
        AND routine_definition LIKE '%brand_name%'
        AND routine_definition LIKE '%brand_description%'
        THEN '✅ Fonction contient les alias explicites'
        ELSE '❌ Fonction ne contient pas les alias explicites'
    END as fonction_avec_alias;

-- 5. TEST DE LA FONCTION (si un utilisateur est connecté)
-- ============================================================================
SELECT '=== TEST DE LA FONCTION ===' as section;

-- Note: Ces tests ne fonctionneront que si un utilisateur est authentifié
-- Décommentez les lignes suivantes pour tester :

-- Test avec des paramètres simples
-- SELECT 'Test avec paramètres simples...' as test_step;
-- SELECT * FROM public.upsert_brand('test_brand_' || extract(epoch from now()), 'Test Brand', 'Description test', '', NULL);

-- Test avec des catégories (si des catégories existent)
-- SELECT 'Test avec catégories...' as test_step;
-- SELECT * FROM public.upsert_brand('test_brand_cat_' || extract(epoch from now()), 'Test Brand avec Catégories', 'Description test', '', ARRAY['category_id_1', 'category_id_2']);

-- 6. VÉRIFICATION DE LA STRUCTURE DE RETOUR
-- ============================================================================
SELECT '=== VÉRIFICATION DE LA STRUCTURE DE RETOUR ===' as section;

-- Vérifier que la fonction retourne les bons types
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_name = 'upsert_brand'
            AND routine_schema = 'public'
            AND data_type = 'record'
        ) THEN '✅ Fonction retourne un record'
        ELSE '❌ Fonction ne retourne pas un record'
    END as fonction_retourne_record;

-- 7. VÉRIFICATION DES TYPES DE COLONNES
-- ============================================================================
SELECT '=== VÉRIFICATION DES TYPES DE COLONNES ===' as section;

-- Vérifier que les types des colonnes sont corrects
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name IN ('device_brands', 'brand_categories', 'device_categories')
AND column_name IN ('id', 'brand_id', 'category_id')
AND table_schema = 'public'
ORDER BY table_name, column_name;

-- 8. VÉRIFICATION DES CONTRAINTES
-- ============================================================================
SELECT '=== VÉRIFICATION DES CONTRAINTES ===' as section;

-- Vérifier que les contraintes de clé étrangère existent
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
AND ccu.table_name = 'device_brands'
AND ccu.column_name = 'id'
AND tc.table_schema = 'public'
ORDER BY tc.table_name, tc.constraint_name;

-- 9. VÉRIFICATION DES DONNÉES
-- ============================================================================
SELECT '=== VÉRIFICATION DES DONNÉES ===' as section;

-- Compter les marques existantes
SELECT COUNT(*) as nombre_de_marques FROM public.device_brands;

-- Compter les catégories existantes
SELECT COUNT(*) as nombre_de_categories FROM public.device_categories;

-- Compter les associations marque-catégorie
SELECT COUNT(*) as nombre_d_associations FROM public.brand_categories;

-- 10. RÉSUMÉ DES TESTS
-- ============================================================================
SELECT '=== RÉSUMÉ DES TESTS ===' as section;

-- Compter les éléments vérifiés
SELECT 
    (SELECT COUNT(*) FROM information_schema.routines 
     WHERE routine_name = 'upsert_brand'
     AND routine_schema = 'public') as fonction_trouvee,
    
    (SELECT COUNT(*) FROM information_schema.table_constraints 
     WHERE constraint_type = 'FOREIGN KEY' 
     AND table_schema = 'public'
     AND (table_name = 'device_models' OR table_name = 'brand_categories')) as contraintes_trouvees,
    
    (SELECT COUNT(*) FROM public.device_brands) as marques_existantes,
    
    (SELECT COUNT(*) FROM public.device_categories) as categories_existantes;

SELECT '=== TESTS TERMINÉS ===' as section;






