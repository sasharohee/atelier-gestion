-- Script pour ajouter un trigger flexible (optionnel)
-- À exécuter seulement si vous voulez un trigger pour device_models

-- 1. Créer une fonction flexible pour les timestamps
CREATE OR REPLACE FUNCTION public.set_device_model_timestamps()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    -- Si un utilisateur est connecté, l'utiliser
    IF auth.uid() IS NOT NULL THEN
        NEW.user_id := COALESCE(NEW.user_id, auth.uid());
        NEW.created_by := COALESCE(NEW.created_by, auth.uid());
    END IF;
    
    RETURN NEW;
END;
$function$;

-- 2. Créer le trigger flexible
CREATE TRIGGER set_device_model_timestamps_trigger
    BEFORE INSERT ON public.device_models
    FOR EACH ROW
    EXECUTE FUNCTION public.set_device_model_timestamps();

-- 3. Vérifier le nouveau trigger
SELECT 'Nouveau trigger créé:' as info;

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
SELECT 'Test du nouveau trigger...' as info;

INSERT INTO public.device_models (
    name,
    brand_id,
    category_id,
    description,
    is_active
) VALUES (
    'Test With Flexible Trigger',
    (SELECT id FROM public.device_brands LIMIT 1),
    (SELECT id FROM public.device_categories LIMIT 1),
    'Test avec trigger flexible',
    true
) ON CONFLICT DO NOTHING;

-- 5. Vérifier l'insertion
SELECT 'Vérification de l''insertion...' as info;

SELECT 
    id,
    name,
    description,
    user_id,
    created_by,
    created_at,
    updated_at
FROM public.device_models 
WHERE name = 'Test With Flexible Trigger'
ORDER BY created_at DESC
LIMIT 1;

-- 6. Nettoyer le test
DELETE FROM public.device_models 
WHERE name = 'Test With Flexible Trigger';

SELECT 'Trigger flexible ajouté avec succès' as final_status;


