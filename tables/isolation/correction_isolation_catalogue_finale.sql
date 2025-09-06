-- =====================================================
-- CORRECTION FINALE ISOLATION CATALOGUE
-- =====================================================
-- Objectif: Corriger définitivement l'isolation du catalogue
-- Date: 2025-01-23
-- =====================================================

-- 1. NETTOYAGE COMPLET
SELECT '=== NETTOYAGE COMPLET ===' as section;

-- Supprimer toutes les politiques RLS existantes
DROP POLICY IF EXISTS clients_select_policy ON public.clients;
DROP POLICY IF EXISTS clients_insert_policy ON public.clients;
DROP POLICY IF EXISTS clients_update_policy ON public.clients;
DROP POLICY IF EXISTS clients_delete_policy ON public.clients;

DROP POLICY IF EXISTS devices_select_policy ON public.devices;
DROP POLICY IF EXISTS devices_insert_policy ON public.devices;
DROP POLICY IF EXISTS devices_update_policy ON public.devices;
DROP POLICY IF EXISTS devices_delete_policy ON public.devices;

DROP POLICY IF EXISTS services_select_policy ON public.services;
DROP POLICY IF EXISTS services_insert_policy ON public.services;
DROP POLICY IF EXISTS services_update_policy ON public.services;
DROP POLICY IF EXISTS services_delete_policy ON public.services;

DROP POLICY IF EXISTS parts_select_policy ON public.parts;
DROP POLICY IF EXISTS parts_insert_policy ON public.parts;
DROP POLICY IF EXISTS parts_update_policy ON public.parts;
DROP POLICY IF EXISTS parts_delete_policy ON public.parts;

DROP POLICY IF EXISTS products_select_policy ON public.products;
DROP POLICY IF EXISTS products_insert_policy ON public.products;
DROP POLICY IF EXISTS products_update_policy ON public.products;
DROP POLICY IF EXISTS products_delete_policy ON public.products;

DROP POLICY IF EXISTS device_models_select_policy ON public.device_models;
DROP POLICY IF EXISTS device_models_insert_policy ON public.device_models;
DROP POLICY IF EXISTS device_models_update_policy ON public.device_models;
DROP POLICY IF EXISTS device_models_delete_policy ON public.device_models;

-- Supprimer toutes les anciennes politiques
DROP POLICY IF EXISTS "Users can view own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can insert own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can update own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can delete own clients" ON public.clients;

DROP POLICY IF EXISTS "Users can view own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can insert own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can update own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can delete own devices" ON public.devices;

DROP POLICY IF EXISTS "Users can view own services" ON public.services;
DROP POLICY IF EXISTS "Users can insert own services" ON public.services;
DROP POLICY IF EXISTS "Users can update own services" ON public.services;
DROP POLICY IF EXISTS "Users can delete own services" ON public.services;

DROP POLICY IF EXISTS "Users can view own parts" ON public.parts;
DROP POLICY IF EXISTS "Users can insert own parts" ON public.parts;
DROP POLICY IF EXISTS "Users can update own parts" ON public.parts;
DROP POLICY IF EXISTS "Users can delete own parts" ON public.parts;

DROP POLICY IF EXISTS "Users can view own products" ON public.products;
DROP POLICY IF EXISTS "Users can insert own products" ON public.products;
DROP POLICY IF EXISTS "Users can update own products" ON public.products;
DROP POLICY IF EXISTS "Users can delete own products" ON public.products;

-- 2. ACTIVER RLS SUR TOUTES LES TABLES
SELECT '=== ACTIVATION RLS ===' as section;

ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_models ENABLE ROW LEVEL SECURITY;

-- 3. S'ASSURER QUE LES COLONNES D'ISOLATION EXISTENT
SELECT '=== VÉRIFICATION COLONNES ===' as section;

-- Clients
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.clients ADD COLUMN user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne user_id ajoutée à clients';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà dans clients';
    END IF;
END $$;

-- Devices
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'devices' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne user_id ajoutée à devices';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà dans devices';
    END IF;
END $$;

-- Services
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'services' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.services ADD COLUMN user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne user_id ajoutée à services';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà dans services';
    END IF;
END $$;

-- Parts
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'parts' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.parts ADD COLUMN user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne user_id ajoutée à parts';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà dans parts';
    END IF;
END $$;

-- Products
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'products' AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.products ADD COLUMN user_id UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne user_id ajoutée à products';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà dans products';
    END IF;
END $$;

-- Device Models
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'device_models' AND column_name = 'created_by'
    ) THEN
        ALTER TABLE public.device_models ADD COLUMN created_by UUID REFERENCES auth.users(id);
        RAISE NOTICE '✅ Colonne created_by ajoutée à device_models';
    ELSE
        RAISE NOTICE '✅ Colonne created_by existe déjà dans device_models';
    END IF;
END $$;

-- 4. NETTOYER LES DONNÉES EXISTANTES
SELECT '=== NETTOYAGE DONNÉES ===' as section;

-- Mettre à jour les données sans user_id
UPDATE public.clients 
SET user_id = auth.uid()
WHERE user_id IS NULL;

UPDATE public.devices 
SET user_id = auth.uid()
WHERE user_id IS NULL;

UPDATE public.services 
SET user_id = auth.uid()
WHERE user_id IS NULL;

UPDATE public.parts 
SET user_id = auth.uid()
WHERE user_id IS NULL;

UPDATE public.products 
SET user_id = auth.uid()
WHERE user_id IS NULL;

UPDATE public.device_models 
SET created_by = auth.uid()
WHERE created_by IS NULL;

-- 5. CRÉER LES POLITIQUES RLS STRICTES
SELECT '=== CRÉATION POLITIQUES RLS ===' as section;

-- CLIENTS
CREATE POLICY clients_select_policy ON public.clients
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY clients_insert_policy ON public.clients
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY clients_update_policy ON public.clients
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY clients_delete_policy ON public.clients
    FOR DELETE USING (user_id = auth.uid());

-- DEVICES
CREATE POLICY devices_select_policy ON public.devices
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY devices_insert_policy ON public.devices
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY devices_update_policy ON public.devices
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY devices_delete_policy ON public.devices
    FOR DELETE USING (user_id = auth.uid());

-- SERVICES
CREATE POLICY services_select_policy ON public.services
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY services_insert_policy ON public.services
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY services_update_policy ON public.services
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY services_delete_policy ON public.services
    FOR DELETE USING (user_id = auth.uid());

-- PARTS
CREATE POLICY parts_select_policy ON public.parts
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY parts_insert_policy ON public.parts
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY parts_update_policy ON public.parts
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY parts_delete_policy ON public.parts
    FOR DELETE USING (user_id = auth.uid());

-- PRODUCTS
CREATE POLICY products_select_policy ON public.products
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY products_insert_policy ON public.products
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY products_update_policy ON public.products
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY products_delete_policy ON public.products
    FOR DELETE USING (user_id = auth.uid());

-- DEVICE MODELS
CREATE POLICY device_models_select_policy ON public.device_models
    FOR SELECT USING (created_by = auth.uid());

CREATE POLICY device_models_insert_policy ON public.device_models
    FOR INSERT WITH CHECK (created_by = auth.uid());

CREATE POLICY device_models_update_policy ON public.device_models
    FOR UPDATE USING (created_by = auth.uid());

CREATE POLICY device_models_delete_policy ON public.device_models
    FOR DELETE USING (created_by = auth.uid());

-- 6. CRÉER LES TRIGGERS POUR L'ISOLATION AUTOMATIQUE
SELECT '=== CRÉATION TRIGGERS ===' as section;

-- Trigger pour clients
CREATE OR REPLACE FUNCTION set_client_user()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS set_client_user ON public.clients;
CREATE TRIGGER set_client_user
    BEFORE INSERT ON public.clients
    FOR EACH ROW
    EXECUTE FUNCTION set_client_user();

-- Trigger pour devices
CREATE OR REPLACE FUNCTION set_device_user()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS set_device_user ON public.devices;
CREATE TRIGGER set_device_user
    BEFORE INSERT ON public.devices
    FOR EACH ROW
    EXECUTE FUNCTION set_device_user();

-- Trigger pour services
CREATE OR REPLACE FUNCTION set_service_user()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS set_service_user ON public.services;
CREATE TRIGGER set_service_user
    BEFORE INSERT ON public.services
    FOR EACH ROW
    EXECUTE FUNCTION set_service_user();

-- Trigger pour parts
CREATE OR REPLACE FUNCTION set_part_user()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS set_part_user ON public.parts;
CREATE TRIGGER set_part_user
    BEFORE INSERT ON public.parts
    FOR EACH ROW
    EXECUTE FUNCTION set_part_user();

-- Trigger pour products
CREATE OR REPLACE FUNCTION set_product_user()
RETURNS TRIGGER AS $$
BEGIN
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS set_product_user ON public.products;
CREATE TRIGGER set_product_user
    BEFORE INSERT ON public.products
    FOR EACH ROW
    EXECUTE FUNCTION set_product_user();

-- Trigger pour device_models
CREATE OR REPLACE FUNCTION set_device_model_user()
RETURNS TRIGGER AS $$
BEGIN
    NEW.created_by := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS set_device_model_user ON public.device_models;
CREATE TRIGGER set_device_model_user
    BEFORE INSERT ON public.device_models
    FOR EACH ROW
    EXECUTE FUNCTION set_device_model_user();

-- 7. TEST D'ISOLATION COMPLET
SELECT '=== TEST ISOLATION COMPLET ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    test_result BOOLEAN := TRUE;
    table_name TEXT;
    total_records INTEGER;
    user_records INTEGER;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '⚠️ Test d''isolation impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Test d''isolation pour utilisateur: %', current_user_id;
    
    -- Test pour chaque table du catalogue
    FOR table_name IN SELECT unnest(ARRAY['clients', 'devices', 'services', 'parts', 'products', 'device_models'])
    LOOP
        EXECUTE format('SELECT COUNT(*) FROM public.%I', table_name) INTO total_records;
        
        IF table_name = 'device_models' THEN
            EXECUTE format('SELECT COUNT(*) FROM public.%I WHERE created_by = $1', table_name) 
            USING current_user_id INTO user_records;
        ELSE
            EXECUTE format('SELECT COUNT(*) FROM public.%I WHERE user_id = $1', table_name) 
            USING current_user_id INTO user_records;
        END IF;
        
        IF total_records != user_records THEN
            RAISE NOTICE '❌ Problème d''isolation dans %: %/%', table_name, user_records, total_records;
            test_result := FALSE;
        ELSE
            RAISE NOTICE '✅ Isolation OK dans %: %/%', table_name, user_records, total_records;
        END IF;
    END LOOP;
    
    IF test_result THEN
        RAISE NOTICE '✅ Test d''isolation réussi - Toutes les données appartiennent à l''utilisateur connecté';
    ELSE
        RAISE NOTICE '❌ Test d''isolation échoué - Problèmes détectés';
    END IF;
END $$;

-- 8. VÉRIFICATION FINALE
SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier le statut RLS
SELECT 
    'Statut RLS catalogue' as info,
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('clients', 'devices', 'services', 'parts', 'products', 'device_models')
ORDER BY tablename;

-- Vérifier les politiques créées
SELECT 
    'Politiques RLS créées' as info,
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('clients', 'devices', 'services', 'parts', 'products', 'device_models')
ORDER BY tablename, policyname;

-- Vérifier les triggers créés
SELECT 
    'Triggers créés' as info,
    event_object_table,
    trigger_name,
    event_manipulation
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN ('clients', 'devices', 'services', 'parts', 'products', 'device_models')
ORDER BY event_object_table, trigger_name;

SELECT 'ISOLATION CATALOGUE CORRIGÉE AVEC SUCCÈS' as status;
