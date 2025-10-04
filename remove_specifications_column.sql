-- Script pour supprimer la colonne specifications (JSON) de device_models
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier la structure actuelle
SELECT '=== STRUCTURE ACTUELLE DE DEVICE_MODELS ===' as info;

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

-- 2. Vérifier si la colonne specifications existe
SELECT '=== VÉRIFICATION COLONNE SPECIFICATIONS ===' as info;

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'specifications'
        )
        THEN '✅ Colonne specifications EXISTE'
        ELSE '❌ Colonne specifications N''EXISTE PAS'
    END as specifications_status;

-- 3. Supprimer la colonne specifications si elle existe
SELECT '=== SUPPRESSION DE LA COLONNE SPECIFICATIONS ===' as info;

ALTER TABLE public.device_models 
DROP COLUMN IF EXISTS specifications;

-- 4. Vérifier que la colonne a été supprimée
SELECT '=== VÉRIFICATION APRÈS SUPPRESSION ===' as info;

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
    END as specifications_status_after;

-- 5. Vérifier la structure finale
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

-- 6. Tester l'insertion sans specifications
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

-- 7. Vérifier l'insertion
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

-- 8. Nettoyer le test
DELETE FROM public.device_models 
WHERE name = 'Test Without Specifications';

-- 9. Vérifier le nettoyage
SELECT '=== VÉRIFICATION NETTOYAGE ===' as info;

SELECT COUNT(*) as remaining_test_models
FROM public.device_models 
WHERE name = 'Test Without Specifications';

-- 10. Résumé final
SELECT '=== RÉSUMÉ FINAL ===' as info;

SELECT 
    '✅ Structure de table vérifiée' as test_1,
    '✅ Colonne specifications supprimée' as test_2,
    '✅ Insertion sans specifications réussie' as test_3,
    '✅ Nettoyage effectué' as test_4;

SELECT '🎉 COLONNE SPECIFICATIONS SUPPRIMÉE AVEC SUCCÈS' as final_status;


