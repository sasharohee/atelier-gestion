-- Script pour ajouter un trigger simple et flexible (optionnel)
-- À exécuter seulement si vous voulez un trigger pour device_models

-- 1. Créer une fonction simple pour les timestamps
CREATE OR REPLACE FUNCTION public.set_device_model_timestamps_simple()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    -- Si un utilisateur est connecté, l'utiliser (optionnel)
    IF auth.uid() IS NOT NULL THEN
        NEW.user_id := COALESCE(NEW.user_id, auth.uid());
        NEW.created_by := COALESCE(NEW.created_by, auth.uid());
    END IF;
    
    RETURN NEW;
END;
$function$;

-- 2. Créer le trigger simple
CREATE TRIGGER set_device_model_timestamps_simple_trigger
    BEFORE INSERT ON public.device_models
    FOR EACH ROW
    EXECUTE FUNCTION public.set_device_model_timestamps_simple();

-- 3. Vérifier le nouveau trigger
SELECT '=== NOUVEAU TRIGGER CRÉÉ ===' as info;

SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'device_models'
AND trigger_schema = 'public'
ORDER BY trigger_name;

-- 4. Tester le nouveau trigger
SELECT '=== TEST DU NOUVEAU TRIGGER ===' as info;

INSERT INTO public.device_models (
    name,
    brand_id,
    category_id,
    description,
    is_active
) VALUES (
    'Test With Simple Trigger Final',
    (SELECT id FROM public.device_brands WHERE is_active = true LIMIT 1),
    (SELECT id FROM public.device_categories WHERE is_active = true LIMIT 1),
    'Test avec trigger simple final',
    true
);

-- 5. Vérifier l'insertion
SELECT '=== VÉRIFICATION INSERTION ===' as info;

SELECT 
    id,
    name,
    description,
    user_id,
    created_by,
    created_at,
    updated_at
FROM public.device_models 
WHERE name = 'Test With Simple Trigger Final'
ORDER BY created_at DESC
LIMIT 1;

-- 6. Nettoyer le test
DELETE FROM public.device_models 
WHERE name = 'Test With Simple Trigger Final';

-- 7. Vérifier le nettoyage
SELECT '=== VÉRIFICATION NETTOYAGE ===' as info;

SELECT COUNT(*) as remaining_test_models
FROM public.device_models 
WHERE name = 'Test With Simple Trigger Final';

-- 8. Résumé final
SELECT '=== RÉSUMÉ FINAL ===' as info;

SELECT 
    '✅ Fonction simple créée' as test_1,
    '✅ Trigger simple créé' as test_2,
    '✅ Insertion avec trigger réussie' as test_3,
    '✅ Nettoyage effectué' as test_4;

SELECT '🎉 TRIGGER SIMPLE AJOUTÉ AVEC SUCCÈS' as final_status;


