-- =====================================================
-- DIAGNOSTIC ISOLATION CLIENTS PRÉCIS
-- =====================================================
-- Script pour diagnostiquer précisément pourquoi l'isolation des clients
-- ne fonctionne pas (RLS vs Code)
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier l'utilisateur actuel
SELECT '=== UTILISATEUR ACTUEL ===' as etape;
SELECT 
    auth.uid() as user_id,
    CASE 
        WHEN auth.uid() IS NOT NULL THEN '✅ Utilisateur connecté'
        ELSE '❌ Aucun utilisateur connecté'
    END as status;

-- 2. Test direct de l'isolation RLS
SELECT '=== TEST DIRECT RLS ===' as etape;

-- Test 1: Compter TOUS les clients (devrait être limité par RLS)
SELECT 
    'Test RLS - Tous les clients' as test,
    COUNT(*) as nombre_clients
FROM clients;

-- Test 2: Compter les clients de l'utilisateur actuel
SELECT 
    'Test RLS - Clients utilisateur' as test,
    COUNT(*) as nombre_clients
FROM clients 
WHERE user_id = auth.uid();

-- Test 3: Lister les clients visibles (devrait être limité par RLS)
SELECT 
    'Test RLS - Clients visibles' as test,
    id,
    first_name,
    last_name,
    email,
    user_id,
    CASE 
        WHEN user_id = auth.uid() THEN '✅ Mon client'
        WHEN user_id IS NULL THEN '⚠️ Sans user_id'
        ELSE '❌ Client d''un autre utilisateur'
    END as propriete
FROM clients 
ORDER BY created_at DESC
LIMIT 10;

-- 3. Vérifier l'état RLS de la table clients
SELECT '=== ÉTAT RLS TABLE CLIENTS ===' as etape;

SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status,
    CASE 
        WHEN rowsecurity THEN 'Sécurisé'
        ELSE '🚨 VULNÉRABLE - Données visibles par tous'
    END as securite
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename = 'clients';

-- 4. Vérifier les politiques RLS détaillées
SELECT '=== POLITIQUES RLS DÉTAILLÉES ===' as etape;

SELECT 
    policyname as nom_politique,
    cmd as commande,
    qual as condition,
    with_check as verification,
    CASE 
        WHEN qual LIKE '%user_id = auth.uid()%' THEN '✅ Isolation par user_id'
        WHEN qual LIKE '%auth.uid()%' THEN '⚠️ Utilise auth.uid() mais pas user_id'
        WHEN qual IS NULL THEN '❌ Aucune condition'
        ELSE '❌ Autre condition'
    END as type_isolation
FROM pg_policies 
WHERE tablename = 'clients'
ORDER BY policyname;

-- 5. Vérifier la structure de la table clients
SELECT '=== STRUCTURE TABLE CLIENTS ===' as etape;

SELECT 
    column_name as colonne,
    data_type as type,
    is_nullable as nullable,
    column_default as valeur_par_defaut
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name = 'clients'
ORDER BY ordinal_position;

-- 6. Test d'insertion pour vérifier l'isolation
SELECT '=== TEST D''INSERTION ===' as etape;

DO $$
DECLARE
    v_user_id UUID;
    v_test_client_id UUID;
    v_insert_success BOOLEAN := FALSE;
    v_select_success BOOLEAN := FALSE;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE NOTICE '❌ Aucun utilisateur connecté - test impossible';
        RETURN;
    END IF;
    
    RAISE NOTICE '✅ Test d''insertion pour l''utilisateur: %', v_user_id;
    
    -- Test 1: Insérer un client de test
    BEGIN
        INSERT INTO clients (
            first_name, last_name, email, phone, address, user_id
        ) VALUES (
            'Test', 'Isolation', 'test.isolation@example.com', '0123456789', '123 Test Street', v_user_id
        ) RETURNING id INTO v_test_client_id;
        
        v_insert_success := TRUE;
        RAISE NOTICE '✅ Insertion réussie - ID: %', v_test_client_id;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors de l''insertion: %', SQLERRM;
    END;
    
    -- Test 2: Vérifier que le client est visible
    IF v_test_client_id IS NOT NULL THEN
        BEGIN
            IF EXISTS (
                SELECT 1 FROM clients 
                WHERE id = v_test_client_id AND user_id = v_user_id
            ) THEN
                v_select_success := TRUE;
                RAISE NOTICE '✅ Client visible après insertion';
            ELSE
                RAISE NOTICE '❌ Client non visible après insertion';
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Erreur lors de la vérification: %', SQLERRM;
        END;
        
        -- Nettoyer le test
        DELETE FROM clients WHERE id = v_test_client_id;
        RAISE NOTICE '✅ Test nettoyé';
    END IF;
    
    -- Résumé du test
    RAISE NOTICE '📊 Résumé du test:';
    RAISE NOTICE '  - Insertion: %', CASE WHEN v_insert_success THEN 'OK' ELSE 'ÉCHEC' END;
    RAISE NOTICE '  - Sélection: %', CASE WHEN v_select_success THEN 'OK' ELSE 'ÉCHEC' END;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 7. Vérifier les données par utilisateur
SELECT '=== DONNÉES PAR UTILISATEUR ===' as etape;

SELECT 
    user_id,
    COUNT(*) as nombre_clients,
    CASE 
        WHEN user_id = auth.uid() THEN '✅ Mes clients'
        WHEN user_id IS NULL THEN '⚠️ Sans user_id'
        ELSE '❌ Clients d''autres utilisateurs'
    END as propriete
FROM clients 
GROUP BY user_id
ORDER BY nombre_clients DESC;

-- 8. Test de contournement RLS (simulation d'un utilisateur non authentifié)
SELECT '=== TEST CONTOURNEMENT RLS ===' as etape;

-- Ce test simule ce qui se passe quand l'application ne passe pas l'utilisateur
DO $$
DECLARE
    v_count_without_auth INTEGER;
    v_count_with_auth INTEGER;
BEGIN
    -- Compter sans authentification (simulation)
    SELECT COUNT(*) INTO v_count_without_auth FROM clients;
    
    -- Compter avec authentification
    SELECT COUNT(*) INTO v_count_with_auth FROM clients WHERE user_id = auth.uid();
    
    RAISE NOTICE '📊 Test de contournement:';
    RAISE NOTICE '  - Clients visibles sans auth: %', v_count_without_auth;
    RAISE NOTICE '  - Clients visibles avec auth: %', v_count_with_auth;
    
    IF v_count_without_auth = v_count_with_auth THEN
        RAISE NOTICE '  ✅ RLS fonctionne correctement';
    ELSE
        RAISE NOTICE '  ❌ PROBLÈME: RLS ne filtre pas correctement';
        RAISE NOTICE '  💡 Différence: % clients supplémentaires visibles', v_count_without_auth - v_count_with_auth;
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test de contournement: %', SQLERRM;
END $$;

-- 9. Vérifier les triggers
SELECT '=== TRIGGERS ===' as etape;

SELECT 
    trigger_name as nom_trigger,
    event_manipulation as evenement,
    action_timing as moment,
    action_statement as action
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table = 'clients'
ORDER BY trigger_name;

-- 10. Recommandations spécifiques
SELECT '=== RECOMMANDATIONS SPÉCIFIQUES ===' as etape;

DO $$
DECLARE
    v_rls_enabled BOOLEAN;
    v_policy_count INTEGER;
    v_user_id_column_exists BOOLEAN;
    v_data_without_user_id INTEGER;
    v_total_clients INTEGER;
    v_user_clients INTEGER;
BEGIN
    -- Vérifications
    SELECT rowsecurity INTO v_rls_enabled FROM pg_tables WHERE schemaname = 'public' AND tablename = 'clients';
    SELECT COUNT(*) INTO v_policy_count FROM pg_policies WHERE tablename = 'clients';
    SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'clients' AND column_name = 'user_id') INTO v_user_id_column_exists;
    SELECT COUNT(*) INTO v_data_without_user_id FROM clients WHERE user_id IS NULL;
    SELECT COUNT(*) INTO v_total_clients FROM clients;
    SELECT COUNT(*) INTO v_user_clients FROM clients WHERE user_id = auth.uid();
    
    RAISE NOTICE '📋 État actuel:';
    RAISE NOTICE '  - RLS activé: %', CASE WHEN v_rls_enabled THEN 'Oui' ELSE 'Non' END;
    RAISE NOTICE '  - Politiques: %', v_policy_count;
    RAISE NOTICE '  - Colonne user_id: %', CASE WHEN v_user_id_column_exists THEN 'Oui' ELSE 'Non' END;
    RAISE NOTICE '  - Données sans user_id: %', v_data_without_user_id;
    RAISE NOTICE '  - Total clients: %', v_total_clients;
    RAISE NOTICE '  - Mes clients: %', v_user_clients;
    
    RAISE NOTICE '';
    RAISE NOTICE '🔧 Actions selon le problème:';
    
    IF NOT v_rls_enabled THEN
        RAISE NOTICE '  🚨 URGENT: Activer RLS';
        RAISE NOTICE '     ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;';
    END IF;
    
    IF v_policy_count = 0 THEN
        RAISE NOTICE '  🚨 URGENT: Créer des politiques RLS';
        RAISE NOTICE '     CREATE POLICY "clients_select_policy" ON public.clients FOR SELECT USING (user_id = auth.uid());';
    END IF;
    
    IF v_data_without_user_id > 0 THEN
        RAISE NOTICE '  ⚠️ Mettre à jour les données sans user_id';
        RAISE NOTICE '     UPDATE clients SET user_id = auth.uid() WHERE user_id IS NULL;';
    END IF;
    
    IF v_total_clients != v_user_clients THEN
        RAISE NOTICE '  ❌ PROBLÈME: Vous voyez des clients d''autres utilisateurs';
        RAISE NOTICE '  💡 Vérifiez le code de l''application (services)';
    END IF;
    
    IF v_rls_enabled AND v_policy_count > 0 AND v_user_id_column_exists AND v_data_without_user_id = 0 AND v_total_clients = v_user_clients THEN
        RAISE NOTICE '  ✅ Configuration RLS correcte';
        RAISE NOTICE '  💡 Le problème vient probablement du code de l''application';
    END IF;
    
END $$;
