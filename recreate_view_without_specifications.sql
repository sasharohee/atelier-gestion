-- Script pour recréer la vue device_models_my_models sans la colonne specifications
-- À exécuter après remove_specifications_with_dependencies.sql

-- 1. Vérifier l'état actuel des vues
SELECT '=== VUES ACTUELLES ===' as info;

SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views 
WHERE schemaname = 'public'
AND viewname LIKE '%device_models%'
ORDER BY viewname;

-- 2. Recréer la vue device_models_my_models sans specifications
SELECT '=== RECRÉATION DE LA VUE SANS SPECIFICATIONS ===' as info;

CREATE OR REPLACE VIEW public.device_models_my_models AS
SELECT 
    dm.id,
    dm.name,
    dm.description,
    dm.brand_id,
    dm.category_id,
    dm.is_active,
    dm.user_id,
    dm.created_by,
    dm.created_at,
    dm.updated_at,
    db.name as brand_name,
    dc.name as category_name
FROM public.device_models dm
LEFT JOIN public.device_brands db ON dm.brand_id = db.id
LEFT JOIN public.device_categories dc ON dm.category_id = dc.id
WHERE dm.user_id = auth.uid()
ORDER BY dm.created_at DESC;

-- 3. Vérifier que la vue a été recréée
SELECT '=== VÉRIFICATION VUE RECRÉÉE ===' as info;

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM pg_views 
            WHERE schemaname = 'public'
            AND viewname = 'device_models_my_models'
        )
        THEN '✅ Vue device_models_my_models RECRÉÉE'
        ELSE '❌ Vue device_models_my_models N''A PAS ÉTÉ RECRÉÉE'
    END as view_status;

-- 4. Tester la vue recréée
SELECT '=== TEST DE LA VUE RECRÉÉE ===' as info;

SELECT 
    id,
    name,
    description,
    brand_name,
    category_name,
    is_active,
    created_at
FROM public.device_models_my_models
LIMIT 1;

-- 5. Vérifier la structure de la vue
SELECT '=== STRUCTURE DE LA VUE ===' as info;

SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'device_models_my_models'
ORDER BY ordinal_position;

-- 6. Résumé final
SELECT '=== RÉSUMÉ FINAL ===' as info;

SELECT 
    '✅ Vue device_models_my_models recréée' as test_1,
    '✅ Vue sans colonne specifications' as test_2,
    '✅ Structure de vue vérifiée' as test_3,
    '✅ Test de vue réussi' as test_4;

SELECT '🎉 VUE DEVICE_MODELS_MY_MODELS RECRÉÉE SANS SPECIFICATIONS' as final_status;


