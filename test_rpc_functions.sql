-- Script de test pour les fonctions RPC
-- À exécuter dans Supabase SQL Editor

-- 1. Vérifier que les fonctions existent
SELECT '=== VÉRIFICATION DES FONCTIONS RPC ===' as info;

SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_function_result(p.oid) as return_type,
    pg_get_function_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
AND p.proname IN ('upsert_brand', 'update_brand_categories')
ORDER BY p.proname;

-- 2. Test de la fonction upsert_brand
SELECT '=== TEST DE LA FONCTION upsert_brand ===' as info;

-- Créer une marque de test
SELECT public.upsert_brand(
    'test_brand_1',
    'Marque de Test',
    'Description de la marque de test',
    '',
    ARRAY[]::uuid[]
) as result;

-- 3. Vérifier que la marque a été créée
SELECT '=== VÉRIFICATION DE LA MARQUE CRÉÉE ===' as info;

SELECT id, name, description, logo, is_active, user_id
FROM public.device_brands 
WHERE id = 'test_brand_1';

-- 4. Test de la fonction update_brand_categories
SELECT '=== TEST DE LA FONCTION update_brand_categories ===' as info;

-- Mettre à jour les catégories de la marque de test
-- (Remplacez par un vrai UUID de catégorie si vous en avez une)
SELECT public.update_brand_categories(
    'test_brand_1',
    ARRAY[]::uuid[]
) as result;

-- 5. Nettoyer les données de test
SELECT '=== NETTOYAGE DES DONNÉES DE TEST ===' as info;

DELETE FROM public.brand_categories WHERE brand_id = 'test_brand_1';
DELETE FROM public.device_brands WHERE id = 'test_brand_1';

SELECT '✅ Tests des fonctions RPC terminés !' as result;
SELECT '💡 Les fonctions devraient maintenant fonctionner dans l''application.' as note;
