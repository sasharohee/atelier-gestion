-- =====================================================
-- CORRECTION ISOLATION FORCÉE (URGENT)
-- =====================================================
-- Date: 2025-01-23
-- Problème: Les modèles créés sur le compte A apparaissent aussi sur le compte B
-- Solution: Isolation directe par user_id sans utiliser system_settings
-- =====================================================

-- 1. DIAGNOSTIC INITIAL
SELECT '=== DIAGNOSTIC INITIAL ===' as section;

-- Vérifier l'utilisateur actuel
SELECT 
    'Utilisateur actuel' as info,
    auth.uid() as user_id,
    (SELECT email FROM auth.users WHERE id = auth.uid()) as email;

-- 2. SUPPRIMER TOUTES LES POLITIQUES RLS EXISTANTES
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

-- 3. CRÉER DES POLITIQUES RLS STRICTES PAR USER_ID (SANS WORKSHOP_ID)
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

-- 4. CRÉER DES TRIGGERS POUR DÉFINIR AUTOMATIQUEMENT USER_ID
SELECT '=== CRÉATION TRIGGERS USER_ID ===' as section;

-- Trigger pour clients
CREATE OR REPLACE FUNCTION set_client_user_context()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id := auth.uid();
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

-- 5. METTRE À JOUR LES DONNÉES EXISTANTES AVEC USER_ID
SELECT '=== MISE À JOUR DONNÉES EXISTANTES ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    nombre_mis_a_jour INTEGER;
BEGIN
    current_user_id := auth.uid();
    
    RAISE NOTICE 'Mise à jour des données pour utilisateur: %', current_user_id;
    
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
    
    -- Mettre à jour device_models sans created_by
    UPDATE device_models 
    SET created_by = current_user_id
    WHERE created_by IS NULL;
    GET DIAGNOSTICS nombre_mis_a_jour = ROW_COUNT;
    RAISE NOTICE '✅ Device models mis à jour: %', nombre_mis_a_jour;
END $$;

-- 6. RAFRAÎCHIR LE CACHE POSTGREST
SELECT '=== RAFRAÎCHISSEMENT CACHE ===' as section;
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(3);

-- 7. TEST D'ISOLATION
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
    VALUES ('Test Isolation', 'Urgent', 'other', 2024)
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
    
    -- Nettoyer
    DELETE FROM device_models WHERE id = test_model_id;
    RAISE NOTICE 'Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 8. VÉRIFICATION FINALE
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

-- Vérifier les données par utilisateur pour les autres tables
SELECT 
    'clients' as table_name,
    user_id,
    COUNT(*) as nombre_enregistrements
FROM clients 
GROUP BY user_id
ORDER BY user_id;

SELECT 
    'devices' as table_name,
    user_id,
    COUNT(*) as nombre_enregistrements
FROM devices 
GROUP BY user_id
ORDER BY user_id;

SELECT 
    'repairs' as table_name,
    user_id,
    COUNT(*) as nombre_enregistrements
FROM repairs 
GROUP BY user_id
ORDER BY user_id;

SELECT 'ISOLATION URGENTE TERMINÉE' as status;
