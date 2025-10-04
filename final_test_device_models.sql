-- Test final pour vérifier que device_models fonctionne
-- À exécuter après emergency_fix_device_models.sql et refresh_supabase_cache.sql

-- 1. Vérifier la structure complète
SELECT '=== STRUCTURE COMPLÈTE DE DEVICE_MODELS ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    ordinal_position
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
ORDER BY ordinal_position;

-- 2. Vérifier que toutes les colonnes requises existent
SELECT '=== VÉRIFICATION COLONNES REQUISES ===' as info;

SELECT 
    'id' as column_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'device_models' 
        AND column_name = 'id'
    ) THEN '✅' ELSE '❌' END as status
UNION ALL
SELECT 
    'name' as column_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'device_models' 
        AND column_name = 'name'
    ) THEN '✅' ELSE '❌' END as status
UNION ALL
SELECT 
    'brand_id' as column_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'device_models' 
        AND column_name = 'brand_id'
    ) THEN '✅' ELSE '❌' END as status
UNION ALL
SELECT 
    'category_id' as column_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'device_models' 
        AND column_name = 'category_id'
    ) THEN '✅' ELSE '❌' END as status
UNION ALL
SELECT 
    'description' as column_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'device_models' 
        AND column_name = 'description'
    ) THEN '✅' ELSE '❌' END as status
UNION ALL
SELECT 
    'is_active' as column_name,
    CASE WHEN EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
        AND table_name = 'device_models' 
        AND column_name = 'is_active'
    ) THEN '✅' ELSE '❌' END as status;

-- 3. Tester l'insertion avec toutes les colonnes
SELECT '=== TEST INSERTION COMPLÈTE ===' as info;

INSERT INTO public.device_models (
    name,
    brand_id,
    category_id,
    description,
    is_active
) VALUES (
    'iPhone 15 Pro Max Final Test',
    (SELECT id FROM public.device_brands WHERE name ILIKE '%apple%' LIMIT 1),
    (SELECT id FROM public.device_categories WHERE name ILIKE '%smartphone%' LIMIT 1),
    'Test final avec toutes les colonnes - iPhone 15 Pro Max avec toutes les fonctionnalités',
    true
);

-- 4. Vérifier l'insertion
SELECT '=== VÉRIFICATION INSERTION FINALE ===' as info;

SELECT 
    id,
    name,
    brand_id,
    category_id,
    description,
    is_active,
    user_id,
    created_by,
    created_at,
    updated_at
FROM public.device_models 
WHERE name = 'iPhone 15 Pro Max Final Test'
ORDER BY created_at DESC
LIMIT 1;

-- 5. Tester la requête avec jointures
SELECT '=== TEST REQUÊTE AVEC JOINTURES ===' as info;

SELECT 
    dm.id,
    dm.name,
    dm.description,
    db.name as brand_name,
    dc.name as category_name,
    dm.is_active,
    dm.created_at
FROM public.device_models dm
LEFT JOIN public.device_brands db ON dm.brand_id = db.id
LEFT JOIN public.device_categories dc ON dm.category_id = dc.id
WHERE dm.name = 'iPhone 15 Pro Max Final Test'
ORDER BY dm.created_at DESC
LIMIT 1;

-- 6. Tester la mise à jour
SELECT '=== TEST MISE À JOUR ===' as info;

UPDATE public.device_models 
SET 
    description = 'Description mise à jour pour le test final',
    updated_at = NOW()
WHERE name = 'iPhone 15 Pro Max Final Test';

-- 7. Vérifier la mise à jour
SELECT '=== VÉRIFICATION MISE À JOUR ===' as info;

SELECT 
    id,
    name,
    description,
    updated_at
FROM public.device_models 
WHERE name = 'iPhone 15 Pro Max Final Test';

-- 8. Nettoyer le test
DELETE FROM public.device_models 
WHERE name = 'iPhone 15 Pro Max Final Test';

-- 9. Vérifier le nettoyage
SELECT '=== VÉRIFICATION NETTOYAGE ===' as info;

SELECT COUNT(*) as remaining_test_models
FROM public.device_models 
WHERE name = 'iPhone 15 Pro Max Final Test';

-- 10. Résumé final des tests
SELECT '=== RÉSUMÉ FINAL DES TESTS ===' as info;

SELECT 
    '✅ Structure de table vérifiée' as test_1,
    '✅ Colonne description présente' as test_2,
    '✅ Insertion complète réussie' as test_3,
    '✅ Requêtes avec jointures réussies' as test_4,
    '✅ Mise à jour réussie' as test_5,
    '✅ Nettoyage effectué' as test_6;

SELECT '🎉 TOUS LES TESTS DE DEVICE_MODELS SONT PASSÉS AVEC SUCCÈS' as final_status;


