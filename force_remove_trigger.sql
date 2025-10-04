-- Script pour forcer la suppression du trigger problématique
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

-- 2. Supprimer TOUS les triggers sur device_models
SELECT '=== SUPPRESSION DE TOUS LES TRIGGERS ===' as info;

DROP TRIGGER IF EXISTS set_device_model_user_ultime ON public.device_models;
DROP TRIGGER IF EXISTS set_device_model_user_safe ON public.device_models;
DROP TRIGGER IF EXISTS set_device_model_timestamps_trigger ON public.device_models;
DROP TRIGGER IF EXISTS set_device_model_user_safe_trigger ON public.device_models;

-- 3. Supprimer TOUTES les fonctions liées
SELECT '=== SUPPRESSION DES FONCTIONS ===' as info;

DROP FUNCTION IF EXISTS public.set_device_model_user_ultime() CASCADE;
DROP FUNCTION IF EXISTS public.set_device_model_user_safe() CASCADE;
DROP FUNCTION IF EXISTS public.set_device_model_timestamps() CASCADE;
DROP FUNCTION IF EXISTS public.set_device_model_user_safe() CASCADE;

-- 4. Vérifier qu'il n'y a plus de triggers
SELECT '=== VÉRIFICATION APRÈS SUPPRESSION ===' as info;

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
    'Test Without Trigger',
    (SELECT id FROM public.device_brands WHERE is_active = true LIMIT 1),
    (SELECT id FROM public.device_categories WHERE is_active = true LIMIT 1),
    'Test sans trigger problématique',
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
WHERE name = 'Test Without Trigger'
ORDER BY created_at DESC
LIMIT 1;

-- 7. Nettoyer le test
DELETE FROM public.device_models 
WHERE name = 'Test Without Trigger';

-- 8. Vérifier le nettoyage
SELECT '=== VÉRIFICATION NETTOYAGE ===' as info;

SELECT COUNT(*) as remaining_test_models
FROM public.device_models 
WHERE name = 'Test Without Trigger';

SELECT '✅ Trigger problématique supprimé avec succès' as final_status;


