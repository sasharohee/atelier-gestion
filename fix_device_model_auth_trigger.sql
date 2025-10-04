-- Script pour corriger le trigger d'authentification de device_models
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier le trigger actuel
SELECT 'Vérification du trigger actuel...' as info;

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

-- 4. Créer une fonction plus flexible
SELECT 'Création d''une fonction plus flexible...' as info;

CREATE OR REPLACE FUNCTION public.set_device_model_user_safe()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $function$
BEGIN
    -- Si un utilisateur est authentifié, utiliser son ID
    IF auth.uid() IS NOT NULL THEN
        NEW.user_id := auth.uid();
        NEW.created_by := auth.uid();
        RAISE NOTICE 'Device model créé par utilisateur authentifié: %', auth.uid();
    ELSE
        -- Si aucun utilisateur n'est authentifié, permettre la création
        -- mais ne pas définir user_id/created_by (ou les laisser à NULL si la colonne est nullable)
        -- Ou définir un utilisateur par défaut si nécessaire pour les données globales
        NEW.user_id := NULL; -- Ou un UUID par défaut pour les données globales
        NEW.created_by := NULL; -- Ou un UUID par défaut
        RAISE NOTICE 'Device model créé sans utilisateur authentifié (pour données globales ou tests)';
    END IF;

    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();

    RETURN NEW;
END;
$function$;

-- 5. Recréer le trigger avec la nouvelle fonction
SELECT 'Création du nouveau trigger...' as info;

CREATE TRIGGER set_device_model_user_safe_trigger
    BEFORE INSERT ON public.device_models
    FOR EACH ROW
    EXECUTE FUNCTION public.set_device_model_user_safe();

-- 6. Vérifier que le trigger est bien en place
SELECT 'Vérification du nouveau trigger...' as info;

SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'device_models'
AND trigger_schema = 'public'
ORDER BY trigger_name;

-- 7. Tester la création d'un modèle sans authentification
SELECT 'Test de création sans authentification...' as info;

-- Créer un modèle de test
INSERT INTO public.device_models (
    name,
    brand_id,
    category_id,
    description,
    is_active
) VALUES (
    'Test Model Without Auth',
    (SELECT id FROM public.device_brands LIMIT 1),
    (SELECT id FROM public.device_categories LIMIT 1),
    'Test sans authentification',
    true
) ON CONFLICT DO NOTHING;

-- 8. Vérifier l'insertion
SELECT 'Vérification de l''insertion...' as info;

SELECT 
    id,
    name,
    description,
    user_id,
    created_by,
    created_at
FROM public.device_models 
WHERE name = 'Test Model Without Auth'
ORDER BY created_at DESC
LIMIT 1;

-- 9. Nettoyer le test
DELETE FROM public.device_models 
WHERE name = 'Test Model Without Auth';

-- 10. Vérifier le nettoyage
SELECT 'Vérification du nettoyage...' as info;

SELECT COUNT(*) as remaining_test_models
FROM public.device_models 
WHERE name = 'Test Model Without Auth';

-- 11. Tester avec authentification (si possible)
SELECT 'Test avec authentification...' as info;

-- Note: Ce test ne fonctionnera que si un utilisateur est connecté
-- Dans l'éditeur SQL de Supabase, cela dépendra de la session active
INSERT INTO public.device_models (
    name,
    brand_id,
    category_id,
    description,
    is_active
) VALUES (
    'Test Model With Auth',
    (SELECT id FROM public.device_brands LIMIT 1),
    (SELECT id FROM public.device_categories LIMIT 1),
    'Test avec authentification',
    true
) ON CONFLICT DO NOTHING;

-- Vérifier l'insertion avec auth
SELECT 
    id,
    name,
    description,
    user_id,
    created_by,
    created_at
FROM public.device_models 
WHERE name = 'Test Model With Auth'
ORDER BY created_at DESC
LIMIT 1;

-- Nettoyer ce test aussi
DELETE FROM public.device_models 
WHERE name = 'Test Model With Auth';

SELECT 'Trigger d''authentification corrigé avec succès' as final_status;


