-- =====================================================
-- DIAGNOSTIC ÉTAT RLS CLIENTS
-- =====================================================
-- Script pour diagnostiquer l'état actuel du RLS
-- sur la table clients avant correction
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier l'état RLS de la table
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

-- 2. Lister toutes les politiques existantes
SELECT '=== POLITIQUES EXISTANTES ===' as etape;

SELECT 
    policyname as nom_politique,
    cmd as commande,
    qual as condition,
    with_check as verification,
    CASE 
        WHEN qual LIKE '%user_id = auth.uid()%' AND qual LIKE '%auth.uid() IS NOT NULL%' THEN '✅ Ultra-strict'
        WHEN qual LIKE '%user_id = auth.uid()%' THEN '⚠️ Standard'
        WHEN qual LIKE '%auth.uid()%' THEN '⚠️ Utilise auth.uid() mais pas user_id'
        WHEN qual IS NULL THEN '❌ Aucune condition'
        ELSE '❌ Autre condition'
    END as type_isolation
FROM pg_policies 
WHERE tablename = 'clients'
ORDER BY policyname;

-- 3. Vérifier la structure de la table
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

-- 4. Vérifier les triggers
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

-- 5. Test d'isolation actuel
SELECT '=== TEST ISOLATION ACTUEL ===' as etape;

DO $$
DECLARE
    v_user_id UUID;
    v_count_without_filter INTEGER;
    v_count_with_filter INTEGER;
    v_other_users_count INTEGER;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE NOTICE '❌ Aucun utilisateur connecté - test impossible';
        RETURN;
    END IF;
    
    RAISE NOTICE '✅ Test d''isolation pour l''utilisateur: %', v_user_id;
    
    -- Test 1: Compter tous les clients (devrait être limité par RLS)
    SELECT COUNT(*) INTO v_count_without_filter FROM clients;
    RAISE NOTICE '📊 Clients visibles sans filtrage: %', v_count_without_filter;
    
    -- Test 2: Compter les clients avec filtrage
    SELECT COUNT(*) INTO v_count_with_filter FROM clients WHERE user_id = v_user_id;
    RAISE NOTICE '📊 Mes clients (avec filtrage): %', v_count_with_filter;
    
    -- Test 3: Compter les clients d'autres utilisateurs
    SELECT COUNT(*) INTO v_other_users_count FROM clients WHERE user_id != v_user_id;
    RAISE NOTICE '📊 Clients d''autres utilisateurs: %', v_other_users_count;
    
    -- Analyse
    IF v_other_users_count > 0 THEN
        RAISE NOTICE '❌ PROBLÈME: Vous pouvez voir des clients d''autres utilisateurs';
        RAISE NOTICE '🔧 Action requise: Appliquer la correction RLS ultra-strict';
    ELSE
        RAISE NOTICE '✅ Isolation correcte: seuls vos clients sont visibles';
    END IF;
    
    IF v_count_without_filter = v_count_with_filter THEN
        RAISE NOTICE '✅ RLS fonctionne: même nombre avec et sans filtrage';
    ELSE
        RAISE NOTICE '⚠️ RLS ne filtre pas: différence entre avec et sans filtrage';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 6. Vérifier les données par utilisateur
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

-- 7. Recommandations
SELECT '=== RECOMMANDATIONS ===' as etape;

DO $$
DECLARE
    v_rls_enabled BOOLEAN;
    v_policy_count INTEGER;
    v_user_id_column_exists BOOLEAN;
    v_data_without_user_id INTEGER;
    v_total_clients INTEGER;
    v_user_clients INTEGER;
    v_other_clients INTEGER;
BEGIN
    -- Vérifications
    SELECT rowsecurity INTO v_rls_enabled FROM pg_tables WHERE schemaname = 'public' AND tablename = 'clients';
    SELECT COUNT(*) INTO v_policy_count FROM pg_policies WHERE tablename = 'clients';
    SELECT EXISTS(SELECT 1 FROM information_schema.columns WHERE table_schema = 'public' AND table_name = 'clients' AND column_name = 'user_id') INTO v_user_id_column_exists;
    SELECT COUNT(*) INTO v_data_without_user_id FROM clients WHERE user_id IS NULL;
    SELECT COUNT(*) INTO v_total_clients FROM clients;
    SELECT COUNT(*) INTO v_user_clients FROM clients WHERE user_id = auth.uid();
    SELECT COUNT(*) INTO v_other_clients FROM clients WHERE user_id != auth.uid();
    
    RAISE NOTICE '📋 État actuel:';
    RAISE NOTICE '  - RLS activé: %', CASE WHEN v_rls_enabled THEN 'Oui' ELSE 'Non' END;
    RAISE NOTICE '  - Politiques: %', v_policy_count;
    RAISE NOTICE '  - Colonne user_id: %', CASE WHEN v_user_id_column_exists THEN 'Oui' ELSE 'Non' END;
    RAISE NOTICE '  - Données sans user_id: %', v_data_without_user_id;
    RAISE NOTICE '  - Total clients: %', v_total_clients;
    RAISE NOTICE '  - Mes clients: %', v_user_clients;
    RAISE NOTICE '  - Clients d''autres utilisateurs: %', v_other_clients;
    
    RAISE NOTICE '';
    RAISE NOTICE '🔧 Actions selon le problème:';
    
    IF NOT v_rls_enabled THEN
        RAISE NOTICE '  🚨 URGENT: Activer RLS';
        RAISE NOTICE '     ALTER TABLE public.clients ENABLE ROW LEVEL SECURITY;';
    END IF;
    
    IF v_policy_count = 0 THEN
        RAISE NOTICE '  🚨 URGENT: Créer des politiques RLS';
        RAISE NOTICE '     Exécuter: correction_rls_clients_ultra_strict_v2.sql';
    END IF;
    
    IF v_data_without_user_id > 0 THEN
        RAISE NOTICE '  ⚠️ Mettre à jour les données sans user_id';
        RAISE NOTICE '     UPDATE clients SET user_id = auth.uid() WHERE user_id IS NULL;';
    END IF;
    
    IF v_other_clients > 0 THEN
        RAISE NOTICE '  ❌ PROBLÈME: Vous voyez des clients d''autres utilisateurs';
        RAISE NOTICE '  🔧 Solution: Exécuter correction_rls_clients_ultra_strict_v2.sql';
    END IF;
    
    IF v_rls_enabled AND v_policy_count > 0 AND v_user_id_column_exists AND v_data_without_user_id = 0 AND v_other_clients = 0 THEN
        RAISE NOTICE '  ✅ Configuration RLS correcte';
        RAISE NOTICE '  💡 Le problème vient probablement du code de l''application';
    END IF;
    
END $$;
