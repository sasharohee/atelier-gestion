-- =====================================================
-- DIAGNOSTIC ULTIME ISOLATION - PROBLÈME RACINE
-- =====================================================
-- Objectif: Identifier la cause racine du problème d'isolation
-- Date: 2025-01-23
-- =====================================================

-- 1. VÉRIFICATION UTILISATEUR ET AUTHENTIFICATION
SELECT '=== 1. VÉRIFICATION AUTHENTIFICATION ===' as section;

-- Vérifier l'utilisateur actuel
SELECT 
    'Utilisateur connecté' as info,
    auth.uid() as user_id,
    (SELECT email FROM auth.users WHERE id = auth.uid()) as email,
    (SELECT role FROM public.users WHERE id = auth.uid()) as role,
    (SELECT first_name FROM public.users WHERE id = auth.uid()) as first_name,
    (SELECT last_name FROM public.users WHERE id = auth.uid()) as last_name;

-- Vérifier si l'utilisateur existe dans la table users
SELECT 
    'Utilisateur dans table users' as info,
    CASE 
        WHEN EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid()) 
        THEN 'EXISTE' 
        ELSE 'N''EXISTE PAS' 
    END as status;

-- 2. VÉRIFICATION RÔLES ET PERMISSIONS
SELECT '=== 2. VÉRIFICATION RÔLES ===' as section;

-- Vérifier tous les utilisateurs et leurs rôles
SELECT 
    'Tous les utilisateurs et rôles' as info,
    au.id,
    au.email,
    au.created_at,
    pu.role,
    pu.first_name,
    pu.last_name,
    CASE 
        WHEN pu.role = 'admin' THEN 'ADMINISTRATEUR'
        WHEN pu.role = 'technician' THEN 'TECHNICIEN'
        ELSE 'RÔLE INCONNU'
    END as role_description
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
ORDER BY au.created_at;

-- 3. VÉRIFICATION STRUCTURE TABLES DÉTAILLÉE
SELECT '=== 3. STRUCTURE TABLES DÉTAILLÉE ===' as section;

-- Vérifier la structure de chaque table avec plus de détails
SELECT 
    'Structure clients détaillée' as info,
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name = 'user_id' THEN 'COLONNE ISOLATION'
        WHEN column_name = 'created_by' THEN 'COLONNE ISOLATION'
        ELSE 'COLONNE NORMALE'
    END as type_colonne
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'clients'
ORDER BY ordinal_position;

SELECT 
    'Structure devices détaillée' as info,
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name = 'user_id' THEN 'COLONNE ISOLATION'
        WHEN column_name = 'created_by' THEN 'COLONNE ISOLATION'
        ELSE 'COLONNE NORMALE'
    END as type_colonne
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'devices'
ORDER BY ordinal_position;

SELECT 
    'Structure services détaillée' as info,
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name = 'user_id' THEN 'COLONNE ISOLATION'
        WHEN column_name = 'created_by' THEN 'COLONNE ISOLATION'
        ELSE 'COLONNE NORMALE'
    END as type_colonne
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'services'
ORDER BY ordinal_position;

SELECT 
    'Structure parts détaillée' as info,
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name = 'user_id' THEN 'COLONNE ISOLATION'
        WHEN column_name = 'created_by' THEN 'COLONNE ISOLATION'
        ELSE 'COLONNE NORMALE'
    END as type_colonne
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'parts'
ORDER BY ordinal_position;

SELECT 
    'Structure products détaillée' as info,
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name = 'user_id' THEN 'COLONNE ISOLATION'
        WHEN column_name = 'created_by' THEN 'COLONNE ISOLATION'
        ELSE 'COLONNE NORMALE'
    END as type_colonne
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'products'
ORDER BY ordinal_position;

SELECT 
    'Structure device_models détaillée' as info,
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name = 'user_id' THEN 'COLONNE ISOLATION'
        WHEN column_name = 'created_by' THEN 'COLONNE ISOLATION'
        ELSE 'COLONNE NORMALE'
    END as type_colonne
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'device_models'
ORDER BY ordinal_position;

-- 4. VÉRIFICATION DONNÉES ACTUELLES DÉTAILLÉE
SELECT '=== 4. DONNÉES ACTUELLES DÉTAILLÉE ===' as section;

-- Vérifier toutes les données avec plus de détails
SELECT 
    'Données clients détaillées' as info,
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

SELECT 
    'Données devices détaillées' as info,
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

SELECT 
    'Données services détaillées' as info,
    id,
    name,
    description,
    user_id,
    created_by,
    created_at,
    CASE 
        WHEN user_id = auth.uid() THEN 'MES DONNÉES'
        WHEN user_id IS NULL THEN 'SANS UTILISATEUR'
        ELSE 'DONNÉES AUTRE UTILISATEUR'
    END as proprietaire
FROM public.services
ORDER BY created_at;

SELECT 
    'Données parts détaillées' as info,
    id,
    name,
    description,
    user_id,
    created_by,
    created_at,
    CASE 
        WHEN user_id = auth.uid() THEN 'MES DONNÉES'
        WHEN user_id IS NULL THEN 'SANS UTILISATEUR'
        ELSE 'DONNÉES AUTRE UTILISATEUR'
    END as proprietaire
FROM public.parts
ORDER BY created_at;

SELECT 
    'Données products détaillées' as info,
    id,
    name,
    description,
    user_id,
    created_by,
    created_at,
    CASE 
        WHEN user_id = auth.uid() THEN 'MES DONNÉES'
        WHEN user_id IS NULL THEN 'SANS UTILISATEUR'
        ELSE 'DONNÉES AUTRE UTILISATEUR'
    END as proprietaire
FROM public.products
ORDER BY created_at;

SELECT 
    'Données device_models détaillées' as info,
    id,
    brand,
    model,
    user_id,
    created_by,
    created_at,
    CASE 
        WHEN created_by = auth.uid() THEN 'MES DONNÉES'
        WHEN created_by IS NULL THEN 'SANS UTILISATEUR'
        ELSE 'DONNÉES AUTRE UTILISATEUR'
    END as proprietaire
FROM public.device_models
ORDER BY created_at;

-- 5. VÉRIFICATION RLS DÉTAILLÉE
SELECT '=== 5. VÉRIFICATION RLS DÉTAILLÉE ===' as section;

-- Statut RLS détaillé
SELECT 
    'Statut RLS détaillé' as info,
    schemaname,
    tablename,
    rowsecurity,
    CASE 
        WHEN rowsecurity THEN 'RLS ACTIVÉ'
        ELSE 'RLS DÉSACTIVÉ'
    END as status_rls
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('clients', 'devices', 'services', 'parts', 'products', 'device_models')
ORDER BY tablename;

-- Politiques RLS détaillées
SELECT 
    'Politiques RLS détaillées' as info,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check,
    CASE 
        WHEN cmd = 'SELECT' THEN 'LECTURE'
        WHEN cmd = 'INSERT' THEN 'INSERTION'
        WHEN cmd = 'UPDATE' THEN 'MODIFICATION'
        WHEN cmd = 'DELETE' THEN 'SUPPRESSION'
        ELSE 'AUTRE'
    END as type_operation
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('clients', 'devices', 'services', 'parts', 'products', 'device_models')
ORDER BY tablename, policyname;

-- 6. VÉRIFICATION TRIGGERS DÉTAILLÉE
SELECT '=== 6. VÉRIFICATION TRIGGERS DÉTAILLÉE ===' as section;

SELECT 
    'Triggers détaillés' as info,
    event_object_table,
    trigger_name,
    event_manipulation,
    action_statement,
    CASE 
        WHEN trigger_name LIKE '%radical%' THEN 'TRIGGER RADICAL'
        WHEN trigger_name LIKE '%user%' THEN 'TRIGGER ISOLATION'
        ELSE 'TRIGGER AUTRE'
    END as type_trigger
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN ('clients', 'devices', 'services', 'parts', 'products', 'device_models')
ORDER BY event_object_table, trigger_name;

-- 7. TEST D'ISOLATION ULTIME
SELECT '=== 7. TEST ISOLATION ULTIME ===' as section;

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
    total_services INTEGER;
    my_services INTEGER;
    other_services INTEGER;
    null_services INTEGER;
    total_parts INTEGER;
    my_parts INTEGER;
    other_parts INTEGER;
    null_parts INTEGER;
    total_products INTEGER;
    my_products INTEGER;
    other_products INTEGER;
    null_products INTEGER;
    total_models INTEGER;
    my_models INTEGER;
    other_models INTEGER;
    null_models INTEGER;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ AUCUN UTILISATEUR CONNECTÉ - Test impossible';
        RETURN;
    END IF;
    
    RAISE NOTICE '🔍 Test d''isolation ultime pour utilisateur: %', current_user_id;
    
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
    
    -- Test Services
    SELECT COUNT(*) INTO total_services FROM public.services;
    SELECT COUNT(*) INTO my_services FROM public.services WHERE user_id = current_user_id;
    SELECT COUNT(*) INTO other_services FROM public.services WHERE user_id != current_user_id AND user_id IS NOT NULL;
    SELECT COUNT(*) INTO null_services FROM public.services WHERE user_id IS NULL;
    
    RAISE NOTICE '📊 Services: %/% (moi/total) - Autres: % - Sans utilisateur: %', my_services, total_services, other_services, null_services;
    
    -- Test Parts
    SELECT COUNT(*) INTO total_parts FROM public.parts;
    SELECT COUNT(*) INTO my_parts FROM public.parts WHERE user_id = current_user_id;
    SELECT COUNT(*) INTO other_parts FROM public.parts WHERE user_id != current_user_id AND user_id IS NOT NULL;
    SELECT COUNT(*) INTO null_parts FROM public.parts WHERE user_id IS NULL;
    
    RAISE NOTICE '📊 Parts: %/% (moi/total) - Autres: % - Sans utilisateur: %', my_parts, total_parts, other_parts, null_parts;
    
    -- Test Products
    SELECT COUNT(*) INTO total_products FROM public.products;
    SELECT COUNT(*) INTO my_products FROM public.products WHERE user_id = current_user_id;
    SELECT COUNT(*) INTO other_products FROM public.products WHERE user_id != current_user_id AND user_id IS NOT NULL;
    SELECT COUNT(*) INTO null_products FROM public.products WHERE user_id IS NULL;
    
    RAISE NOTICE '📊 Products: %/% (moi/total) - Autres: % - Sans utilisateur: %', my_products, total_products, other_products, null_products;
    
    -- Test Device Models
    SELECT COUNT(*) INTO total_models FROM public.device_models;
    SELECT COUNT(*) INTO my_models FROM public.device_models WHERE created_by = current_user_id;
    SELECT COUNT(*) INTO other_models FROM public.device_models WHERE created_by != current_user_id AND created_by IS NOT NULL;
    SELECT COUNT(*) INTO null_models FROM public.device_models WHERE created_by IS NULL;
    
    RAISE NOTICE '📊 Device Models: %/% (moi/total) - Autres: % - Sans utilisateur: %', my_models, total_models, other_models, null_models;
    
    -- Analyse ultime
    IF other_clients > 0 OR other_devices > 0 OR other_services > 0 OR 
       other_parts > 0 OR other_products > 0 OR other_models > 0 THEN
        RAISE NOTICE '❌ PROBLÈME D''ISOLATION MAJEUR - Données d''autres utilisateurs visibles';
    ELSIF null_clients > 0 OR null_devices > 0 OR null_services > 0 OR 
          null_parts > 0 OR null_products > 0 OR null_models > 0 THEN
        RAISE NOTICE '⚠️ PROBLÈME D''ISOLATION - Données sans utilisateur assigné';
    ELSE
        RAISE NOTICE '✅ Isolation parfaite - Toutes les données appartiennent à l''utilisateur connecté';
    END IF;
END $$;

-- 8. TEST DE LECTURE DIRECTE ULTIME
SELECT '=== 8. TEST LECTURE DIRECTE ULTIME ===' as section;

-- Test de lecture directe pour chaque table avec analyse détaillée
SELECT 
    'Lecture directe clients ultime' as info,
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

SELECT 
    'Lecture directe devices ultime' as info,
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

SELECT 
    'Lecture directe services ultime' as info,
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
FROM public.services;

SELECT 
    'Lecture directe parts ultime' as info,
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
FROM public.parts;

SELECT 
    'Lecture directe products ultime' as info,
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
FROM public.products;

SELECT 
    'Lecture directe device_models ultime' as info,
    COUNT(*) as total,
    COUNT(CASE WHEN created_by = auth.uid() THEN 1 END) as mes_donnees,
    COUNT(CASE WHEN created_by != auth.uid() AND created_by IS NOT NULL THEN 1 END) as autres_donnees,
    COUNT(CASE WHEN created_by IS NULL THEN 1 END) as sans_utilisateur,
    CASE 
        WHEN COUNT(CASE WHEN created_by != auth.uid() AND created_by IS NOT NULL THEN 1 END) > 0 
        THEN 'PROBLÈME ISOLATION'
        WHEN COUNT(CASE WHEN created_by IS NULL THEN 1 END) > 0 
        THEN 'DONNÉES ORPHELINES'
        ELSE 'ISOLATION OK'
    END as status
FROM public.device_models;

-- 9. TEST D'INSERTION ULTIME
SELECT '=== 9. TEST INSERTION ULTIME ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    test_id UUID;
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
    VALUES ('Test Ultime', 'Diagnostic', 'test.ultime@example.com', '777777777')
    RETURNING id INTO test_id;
    
    RAISE NOTICE '✅ Client créé avec ID: %', test_id;
    
    -- Vérifier que le client appartient à l'utilisateur actuel
    SELECT user_id INTO test_user_id
    FROM public.clients 
    WHERE id = test_id;
    
    RAISE NOTICE '✅ Client créé par: %', test_user_id;
    
    IF test_user_id = current_user_id THEN
        RAISE NOTICE '✅ Isolation d''insertion OK';
    ELSE
        RAISE NOTICE '❌ PROBLÈME D''ISOLATION D''INSERTION';
    END IF;
    
    -- Nettoyer
    DELETE FROM public.clients WHERE id = test_id;
    RAISE NOTICE '🧹 Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test d''insertion: %', SQLERRM;
END $$;

-- 10. VÉRIFICATION CACHE POSTGREST ULTIME
SELECT '=== 10. VÉRIFICATION CACHE ULTIME ===' as section;

-- Rafraîchir le cache PostgREST
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(2);

-- 11. RÉSUMÉ DIAGNOSTIC ULTIME
SELECT '=== 11. RÉSUMÉ DIAGNOSTIC ULTIME ===' as section;

-- Résumé des données par table avec analyse
SELECT 
    'Résumé diagnostic ultime' as info,
    table_name,
    COUNT(*) as total_enregistrements,
    COUNT(CASE WHEN user_id = auth.uid() OR created_by = auth.uid() THEN 1 END) as mes_enregistrements,
    COUNT(CASE WHEN (user_id != auth.uid() AND user_id IS NOT NULL) OR (created_by != auth.uid() AND created_by IS NOT NULL) THEN 1 END) as autres_enregistrements,
    COUNT(CASE WHEN user_id IS NULL AND created_by IS NULL THEN 1 END) as sans_utilisateur,
    CASE 
        WHEN COUNT(CASE WHEN (user_id != auth.uid() AND user_id IS NOT NULL) OR (created_by != auth.uid() AND created_by IS NOT NULL) THEN 1 END) > 0 
        THEN 'PROBLÈME ISOLATION'
        WHEN COUNT(CASE WHEN user_id IS NULL AND created_by IS NULL THEN 1 END) > 0 
        THEN 'DONNÉES ORPHELINES'
        ELSE 'ISOLATION OK'
    END as status_isolation
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

SELECT 'DIAGNOSTIC ULTIME TERMINÉ' as status;
