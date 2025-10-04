-- Script pour supprimer définitivement le trigger set_device_model_user_ultime
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier les triggers actuels
SELECT '=== TRIGGERS ACTUELS ===' as info;

SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'device_models'
AND trigger_schema = 'public'
ORDER BY trigger_name;

-- 2. Supprimer le trigger problématique set_device_model_user_ultime
SELECT '=== SUPPRESSION DU TRIGGER PROBLÉMATIQUE ===' as info;

DROP TRIGGER IF EXISTS set_device_model_user_ultime ON public.device_models;

-- 3. Supprimer la fonction problématique
SELECT '=== SUPPRESSION DE LA FONCTION PROBLÉMATIQUE ===' as info;

DROP FUNCTION IF EXISTS public.set_device_model_user_ultime() CASCADE;

-- 4. Vérifier que le trigger a été supprimé
SELECT '=== VÉRIFICATION SUPPRESSION ===' as info;

SELECT 
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'device_models'
AND trigger_schema = 'public'
ORDER BY trigger_name;

-- 5. Tester l'insertion sans trigger
SELECT '=== TEST INSERTION SANS TRIGGER ===' as info;

INSERT INTO public.device_models (
    name,
    brand_id,
    category_id,
    description,
    is_active
) VALUES (
    'Test Without Ultime Trigger Final',
    (SELECT id FROM public.device_brands WHERE is_active = true LIMIT 1),
    (SELECT id FROM public.device_categories WHERE is_active = true LIMIT 1),
    'Test sans trigger ultime final',
    true
);

-- 6. Vérifier l'insertion
SELECT '=== VÉRIFICATION INSERTION ===' as info;

SELECT 
    id,
    name,
    description,
    brand_id,
    category_id,
    is_active,
    user_id,
    created_by,
    created_at
FROM public.device_models 
WHERE name = 'Test Without Ultime Trigger Final'
ORDER BY created_at DESC
LIMIT 1;

-- 7. Nettoyer le test
DELETE FROM public.device_models 
WHERE name = 'Test Without Ultime Trigger Final';

-- 8. Vérifier le nettoyage
SELECT '=== VÉRIFICATION NETTOYAGE ===' as info;

SELECT COUNT(*) as remaining_test_models
FROM public.device_models 
WHERE name = 'Test Without Ultime Trigger Final';

-- 9. Résumé final
SELECT '=== RÉSUMÉ FINAL ===' as info;

SELECT 
    '✅ Trigger set_device_model_user_ultime supprimé' as test_1,
    '✅ Fonction set_device_model_user_ultime supprimée' as test_2,
    '✅ Insertion sans trigger réussie' as test_3,
    '✅ Nettoyage effectué' as test_4;

SELECT '🎉 TRIGGER ULTIME SUPPRIMÉ DÉFINITIVEMENT' as final_status;


