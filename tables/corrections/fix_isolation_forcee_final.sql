-- =====================================================
-- CORRECTION ISOLATION FORCÉE (VERSION FINALE)
-- =====================================================
-- Date: 2025-01-23
-- Problème: Les modèles créés sur le compte A apparaissent aussi sur le compte B
-- Solution: Forcer l'isolation en utilisant l'user_id comme workshop_id
-- Correction: Gestion correcte de la table system_settings selon sa structure
-- =====================================================

-- 1. DIAGNOSTIC INITIAL
SELECT '=== DIAGNOSTIC INITIAL ===' as section;

-- Vérifier l'utilisateur actuel
SELECT 
    'Utilisateur actuel' as info,
    auth.uid() as user_id,
    (SELECT email FROM auth.users WHERE id = auth.uid()) as email;

-- 2. VÉRIFIER LA STRUCTURE DE SYSTEM_SETTINGS
SELECT '=== STRUCTURE SYSTEM_SETTINGS ===' as section;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'system_settings'
ORDER BY ordinal_position;

-- 3. CRÉER UN WORKSHOP_ID UNIQUE PAR UTILISATEUR (VERSION ADAPTATIVE)
SELECT '=== CRÉATION WORKSHOP_ID UNIQUE ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    current_user_email TEXT;
    workshop_id_value TEXT;
    existing_workshop_id TEXT;
    has_user_id_column BOOLEAN;
    has_setting_key_column BOOLEAN;
BEGIN
    -- Obtenir l'utilisateur actuel
    current_user_id := auth.uid();
    SELECT email INTO current_user_email FROM auth.users WHERE id = current_user_id;
    
    -- Créer un workshop_id unique basé sur l'email de l'utilisateur
    workshop_id_value := 'workshop_' || REPLACE(current_user_email, '@', '_at_') || '_' || EXTRACT(EPOCH FROM NOW())::TEXT;
    
    -- Vérifier la structure de la table
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'system_settings' AND column_name = 'user_id'
    ) INTO has_user_id_column;
    
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'system_settings' AND column_name = 'setting_key'
    ) INTO has_setting_key_column;
    
    RAISE NOTICE 'Structure détectée - user_id: %, setting_key: %', has_user_id_column, has_setting_key_column;
    
    -- Vérifier si un workshop_id existe déjà
    IF has_user_id_column THEN
        -- Version avec user_id
        SELECT value INTO existing_workshop_id 
        FROM system_settings 
        WHERE key = 'workshop_id' AND user_id = current_user_id
        LIMIT 1;
    ELSE
        -- Version sans user_id
        SELECT value INTO existing_workshop_id 
        FROM system_settings 
        WHERE key = 'workshop_id' 
        LIMIT 1;
    END IF;
    
    IF existing_workshop_id IS NULL THEN
        -- Créer un nouveau workshop_id
        IF has_user_id_column THEN
            -- Version avec user_id
            INSERT INTO system_settings (user_id, key, value, category, created_at, updated_at)
            VALUES (current_user_id, 'workshop_id', workshop_id_value, 'general', NOW(), NOW());
        ELSIF has_setting_key_column THEN
            -- Version avec setting_key
            INSERT INTO system_settings (setting_key, value, category, created_at, updated_at)
            VALUES ('workshop_id', workshop_id_value, 'general', NOW(), NOW());
        ELSE
            -- Version standard
            INSERT INTO system_settings (key, value, category, created_at, updated_at)
            VALUES ('workshop_id', workshop_id_value, 'general', NOW(), NOW());
        END IF;
        RAISE NOTICE '✅ Nouveau Workshop ID créé: % pour utilisateur: %', workshop_id_value, current_user_email;
    ELSE
        -- Mettre à jour le workshop_id existant
        IF has_user_id_column THEN
            -- Version avec user_id
            UPDATE system_settings 
            SET value = workshop_id_value,
                updated_at = NOW()
            WHERE key = 'workshop_id' AND user_id = current_user_id;
        ELSIF has_setting_key_column THEN
            -- Version avec setting_key
            UPDATE system_settings 
            SET value = workshop_id_value,
                updated_at = NOW()
            WHERE setting_key = 'workshop_id';
        ELSE
            -- Version standard
            UPDATE system_settings 
            SET value = workshop_id_value,
                updated_at = NOW()
            WHERE key = 'workshop_id';
        END IF;
        RAISE NOTICE '✅ Workshop ID mis à jour: % pour utilisateur: %', workshop_id_value, current_user_email;
    END IF;
END $$;

-- 4. METTRE À JOUR TOUTES LES DONNÉES AVEC LE NOUVEAU WORKSHOP_ID
SELECT '=== MISE À JOUR DONNÉES ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    current_workshop_id TEXT;
    nombre_mis_a_jour INTEGER;
BEGIN
    -- Obtenir l'utilisateur et workshop_id actuels
    current_user_id := auth.uid();
    
    -- Récupérer le workshop_id selon la structure
    SELECT value INTO current_workshop_id 
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    RAISE NOTICE 'Mise à jour des données pour utilisateur: % avec workshop: %', current_user_id, current_workshop_id;
    
    -- Mettre à jour clients
    UPDATE clients 
    SET workshop_id = current_workshop_id::UUID
    WHERE user_id = current_user_id;
    GET DIAGNOSTICS nombre_mis_a_jour = ROW_COUNT;
    RAISE NOTICE '✅ Clients mis à jour: %', nombre_mis_a_jour;
    
    -- Mettre à jour devices
    UPDATE devices 
    SET workshop_id = current_workshop_id::UUID
    WHERE user_id = current_user_id;
    GET DIAGNOSTICS nombre_mis_a_jour = ROW_COUNT;
    RAISE NOTICE '✅ Devices mis à jour: %', nombre_mis_a_jour;
    
    -- Mettre à jour repairs
    UPDATE repairs 
    SET workshop_id = current_workshop_id::UUID
    WHERE user_id = current_user_id;
    GET DIAGNOSTICS nombre_mis_a_jour = ROW_COUNT;
    RAISE NOTICE '✅ Repairs mis à jour: %', nombre_mis_a_jour;
    
    -- Mettre à jour device_models
    UPDATE device_models 
    SET workshop_id = current_workshop_id::UUID
    WHERE created_by = current_user_id;
    GET DIAGNOSTICS nombre_mis_a_jour = ROW_COUNT;
    RAISE NOTICE '✅ Device models mis à jour: %', nombre_mis_a_jour;
END $$;

-- 5. SUPPRIMER TOUTES LES POLITIQUES RLS EXISTANTES
SELECT '=== SUPPRESSION POLITIQUES EXISTANTES ===' as section;

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

-- 6. CRÉER DES POLITIQUES RLS STRICTES PAR USER_ID
SELECT '=== CRÉATION POLITIQUES RLS STRICTES ===' as section;

-- Politiques pour clients
CREATE POLICY "clients_select_policy" ON public.clients
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "clients_insert_policy" ON public.clients
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "clients_update_policy" ON public.clients
    FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "clients_delete_policy" ON public.clients
    FOR DELETE USING (user_id = auth.uid());

-- Politiques pour devices
CREATE POLICY "devices_select_policy" ON public.devices
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "devices_insert_policy" ON public.devices
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "devices_update_policy" ON public.devices
    FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "devices_delete_policy" ON public.devices
    FOR DELETE USING (user_id = auth.uid());

-- Politiques pour repairs
CREATE POLICY "repairs_select_policy" ON public.repairs
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "repairs_insert_policy" ON public.repairs
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "repairs_update_policy" ON public.repairs
    FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "repairs_delete_policy" ON public.repairs
    FOR DELETE USING (user_id = auth.uid());

-- Politiques pour device_models (utilise created_by)
CREATE POLICY "device_models_select_policy" ON public.device_models
    FOR SELECT USING (created_by = auth.uid());

CREATE POLICY "device_models_insert_policy" ON public.device_models
    FOR INSERT WITH CHECK (created_by = auth.uid());

CREATE POLICY "device_models_update_policy" ON public.device_models
    FOR UPDATE USING (created_by = auth.uid()) WITH CHECK (created_by = auth.uid());

CREATE POLICY "device_models_delete_policy" ON public.device_models
    FOR DELETE USING (created_by = auth.uid());

-- 7. CRÉER DES TRIGGERS POUR DÉFINIR AUTOMATIQUEMENT USER_ID
SELECT '=== CRÉATION TRIGGERS USER_ID ===' as section;

-- Trigger pour clients
CREATE OR REPLACE FUNCTION set_client_user_context()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id := auth.uid();
    NEW.workshop_id := (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger pour devices
CREATE OR REPLACE FUNCTION set_device_user_context()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id := auth.uid();
    NEW.workshop_id := (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger pour repairs
CREATE OR REPLACE FUNCTION set_repair_user_context()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id := auth.uid();
    NEW.workshop_id := (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger pour device_models
CREATE OR REPLACE FUNCTION set_device_model_user_context()
RETURNS TRIGGER AS $$
BEGIN
    NEW.created_by := auth.uid();
    NEW.workshop_id := (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer les triggers
DROP TRIGGER IF EXISTS set_client_user_context ON public.clients;
CREATE TRIGGER set_client_user_context
    BEFORE INSERT ON public.clients
    FOR EACH ROW
    EXECUTE FUNCTION set_client_user_context();

DROP TRIGGER IF EXISTS set_device_user_context ON public.devices;
CREATE TRIGGER set_device_user_context
    BEFORE INSERT ON public.devices
    FOR EACH ROW
    EXECUTE FUNCTION set_device_user_context();

DROP TRIGGER IF EXISTS set_repair_user_context ON public.repairs;
CREATE TRIGGER set_repair_user_context
    BEFORE INSERT ON public.repairs
    FOR EACH ROW
    EXECUTE FUNCTION set_repair_user_context();

DROP TRIGGER IF EXISTS set_device_model_user_context ON public.device_models;
CREATE TRIGGER set_device_model_user_context
    BEFORE INSERT ON public.device_models
    FOR EACH ROW
    EXECUTE FUNCTION set_device_model_user_context();

-- 8. RAFRAÎCHIR LE CACHE POSTGREST
SELECT '=== RAFRAÎCHISSEMENT CACHE ===' as section;
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(3);

-- 9. TEST D'ISOLATION
SELECT '=== TEST ISOLATION ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    nombre_modeles_avant INTEGER;
    nombre_modeles_apres INTEGER;
    test_model_id UUID;
BEGIN
    current_user_id := auth.uid();
    
    RAISE NOTICE 'Test d''isolation pour utilisateur: %', current_user_id;
    
    -- Compter les modèles avant
    SELECT COUNT(*) INTO nombre_modeles_avant
    FROM device_models 
    WHERE created_by = current_user_id;
    
    RAISE NOTICE 'Nombre de modèles avant: %', nombre_modeles_avant;
    
    -- Créer un modèle de test
    INSERT INTO device_models (brand, model, type, year)
    VALUES ('Test Isolation', 'Finale', 'other', 2024)
    RETURNING id INTO test_model_id;
    
    RAISE NOTICE 'Modèle créé avec ID: %', test_model_id;
    
    -- Vérifier que le modèle appartient à l'utilisateur actuel
    SELECT created_by, workshop_id INTO current_user_id, test_model_id
    FROM device_models 
    WHERE id = test_model_id;
    
    RAISE NOTICE 'Modèle créé par: %, Workshop: %', current_user_id, test_model_id;
    
    -- Compter les modèles après
    SELECT COUNT(*) INTO nombre_modeles_apres
    FROM device_models 
    WHERE created_by = auth.uid();
    
    RAISE NOTICE 'Nombre de modèles après: %', nombre_modeles_apres;
    
    -- Nettoyer
    DELETE FROM device_models WHERE id = test_model_id;
    RAISE NOTICE 'Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 10. VÉRIFICATION FINALE
SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier les politiques créées
SELECT 
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%auth.uid()%' THEN '✅ Isolation par user_id'
        ELSE '⚠️ Autre condition'
    END as isolation_type
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('clients', 'devices', 'repairs', 'device_models')
ORDER BY tablename, policyname;

-- Vérifier les données par utilisateur
SELECT 
    'device_models' as table_name,
    created_by,
    COUNT(*) as nombre_enregistrements
FROM device_models 
GROUP BY created_by
ORDER BY created_by;

-- Vérifier le workshop_id créé
SELECT 
    'Workshop ID créé' as info,
    key,
    value
FROM system_settings 
WHERE key = 'workshop_id';

SELECT 'ISOLATION FORCÉE FINALE TERMINÉE' as status;
