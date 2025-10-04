-- Script pour supprimer le trigger problématique
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier les triggers actuels
SELECT 'Triggers actuels sur device_models:' as info;

SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'device_models'
AND trigger_schema = 'public'
ORDER BY trigger_name;

-- 2. Supprimer le trigger problématique
SELECT 'Suppression du trigger problématique...' as info;

DROP TRIGGER IF EXISTS set_device_model_user_ultime ON public.device_models;

-- 3. Supprimer la fonction problématique
SELECT 'Suppression de la fonction problématique...' as info;

DROP FUNCTION IF EXISTS public.set_device_model_user_ultime() CASCADE;

-- 4. Vérifier que le trigger a été supprimé
SELECT 'Vérification de la suppression...' as info;

SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'device_models'
AND trigger_schema = 'public'
ORDER BY trigger_name;

-- 5. Tester la création d'un modèle sans trigger
SELECT 'Test de création sans trigger...' as info;

INSERT INTO public.device_models (
    name,
    brand_id,
    category_id,
    description,
    is_active
) VALUES (
    'Test Without Trigger',
    (SELECT id FROM public.device_brands LIMIT 1),
    (SELECT id FROM public.device_categories LIMIT 1),
    'Test sans trigger problématique',
    true
) ON CONFLICT DO NOTHING;

-- 6. Vérifier l'insertion
SELECT 'Vérification de l''insertion...' as info;

SELECT 
    id,
    name,
    description,
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
SELECT 'Vérification du nettoyage...' as info;

SELECT COUNT(*) as remaining_test_models
FROM public.device_models 
WHERE name = 'Test Without Trigger';

SELECT 'Trigger problématique supprimé avec succès' as final_status;


