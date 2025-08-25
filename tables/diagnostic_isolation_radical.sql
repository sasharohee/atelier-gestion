-- =====================================================
-- DIAGNOSTIC RADICAL ISOLATION - IDENTIFICATION PROBLÈME
-- =====================================================
-- Objectif: Identifier pourquoi l'isolation ne fonctionne PAS
-- Date: 2025-01-23
-- =====================================================

-- 1. VÉRIFICATION UTILISATEUR ACTUEL
SELECT '=== 1. UTILISATEUR ACTUEL ===' as section;

SELECT 
    'Utilisateur connecté' as info,
    auth.uid() as user_id,
    (SELECT email FROM auth.users WHERE id = auth.uid()) as email,
    (SELECT role FROM public.users WHERE id = auth.uid()) as role;

-- 2. VÉRIFICATION TOUS LES UTILISATEURS
SELECT '=== 2. TOUS LES UTILISATEURS ===' as section;

SELECT 
    'Tous les utilisateurs' as info,
    au.id,
    au.email,
    au.created_at,
    pu.role,
    pu.first_name,
    pu.last_name
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
ORDER BY au.created_at;

-- 3. VÉRIFICATION STRUCTURE TABLES
SELECT '=== 3. STRUCTURE TABLES ===' as section;

-- Vérifier la structure de chaque table
SELECT 
    'Structure clients' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'clients'
ORDER BY ordinal_position;

SELECT 
    'Structure devices' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'devices'
ORDER BY ordinal_position;

SELECT 
    'Structure services' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'services'
ORDER BY ordinal_position;

SELECT 
    'Structure parts' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'parts'
ORDER BY ordinal_position;

SELECT 
    'Structure products' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'products'
ORDER BY ordinal_position;

SELECT 
    'Structure device_models' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'device_models'
ORDER BY ordinal_position;

-- 4. VÉRIFICATION DONNÉES ACTUELLES
SELECT '=== 4. DONNÉES ACTUELLES ===' as section;

-- Clients
SELECT 
    'Données clients' as info,
    id,
    first_name,
    last_name,
    email,
    user_id,
    created_by,
    created_at
FROM public.clients
ORDER BY created_at;

-- Devices
SELECT 
    'Données devices' as info,
    id,
    brand,
    model,
    user_id,
    created_by,
    created_at
FROM public.devices
ORDER BY created_at;

-- Services
SELECT 
    'Données services' as info,
    id,
    name,
    description,
    user_id,
    created_by,
    created_at
FROM public.services
ORDER BY created_at;

-- Parts
SELECT 
    'Données parts' as info,
    id,
    name,
    description,
    user_id,
    created_by,
    created_at
FROM public.parts
ORDER BY created_at;

-- Products
SELECT 
    'Données products' as info,
    id,
    name,
    description,
    user_id,
    created_by,
    created_at
FROM public.products
ORDER BY created_at;

-- Device Models
SELECT 
    'Données device_models' as info,
    id,
    brand,
    model,
    user_id,
    created_by,
    created_at
FROM public.device_models
ORDER BY created_at;

-- 5. VÉRIFICATION RLS
SELECT '=== 5. VÉRIFICATION RLS ===' as section;

-- Statut RLS
SELECT 
    'Statut RLS' as info,
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('clients', 'devices', 'services', 'parts', 'products', 'device_models')
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
AND tablename IN ('clients', 'devices', 'services', 'parts', 'products', 'device_models')
ORDER BY tablename, policyname;

-- 6. VÉRIFICATION TRIGGERS
SELECT '=== 6. VÉRIFICATION TRIGGERS ===' as section;

SELECT 
    'Triggers existants' as info,
    event_object_table,
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN ('clients', 'devices', 'services', 'parts', 'products', 'device_models')
ORDER BY event_object_table, trigger_name;

-- 7. TEST D'ISOLATION MANUEL
SELECT '=== 7. TEST ISOLATION MANUEL ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    total_clients INTEGER;
    my_clients INTEGER;
    total_devices INTEGER;
    my_devices INTEGER;
    total_services INTEGER;
    my_services INTEGER;
    total_parts INTEGER;
    my_parts INTEGER;
    total_products INTEGER;
    my_products INTEGER;
    total_models INTEGER;
    my_models INTEGER;
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
    RAISE NOTICE '📊 Clients: %/% (moi/total)', my_clients, total_clients;
    
    -- Test Devices
    SELECT COUNT(*) INTO total_devices FROM public.devices;
    SELECT COUNT(*) INTO my_devices FROM public.devices WHERE user_id = current_user_id;
    RAISE NOTICE '📊 Devices: %/% (moi/total)', my_devices, total_devices;
    
    -- Test Services
    SELECT COUNT(*) INTO total_services FROM public.services;
    SELECT COUNT(*) INTO my_services FROM public.services WHERE user_id = current_user_id;
    RAISE NOTICE '📊 Services: %/% (moi/total)', my_services, total_services;
    
    -- Test Parts
    SELECT COUNT(*) INTO total_parts FROM public.parts;
    SELECT COUNT(*) INTO my_parts FROM public.parts WHERE user_id = current_user_id;
    RAISE NOTICE '📊 Parts: %/% (moi/total)', my_parts, total_parts;
    
    -- Test Products
    SELECT COUNT(*) INTO total_products FROM public.products;
    SELECT COUNT(*) INTO my_products FROM public.products WHERE user_id = current_user_id;
    RAISE NOTICE '📊 Products: %/% (moi/total)', my_products, total_products;
    
    -- Test Device Models
    SELECT COUNT(*) INTO total_models FROM public.device_models;
    SELECT COUNT(*) INTO my_models FROM public.device_models WHERE created_by = current_user_id;
    RAISE NOTICE '📊 Device Models: %/% (moi/total)', my_models, total_models;
    
    -- Analyse
    IF total_clients != my_clients OR total_devices != my_devices OR 
       total_services != my_services OR total_parts != my_parts OR 
       total_products != my_products OR total_models != my_models THEN
        RAISE NOTICE '❌ PROBLÈME D''ISOLATION DÉTECTÉ - Données d''autres utilisateurs visibles';
    ELSE
        RAISE NOTICE '✅ Isolation parfaite - Toutes les données appartiennent à l''utilisateur connecté';
    END IF;
END $$;

-- 8. TEST DE LECTURE DIRECTE
SELECT '=== 8. TEST LECTURE DIRECTE ===' as section;

-- Test de lecture directe pour chaque table
SELECT 
    'Lecture directe clients' as info,
    COUNT(*) as total,
    COUNT(CASE WHEN user_id = auth.uid() THEN 1 END) as mes_donnees,
    COUNT(CASE WHEN user_id != auth.uid() THEN 1 END) as autres_donnees
FROM public.clients;

SELECT 
    'Lecture directe devices' as info,
    COUNT(*) as total,
    COUNT(CASE WHEN user_id = auth.uid() THEN 1 END) as mes_donnees,
    COUNT(CASE WHEN user_id != auth.uid() THEN 1 END) as autres_donnees
FROM public.devices;

SELECT 
    'Lecture directe services' as info,
    COUNT(*) as total,
    COUNT(CASE WHEN user_id = auth.uid() THEN 1 END) as mes_donnees,
    COUNT(CASE WHEN user_id != auth.uid() THEN 1 END) as autres_donnees
FROM public.services;

SELECT 
    'Lecture directe parts' as info,
    COUNT(*) as total,
    COUNT(CASE WHEN user_id = auth.uid() THEN 1 END) as mes_donnees,
    COUNT(CASE WHEN user_id != auth.uid() THEN 1 END) as autres_donnees
FROM public.parts;

SELECT 
    'Lecture directe products' as info,
    COUNT(*) as total,
    COUNT(CASE WHEN user_id = auth.uid() THEN 1 END) as mes_donnees,
    COUNT(CASE WHEN user_id != auth.uid() THEN 1 END) as autres_donnees
FROM public.products;

SELECT 
    'Lecture directe device_models' as info,
    COUNT(*) as total,
    COUNT(CASE WHEN created_by = auth.uid() THEN 1 END) as mes_donnees,
    COUNT(CASE WHEN created_by != auth.uid() THEN 1 END) as autres_donnees
FROM public.device_models;

-- 9. TEST D'INSERTION
SELECT '=== 9. TEST INSERTION ===' as section;

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
    
    RAISE NOTICE '🔍 Test d''insertion pour utilisateur: %', current_user_id;
    
    -- Test d'insertion dans clients
    INSERT INTO public.clients (first_name, last_name, email, phone)
    VALUES ('Test Radical', 'Diagnostic', 'test.radical@example.com', '999999999')
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

-- 10. VÉRIFICATION CACHE POSTGREST
SELECT '=== 10. VÉRIFICATION CACHE ===' as section;

-- Rafraîchir le cache PostgREST
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(2);

-- 11. RÉSUMÉ DIAGNOSTIC
SELECT '=== 11. RÉSUMÉ DIAGNOSTIC ===' as section;

-- Résumé des données par table
SELECT 
    'Résumé diagnostic' as info,
    table_name,
    COUNT(*) as total_enregistrements,
    COUNT(CASE WHEN user_id = auth.uid() OR created_by = auth.uid() THEN 1 END) as mes_enregistrements,
    COUNT(CASE WHEN (user_id != auth.uid() AND user_id IS NOT NULL) OR (created_by != auth.uid() AND created_by IS NOT NULL) THEN 1 END) as autres_enregistrements,
    COUNT(CASE WHEN user_id IS NULL AND created_by IS NULL THEN 1 END) as sans_utilisateur
FROM (
    SELECT 'clients' as table_name, user_id, created_by FROM public.clients
    UNION ALL
    SELECT 'devices', user_id, created_by FROM public.devices
    UNION ALL
    SELECT 'services', user_id, created_by FROM public.services
    UNION ALL
    SELECT 'parts', user_id, created_by FROM public.parts
    UNION ALL
    SELECT 'products', user_id, created_by FROM public.products
    UNION ALL
    SELECT 'device_models', user_id, created_by FROM public.device_models
) t
GROUP BY table_name
ORDER BY table_name;

SELECT 'DIAGNOSTIC RADICAL TERMINÉ' as status;
