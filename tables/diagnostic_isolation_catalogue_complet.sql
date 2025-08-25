-- =====================================================
-- DIAGNOSTIC COMPLET ISOLATION CATALOGUE
-- =====================================================
-- Objectif: Diagnostiquer pourquoi l'isolation ne fonctionne pas dans le catalogue
-- Date: 2025-01-23
-- =====================================================

-- 1. DIAGNOSTIC UTILISATEUR
SELECT '=== DIAGNOSTIC UTILISATEUR ===' as section;

-- Vérifier l'utilisateur actuel
SELECT 
    'Utilisateur actuel' as info,
    auth.uid() as user_id,
    (SELECT email FROM auth.users WHERE id = auth.uid()) as email;

-- Vérifier tous les utilisateurs
SELECT 
    'Tous les utilisateurs' as info,
    id,
    email,
    created_at
FROM auth.users
ORDER BY created_at;

-- 2. DIAGNOSTIC STRUCTURE TABLES CATALOGUE
SELECT '=== DIAGNOSTIC STRUCTURE ===' as section;

-- Vérifier la structure de toutes les tables du catalogue
SELECT 
    'Structure tables catalogue' as info,
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name IN ('clients', 'devices', 'services', 'parts', 'products', 'device_models')
ORDER BY table_name, ordinal_position;

-- 3. DIAGNOSTIC DONNÉES ACTUELLES
SELECT '=== DIAGNOSTIC DONNÉES ===' as section;

-- Vérifier toutes les données du catalogue par utilisateur
SELECT 
    'Données catalogue par utilisateur' as info,
    table_name,
    user_id,
    created_by,
    COUNT(*) as nombre_enregistrements,
    MIN(created_at) as premier_enregistrement,
    MAX(created_at) as dernier_enregistrement
FROM (
    SELECT 'clients' as table_name, user_id, created_by, created_at FROM public.clients
    UNION ALL
    SELECT 'devices', user_id, created_by, created_at FROM public.devices
    UNION ALL
    SELECT 'services', user_id, created_by, created_at FROM public.services
    UNION ALL
    SELECT 'parts', user_id, created_by, created_at FROM public.parts
    UNION ALL
    SELECT 'products', user_id, created_by, created_at FROM public.products
    UNION ALL
    SELECT 'device_models', user_id, created_by, created_at FROM public.device_models
) t
GROUP BY table_name, user_id, created_by
ORDER BY table_name, user_id;

-- 4. DIAGNOSTIC RLS
SELECT '=== DIAGNOSTIC RLS ===' as section;

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

-- Vérifier les politiques RLS
SELECT 
    'Politiques RLS catalogue' as info,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('clients', 'devices', 'services', 'parts', 'products', 'device_models')
ORDER BY tablename, policyname;

-- 5. DIAGNOSTIC TRIGGERS
SELECT '=== DIAGNOSTIC TRIGGERS ===' as section;

-- Vérifier les triggers
SELECT 
    'Triggers catalogue' as info,
    event_object_table,
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN ('clients', 'devices', 'services', 'parts', 'products', 'device_models')
ORDER BY event_object_table, trigger_name;

-- 6. TEST D'ISOLATION COMPLET
SELECT '=== TEST ISOLATION COMPLET ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    total_records INTEGER;
    user_records INTEGER;
    isolation_check BOOLEAN := TRUE;
    table_name TEXT;
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
        EXECUTE format('SELECT COUNT(*) FROM public.%I WHERE user_id = $1 OR created_by = $1', table_name) 
        USING current_user_id INTO user_records;
        
        IF total_records != user_records THEN
            RAISE NOTICE '❌ Problème d''isolation dans %: %/%', table_name, user_records, total_records;
            isolation_check := FALSE;
        ELSE
            RAISE NOTICE '✅ Isolation OK dans %: %/%', table_name, user_records, total_records;
        END IF;
    END LOOP;
    
    IF isolation_check THEN
        RAISE NOTICE '✅ Test d''isolation réussi - Toutes les données appartiennent à l''utilisateur connecté';
    ELSE
        RAISE NOTICE '❌ Test d''isolation échoué - Problèmes détectés';
    END IF;
END $$;

-- 7. TEST DE LECTURE DIRECTE
SELECT '=== TEST LECTURE DIRECTE ===' as section;

-- Test de lecture directe pour chaque table
SELECT 
    'Lecture directe clients' as info,
    COUNT(*) as nombre_clients
FROM public.clients 
WHERE user_id = auth.uid();

SELECT 
    'Lecture directe devices' as info,
    COUNT(*) as nombre_devices
FROM public.devices 
WHERE user_id = auth.uid();

SELECT 
    'Lecture directe services' as info,
    COUNT(*) as nombre_services
FROM public.services 
WHERE user_id = auth.uid();

SELECT 
    'Lecture directe parts' as info,
    COUNT(*) as nombre_parts
FROM public.parts 
WHERE user_id = auth.uid();

SELECT 
    'Lecture directe products' as info,
    COUNT(*) as nombre_products
FROM public.products 
WHERE user_id = auth.uid();

SELECT 
    'Lecture directe device_models' as info,
    COUNT(*) as nombre_device_models
FROM public.device_models 
WHERE created_by = auth.uid();

-- 8. TEST D'INSERTION
SELECT '=== TEST INSERTION ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    test_id UUID;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '⚠️ Test d''insertion impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Test d''insertion pour utilisateur: %', current_user_id;
    
    -- Test d'insertion dans clients
    INSERT INTO public.clients (first_name, last_name, email, phone)
    VALUES ('Test Diagnostic', 'Catalogue', 'test.diagnostic@example.com', '123456789')
    RETURNING id INTO test_id;
    
    RAISE NOTICE 'Client créé avec ID: %', test_id;
    
    -- Vérifier que le client appartient à l'utilisateur actuel
    SELECT user_id INTO current_user_id
    FROM public.clients 
    WHERE id = test_id;
    
    RAISE NOTICE 'Client créé par: %', current_user_id;
    
    -- Nettoyer
    DELETE FROM public.clients WHERE id = test_id;
    RAISE NOTICE 'Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test d''insertion: %', SQLERRM;
END $$;

-- 9. VÉRIFICATION CACHE POSTGREST
SELECT '=== VÉRIFICATION CACHE ===' as section;

-- Rafraîchir le cache PostgREST
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(2);

-- 10. RÉSUMÉ DIAGNOSTIC
SELECT '=== RÉSUMÉ DIAGNOSTIC ===' as section;

-- Résumé des données par table
SELECT 
    'Résumé catalogue' as info,
    table_name,
    COUNT(*) as total_enregistrements,
    COUNT(CASE WHEN user_id = auth.uid() OR created_by = auth.uid() THEN 1 END) as mes_enregistrements,
    COUNT(CASE WHEN user_id != auth.uid() AND created_by != auth.uid() THEN 1 END) as autres_enregistrements
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

SELECT 'DIAGNOSTIC CATALOGUE TERMINÉ' as status;
