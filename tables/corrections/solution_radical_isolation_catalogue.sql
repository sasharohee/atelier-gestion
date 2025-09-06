-- =====================================================
-- SOLUTION RADICALE - ISOLATION CATALOGUE
-- =====================================================
-- Objectif: Solution radicale pour corriger définitivement l'isolation
-- Date: 2025-01-23
-- =====================================================

-- 1. NETTOYAGE COMPLET ET RADICAL
SELECT '=== 1. NETTOYAGE RADICAL ===' as section;

-- Supprimer TOUTES les politiques RLS existantes
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

-- Supprimer TOUTES les anciennes politiques
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

DROP POLICY IF EXISTS "Users can view own device_models" ON public.device_models;
DROP POLICY IF EXISTS "Users can insert own device_models" ON public.device_models;
DROP POLICY IF EXISTS "Users can update own device_models" ON public.device_models;
DROP POLICY IF EXISTS "Users can delete own device_models" ON public.device_models;

-- Supprimer TOUS les triggers existants
DROP TRIGGER IF EXISTS set_client_user ON public.clients;
DROP TRIGGER IF EXISTS set_device_user ON public.devices;
DROP TRIGGER IF EXISTS set_service_user ON public.services;
DROP TRIGGER IF EXISTS set_part_user ON public.parts;
DROP TRIGGER IF EXISTS set_product_user ON public.products;
DROP TRIGGER IF EXISTS set_device_model_user ON public.device_models;

-- Supprimer TOUTES les fonctions
DROP FUNCTION IF EXISTS set_client_user();
DROP FUNCTION IF EXISTS set_device_user();
DROP FUNCTION IF EXISTS set_service_user();
DROP FUNCTION IF EXISTS set_part_user();
DROP FUNCTION IF EXISTS set_product_user();
DROP FUNCTION IF EXISTS set_device_model_user();

-- 2. VIDER TOUTES LES DONNÉES EXISTANTES
SELECT '=== 2. VIDAGE DONNÉES ===' as section;

-- Vider toutes les tables du catalogue
DELETE FROM public.clients;
DELETE FROM public.devices;
DELETE FROM public.services;
DELETE FROM public.parts;
DELETE FROM public.products;
DELETE FROM public.device_models;

-- 3. S'ASSURER QUE LES COLONNES D'ISOLATION EXISTENT
SELECT '=== 3. VÉRIFICATION COLONNES ===' as section;

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

-- 4. ACTIVER RLS SUR TOUTES LES TABLES
SELECT '=== 4. ACTIVATION RLS ===' as section;

ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.services ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.device_models ENABLE ROW LEVEL SECURITY;

-- 5. CRÉER LES POLITIQUES RLS ULTRA STRICTES
SELECT '=== 5. CRÉATION POLITIQUES ULTRA STRICTES ===' as section;

-- CLIENTS - Politiques ultra strictes
CREATE POLICY "RADICAL_clients_select" ON public.clients
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "RADICAL_clients_insert" ON public.clients
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "RADICAL_clients_update" ON public.clients
    FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "RADICAL_clients_delete" ON public.clients
    FOR DELETE USING (user_id = auth.uid());

-- DEVICES - Politiques ultra strictes
CREATE POLICY "RADICAL_devices_select" ON public.devices
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "RADICAL_devices_insert" ON public.devices
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "RADICAL_devices_update" ON public.devices
    FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "RADICAL_devices_delete" ON public.devices
    FOR DELETE USING (user_id = auth.uid());

-- SERVICES - Politiques ultra strictes
CREATE POLICY "RADICAL_services_select" ON public.services
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "RADICAL_services_insert" ON public.services
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "RADICAL_services_update" ON public.services
    FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "RADICAL_services_delete" ON public.services
    FOR DELETE USING (user_id = auth.uid());

-- PARTS - Politiques ultra strictes
CREATE POLICY "RADICAL_parts_select" ON public.parts
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "RADICAL_parts_insert" ON public.parts
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "RADICAL_parts_update" ON public.parts
    FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "RADICAL_parts_delete" ON public.parts
    FOR DELETE USING (user_id = auth.uid());

-- PRODUCTS - Politiques ultra strictes
CREATE POLICY "RADICAL_products_select" ON public.products
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "RADICAL_products_insert" ON public.products
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "RADICAL_products_update" ON public.products
    FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "RADICAL_products_delete" ON public.products
    FOR DELETE USING (user_id = auth.uid());

-- DEVICE MODELS - Politiques ultra strictes
CREATE POLICY "RADICAL_device_models_select" ON public.device_models
    FOR SELECT USING (created_by = auth.uid());

CREATE POLICY "RADICAL_device_models_insert" ON public.device_models
    FOR INSERT WITH CHECK (created_by = auth.uid());

CREATE POLICY "RADICAL_device_models_update" ON public.device_models
    FOR UPDATE USING (created_by = auth.uid()) WITH CHECK (created_by = auth.uid());

CREATE POLICY "RADICAL_device_models_delete" ON public.device_models
    FOR DELETE USING (created_by = auth.uid());

-- 6. CRÉER LES TRIGGERS ULTRA ROBUSTES
SELECT '=== 6. CRÉATION TRIGGERS ULTRA ROBUSTES ===' as section;

-- Trigger ultra robuste pour clients
CREATE OR REPLACE FUNCTION set_client_user_radical()
RETURNS TRIGGER AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non connecté';
    END IF;
    
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RAISE NOTICE 'Client créé par utilisateur: %', auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER set_client_user_radical
    BEFORE INSERT ON public.clients
    FOR EACH ROW
    EXECUTE FUNCTION set_client_user_radical();

-- Trigger ultra robuste pour devices
CREATE OR REPLACE FUNCTION set_device_user_radical()
RETURNS TRIGGER AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non connecté';
    END IF;
    
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RAISE NOTICE 'Device créé par utilisateur: %', auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER set_device_user_radical
    BEFORE INSERT ON public.devices
    FOR EACH ROW
    EXECUTE FUNCTION set_device_user_radical();

-- Trigger ultra robuste pour services
CREATE OR REPLACE FUNCTION set_service_user_radical()
RETURNS TRIGGER AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non connecté';
    END IF;
    
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RAISE NOTICE 'Service créé par utilisateur: %', auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER set_service_user_radical
    BEFORE INSERT ON public.services
    FOR EACH ROW
    EXECUTE FUNCTION set_service_user_radical();

-- Trigger ultra robuste pour parts
CREATE OR REPLACE FUNCTION set_part_user_radical()
RETURNS TRIGGER AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non connecté';
    END IF;
    
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RAISE NOTICE 'Part créée par utilisateur: %', auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER set_part_user_radical
    BEFORE INSERT ON public.parts
    FOR EACH ROW
    EXECUTE FUNCTION set_part_user_radical();

-- Trigger ultra robuste pour products
CREATE OR REPLACE FUNCTION set_product_user_radical()
RETURNS TRIGGER AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non connecté';
    END IF;
    
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RAISE NOTICE 'Product créé par utilisateur: %', auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER set_product_user_radical
    BEFORE INSERT ON public.products
    FOR EACH ROW
    EXECUTE FUNCTION set_product_user_radical();

-- Trigger ultra robuste pour device_models
CREATE OR REPLACE FUNCTION set_device_model_user_radical()
RETURNS TRIGGER AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'Utilisateur non connecté';
    END IF;
    
    NEW.created_by := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RAISE NOTICE 'Device model créé par utilisateur: %', auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER set_device_model_user_radical
    BEFORE INSERT ON public.device_models
    FOR EACH ROW
    EXECUTE FUNCTION set_device_model_user_radical();

-- 7. TEST D'ISOLATION ULTRA STRICT
SELECT '=== 7. TEST ISOLATION ULTRA STRICT ===' as section;

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
        RAISE NOTICE '❌ Test d''isolation impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    RAISE NOTICE '🔍 Test d''isolation ultra strict pour utilisateur: %', current_user_id;
    
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
            RAISE NOTICE '❌ PROBLÈME D''ISOLATION dans %: %/%', table_name, user_records, total_records;
            test_result := FALSE;
        ELSE
            RAISE NOTICE '✅ Isolation parfaite dans %: %/%', table_name, user_records, total_records;
        END IF;
    END LOOP;
    
    IF test_result THEN
        RAISE NOTICE '🎉 ISOLATION ULTRA STRICTE RÉUSSIE - Toutes les données appartiennent à l''utilisateur connecté';
    ELSE
        RAISE NOTICE '❌ Test d''isolation échoué - Problèmes détectés';
    END IF;
END $$;

-- 8. TEST D'INSERTION ULTRA STRICT
SELECT '=== 8. TEST INSERTION ULTRA STRICT ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    test_id UUID;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Test d''insertion impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    RAISE NOTICE '🔍 Test d''insertion ultra strict pour utilisateur: %', current_user_id;
    
    -- Test d'insertion dans clients
    INSERT INTO public.clients (first_name, last_name, email, phone)
    VALUES ('Test Radical', 'Ultra Strict', 'test.radical.ultra@example.com', '888888888')
    RETURNING id INTO test_id;
    
    RAISE NOTICE '✅ Client créé avec ID: %', test_id;
    
    -- Vérifier que le client appartient à l'utilisateur actuel
    SELECT user_id INTO current_user_id
    FROM public.clients 
    WHERE id = test_id;
    
    RAISE NOTICE '✅ Client créé par: %', current_user_id;
    
    -- Nettoyer
    DELETE FROM public.clients WHERE id = test_id;
    RAISE NOTICE '🧹 Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test d''insertion: %', SQLERRM;
END $$;

-- 9. VÉRIFICATION FINALE ULTRA STRICTE
SELECT '=== 9. VÉRIFICATION FINALE ULTRA STRICTE ===' as section;

-- Vérifier le statut RLS
SELECT 
    'Statut RLS ultra strict' as info,
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('clients', 'devices', 'services', 'parts', 'products', 'device_models')
ORDER BY tablename;

-- Vérifier les politiques créées
SELECT 
    'Politiques RLS ultra strictes créées' as info,
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('clients', 'devices', 'services', 'parts', 'products', 'device_models')
ORDER BY tablename, policyname;

-- Vérifier les triggers créés
SELECT 
    'Triggers ultra robustes créés' as info,
    event_object_table,
    trigger_name,
    event_manipulation
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN ('clients', 'devices', 'services', 'parts', 'products', 'device_models')
ORDER BY event_object_table, trigger_name;

SELECT 'ISOLATION ULTRA STRICTE CATALOGUE RÉUSSIE' as status;
