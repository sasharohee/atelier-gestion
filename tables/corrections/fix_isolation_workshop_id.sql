-- =====================================================
-- CORRECTION ISOLATION PAR WORKSHOP_ID
-- =====================================================
-- Date: 2025-01-23
-- Problème: L'isolation des données ne fonctionne plus car les politiques RLS utilisent user_id au lieu de workshop_id
-- =====================================================

-- 1. VÉRIFIER L'ÉTAT ACTUEL
SELECT '=== ÉTAT ACTUEL DES POLITIQUES RLS ===' as section;

SELECT 
    tablename,
    policyname,
    cmd,
    qual,
    CASE 
        WHEN qual LIKE '%user_id%' THEN '❌ Isolation par user_id'
        WHEN qual LIKE '%workshop_id%' THEN '✅ Isolation par workshop_id'
        WHEN qual = 'true' THEN '⚠️ Permissive'
        ELSE '⚠️ Autre condition'
    END as isolation_type
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('clients', 'devices', 'repairs', 'device_models')
ORDER BY tablename, policyname;

-- 2. VÉRIFIER LES COLONNES D'ISOLATION
SELECT '=== COLONNES D''ISOLATION ===' as section;

SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name IN ('clients', 'devices', 'repairs', 'device_models')
AND column_name IN ('workshop_id', 'user_id', 'created_by')
ORDER BY table_name, column_name;

-- 3. AJOUTER LES COLONNES WORKSHOP_ID MANQUANTES
SELECT '=== AJOUT COLONNES WORKSHOP_ID ===' as section;

DO $$
BEGIN
    -- Ajouter workshop_id à clients si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'clients' 
            AND column_name = 'workshop_id'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN workshop_id UUID;
        RAISE NOTICE '✅ Colonne workshop_id ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne workshop_id existe déjà dans clients';
    END IF;

    -- Ajouter workshop_id à devices si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'devices' 
            AND column_name = 'workshop_id'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN workshop_id UUID;
        RAISE NOTICE '✅ Colonne workshop_id ajoutée à devices';
    ELSE
        RAISE NOTICE '✅ Colonne workshop_id existe déjà dans devices';
    END IF;

    -- Ajouter workshop_id à repairs si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'repairs' 
            AND column_name = 'workshop_id'
    ) THEN
        ALTER TABLE public.repairs ADD COLUMN workshop_id UUID;
        RAISE NOTICE '✅ Colonne workshop_id ajoutée à repairs';
    ELSE
        RAISE NOTICE '✅ Colonne workshop_id existe déjà dans repairs';
    END IF;

    -- Ajouter workshop_id à device_models si manquant
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'device_models' 
            AND column_name = 'workshop_id'
    ) THEN
        ALTER TABLE public.device_models ADD COLUMN workshop_id UUID;
        RAISE NOTICE '✅ Colonne workshop_id ajoutée à device_models';
    ELSE
        RAISE NOTICE '✅ Colonne workshop_id existe déjà dans device_models';
    END IF;
END $$;

-- 4. METTRE À JOUR LES DONNÉES EXISTANTES AVEC WORKSHOP_ID
SELECT '=== MISE À JOUR WORKSHOP_ID ===' as section;

-- Mettre à jour clients
UPDATE public.clients 
SET workshop_id = (
    SELECT value::UUID 
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1
)
WHERE workshop_id IS NULL;

-- Mettre à jour devices
UPDATE public.devices 
SET workshop_id = (
    SELECT value::UUID 
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1
)
WHERE workshop_id IS NULL;

-- Mettre à jour repairs
UPDATE public.repairs 
SET workshop_id = (
    SELECT value::UUID 
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1
)
WHERE workshop_id IS NULL;

-- Mettre à jour device_models
UPDATE public.device_models 
SET workshop_id = (
    SELECT value::UUID 
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1
)
WHERE workshop_id IS NULL;

-- 5. SUPPRIMER LES ANCIENNES POLITIQUES RLS
SELECT '=== SUPPRESSION ANCIENNES POLITIQUES ===' as section;

-- Supprimer toutes les politiques existantes
DROP POLICY IF EXISTS "Users can view own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can create own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can update own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can delete own clients" ON public.clients;

DROP POLICY IF EXISTS "Users can view own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can create own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can update own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can delete own devices" ON public.devices;

DROP POLICY IF EXISTS "Users can view own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can create own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can update own repairs" ON public.repairs;
DROP POLICY IF EXISTS "Users can delete own repairs" ON public.repairs;

-- 6. CRÉER LES NOUVELLES POLITIQUES RLS AVEC WORKSHOP_ID
SELECT '=== CRÉATION NOUVELLES POLITIQUES WORKSHOP_ID ===' as section;

-- Politiques pour clients
CREATE POLICY "clients_select_policy" ON public.clients
    FOR SELECT USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

CREATE POLICY "clients_insert_policy" ON public.clients
    FOR INSERT WITH CHECK (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

CREATE POLICY "clients_update_policy" ON public.clients
    FOR UPDATE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    ) WITH CHECK (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

CREATE POLICY "clients_delete_policy" ON public.clients
    FOR DELETE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

-- Politiques pour devices
CREATE POLICY "devices_select_policy" ON public.devices
    FOR SELECT USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

CREATE POLICY "devices_insert_policy" ON public.devices
    FOR INSERT WITH CHECK (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

CREATE POLICY "devices_update_policy" ON public.devices
    FOR UPDATE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    ) WITH CHECK (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

CREATE POLICY "devices_delete_policy" ON public.devices
    FOR DELETE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

-- Politiques pour repairs
CREATE POLICY "repairs_select_policy" ON public.repairs
    FOR SELECT USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

CREATE POLICY "repairs_insert_policy" ON public.repairs
    FOR INSERT WITH CHECK (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

CREATE POLICY "repairs_update_policy" ON public.repairs
    FOR UPDATE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    ) WITH CHECK (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

CREATE POLICY "repairs_delete_policy" ON public.repairs
    FOR DELETE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

-- 7. CRÉER LES TRIGGERS POUR DÉFINIR AUTOMATIQUEMENT WORKSHOP_ID
SELECT '=== CRÉATION TRIGGERS WORKSHOP_ID ===' as section;

-- Trigger pour clients
CREATE OR REPLACE FUNCTION set_client_workshop_context()
RETURNS TRIGGER AS $$
DECLARE
    v_workshop_id UUID;
    v_user_id UUID;
BEGIN
    -- Obtenir le workshop_id
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les valeurs automatiquement
    NEW.workshop_id := v_workshop_id;
    NEW.user_id := v_user_id;
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger pour devices
CREATE OR REPLACE FUNCTION set_device_workshop_context()
RETURNS TRIGGER AS $$
DECLARE
    v_workshop_id UUID;
    v_user_id UUID;
BEGIN
    -- Obtenir le workshop_id
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les valeurs automatiquement
    NEW.workshop_id := v_workshop_id;
    NEW.user_id := v_user_id;
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger pour repairs
CREATE OR REPLACE FUNCTION set_repair_workshop_context()
RETURNS TRIGGER AS $$
DECLARE
    v_workshop_id UUID;
    v_user_id UUID;
BEGIN
    -- Obtenir le workshop_id
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les valeurs automatiquement
    NEW.workshop_id := v_workshop_id;
    NEW.user_id := v_user_id;
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger pour device_models
CREATE OR REPLACE FUNCTION set_device_model_workshop_context()
RETURNS TRIGGER AS $$
DECLARE
    v_workshop_id UUID;
    v_user_id UUID;
BEGIN
    -- Obtenir le workshop_id
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Obtenir l'utilisateur actuel
    v_user_id := COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1));
    
    -- Définir les valeurs automatiquement
    NEW.workshop_id := v_workshop_id;
    NEW.created_by := v_user_id;
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Créer les triggers
DROP TRIGGER IF EXISTS set_client_workshop_context ON public.clients;
CREATE TRIGGER set_client_workshop_context
    BEFORE INSERT ON public.clients
    FOR EACH ROW
    EXECUTE FUNCTION set_client_workshop_context();

DROP TRIGGER IF EXISTS set_device_workshop_context ON public.devices;
CREATE TRIGGER set_device_workshop_context
    BEFORE INSERT ON public.devices
    FOR EACH ROW
    EXECUTE FUNCTION set_device_workshop_context();

DROP TRIGGER IF EXISTS set_repair_workshop_context ON public.repairs;
CREATE TRIGGER set_repair_workshop_context
    BEFORE INSERT ON public.repairs
    FOR EACH ROW
    EXECUTE FUNCTION set_repair_workshop_context();

DROP TRIGGER IF EXISTS set_device_model_workshop_context ON public.device_models;
CREATE TRIGGER set_device_model_workshop_context
    BEFORE INSERT ON public.device_models
    FOR EACH ROW
    EXECUTE FUNCTION set_device_model_workshop_context();

-- 8. RAFRAÎCHIR LE CACHE POSTGREST
SELECT '=== RAFRAÎCHISSEMENT CACHE ===' as section;
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(2);

-- 9. VÉRIFIER LES NOUVELLES POLITIQUES
SELECT '=== VÉRIFICATION NOUVELLES POLITIQUES ===' as section;

SELECT 
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%workshop_id%' THEN '✅ Isolation par workshop_id'
        WHEN qual = 'true' THEN '⚠️ Permissive'
        ELSE '⚠️ Autre condition'
    END as isolation_type
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('clients', 'devices', 'repairs', 'device_models')
ORDER BY tablename, policyname;

-- 10. TEST D'ISOLATION
SELECT '=== TEST ISOLATION ===' as section;

DO $$
DECLARE
    current_workshop_id UUID;
    test_client_id UUID;
    test_device_id UUID;
    test_repair_id UUID;
    test_model_id UUID;
BEGIN
    -- Obtenir le workshop_id actuel
    SELECT value::UUID INTO current_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    RAISE NOTICE 'Workshop ID actuel: %', current_workshop_id;
    
    -- Test d'insertion client
    INSERT INTO public.clients (first_name, last_name, email, phone, workshop_id)
    VALUES ('Test Isolation', 'Client', 'test.isolation@example.com', '0123456789', current_workshop_id)
    RETURNING id INTO test_client_id;
    
    RAISE NOTICE '✅ Test client isolation réussi. ID: %', test_client_id;
    
    -- Test d'insertion device
    INSERT INTO public.devices (brand, model, type, workshop_id)
    VALUES ('Test Isolation', 'Device', 'other', current_workshop_id)
    RETURNING id INTO test_device_id;
    
    RAISE NOTICE '✅ Test device isolation réussi. ID: %', test_device_id;
    
    -- Test d'insertion repair
    INSERT INTO public.repairs (status, description, due_date, workshop_id)
    VALUES ('new', 'Test isolation', NOW() + INTERVAL '7 days', current_workshop_id)
    RETURNING id INTO test_repair_id;
    
    RAISE NOTICE '✅ Test repair isolation réussi. ID: %', test_repair_id;
    
    -- Test d'insertion device_model
    INSERT INTO public.device_models (brand, model, type, year, workshop_id)
    VALUES ('Test Isolation', 'Model', 'other', 2024, current_workshop_id)
    RETURNING id INTO test_model_id;
    
    RAISE NOTICE '✅ Test device_model isolation réussi. ID: %', test_model_id;
    
    -- Nettoyer les tests
    DELETE FROM public.clients WHERE id = test_client_id;
    DELETE FROM public.devices WHERE id = test_device_id;
    DELETE FROM public.repairs WHERE id = test_repair_id;
    DELETE FROM public.device_models WHERE id = test_model_id;
    
    RAISE NOTICE '✅ Tests nettoyés';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors des tests: %', SQLERRM;
END $$;

-- 11. VÉRIFICATION FINALE
SELECT 'ISOLATION PAR WORKSHOP_ID RÉTABLIE' as status;
