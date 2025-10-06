-- ============================================================================
-- TEST FINAL DE LA CORRECTION DE L'AMBIGUÏTÉ DE COLONNE (CORRIGÉ)
-- ============================================================================

SELECT '=== TEST FINAL DE LA CORRECTION DE L''AMBIGUÏTÉ (CORRIGÉ) ===' as section;

-- 1. VÉRIFIER QUE LA FONCTION EXISTE
-- ============================================================================
SELECT '=== VÉRIFICATION DE LA FONCTION ===' as section;

SELECT 
    routine_name, 
    routine_type, 
    data_type 
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

-- 4. VÉRIFIER LA DÉFINITION DE LA FONCTION (CORRIGÉ)
-- ============================================================================
SELECT '=== VÉRIFICATION DE LA DÉFINITION ===' as section;

-- Vérifier que la fonction contient les qualifications de table complètes
SELECT 
    CASE 
        WHEN pg_get_functiondef(oid) LIKE '%device_brands.id%' 
        AND pg_get_functiondef(oid) LIKE '%device_categories.id%'
        AND pg_get_functiondef(oid) LIKE '%brand_categories.brand_id%'
        THEN '✅ Fonction contient les qualifications de table complètes'
        ELSE '❌ Fonction ne contient pas les qualifications de table complètes'
    END as fonction_avec_qualifications
FROM pg_proc 
WHERE proname = 'upsert_brand' 
AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- 5. VÉRIFIER LES TYPES DE COLONNES
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

-- 6. VÉRIFIER LES CONTRAINTES
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

-- 7. VÉRIFIER LES DONNÉES
-- ============================================================================
SELECT '=== VÉRIFICATION DES DONNÉES ===' as section;

-- Compter les marques existantes
SELECT COUNT(*) as nombre_de_marques FROM public.device_brands;

-- Compter les catégories existantes
SELECT COUNT(*) as nombre_de_categories FROM public.device_categories;

-- Compter les associations marque-catégorie
SELECT COUNT(*) as nombre_d_associations FROM public.brand_categories;

-- 8. TEST DE LA FONCTION (si un utilisateur est connecté)
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

-- 9. VÉRIFICATION DE LA STRUCTURE DE RETOUR
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

-- 10. RÉSUMÉ COMPLET DES TESTS
-- ============================================================================
SELECT '=== RÉSUMÉ COMPLET DES TESTS ===' as section;

-- Compter tous les éléments vérifiés
SELECT 
    (SELECT COUNT(*) FROM information_schema.routines 
     WHERE routine_name = 'upsert_brand'
     AND routine_schema = 'public') as fonction_trouvee,
    
    (SELECT COUNT(*) FROM information_schema.routine_privileges 
     WHERE routine_name = 'upsert_brand'
     AND routine_schema = 'public'
     AND grantee = 'authenticated') as permissions_trouvees,
    
    (SELECT COUNT(*) FROM information_schema.table_constraints 
     WHERE constraint_type = 'FOREIGN KEY' 
     AND table_schema = 'public'
     AND (table_name = 'device_models' OR table_name = 'brand_categories')) as contraintes_trouvees,
    
    (SELECT COUNT(*) FROM public.device_brands) as marques_existantes,
    
    (SELECT COUNT(*) FROM public.device_categories) as categories_existantes;

-- 11. VÉRIFICATION FINALE DE L'AMBIGUÏTÉ (CORRIGÉ)
-- ============================================================================
SELECT '=== VÉRIFICATION FINALE DE L''AMBIGUÏTÉ ===' as section;

-- Vérifier que la fonction ne contient pas d'ambiguïté
SELECT 
    CASE 
        WHEN pg_get_functiondef(oid) NOT LIKE '%b.id%' 
        AND pg_get_functiondef(oid) NOT LIKE '%bc.id%'
        AND pg_get_functiondef(oid) NOT LIKE '%dc.id%'
        AND pg_get_functiondef(oid) LIKE '%device_brands.id%'
        AND pg_get_functiondef(oid) LIKE '%device_categories.id%'
        AND pg_get_functiondef(oid) LIKE '%brand_categories.brand_id%'
        THEN '✅ Fonction sans ambiguïté de colonne'
        ELSE '❌ Fonction contient encore des ambiguïtés'
    END as fonction_sans_ambiguite
FROM pg_proc 
WHERE proname = 'upsert_brand' 
AND pronamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public');

-- 12. VÉRIFICATION FINALE DES TYPES
-- ============================================================================
SELECT '=== VÉRIFICATION FINALE DES TYPES ===' as section;

-- Vérifier que tous les types brand_id sont cohérents
SELECT 
    'Tous les types brand_id sont cohérents' as status
WHERE NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE column_name LIKE '%brand_id%'
    AND table_schema = 'public'
    AND data_type != 'text'
)
AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'device_brands' 
    AND column_name = 'id'
    AND table_schema = 'public'
    AND data_type != 'text'
);

SELECT '=== TESTS FINAUX CORRIGÉS TERMINÉS ===' as section;



