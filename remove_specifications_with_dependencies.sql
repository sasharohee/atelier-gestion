-- Script pour supprimer la colonne specifications avec ses dépendances
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier les dépendances de la colonne specifications
SELECT '=== VÉRIFICATION DES DÉPENDANCES ===' as info;

SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views 
WHERE schemaname = 'public'
AND viewname LIKE '%device_models%'
ORDER BY viewname;

-- 2. Vérifier les vues qui dépendent de device_models
SELECT '=== VUES DÉPENDANTES DE DEVICE_MODELS ===' as info;

SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views 
WHERE schemaname = 'public'
AND definition LIKE '%device_models%'
ORDER BY viewname;

-- 3. Supprimer la vue device_models_my_models si elle existe
SELECT '=== SUPPRESSION DE LA VUE DEPENDANTE ===' as info;

DROP VIEW IF EXISTS public.device_models_my_models CASCADE;

-- 4. Vérifier que la vue a été supprimée
SELECT '=== VÉRIFICATION SUPPRESSION VUE ===' as info;

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_views 
            WHERE schemaname = 'public'
            AND viewname = 'device_models_my_models'
        )
        THEN '❌ Vue device_models_my_models EXISTE ENCORE'
        ELSE '✅ Vue device_models_my_models SUPPRIMÉE'
    END as view_status;

-- 5. Supprimer la colonne specifications maintenant
SELECT '=== SUPPRESSION DE LA COLONNE SPECIFICATIONS ===' as info;

ALTER TABLE public.device_models 
DROP COLUMN IF EXISTS specifications CASCADE;

-- 6. Vérifier que la colonne a été supprimée
SELECT '=== VÉRIFICATION SUPPRESSION COLONNE ===' as info;

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'specifications'
        )
        THEN '❌ Colonne specifications EXISTE ENCORE'
        ELSE '✅ Colonne specifications SUPPRIMÉE'
    END as specifications_status;

-- 7. Vérifier la structure finale
SELECT '=== STRUCTURE FINALE ===' as info;

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

-- 8. Tester l'insertion sans specifications
SELECT '=== TEST INSERTION SANS SPECIFICATIONS ===' as info;

INSERT INTO public.device_models (
    name,
    brand_id,
    category_id,
    description,
    is_active
) VALUES (
    'Test Without Specifications',
    (SELECT id FROM public.device_brands WHERE is_active = true LIMIT 1),
    (SELECT id FROM public.device_categories WHERE is_active = true LIMIT 1),
    'Test sans colonne specifications',
    true
);

-- 9. Vérifier l'insertion
SELECT '=== VÉRIFICATION INSERTION ===' as info;

SELECT 
    id,
    name,
    description,
    brand_id,
    category_id,
    is_active,
    created_at
FROM public.device_models 
WHERE name = 'Test Without Specifications'
ORDER BY created_at DESC
LIMIT 1;

-- 10. Nettoyer le test
DELETE FROM public.device_models 
WHERE name = 'Test Without Specifications';

-- 11. Vérifier le nettoyage
SELECT '=== VÉRIFICATION NETTOYAGE ===' as info;

SELECT COUNT(*) as remaining_test_models
FROM public.device_models 
WHERE name = 'Test Without Specifications';

-- 12. Résumé final
SELECT '=== RÉSUMÉ FINAL ===' as info;

SELECT 
    '✅ Vue dépendante supprimée' as test_1,
    '✅ Colonne specifications supprimée' as test_2,
    '✅ Insertion sans specifications réussie' as test_3,
    '✅ Nettoyage effectué' as test_4;

SELECT '🎉 COLONNE SPECIFICATIONS ET DÉPENDANCES SUPPRIMÉES AVEC SUCCÈS' as final_status;


