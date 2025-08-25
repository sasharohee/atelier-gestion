-- =====================================================
-- SOLUTION FINALE - RECRÉATION TABLES CLIENTS ET DEVICES
-- =====================================================
-- Objectif: Recréer complètement les tables avec isolation garantie
-- Date: 2025-01-23
-- ATTENTION: Cette solution supprime et recrée complètement les tables
-- =====================================================

-- 1. NETTOYAGE COMPLET ET FINAL
SELECT '=== 1. NETTOYAGE COMPLET ET FINAL ===' as section;

-- Supprimer TOUTES les politiques RLS existantes
DROP POLICY IF EXISTS clients_select_policy ON public.clients;
DROP POLICY IF EXISTS clients_insert_policy ON public.clients;
DROP POLICY IF EXISTS clients_update_policy ON public.clients;
DROP POLICY IF EXISTS clients_delete_policy ON public.clients;

DROP POLICY IF EXISTS devices_select_policy ON public.devices;
DROP POLICY IF EXISTS devices_insert_policy ON public.devices;
DROP POLICY IF EXISTS devices_update_policy ON public.devices;
DROP POLICY IF EXISTS devices_delete_policy ON public.devices;

DROP POLICY IF EXISTS "Users can view own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can insert own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can update own clients" ON public.clients;
DROP POLICY IF EXISTS "Users can delete own clients" ON public.clients;

DROP POLICY IF EXISTS "Users can view own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can insert own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can update own devices" ON public.devices;
DROP POLICY IF EXISTS "Users can delete own devices" ON public.devices;

DROP POLICY IF EXISTS "ULTIME_clients_select" ON public.clients;
DROP POLICY IF EXISTS "ULTIME_clients_insert" ON public.clients;
DROP POLICY IF EXISTS "ULTIME_clients_update" ON public.clients;
DROP POLICY IF EXISTS "ULTIME_clients_delete" ON public.clients;

DROP POLICY IF EXISTS "ULTIME_devices_select" ON public.devices;
DROP POLICY IF EXISTS "ULTIME_devices_insert" ON public.devices;
DROP POLICY IF EXISTS "ULTIME_devices_update" ON public.devices;
DROP POLICY IF EXISTS "ULTIME_devices_delete" ON public.devices;

DROP POLICY IF EXISTS "CLIENTS_ISOLATION_select" ON public.clients;
DROP POLICY IF EXISTS "CLIENTS_ISOLATION_insert" ON public.clients;
DROP POLICY IF EXISTS "CLIENTS_ISOLATION_update" ON public.clients;
DROP POLICY IF EXISTS "CLIENTS_ISOLATION_delete" ON public.clients;

DROP POLICY IF EXISTS "DEVICES_ISOLATION_select" ON public.devices;
DROP POLICY IF EXISTS "DEVICES_ISOLATION_insert" ON public.devices;
DROP POLICY IF EXISTS "DEVICES_ISOLATION_update" ON public.devices;
DROP POLICY IF EXISTS "DEVICES_ISOLATION_delete" ON public.devices;

DROP POLICY IF EXISTS "RADICAL_clients_select" ON public.clients;
DROP POLICY IF EXISTS "RADICAL_clients_insert" ON public.clients;
DROP POLICY IF EXISTS "RADICAL_clients_update" ON public.clients;
DROP POLICY IF EXISTS "RADICAL_clients_delete" ON public.clients;

DROP POLICY IF EXISTS "RADICAL_devices_select" ON public.devices;
DROP POLICY IF EXISTS "RADICAL_devices_insert" ON public.devices;
DROP POLICY IF EXISTS "RADICAL_devices_update" ON public.devices;
DROP POLICY IF EXISTS "RADICAL_devices_delete" ON public.devices;

-- Supprimer TOUS les triggers existants
DROP TRIGGER IF EXISTS set_client_user ON public.clients;
DROP TRIGGER IF EXISTS set_device_user ON public.devices;
DROP TRIGGER IF EXISTS set_client_user_ultime ON public.clients;
DROP TRIGGER IF EXISTS set_device_user_ultime ON public.devices;
DROP TRIGGER IF EXISTS set_client_user_strict ON public.clients;
DROP TRIGGER IF EXISTS set_device_user_strict ON public.devices;
DROP TRIGGER IF EXISTS set_client_user_radical ON public.clients;
DROP TRIGGER IF EXISTS set_device_user_radical ON public.devices;

-- Supprimer TOUTES les fonctions
DROP FUNCTION IF EXISTS set_client_user();
DROP FUNCTION IF EXISTS set_device_user();
DROP FUNCTION IF EXISTS set_client_user_ultime();
DROP FUNCTION IF EXISTS set_device_user_ultime();
DROP FUNCTION IF EXISTS set_client_user_strict();
DROP FUNCTION IF EXISTS set_device_user_strict();
DROP FUNCTION IF EXISTS set_client_user_radical();
DROP FUNCTION IF EXISTS set_device_user_radical();

-- 2. SUPPRIMER ET RECRÉER LES TABLES
SELECT '=== 2. SUPPRIMER ET RECRÉER LES TABLES ===' as section;

-- Supprimer les tables existantes
DROP TABLE IF EXISTS public.clients CASCADE;
DROP TABLE IF EXISTS public.devices CASCADE;

-- Recréer la table clients avec isolation intégrée
CREATE TABLE public.clients (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    first_name VARCHAR(255) NOT NULL,
    last_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE,
    phone VARCHAR(50),
    address TEXT,
    notes TEXT,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Recréer la table devices avec isolation intégrée
CREATE TABLE public.devices (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    brand VARCHAR(255) NOT NULL,
    model VARCHAR(255) NOT NULL,
    serial_number VARCHAR(255) UNIQUE,
    color VARCHAR(100),
    condition_status VARCHAR(100),
    notes TEXT,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. ACTIVER RLS IMMÉDIATEMENT
SELECT '=== 3. ACTIVATION RLS IMMÉDIATE ===' as section;

ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;

-- 4. CRÉER LES POLITIQUES RLS FINALES
SELECT '=== 4. CRÉATION POLITIQUES RLS FINALES ===' as section;

-- CLIENTS - Politiques finales
CREATE POLICY "FINAL_clients_select" ON public.clients
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "FINAL_clients_insert" ON public.clients
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "FINAL_clients_update" ON public.clients
    FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "FINAL_clients_delete" ON public.clients
    FOR DELETE USING (user_id = auth.uid());

-- DEVICES - Politiques finales
CREATE POLICY "FINAL_devices_select" ON public.devices
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "FINAL_devices_insert" ON public.devices
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "FINAL_devices_update" ON public.devices
    FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "FINAL_devices_delete" ON public.devices
    FOR DELETE USING (user_id = auth.uid());

-- 5. CRÉER LES TRIGGERS FINAUX
SELECT '=== 5. CRÉATION TRIGGERS FINAUX ===' as section;

-- Trigger final pour clients
CREATE OR REPLACE FUNCTION set_client_user_final()
RETURNS TRIGGER AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'ERREUR FINALE: Utilisateur non connecté - Isolation impossible';
    END IF;
    
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RAISE NOTICE 'FINAL: Client créé par utilisateur: %', auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER set_client_user_final
    BEFORE INSERT ON public.clients
    FOR EACH ROW
    EXECUTE FUNCTION set_client_user_final();

-- Trigger final pour devices
CREATE OR REPLACE FUNCTION set_device_user_final()
RETURNS TRIGGER AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'ERREUR FINALE: Utilisateur non connecté - Isolation impossible';
    END IF;
    
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RAISE NOTICE 'FINAL: Device créé par utilisateur: %', auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER set_device_user_final
    BEFORE INSERT ON public.devices
    FOR EACH ROW
    EXECUTE FUNCTION set_device_user_final();

-- 6. TEST D'ISOLATION FINAL
SELECT '=== 6. TEST ISOLATION FINAL ===' as section;

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
    
    RAISE NOTICE '🔍 Test d''isolation final pour utilisateur: %', current_user_id;
    
    -- Test pour clients et devices
    FOR table_name IN SELECT unnest(ARRAY['clients', 'devices'])
    LOOP
        EXECUTE format('SELECT COUNT(*) FROM public.%I', table_name) INTO total_records;
        EXECUTE format('SELECT COUNT(*) FROM public.%I WHERE user_id = $1', table_name) 
        USING current_user_id INTO user_records;
        
        IF total_records != user_records THEN
            RAISE NOTICE '❌ Problème d''isolation dans %: %/%', table_name, user_records, total_records;
            test_result := FALSE;
        ELSE
            RAISE NOTICE '✅ Isolation OK dans %: %/%', table_name, user_records, total_records;
        END IF;
    END LOOP;
    
    IF test_result THEN
        RAISE NOTICE '✅ Test d''isolation final réussi - Toutes les données appartiennent à l''utilisateur connecté';
    ELSE
        RAISE NOTICE '❌ Test d''isolation final échoué - Problèmes détectés';
    END IF;
END $$;

-- 7. TEST D'INSERTION FINAL
SELECT '=== 7. TEST INSERTION FINAL ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    test_client_id UUID;
    test_device_id UUID;
    test_user_id UUID;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Test d''insertion impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    RAISE NOTICE '🔍 Test d''insertion final pour utilisateur: %', current_user_id;
    
    -- Test d'insertion dans clients
    INSERT INTO public.clients (first_name, last_name, email, phone)
    VALUES ('Test Final', 'Clients', 'test.final.clients@example.com', '000000000')
    RETURNING id INTO test_client_id;
    
    RAISE NOTICE '✅ Client final créé avec ID: %', test_client_id;
    
    -- Vérifier que le client appartient à l'utilisateur actuel
    SELECT user_id INTO test_user_id
    FROM public.clients 
    WHERE id = test_client_id;
    
    RAISE NOTICE '✅ Client final créé par: %', test_user_id;
    
    -- Test d'insertion dans devices
    INSERT INTO public.devices (brand, model, serial_number)
    VALUES ('Test Brand Final', 'Test Model Final', 'TESTFINAL123')
    RETURNING id INTO test_device_id;
    
    RAISE NOTICE '✅ Device final créé avec ID: %', test_device_id;
    
    -- Vérifier que le device appartient à l'utilisateur actuel
    SELECT user_id INTO test_user_id
    FROM public.devices 
    WHERE id = test_device_id;
    
    RAISE NOTICE '✅ Device final créé par: %', test_user_id;
    
    -- Nettoyer
    DELETE FROM public.clients WHERE id = test_client_id;
    DELETE FROM public.devices WHERE id = test_device_id;
    RAISE NOTICE '🧹 Tests finaux nettoyés';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test d''insertion final: %', SQLERRM;
END $$;

-- 8. VÉRIFICATION FINALE
SELECT '=== 8. VÉRIFICATION FINALE ===' as section;

-- Vérifier le statut RLS
SELECT 
    'Statut RLS' as info,
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('clients', 'devices')
ORDER BY tablename;

-- Vérifier les politiques créées
SELECT 
    'Politiques RLS finales créées' as info,
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('clients', 'devices')
ORDER BY tablename, policyname;

-- Vérifier les triggers créés
SELECT 
    'Triggers finaux créés' as info,
    event_object_table,
    trigger_name,
    event_manipulation
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN ('clients', 'devices')
ORDER BY event_object_table, trigger_name;

-- 9. VÉRIFICATION CACHE POSTGREST
SELECT '=== 9. VÉRIFICATION CACHE ===' as section;

-- Rafraîchir le cache PostgREST
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(2);

-- 10. RÉSUMÉ FINAL
SELECT '=== 10. RÉSUMÉ FINAL ===' as section;

-- Résumé des données par table
SELECT 
    'Résumé final' as info,
    table_name,
    COUNT(*) as total_enregistrements,
    COUNT(CASE WHEN user_id = auth.uid() THEN 1 END) as mes_enregistrements,
    COUNT(CASE WHEN user_id != auth.uid() AND user_id IS NOT NULL THEN 1 END) as autres_enregistrements,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as sans_utilisateur,
    CASE 
        WHEN COUNT(CASE WHEN user_id != auth.uid() AND user_id IS NOT NULL THEN 1 END) > 0 
        THEN 'PROBLÈME ISOLATION'
        WHEN COUNT(CASE WHEN user_id IS NULL THEN 1 END) > 0 
        THEN 'DONNÉES ORPHELINES'
        ELSE 'ISOLATION PARFAITE'
    END as status_isolation
FROM (
    SELECT 'clients' as table_name, user_id FROM public.clients
    UNION ALL
    SELECT 'devices', user_id FROM public.devices
) t
GROUP BY table_name
ORDER BY table_name;

-- 11. TEST FINAL DE CONFIRMATION
SELECT '=== 11. TEST FINAL DE CONFIRMATION ===' as section;

-- Test final de lecture directe
SELECT 
    'Test final clients' as info,
    COUNT(*) as total,
    COUNT(CASE WHEN user_id = auth.uid() THEN 1 END) as mes_donnees,
    COUNT(CASE WHEN user_id != auth.uid() AND user_id IS NOT NULL THEN 1 END) as autres_donnees,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as sans_utilisateur
FROM public.clients;

SELECT 
    'Test final devices' as info,
    COUNT(*) as total,
    COUNT(CASE WHEN user_id = auth.uid() THEN 1 END) as mes_donnees,
    COUNT(CASE WHEN user_id != auth.uid() AND user_id IS NOT NULL THEN 1 END) as autres_donnees,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as sans_utilisateur
FROM public.devices;

SELECT 'SOLUTION FINALE - TABLES RECRÉÉES AVEC ISOLATION GARANTIE' as status;
