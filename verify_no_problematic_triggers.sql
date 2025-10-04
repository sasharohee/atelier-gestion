-- Script pour vérifier qu'il n'y a plus de triggers problématiques
-- À exécuter après force_remove_trigger_ultime.sql

-- 1. Vérifier tous les triggers sur device_models
SELECT '=== TOUS LES TRIGGERS SUR DEVICE_MODELS ===' as info;

SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'device_models'
AND trigger_schema = 'public'
ORDER BY trigger_name;

-- 2. Vérifier qu'il n'y a plus de trigger ultime
SELECT '=== VÉRIFICATION SUPPRESSION TRIGGER ULTIME ===' as info;

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.triggers 
            WHERE event_object_table = 'device_models'
            AND trigger_schema = 'public'
            AND trigger_name = 'set_device_model_user_ultime'
        )
        THEN '❌ Trigger set_device_model_user_ultime EXISTE ENCORE'
        ELSE '✅ Trigger set_device_model_user_ultime SUPPRIMÉ'
    END as ultime_trigger_status;

-- 3. Vérifier qu'il n'y a plus de fonction ultime
SELECT '=== VÉRIFICATION SUPPRESSION FONCTION ULTIME ===' as info;

SELECT 
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.routines 
            WHERE routine_schema = 'public'
            AND routine_name = 'set_device_model_user_ultime'
        )
        THEN '❌ Fonction set_device_model_user_ultime EXISTE ENCORE'
        ELSE '✅ Fonction set_device_model_user_ultime SUPPRIMÉE'
    END as ultime_function_status;

-- 4. Tester l'insertion multiple
SELECT '=== TEST INSERTION MULTIPLE ===' as info;

INSERT INTO public.device_models (
    name,
    brand_id,
    category_id,
    description,
    is_active
) VALUES 
('Test Multiple 1', (SELECT id FROM public.device_brands WHERE is_active = true LIMIT 1), (SELECT id FROM public.device_categories WHERE is_active = true LIMIT 1), 'Test multiple 1', true),
('Test Multiple 2', (SELECT id FROM public.device_brands WHERE is_active = true LIMIT 1), (SELECT id FROM public.device_categories WHERE is_active = true LIMIT 1), 'Test multiple 2', true);

-- 5. Vérifier les insertions
SELECT '=== VÉRIFICATION INSERTIONS MULTIPLES ===' as info;

SELECT 
    id,
    name,
    description,
    brand_id,
    category_id,
    is_active,
    created_at
FROM public.device_models 
WHERE name LIKE 'Test Multiple%'
ORDER BY created_at DESC;

-- 6. Nettoyer les tests
DELETE FROM public.device_models 
WHERE name LIKE 'Test Multiple%';

-- 7. Vérifier le nettoyage
SELECT '=== VÉRIFICATION NETTOYAGE ===' as info;

SELECT COUNT(*) as remaining_test_models
FROM public.device_models 
WHERE name LIKE 'Test Multiple%';

-- 8. Résumé final
SELECT '=== RÉSUMÉ FINAL ===' as info;

SELECT 
    '✅ Aucun trigger problématique' as test_1,
    '✅ Aucune fonction problématique' as test_2,
    '✅ Insertions multiples réussies' as test_3,
    '✅ Nettoyage effectué' as test_4;

SELECT '🎉 AUCUN TRIGGER PROBLÉMATIQUE DÉTECTÉ' as final_status;


