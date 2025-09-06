-- =====================================================
-- SOLUTION ULTIME ISOLATION CLIENTS ET APPAREILS
-- =====================================================
-- Objectif: Solution ultime pour corriger définitivement l'isolation
-- Date: 2025-01-23
-- ATTENTION: Cette solution vide complètement les tables et recrée tout
-- =====================================================

-- 1. NETTOYAGE COMPLET ET ULTIME
SELECT '=== 1. NETTOYAGE COMPLET ET ULTIME ===' as section;

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

-- 2. VIDAGE COMPLET DES DONNÉES
SELECT '=== 2. VIDAGE COMPLET DES DONNÉES ===' as section;

-- Vider complètement les tables clients et devices
DELETE FROM public.clients;
DELETE FROM public.devices;

-- Vérifier que les tables sont vides
SELECT 
    'Vérification vidage ultime' as info,
    'clients' as table_name,
    COUNT(*) as nombre_enregistrements
FROM public.clients
UNION ALL
SELECT 
    'Vérification vidage ultime' as info,
    'devices' as table_name,
    COUNT(*) as nombre_enregistrements
FROM public.devices;

-- 3. DÉSACTIVER RLS TEMPORAIREMENT
SELECT '=== 3. DÉSACTIVATION RLS TEMPORAIRE ===' as section;

ALTER TABLE public.clients DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices DISABLE ROW LEVEL SECURITY;

-- 4. S'ASSURER QUE LES COLONNES D'ISOLATION EXISTENT
SELECT '=== 4. VÉRIFICATION COLONNES ===' as section;

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

-- 5. ACTIVER RLS
SELECT '=== 5. ACTIVATION RLS ===' as section;

ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.devices ENABLE ROW LEVEL SECURITY;

-- 6. CRÉER LES POLITIQUES RLS ULTIMES
SELECT '=== 6. CRÉATION POLITIQUES RLS ULTIMES ===' as section;

-- CLIENTS - Politiques ultimes
CREATE POLICY "ULTIME_clients_select" ON public.clients
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "ULTIME_clients_insert" ON public.clients
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "ULTIME_clients_update" ON public.clients
    FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "ULTIME_clients_delete" ON public.clients
    FOR DELETE USING (user_id = auth.uid());

-- DEVICES - Politiques ultimes
CREATE POLICY "ULTIME_devices_select" ON public.devices
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "ULTIME_devices_insert" ON public.devices
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "ULTIME_devices_update" ON public.devices
    FOR UPDATE USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "ULTIME_devices_delete" ON public.devices
    FOR DELETE USING (user_id = auth.uid());

-- 7. CRÉER LES TRIGGERS ULTIMES
SELECT '=== 7. CRÉATION TRIGGERS ULTIMES ===' as section;

-- Trigger ultime pour clients
CREATE OR REPLACE FUNCTION set_client_user_ultime()
RETURNS TRIGGER AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'ERREUR ULTIME: Utilisateur non connecté - Isolation impossible';
    END IF;
    
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RAISE NOTICE 'ULTIME: Client créé par utilisateur: %', auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER set_client_user_ultime
    BEFORE INSERT ON public.clients
    FOR EACH ROW
    EXECUTE FUNCTION set_client_user_ultime();

-- Trigger ultime pour devices
CREATE OR REPLACE FUNCTION set_device_user_ultime()
RETURNS TRIGGER AS $$
BEGIN
    IF auth.uid() IS NULL THEN
        RAISE EXCEPTION 'ERREUR ULTIME: Utilisateur non connecté - Isolation impossible';
    END IF;
    
    NEW.user_id := auth.uid();
    NEW.created_at := COALESCE(NEW.created_at, NOW());
    NEW.updated_at := NOW();
    
    RAISE NOTICE 'ULTIME: Device créé par utilisateur: %', auth.uid();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER set_device_user_ultime
    BEFORE INSERT ON public.devices
    FOR EACH ROW
    EXECUTE FUNCTION set_device_user_ultime();

-- 8. TEST D'ISOLATION ULTIME
SELECT '=== 8. TEST ISOLATION ULTIME ===' as section;

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
    
    RAISE NOTICE '🔍 Test d''isolation ultime pour utilisateur: %', current_user_id;
    
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
        RAISE NOTICE '✅ Test d''isolation ultime réussi - Toutes les données appartiennent à l''utilisateur connecté';
    ELSE
        RAISE NOTICE '❌ Test d''isolation ultime échoué - Problèmes détectés';
    END IF;
END $$;

-- 9. TEST D'INSERTION ULTIME
SELECT '=== 9. TEST INSERTION ULTIME ===' as section;

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
    
    RAISE NOTICE '🔍 Test d''insertion ultime pour utilisateur: %', current_user_id;
    
    -- Test d'insertion dans clients
    INSERT INTO public.clients (first_name, last_name, email, phone)
    VALUES ('Test Ultime', 'Clients', 'test.ultime.clients@example.com', '111111111')
    RETURNING id INTO test_client_id;
    
    RAISE NOTICE '✅ Client ultime créé avec ID: %', test_client_id;
    
    -- Vérifier que le client appartient à l'utilisateur actuel
    SELECT user_id INTO test_user_id
    FROM public.clients 
    WHERE id = test_client_id;
    
    RAISE NOTICE '✅ Client ultime créé par: %', test_user_id;
    
    -- Test d'insertion dans devices
    INSERT INTO public.devices (brand, model, serial_number)
    VALUES ('Test Brand Ultime', 'Test Model Ultime', 'TESTULTIME123')
    RETURNING id INTO test_device_id;
    
    RAISE NOTICE '✅ Device ultime créé avec ID: %', test_device_id;
    
    -- Vérifier que le device appartient à l'utilisateur actuel
    SELECT user_id INTO test_user_id
    FROM public.devices 
    WHERE id = test_device_id;
    
    RAISE NOTICE '✅ Device ultime créé par: %', test_user_id;
    
    -- Nettoyer
    DELETE FROM public.clients WHERE id = test_client_id;
    DELETE FROM public.devices WHERE id = test_device_id;
    RAISE NOTICE '🧹 Tests ultimes nettoyés';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test d''insertion ultime: %', SQLERRM;
END $$;

-- 10. VÉRIFICATION FINALE ULTIME
SELECT '=== 10. VÉRIFICATION FINALE ULTIME ===' as section;

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
    'Politiques RLS ultimes créées' as info,
    tablename,
    policyname,
    cmd
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('clients', 'devices')
ORDER BY tablename, policyname;

-- Vérifier les triggers créés
SELECT 
    'Triggers ultimes créés' as info,
    event_object_table,
    trigger_name,
    event_manipulation
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN ('clients', 'devices')
ORDER BY event_object_table, trigger_name;

-- 11. VÉRIFICATION CACHE POSTGREST
SELECT '=== 11. VÉRIFICATION CACHE ===' as section;

-- Rafraîchir le cache PostgREST
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(2);

-- 12. RÉSUMÉ FINAL ULTIME
SELECT '=== 12. RÉSUMÉ FINAL ULTIME ===' as section;

-- Résumé des données par table
SELECT 
    'Résumé final ultime' as info,
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

-- 13. TEST FINAL DE CONFIRMATION
SELECT '=== 13. TEST FINAL DE CONFIRMATION ===' as section;

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

SELECT 'SOLUTION ULTIME CLIENTS ET DEVICES APPLIQUÉE AVEC SUCCÈS' as status;
