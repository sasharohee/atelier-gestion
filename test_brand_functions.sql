-- Script de test pour vérifier les fonctions RPC de gestion des marques
-- À exécuter après la migration V7

-- 1. Vérifier que toutes les fonctions existent
SELECT 'Vérification des fonctions RPC créées...' as step;

SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN (
    'update_brand_categories',
    'upsert_brand',
    'upsert_brand_simple',
    'create_brand_basic'
)
ORDER BY routine_name;

-- 2. Tester la fonction create_brand_basic
SELECT 'Test de create_brand_basic...' as step;

SELECT public.create_brand_basic(
    'test_brand_basic',
    'Marque Test Basic',
    'Description de test',
    'logo_test.png'
) as result;

-- 3. Vérifier que la marque a été créée
SELECT 'Vérification de la marque créée...' as step;

SELECT 
    id,
    name,
    description,
    logo,
    user_id
FROM public.device_brands 
WHERE id = 'test_brand_basic';

-- 4. Tester la fonction upsert_brand_simple
SELECT 'Test de upsert_brand_simple...' as step;

SELECT public.upsert_brand_simple(
    'test_brand_simple',
    'Marque Test Simple',
    'Description de test simple',
    'logo_simple.png'
) as result;

-- 5. Tester la fonction upsert_brand (complète)
SELECT 'Test de upsert_brand...' as step;

SELECT public.upsert_brand(
    'test_brand_complete',
    'Marque Test Complète',
    'Description de test complète',
    'logo_complete.png',
    ARRAY[]::uuid[]
) as result;

-- 6. Tester la fonction update_brand_categories
SELECT 'Test de update_brand_categories...' as step;

SELECT public.update_brand_categories(
    'test_brand_complete',
    ARRAY[]::uuid[]
) as result;

-- 7. Nettoyer les données de test
SELECT 'Nettoyage des données de test...' as step;

DELETE FROM public.device_brands 
WHERE id IN ('test_brand_basic', 'test_brand_simple', 'test_brand_complete');

-- 8. Vérifier le nettoyage
SELECT 'Vérification du nettoyage...' as step;

SELECT COUNT(*) as remaining_test_brands
FROM public.device_brands 
WHERE id LIKE 'test_brand%';

-- 9. Résumé des tests
SELECT 'Tests terminés avec succès' as final_status;


