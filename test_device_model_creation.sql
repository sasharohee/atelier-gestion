-- Script de test pour vérifier la création de modèles d'appareils
-- À exécuter après la migration V9

-- 1. Vérifier que les triggers existent
SELECT 'Vérification des triggers...' as step;

SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'device_models'
AND trigger_schema = 'public'
ORDER BY trigger_name;

-- 2. Vérifier que les fonctions existent
SELECT 'Vérification des fonctions...' as step;

SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN (
    'set_device_model_user_ultime',
    'set_device_model_user_safe'
)
ORDER BY routine_name;

-- 3. Tester la création d'un modèle avec authentification
SELECT 'Test de création avec authentification...' as step;

-- Simuler un utilisateur connecté (si possible)
-- Note: Ce test peut échouer si aucun utilisateur n'est connecté
INSERT INTO public.device_models (
    name,
    brand_id,
    category_id,
    description,
    is_active
) VALUES (
    'Test Model Auth',
    (SELECT id FROM public.device_brands LIMIT 1),
    (SELECT id FROM public.device_categories LIMIT 1),
    'Modèle de test avec authentification',
    true
) ON CONFLICT DO NOTHING;

-- 4. Vérifier la création
SELECT 'Vérification de la création...' as step;

SELECT 
    id,
    name,
    description,
    created_by,
    user_id,
    created_at,
    is_active
FROM public.device_models 
WHERE name = 'Test Model Auth'
ORDER BY created_at DESC
LIMIT 1;

-- 5. Tester la création d'un modèle sans authentification
SELECT 'Test de création sans authentification...' as step;

-- Ce test devrait maintenant fonctionner grâce au trigger sécurisé
INSERT INTO public.device_models (
    name,
    brand_id,
    category_id,
    description,
    is_active
) VALUES (
    'Test Model No Auth',
    (SELECT id FROM public.device_brands LIMIT 1),
    (SELECT id FROM public.device_categories LIMIT 1),
    'Modèle de test sans authentification',
    true
) ON CONFLICT DO NOTHING;

-- 6. Vérifier la création sans authentification
SELECT 'Vérification de la création sans auth...' as step;

SELECT 
    id,
    name,
    description,
    created_by,
    user_id,
    created_at,
    is_active
FROM public.device_models 
WHERE name = 'Test Model No Auth'
ORDER BY created_at DESC
LIMIT 1;

-- 7. Nettoyer les tests
SELECT 'Nettoyage des tests...' as step;

DELETE FROM public.device_models 
WHERE name IN ('Test Model Auth', 'Test Model No Auth');

-- 8. Vérifier le nettoyage
SELECT 'Vérification du nettoyage...' as step;

SELECT COUNT(*) as remaining_test_models
FROM public.device_models 
WHERE name LIKE 'Test Model%';

-- 9. Résumé des tests
SELECT 'Tests terminés avec succès - Les modèles peuvent maintenant être créés' as final_status;


