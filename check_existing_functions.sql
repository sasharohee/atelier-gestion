-- Script pour vérifier les fonctions existantes
-- À exécuter dans Supabase SQL Editor

-- 1. Vérifier les fonctions upsert_brand existantes
SELECT '=== FONCTIONS upsert_brand EXISTANTES ===' as info;
SELECT 
    routine_name,
    routine_type,
    data_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'upsert_brand'
AND routine_schema = 'public';

-- 2. Vérifier les fonctions update_brand_categories existantes
SELECT '=== FONCTIONS update_brand_categories EXISTANTES ===' as info;
SELECT 
    routine_name,
    routine_type,
    data_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'update_brand_categories'
AND routine_schema = 'public';

-- 3. Vérifier les signatures des fonctions
SELECT '=== SIGNATURES DES FONCTIONS ===' as info;
SELECT 
    p.proname as function_name,
    pg_get_function_arguments(p.oid) as arguments,
    pg_get_function_result(p.oid) as return_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public'
AND p.proname IN ('upsert_brand', 'update_brand_categories');

-- 4. Supprimer les fonctions existantes si nécessaire
SELECT '=== SUPPRESSION DES FONCTIONS EXISTANTES ===' as info;

-- Supprimer upsert_brand avec toutes ses signatures possibles
DO $$
BEGIN
    -- Supprimer toutes les variantes de upsert_brand
    DROP FUNCTION IF EXISTS public.upsert_brand(TEXT, TEXT, TEXT, TEXT, UUID[]);
    DROP FUNCTION IF EXISTS public.upsert_brand(TEXT, TEXT, TEXT, TEXT);
    DROP FUNCTION IF EXISTS public.upsert_brand(TEXT, TEXT, TEXT);
    DROP FUNCTION IF EXISTS public.upsert_brand(TEXT, TEXT);
    DROP FUNCTION IF EXISTS public.upsert_brand(TEXT);
    
    RAISE NOTICE '✅ Fonctions upsert_brand supprimées';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '⚠️ Erreur lors de la suppression des fonctions upsert_brand: %', SQLERRM;
END $$;

-- Supprimer update_brand_categories avec toutes ses signatures possibles
DO $$
BEGIN
    -- Supprimer toutes les variantes de update_brand_categories
    DROP FUNCTION IF EXISTS public.update_brand_categories(TEXT, UUID[]);
    DROP FUNCTION IF EXISTS public.update_brand_categories(TEXT, TEXT[]);
    DROP FUNCTION IF EXISTS public.update_brand_categories(TEXT);
    
    RAISE NOTICE '✅ Fonctions update_brand_categories supprimées';
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '⚠️ Erreur lors de la suppression des fonctions update_brand_categories: %', SQLERRM;
END $$;

-- 5. Vérifier que les fonctions ont été supprimées
SELECT '=== VÉRIFICATION SUPPRESSION ===' as info;
SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM information_schema.routines 
            WHERE routine_name = 'upsert_brand'
            AND routine_schema = 'public'
        ) THEN '❌ Fonction upsert_brand existe encore'
        ELSE '✅ Fonction upsert_brand supprimée'
    END as status_upsert_brand;

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM information_schema.routines 
            WHERE routine_name = 'update_brand_categories'
            AND routine_schema = 'public'
        ) THEN '❌ Fonction update_brand_categories existe encore'
        ELSE '✅ Fonction update_brand_categories supprimée'
    END as status_update_brand_categories;

SELECT '✅ Script de diagnostic terminé !' as result;
