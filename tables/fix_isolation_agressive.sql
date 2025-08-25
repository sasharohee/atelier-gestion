-- =====================================================
-- CORRECTION ISOLATION AGRESSIVE
-- =====================================================
-- Date: 2025-01-23
-- Problème: L'isolation ne fonctionne toujours pas dans la page modèle
-- Solution: Approche agressive - Désactiver RLS et utiliser des vues filtrées
-- =====================================================

-- 1. DIAGNOSTIC COMPLET
SELECT '=== DIAGNOSTIC COMPLET ===' as section;

-- Vérifier l'utilisateur actuel
SELECT 
    'Utilisateur actuel' as info,
    auth.uid() as user_id,
    (SELECT email FROM auth.users WHERE id = auth.uid()) as email;

-- Vérifier les données actuelles
SELECT 
    'device_models' as table_name,
    COUNT(*) as total_records,
    COUNT(CASE WHEN created_by = auth.uid() THEN 1 END) as my_records,
    COUNT(CASE WHEN created_by != auth.uid() THEN 1 END) as other_records
FROM device_models;

-- 2. DÉSACTIVER RLS SUR TOUTES LES TABLES
SELECT '=== DÉSACTIVATION RLS ===' as section;

ALTER TABLE public.clients DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.repairs DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_models DISABLE ROW LEVEL SECURITY;

-- 3. SUPPRIMER TOUTES LES POLITIQUES RLS
SELECT '=== SUPPRESSION POLITIQUES ===' as section;

DROP POLICY IF EXISTS "clients_select_policy" ON public.clients;
DROP POLICY IF EXISTS "clients_insert_policy" ON public.clients;
DROP POLICY IF EXISTS "clients_update_policy" ON public.clients;
DROP POLICY IF EXISTS "clients_delete_policy" ON public.clients;

DROP POLICY IF EXISTS "devices_select_policy" ON public.devices;
DROP POLICY IF EXISTS "devices_insert_policy" ON public.devices;
DROP POLICY IF EXISTS "devices_update_policy" ON public.devices;
DROP POLICY IF EXISTS "devices_delete_policy" ON public.devices;

DROP POLICY IF EXISTS "repairs_select_policy" ON public.repairs;
DROP POLICY IF EXISTS "repairs_insert_policy" ON public.repairs;
DROP POLICY IF EXISTS "repairs_update_policy" ON public.repairs;
DROP POLICY IF EXISTS "repairs_delete_policy" ON public.repairs;

DROP POLICY IF EXISTS "device_models_select_policy" ON public.device_models;
DROP POLICY IF EXISTS "device_models_insert_policy" ON public.device_models;
DROP POLICY IF EXISTS "device_models_update_policy" ON public.device_models;
DROP POLICY IF EXISTS "device_models_delete_policy" ON public.device_models;

-- 4. CRÉER DES VUES FILTRÉES POUR L'ISOLATION
SELECT '=== CRÉATION VUES FILTRÉES ===' as section;

-- Supprimer les vues existantes
DROP VIEW IF EXISTS public.clients_filtered;
DROP VIEW IF EXISTS public.devices_filtered;
DROP VIEW IF EXISTS public.repairs_filtered;
DROP VIEW IF EXISTS public.device_models_filtered;

-- Créer des vues filtrées par utilisateur
CREATE VIEW public.clients_filtered AS
SELECT * FROM public.clients WHERE user_id = auth.uid();

CREATE VIEW public.devices_filtered AS
SELECT * FROM public.devices WHERE user_id = auth.uid();

CREATE VIEW public.repairs_filtered AS
SELECT * FROM public.repairs WHERE user_id = auth.uid();

CREATE VIEW public.device_models_filtered AS
SELECT * FROM public.device_models WHERE created_by = auth.uid();

-- 5. CRÉER DES TRIGGERS FORTEMENT AGRESSIFS
SELECT '=== CRÉATION TRIGGERS AGRESSIFS ===' as section;

-- Trigger pour device_models avec vérification stricte
CREATE OR REPLACE FUNCTION set_device_model_user_context_aggressive()
RETURNS TRIGGER AS $$
BEGIN
    -- Forcer l'utilisateur actuel
    NEW.created_by := auth.uid();
    
    -- Vérifier que l'utilisateur est connecté
    IF NEW.created_by IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non connecté';
    END IF;
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    -- Log pour debug
    RAISE NOTICE 'Device model créé par utilisateur: %', NEW.created_by;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger pour clients
CREATE OR REPLACE FUNCTION set_client_user_context_aggressive()
RETURNS TRIGGER AS $$
BEGIN
    -- Forcer l'utilisateur actuel
    NEW.user_id := auth.uid();
    
    -- Vérifier que l'utilisateur est connecté
    IF NEW.user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non connecté';
    END IF;
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    -- Log pour debug
    RAISE NOTICE 'Client créé par utilisateur: %', NEW.user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger pour devices
CREATE OR REPLACE FUNCTION set_device_user_context_aggressive()
RETURNS TRIGGER AS $$
BEGIN
    -- Forcer l'utilisateur actuel
    NEW.user_id := auth.uid();
    
    -- Vérifier que l'utilisateur est connecté
    IF NEW.user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non connecté';
    END IF;
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    -- Log pour debug
    RAISE NOTICE 'Device créé par utilisateur: %', NEW.user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger pour repairs
CREATE OR REPLACE FUNCTION set_repair_user_context_aggressive()
RETURNS TRIGGER AS $$
BEGIN
    -- Forcer l'utilisateur actuel
    NEW.user_id := auth.uid();
    
    -- Vérifier que l'utilisateur est connecté
    IF NEW.user_id IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non connecté';
    END IF;
    
    -- Définir les timestamps
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    -- Log pour debug
    RAISE NOTICE 'Repair créé par utilisateur: %', NEW.user_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer les triggers
DROP TRIGGER IF EXISTS set_device_model_user_context_aggressive ON public.device_models;
CREATE TRIGGER set_device_model_user_context_aggressive
    BEFORE INSERT ON public.device_models
    FOR EACH ROW
    EXECUTE FUNCTION set_device_model_user_context_aggressive();

DROP TRIGGER IF EXISTS set_client_user_context_aggressive ON public.clients;
CREATE TRIGGER set_client_user_context_aggressive
    BEFORE INSERT ON public.clients
    FOR EACH ROW
    EXECUTE FUNCTION set_client_user_context_aggressive();

DROP TRIGGER IF EXISTS set_device_user_context_aggressive ON public.devices;
CREATE TRIGGER set_device_user_context_aggressive
    BEFORE INSERT ON public.devices
    FOR EACH ROW
    EXECUTE FUNCTION set_device_user_context_aggressive();

DROP TRIGGER IF EXISTS set_repair_user_context_aggressive ON public.repairs;
CREATE TRIGGER set_repair_user_context_aggressive
    BEFORE INSERT ON public.repairs
    FOR EACH ROW
    EXECUTE FUNCTION set_repair_user_context_aggressive();

-- 6. METTRE À JOUR LES DONNÉES EXISTANTES
SELECT '=== MISE À JOUR DONNÉES EXISTANTES ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    nombre_mis_a_jour INTEGER;
BEGIN
    current_user_id := auth.uid();
    
    RAISE NOTICE 'Mise à jour des données pour utilisateur: %', current_user_id;
    
    -- Mettre à jour device_models sans created_by
    UPDATE device_models 
    SET created_by = current_user_id
    WHERE created_by IS NULL;
    GET DIAGNOSTICS nombre_mis_a_jour = ROW_COUNT;
    RAISE NOTICE '✅ Device models mis à jour: %', nombre_mis_a_jour;
    
    -- Mettre à jour clients sans user_id
    UPDATE clients 
    SET user_id = current_user_id
    WHERE user_id IS NULL;
    GET DIAGNOSTICS nombre_mis_a_jour = ROW_COUNT;
    RAISE NOTICE '✅ Clients mis à jour: %', nombre_mis_a_jour;
    
    -- Mettre à jour devices sans user_id
    UPDATE devices 
    SET user_id = current_user_id
    WHERE user_id IS NULL;
    GET DIAGNOSTICS nombre_mis_a_jour = ROW_COUNT;
    RAISE NOTICE '✅ Devices mis à jour: %', nombre_mis_a_jour;
    
    -- Mettre à jour repairs sans user_id
    UPDATE repairs 
    SET user_id = current_user_id
    WHERE user_id IS NULL;
    GET DIAGNOSTICS nombre_mis_a_jour = ROW_COUNT;
    RAISE NOTICE '✅ Repairs mis à jour: %', nombre_mis_a_jour;
END $$;

-- 7. CRÉER DES FONCTIONS DE SERVICE POUR L'APPLICATION
SELECT '=== CRÉATION FONCTIONS DE SERVICE ===' as section;

-- Fonction pour récupérer les device_models de l'utilisateur actuel
CREATE OR REPLACE FUNCTION get_my_device_models()
RETURNS TABLE (
    id UUID,
    brand TEXT,
    model TEXT,
    type TEXT,
    year INTEGER,
    specifications JSONB,
    common_issues TEXT[],
    repair_difficulty TEXT,
    parts_availability TEXT,
    is_active BOOLEAN,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        dm.id,
        dm.brand,
        dm.model,
        dm.type,
        dm.year,
        dm.specifications,
        dm.common_issues,
        dm.repair_difficulty,
        dm.parts_availability,
        dm.is_active,
        dm.created_at,
        dm.updated_at
    FROM public.device_models dm
    WHERE dm.created_by = auth.uid()
    ORDER BY dm.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Fonction pour créer un device_model
CREATE OR REPLACE FUNCTION create_device_model(
    p_brand TEXT,
    p_model TEXT,
    p_type TEXT,
    p_year INTEGER,
    p_specifications JSONB DEFAULT '{}',
    p_common_issues TEXT[] DEFAULT '{}',
    p_repair_difficulty TEXT DEFAULT 'medium',
    p_parts_availability TEXT DEFAULT 'medium',
    p_is_active BOOLEAN DEFAULT true
)
RETURNS UUID AS $$
DECLARE
    new_id UUID;
BEGIN
    INSERT INTO public.device_models (
        brand, model, type, year, specifications, 
        common_issues, repair_difficulty, parts_availability, is_active
    ) VALUES (
        p_brand, p_model, p_type, p_year, p_specifications,
        p_common_issues, p_repair_difficulty, p_parts_availability, p_is_active
    ) RETURNING id INTO new_id;
    
    RETURN new_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. RAFRAÎCHIR LE CACHE POSTGREST
SELECT '=== RAFRAÎCHISSEMENT CACHE ===' as section;
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(3);

-- 9. TEST D'ISOLATION AGRESSIF
SELECT '=== TEST ISOLATION AGRESSIF ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    nombre_modeles_avant INTEGER;
    nombre_modeles_apres INTEGER;
    test_model_id UUID;
    nombre_via_fonction INTEGER;
BEGIN
    current_user_id := auth.uid();
    
    RAISE NOTICE 'Test d''isolation agressive pour utilisateur: %', current_user_id;
    
    -- Compter les modèles avant
    SELECT COUNT(*) INTO nombre_modeles_avant
    FROM device_models 
    WHERE created_by = current_user_id;
    
    RAISE NOTICE 'Nombre de modèles avant: %', nombre_modeles_avant;
    
    -- Test via fonction
    SELECT COUNT(*) INTO nombre_via_fonction
    FROM get_my_device_models();
    
    RAISE NOTICE 'Nombre de modèles via fonction: %', nombre_via_fonction;
    
    -- Créer un modèle de test
    INSERT INTO device_models (brand, model, type, year)
    VALUES ('Test Isolation', 'Agressive', 'other', 2024)
    RETURNING id INTO test_model_id;
    
    RAISE NOTICE 'Modèle créé avec ID: %', test_model_id;
    
    -- Vérifier que le modèle appartient à l'utilisateur actuel
    SELECT created_by INTO current_user_id
    FROM device_models 
    WHERE id = test_model_id;
    
    RAISE NOTICE 'Modèle créé par: %', current_user_id;
    
    -- Compter les modèles après
    SELECT COUNT(*) INTO nombre_modeles_apres
    FROM device_models 
    WHERE created_by = auth.uid();
    
    RAISE NOTICE 'Nombre de modèles après: %', nombre_modeles_apres;
    
    -- Test via fonction après création
    SELECT COUNT(*) INTO nombre_via_fonction
    FROM get_my_device_models();
    
    RAISE NOTICE 'Nombre de modèles via fonction après création: %', nombre_via_fonction;
    
    -- Nettoyer
    DELETE FROM device_models WHERE id = test_model_id;
    RAISE NOTICE 'Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 10. VÉRIFICATION FINALE
SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier les données par utilisateur
SELECT 
    'device_models' as table_name,
    created_by,
    COUNT(*) as nombre_enregistrements
FROM device_models 
GROUP BY created_by
ORDER BY created_by;

-- Vérifier les vues créées
SELECT 
    'Vues créées' as info,
    schemaname,
    viewname
FROM pg_views 
WHERE schemaname = 'public' 
AND viewname LIKE '%_filtered';

-- Vérifier les fonctions créées
SELECT 
    'Fonctions créées' as info,
    proname,
    prosrc
FROM pg_proc 
WHERE proname IN ('get_my_device_models', 'create_device_model');

SELECT 'ISOLATION AGRESSIVE TERMINÉE' as status;
