-- 🧪 TEST RAPIDE - ISOLATION DES CLIENTS
-- Script pour tester rapidement l'isolation des données
-- Date: 2025-01-23

-- ============================================================================
-- 1. TEST RAPIDE DE L'ISOLATION
-- ============================================================================

SELECT '🧪 TEST RAPIDE ISOLATION CLIENTS' as test_section;

-- Vérifier l'utilisateur connecté
DO $$
DECLARE
    current_user_id UUID;
    current_user_email TEXT;
BEGIN
    SELECT auth.uid() INTO current_user_id;
    
    IF current_user_id IS NOT NULL THEN
        SELECT email INTO current_user_email FROM auth.users WHERE id = current_user_id;
        RAISE NOTICE '👤 Utilisateur connecté: % (%s)', current_user_email, current_user_id;
    ELSE
        RAISE NOTICE '❌ Aucun utilisateur connecté';
    END IF;
END $$;

-- Test 1: Compter les clients visibles
SELECT 
    '📊 TEST 1: CLIENTS VISIBLES' as test,
    COUNT(*) as total_clients_visibles,
    COUNT(CASE WHEN user_id = auth.uid() THEN 1 END) as clients_utilisateur_connecte,
    COUNT(CASE WHEN user_id != auth.uid() THEN 1 END) as clients_autres_utilisateurs,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as clients_sans_user_id
FROM public.clients;

-- Test 2: Vérifier l'isolation parfaite
DO $$
DECLARE
    current_user_id UUID;
    total_clients INTEGER;
    user_clients INTEGER;
    isolation_perfect BOOLEAN := TRUE;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Test impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    -- Compter tous les clients visibles
    SELECT COUNT(*) INTO total_clients FROM public.clients;
    
    -- Compter les clients de l'utilisateur connecté
    SELECT COUNT(*) INTO user_clients FROM public.clients WHERE user_id = current_user_id;
    
    RAISE NOTICE '📊 Résultats: % clients visibles, % clients pour l''utilisateur connecté', total_clients, user_clients;
    
    -- Test d'isolation parfaite
    IF total_clients != user_clients THEN
        RAISE NOTICE '❌ ÉCHEC: L''utilisateur peut voir des clients d''autres utilisateurs';
        isolation_perfect := FALSE;
    ELSE
        RAISE NOTICE '✅ SUCCÈS: L''utilisateur ne voit que ses propres clients';
    END IF;
    
    -- Vérifier s'il y a des clients d'autres utilisateurs
    IF EXISTS (SELECT 1 FROM public.clients WHERE user_id != current_user_id) THEN
        RAISE NOTICE '❌ ÉCHEC: Il existe des clients appartenant à d''autres utilisateurs';
        isolation_perfect := FALSE;
    ELSE
        RAISE NOTICE '✅ SUCCÈS: Aucun client d''autre utilisateur visible';
    END IF;
    
    -- Vérifier s'il y a des clients sans user_id
    IF EXISTS (SELECT 1 FROM public.clients WHERE user_id IS NULL) THEN
        RAISE NOTICE '❌ ÉCHEC: Il existe des clients sans user_id';
        isolation_perfect := FALSE;
    ELSE
        RAISE NOTICE '✅ SUCCÈS: Aucun client sans user_id';
    END IF;
    
    IF isolation_perfect THEN
        RAISE NOTICE '🎉 ISOLATION PARFAITE: Tous les tests sont réussis';
    ELSE
        RAISE NOTICE '⚠️ ISOLATION IMPARFAITE: Certains tests ont échoué';
    END IF;
END $$;

-- ============================================================================
-- 2. TEST DES FONCTIONS RPC
-- ============================================================================

SELECT '🧪 TEST 2: FONCTIONS RPC' as test_section;

-- Test de la fonction get_isolated_clients
SELECT 
    'Test get_isolated_clients()' as test,
    json_array_length(get_isolated_clients()) as nombre_clients_via_rpc;

-- Test de création d'un client via RPC
SELECT 
    'Test create_isolated_client()' as test,
    create_isolated_client(
        'Test Rapide', 
        'Isolation', 
        'test.rapide.' || extract(epoch from now())::TEXT || '@example.com',
        '1111111111',
        'Adresse test rapide',
        'Note test rapide'
    ) as resultat_creation;

-- ============================================================================
-- 3. VÉRIFICATION DES POLITIQUES RLS
-- ============================================================================

SELECT '🧪 TEST 3: POLITIQUES RLS' as test_section;

-- Vérifier les politiques RLS actives
SELECT 
    'Politiques RLS actives' as info,
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'clients'
    AND policyname LIKE '%STRICT_ISOLATION%'
ORDER BY policyname;

-- Vérifier le statut RLS
SELECT 
    'Statut RLS' as info,
    rowsecurity as rls_active,
    CASE 
        WHEN rowsecurity THEN '✅ RLS ACTIVÉ'
        ELSE '❌ RLS DÉSACTIVÉ'
    END as statut
FROM pg_tables 
WHERE tablename = 'clients';

-- ============================================================================
-- 4. RÉSULTAT FINAL
-- ============================================================================

SELECT '🎯 RÉSULTAT FINAL' as test_section;

-- Résumé final
SELECT 
    'Résumé du test d''isolation' as info,
    (SELECT COUNT(*) FROM public.clients) as total_clients,
    (SELECT COUNT(*) FROM public.clients WHERE user_id = auth.uid()) as clients_utilisateur_connecte,
    (SELECT json_array_length(get_isolated_clients())) as clients_via_rpc,
    (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'clients' AND policyname LIKE '%STRICT_ISOLATION%') as politiques_rls_creees,
    CASE 
        WHEN (SELECT COUNT(*) FROM public.clients) = (SELECT COUNT(*) FROM public.clients WHERE user_id = auth.uid())
        THEN '✅ ISOLATION PARFAITE'
        ELSE '❌ PROBLÈME D''ISOLATION'
    END as status_isolation;

-- Message final
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM public.clients) = (SELECT COUNT(*) FROM public.clients WHERE user_id = auth.uid())
        THEN '🎉 SUCCÈS: L''isolation des clients fonctionne parfaitement !'
        ELSE '⚠️ ATTENTION: Il y a encore des problèmes d''isolation'
    END as message_final;
