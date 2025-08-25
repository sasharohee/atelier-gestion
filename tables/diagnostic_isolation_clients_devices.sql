-- =====================================================
-- DIAGNOSTIC ISOLATION CLIENTS ET APPAREILS
-- =====================================================
-- Objectif: Diagnostiquer pourquoi l'isolation ne fonctionne pas pour clients et appareils
-- Date: 2025-01-23
-- =====================================================

-- 1. VÉRIFICATION UTILISATEUR ACTUEL
SELECT '=== 1. UTILISATEUR ACTUEL ===' as section;

SELECT 
    'Utilisateur connecté' as info,
    auth.uid() as user_id,
    (SELECT email FROM auth.users WHERE id = auth.uid()) as email,
    (SELECT role FROM public.users WHERE id = auth.uid()) as role;

-- 2. VÉRIFICATION STRUCTURE TABLES
SELECT '=== 2. STRUCTURE TABLES ===' as section;

-- Structure clients
SELECT 
    'Structure clients' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'clients'
ORDER BY ordinal_position;

-- Structure devices
SELECT 
    'Structure devices' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'devices'
ORDER BY ordinal_position;

-- 3. VÉRIFICATION DONNÉES ACTUELLES
SELECT '=== 3. DONNÉES ACTUELLES ===' as section;

-- Données clients
SELECT 
    'Données clients' as info,
    id,
    first_name,
    last_name,
    email,
    user_id,
    created_by,
    created_at,
    CASE 
        WHEN user_id = auth.uid() THEN 'MES DONNÉES'
        WHEN user_id IS NULL THEN 'SANS UTILISATEUR'
        ELSE 'DONNÉES AUTRE UTILISATEUR'
    END as proprietaire
FROM public.clients
ORDER BY created_at;

-- Données devices
SELECT 
    'Données devices' as info,
    id,
    brand,
    model,
    user_id,
    created_by,
    created_at,
    CASE 
        WHEN user_id = auth.uid() THEN 'MES DONNÉES'
        WHEN user_id IS NULL THEN 'SANS UTILISATEUR'
        ELSE 'DONNÉES AUTRE UTILISATEUR'
    END as proprietaire
FROM public.devices
ORDER BY created_at;

-- 4. VÉRIFICATION RLS
SELECT '=== 4. VÉRIFICATION RLS ===' as section;

-- Statut RLS
SELECT 
    'Statut RLS' as info,
    schemaname,
    tablename,
    rowsecurity,
    CASE 
        WHEN rowsecurity THEN 'RLS ACTIVÉ'
        ELSE 'RLS DÉSACTIVÉ'
    END as status_rls
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('clients', 'devices')
ORDER BY tablename;

-- Politiques RLS
SELECT 
    'Politiques RLS' as info,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('clients', 'devices')
ORDER BY tablename, policyname;

-- 5. VÉRIFICATION TRIGGERS
SELECT '=== 5. VÉRIFICATION TRIGGERS ===' as section;

SELECT 
    'Triggers existants' as info,
    event_object_table,
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN ('clients', 'devices')
ORDER BY event_object_table, trigger_name;

-- 6. TEST D'ISOLATION MANUEL
SELECT '=== 6. TEST ISOLATION MANUEL ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    total_clients INTEGER;
    my_clients INTEGER;
    other_clients INTEGER;
    null_clients INTEGER;
    total_devices INTEGER;
    my_devices INTEGER;
    other_devices INTEGER;
    null_devices INTEGER;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ AUCUN UTILISATEUR CONNECTÉ - Test impossible';
        RETURN;
    END IF;
    
    RAISE NOTICE '🔍 Test d''isolation pour utilisateur: %', current_user_id;
    
    -- Test Clients
    SELECT COUNT(*) INTO total_clients FROM public.clients;
    SELECT COUNT(*) INTO my_clients FROM public.clients WHERE user_id = current_user_id;
    SELECT COUNT(*) INTO other_clients FROM public.clients WHERE user_id != current_user_id AND user_id IS NOT NULL;
    SELECT COUNT(*) INTO null_clients FROM public.clients WHERE user_id IS NULL;
    
    RAISE NOTICE '📊 Clients: %/% (moi/total) - Autres: % - Sans utilisateur: %', my_clients, total_clients, other_clients, null_clients;
    
    -- Test Devices
    SELECT COUNT(*) INTO total_devices FROM public.devices;
    SELECT COUNT(*) INTO my_devices FROM public.devices WHERE user_id = current_user_id;
    SELECT COUNT(*) INTO other_devices FROM public.devices WHERE user_id != current_user_id AND user_id IS NOT NULL;
    SELECT COUNT(*) INTO null_devices FROM public.devices WHERE user_id IS NULL;
    
    RAISE NOTICE '📊 Devices: %/% (moi/total) - Autres: % - Sans utilisateur: %', my_devices, total_devices, other_devices, null_devices;
    
    -- Analyse
    IF other_clients > 0 OR other_devices > 0 THEN
        RAISE NOTICE '❌ PROBLÈME D''ISOLATION MAJEUR - Données d''autres utilisateurs visibles';
    ELSIF null_clients > 0 OR null_devices > 0 THEN
        RAISE NOTICE '⚠️ PROBLÈME D''ISOLATION - Données sans utilisateur assigné';
    ELSE
        RAISE NOTICE '✅ Isolation parfaite - Toutes les données appartiennent à l''utilisateur connecté';
    END IF;
END $$;

-- 7. TEST DE LECTURE DIRECTE
SELECT '=== 7. TEST LECTURE DIRECTE ===' as section;

-- Test de lecture directe pour clients
SELECT 
    'Lecture directe clients' as info,
    COUNT(*) as total,
    COUNT(CASE WHEN user_id = auth.uid() THEN 1 END) as mes_donnees,
    COUNT(CASE WHEN user_id != auth.uid() AND user_id IS NOT NULL THEN 1 END) as autres_donnees,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as sans_utilisateur,
    CASE 
        WHEN COUNT(CASE WHEN user_id != auth.uid() AND user_id IS NOT NULL THEN 1 END) > 0 
        THEN 'PROBLÈME ISOLATION'
        WHEN COUNT(CASE WHEN user_id IS NULL THEN 1 END) > 0 
        THEN 'DONNÉES ORPHELINES'
        ELSE 'ISOLATION OK'
    END as status
FROM public.clients;

-- Test de lecture directe pour devices
SELECT 
    'Lecture directe devices' as info,
    COUNT(*) as total,
    COUNT(CASE WHEN user_id = auth.uid() THEN 1 END) as mes_donnees,
    COUNT(CASE WHEN user_id != auth.uid() AND user_id IS NOT NULL THEN 1 END) as autres_donnees,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as sans_utilisateur,
    CASE 
        WHEN COUNT(CASE WHEN user_id != auth.uid() AND user_id IS NOT NULL THEN 1 END) > 0 
        THEN 'PROBLÈME ISOLATION'
        WHEN COUNT(CASE WHEN user_id IS NULL THEN 1 END) > 0 
        THEN 'DONNÉES ORPHELINES'
        ELSE 'ISOLATION OK'
    END as status
FROM public.devices;

-- 8. TEST D'INSERTION
SELECT '=== 8. TEST INSERTION ===' as section;

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
    
    RAISE NOTICE '🔍 Test d''insertion pour utilisateur: %', current_user_id;
    
    -- Test d'insertion dans clients
    INSERT INTO public.clients (first_name, last_name, email, phone)
    VALUES ('Test Diagnostic', 'Clients', 'test.diagnostic.clients@example.com', '555555555')
    RETURNING id INTO test_client_id;
    
    RAISE NOTICE '✅ Client créé avec ID: %', test_client_id;
    
    -- Vérifier que le client appartient à l'utilisateur actuel
    SELECT user_id INTO test_user_id
    FROM public.clients 
    WHERE id = test_client_id;
    
    RAISE NOTICE '✅ Client créé par: %', test_user_id;
    
    -- Test d'insertion dans devices
    INSERT INTO public.devices (brand, model, serial_number)
    VALUES ('Test Brand', 'Test Model', 'TEST123456')
    RETURNING id INTO test_device_id;
    
    RAISE NOTICE '✅ Device créé avec ID: %', test_device_id;
    
    -- Vérifier que le device appartient à l'utilisateur actuel
    SELECT user_id INTO test_user_id
    FROM public.devices 
    WHERE id = test_device_id;
    
    RAISE NOTICE '✅ Device créé par: %', test_user_id;
    
    -- Nettoyer
    DELETE FROM public.clients WHERE id = test_client_id;
    DELETE FROM public.devices WHERE id = test_device_id;
    RAISE NOTICE '🧹 Tests nettoyés';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test d''insertion: %', SQLERRM;
END $$;

-- 9. VÉRIFICATION CACHE POSTGREST
SELECT '=== 9. VÉRIFICATION CACHE ===' as section;

-- Rafraîchir le cache PostgREST
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(2);

-- 10. RÉSUMÉ DIAGNOSTIC
SELECT '=== 10. RÉSUMÉ DIAGNOSTIC ===' as section;

-- Résumé des données par table
SELECT 
    'Résumé diagnostic' as info,
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
        ELSE 'ISOLATION OK'
    END as status_isolation
FROM (
    SELECT 'clients' as table_name, user_id FROM public.clients
    UNION ALL
    SELECT 'devices', user_id FROM public.devices
) t
GROUP BY table_name
ORDER BY table_name;

SELECT 'DIAGNOSTIC CLIENTS ET DEVICES TERMINÉ' as status;
