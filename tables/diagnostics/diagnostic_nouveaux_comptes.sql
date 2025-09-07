-- =====================================================
-- DIAGNOSTIC NOUVEAUX COMPTES RÉPARATEURS
-- =====================================================
-- Script pour diagnostiquer les problèmes d'isolation
-- spécifiques aux nouveaux comptes de réparateurs
-- Date: 2025-01-23
-- =====================================================

-- 1. Analyser les utilisateurs et leurs données
SELECT '=== ANALYSE UTILISATEURS ET DONNÉES ===' as etape;

-- Compter les utilisateurs par date de création
SELECT 
    DATE(created_at) as date_creation,
    COUNT(*) as nombre_utilisateurs,
    CASE 
        WHEN DATE(created_at) >= CURRENT_DATE - INTERVAL '7 days' THEN '🆕 Nouveaux (7 derniers jours)'
        WHEN DATE(created_at) >= CURRENT_DATE - INTERVAL '30 days' THEN '📅 Récents (30 derniers jours)'
        ELSE '📜 Anciens'
    END as categorie
FROM auth.users 
GROUP BY DATE(created_at)
ORDER BY date_creation DESC;

-- 2. Analyser les clients par utilisateur
SELECT '=== ANALYSE CLIENTS PAR UTILISATEUR ===' as etape;

SELECT 
    u.email,
    u.created_at as date_creation_compte,
    COUNT(c.id) as nombre_clients,
    CASE 
        WHEN u.created_at >= CURRENT_DATE - INTERVAL '7 days' THEN '🆕 Nouveau compte'
        WHEN u.created_at >= CURRENT_DATE - INTERVAL '30 days' THEN '📅 Compte récent'
        ELSE '📜 Ancien compte'
    END as type_compte,
    CASE 
        WHEN COUNT(c.id) = 0 THEN '⚠️ Aucun client'
        WHEN COUNT(c.id) > 0 AND COUNT(c.id) <= 5 THEN '✅ Peu de clients'
        ELSE '📊 Beaucoup de clients'
    END as statut_clients
FROM auth.users u
LEFT JOIN clients c ON c.user_id = u.id
GROUP BY u.id, u.email, u.created_at
ORDER BY u.created_at DESC;

-- 3. Vérifier l'isolation pour les nouveaux comptes
SELECT '=== VÉRIFICATION ISOLATION NOUVEAUX COMPTES ===' as etape;

DO $$
DECLARE
    v_new_user_id UUID;
    v_new_user_email TEXT;
    v_total_clients INTEGER;
    v_user_clients INTEGER;
    v_other_clients INTEGER;
    v_new_users_count INTEGER;
BEGIN
    -- Compter les nouveaux utilisateurs (7 derniers jours)
    SELECT COUNT(*) INTO v_new_users_count 
    FROM auth.users 
    WHERE created_at >= CURRENT_DATE - INTERVAL '7 days';
    
    RAISE NOTICE '📊 Nouveaux utilisateurs (7 derniers jours): %', v_new_users_count;
    
    -- Analyser chaque nouveau utilisateur
    FOR v_new_user_id, v_new_user_email IN 
        SELECT id, email 
        FROM auth.users 
        WHERE created_at >= CURRENT_DATE - INTERVAL '7 days'
        ORDER BY created_at DESC
    LOOP
        RAISE NOTICE '';
        RAISE NOTICE '🔍 Analyse pour: %', v_new_user_email;
        
        -- Simuler la connexion de cet utilisateur
        PERFORM set_config('request.jwt.claims', '{"sub":"' || v_new_user_id || '"}', true);
        
        -- Compter les clients visibles
        SELECT COUNT(*) INTO v_total_clients FROM clients;
        SELECT COUNT(*) INTO v_user_clients FROM clients WHERE user_id = v_new_user_id;
        SELECT COUNT(*) INTO v_other_clients FROM clients WHERE user_id != v_new_user_id;
        
        RAISE NOTICE '  - Total clients visibles: %', v_total_clients;
        RAISE NOTICE '  - Ses clients: %', v_user_clients;
        RAISE NOTICE '  - Clients d''autres: %', v_other_clients;
        
        IF v_other_clients > 0 THEN
            RAISE NOTICE '  ❌ PROBLÈME: Peut voir des clients d''autres utilisateurs';
        ELSE
            RAISE NOTICE '  ✅ Isolation correcte';
        END IF;
        
        -- Réinitialiser le contexte
        PERFORM set_config('request.jwt.claims', NULL, true);
    END LOOP;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors de l''analyse: %', SQLERRM;
    PERFORM set_config('request.jwt.claims', NULL, true);
END $$;

-- 4. Vérifier les données de démonstration
SELECT '=== VÉRIFICATION DONNÉES DÉMONSTRATION ===' as etape;

-- Chercher des clients sans user_id ou avec user_id par défaut
SELECT 
    'Clients sans user_id' as type_probleme,
    COUNT(*) as nombre
FROM clients 
WHERE user_id IS NULL

UNION ALL

SELECT 
    'Clients avec user_id par défaut' as type_probleme,
    COUNT(*) as nombre
FROM clients 
WHERE user_id = '00000000-0000-0000-0000-000000000000'::UUID

UNION ALL

SELECT 
    'Clients avec user_id invalide' as type_probleme,
    COUNT(*) as nombre
FROM clients 
WHERE user_id NOT IN (SELECT id FROM auth.users) AND user_id IS NOT NULL;

-- 5. Analyser les clients par date de création
SELECT '=== ANALYSE CLIENTS PAR DATE CRÉATION ===' as etape;

SELECT 
    DATE(c.created_at) as date_creation_client,
    COUNT(*) as nombre_clients,
    COUNT(DISTINCT c.user_id) as nombre_utilisateurs_differents,
    CASE 
        WHEN DATE(c.created_at) >= CURRENT_DATE - INTERVAL '7 days' THEN '🆕 Nouveaux clients'
        WHEN DATE(c.created_at) >= CURRENT_DATE - INTERVAL '30 days' THEN '📅 Clients récents'
        ELSE '📜 Anciens clients'
    END as categorie
FROM clients c
GROUP BY DATE(c.created_at)
ORDER BY date_creation_client DESC;

-- 6. Vérifier les triggers et fonctions
SELECT '=== VÉRIFICATION TRIGGERS ET FONCTIONS ===' as etape;

-- Vérifier les triggers
SELECT 
    trigger_name,
    event_object_table,
    action_statement,
    CASE 
        WHEN action_statement LIKE '%set_client_user_id%' THEN '✅ Trigger user_id'
        ELSE '⚠️ Autre trigger'
    END as type_trigger
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table = 'clients'
ORDER BY trigger_name;

-- Vérifier les fonctions
SELECT 
    routine_name,
    routine_type,
    CASE 
        WHEN routine_name LIKE '%client%user%' THEN '✅ Fonction client/user'
        ELSE '⚠️ Autre fonction'
    END as type_fonction
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name LIKE '%client%'
ORDER BY routine_name;

-- 7. Test de création pour un nouveau compte
SELECT '=== TEST CRÉATION NOUVEAU COMPTE ===' as etape;

DO $$
DECLARE
    v_test_user_id UUID;
    v_test_client_id UUID;
    v_insert_success BOOLEAN := FALSE;
    v_select_success BOOLEAN := FALSE;
BEGIN
    -- Créer un utilisateur de test
    v_test_user_id := gen_random_uuid();
    
    RAISE NOTICE '🧪 Test avec utilisateur fictif: %', v_test_user_id;
    
    -- Simuler la connexion de cet utilisateur
    PERFORM set_config('request.jwt.claims', '{"sub":"' || v_test_user_id || '"}', true);
    
    -- Test d'insertion
    BEGIN
        INSERT INTO clients (
            first_name, last_name, email, phone, address, user_id
        ) VALUES (
            'Test', 'NouveauCompte', 'test.nouveau@example.com', '0123456789', '123 Test Street', v_test_user_id
        ) RETURNING id INTO v_test_client_id;
        
        v_insert_success := TRUE;
        RAISE NOTICE '✅ Insertion réussie - ID: %', v_test_client_id;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors de l''insertion: %', SQLERRM;
    END;
    
    -- Test de sélection
    IF v_test_client_id IS NOT NULL THEN
        BEGIN
            IF EXISTS (
                SELECT 1 FROM clients 
                WHERE id = v_test_client_id AND user_id = v_test_user_id
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
    
    -- Réinitialiser le contexte
    PERFORM set_config('request.jwt.claims', NULL, true);
    
    -- Résumé
    RAISE NOTICE '📊 Résumé du test:';
    RAISE NOTICE '  - Insertion: %', CASE WHEN v_insert_success THEN 'OK' ELSE 'ÉCHEC' END;
    RAISE NOTICE '  - Sélection: %', CASE WHEN v_select_success THEN 'OK' ELSE 'ÉCHEC' END;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
    PERFORM set_config('request.jwt.claims', NULL, true);
END $$;

-- 8. Recommandations spécifiques
SELECT '=== RECOMMANDATIONS SPÉCIFIQUES ===' as etape;

DO $$
DECLARE
    v_new_users_count INTEGER;
    v_problematic_clients INTEGER;
    v_missing_triggers INTEGER;
BEGIN
    -- Compter les nouveaux utilisateurs
    SELECT COUNT(*) INTO v_new_users_count 
    FROM auth.users 
    WHERE created_at >= CURRENT_DATE - INTERVAL '7 days';
    
    -- Compter les clients problématiques
    SELECT COUNT(*) INTO v_problematic_clients 
    FROM clients 
    WHERE user_id IS NULL OR user_id = '00000000-0000-0000-0000-000000000000'::UUID;
    
    -- Vérifier les triggers manquants
    SELECT COUNT(*) INTO v_missing_triggers 
    FROM information_schema.triggers 
    WHERE event_object_schema = 'public'
    AND event_object_table = 'clients'
    AND action_statement LIKE '%set_client_user_id%';
    
    RAISE NOTICE '📋 État des nouveaux comptes:';
    RAISE NOTICE '  - Nouveaux utilisateurs (7 jours): %', v_new_users_count;
    RAISE NOTICE '  - Clients problématiques: %', v_problematic_clients;
    RAISE NOTICE '  - Triggers user_id: %', v_missing_triggers;
    
    RAISE NOTICE '';
    RAISE NOTICE '🔧 Actions recommandées:';
    
    IF v_problematic_clients > 0 THEN
        RAISE NOTICE '  🚨 URGENT: Nettoyer les clients sans user_id valide';
        RAISE NOTICE '     DELETE FROM clients WHERE user_id IS NULL OR user_id = ''00000000-0000-0000-0000-000000000000'';';
    END IF;
    
    IF v_missing_triggers = 0 THEN
        RAISE NOTICE '  🚨 URGENT: Créer les triggers pour user_id automatique';
        RAISE NOTICE '     Exécuter: correction_rls_clients_ultra_strict_v2.sql';
    END IF;
    
    IF v_new_users_count > 0 THEN
        RAISE NOTICE '  💡 Vérifier l''initialisation des nouveaux comptes';
        RAISE NOTICE '     S''assurer que les nouveaux utilisateurs ont des données isolées';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '🎯 Solution complète:';
    RAISE NOTICE '  1. Exécuter correction_rls_clients_ultra_strict_v2.sql';
    RAISE NOTICE '  2. Nettoyer les données problématiques';
    RAISE NOTICE '  3. Tester avec un nouveau compte';
    RAISE NOTICE '  4. Redéployer l''application';
    
END $$;
