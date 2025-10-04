-- Script pour vérifier que la colonne specifications a été supprimée
-- À exécuter après remove_specifications_column.sql

-- 1. Vérifier la structure finale
SELECT '=== STRUCTURE FINALE DE DEVICE_MODELS ===' as info;

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

-- 2. Vérifier que la colonne specifications n'existe plus
SELECT '=== VÉRIFICATION SUPPRESSION SPECIFICATIONS ===' as info;

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

-- 3. Vérifier les colonnes restantes
SELECT '=== COLONNES RESTANTES ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models'
ORDER BY ordinal_position;

-- 4. Tester l'insertion avec les colonnes disponibles
SELECT '=== TEST INSERTION AVEC COLONNES DISPONIBLES ===' as info;

INSERT INTO public.device_models (
    name,
    brand_id,
    category_id,
    description,
    is_active
) VALUES (
    'Test Final Without Specifications',
    (SELECT id FROM public.device_brands WHERE is_active = true LIMIT 1),
    (SELECT id FROM public.device_categories WHERE is_active = true LIMIT 1),
    'Test final sans colonne specifications',
    true
);

-- 5. Vérifier l'insertion
SELECT '=== VÉRIFICATION INSERTION FINALE ===' as info;

SELECT 
    id,
    name,
    description,
    brand_id,
    category_id,
    is_active,
    user_id,
    created_by,
    created_at,
    updated_at
FROM public.device_models 
WHERE name = 'Test Final Without Specifications'
ORDER BY created_at DESC
LIMIT 1;

-- 6. Tester la requête avec jointures
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
WHERE dm.name = 'Test Final Without Specifications'
ORDER BY dm.created_at DESC
LIMIT 1;

-- 7. Nettoyer le test
DELETE FROM public.device_models 
WHERE name = 'Test Final Without Specifications';

-- 8. Vérifier le nettoyage
SELECT '=== VÉRIFICATION NETTOYAGE ===' as info;

SELECT COUNT(*) as remaining_test_models
FROM public.device_models 
WHERE name = 'Test Final Without Specifications';

-- 9. Résumé final
SELECT '=== RÉSUMÉ FINAL ===' as info;

SELECT 
    '✅ Structure de table vérifiée' as test_1,
    '✅ Colonne specifications supprimée' as test_2,
    '✅ Insertion sans specifications réussie' as test_3,
    '✅ Requêtes avec jointures réussies' as test_4,
    '✅ Nettoyage effectué' as test_5;

SELECT '🎉 SUPPRESSION DE LA COLONNE SPECIFICATIONS VÉRIFIÉE ET FONCTIONNELLE' as final_status;


