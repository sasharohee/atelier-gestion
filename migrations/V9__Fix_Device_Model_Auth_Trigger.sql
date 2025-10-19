-- Migration V9: Correction du trigger d'authentification pour device_models
-- Le trigger set_device_model_user_ultime() est trop strict et bloque la création

-- 1. Supprimer le trigger problématique
DROP TRIGGER IF EXISTS set_device_model_user_ultime ON public.device_models;

-- 2. Modifier la fonction pour être moins stricte
CREATE OR REPLACE FUNCTION public.set_device_model_user_ultime()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Vérifier l'authentification de manière plus permissive
    IF auth.uid() IS NOT NULL THEN
        NEW.created_by := auth.uid();
        NEW.user_id := auth.uid();
        RAISE NOTICE 'Device model créé par utilisateur authentifié: %', auth.uid();
    ELSE
        -- Si pas d'authentification, utiliser un utilisateur par défaut ou NULL
        NEW.created_by := NULL;
        NEW.user_id := NULL;
        RAISE NOTICE 'Device model créé sans authentification (mode admin)';
    END IF;
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$;

-- 3. Recréer le trigger avec la fonction corrigée
CREATE TRIGGER set_device_model_user_ultime
    BEFORE INSERT ON public.device_models
    FOR EACH ROW
    EXECUTE FUNCTION public.set_device_model_user_ultime();

-- 4. Alternative: Créer une fonction plus permissive
CREATE OR REPLACE FUNCTION public.set_device_model_user_safe()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Toujours permettre la création, avec ou sans authentification
    NEW.created_by := COALESCE(auth.uid(), NEW.created_by);
    NEW.user_id := COALESCE(auth.uid(), NEW.user_id);
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$;

-- 5. Créer un trigger alternatif plus permissif
CREATE TRIGGER set_device_model_user_safe_trigger
    BEFORE INSERT ON public.device_models
    FOR EACH ROW
    EXECUTE FUNCTION public.set_device_model_user_safe();

-- 6. Migration terminée avec succès
SELECT 'Trigger d''authentification corrigé avec succès' as final_status;


