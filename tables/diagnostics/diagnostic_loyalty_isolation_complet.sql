-- =====================================================
-- DIAGNOSTIC COMPLET ISOLATION POINTS DE FIDÉLITÉ
-- =====================================================
-- Script pour diagnostiquer pourquoi l'isolation
-- des points de fidélité ne fonctionne toujours pas
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier l'existence des tables de fidélité
SELECT '=== EXISTENCE DES TABLES FIDÉLITÉ ===' as etape;

SELECT 
    table_name as table_cible,
    CASE 
        WHEN table_name IS NOT NULL THEN '✅ Table existe'
        ELSE '❌ Table manquante'
    END as statut
FROM information_schema.tables 
WHERE table_schema = 'public'
AND table_name IN ('loyalty_points_history', 'loyalty_tiers_advanced', 'referrals', 'client_loyalty_points')
ORDER BY table_name;

-- 2. Vérifier la structure complète des tables
SELECT '=== STRUCTURE COMPLÈTE DES TABLES ===' as etape;

SELECT 
    table_name as table_cible,
    column_name as colonne,
    data_type as type,
    is_nullable as nullable,
    column_default as valeur_par_defaut,
    CASE 
        WHEN column_name = 'workshop_id' THEN '🎯 Colonne d''isolation'
        WHEN column_name LIKE '%client%' THEN '🔗 Colonne client'
        WHEN column_name LIKE '%user%' THEN '👤 Colonne utilisateur'
        ELSE '📋 Autre colonne'
    END as type_colonne
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name IN ('loyalty_points_history', 'loyalty_tiers_advanced', 'referrals', 'client_loyalty_points')
ORDER BY table_name, ordinal_position;

-- 3. Vérifier l'état RLS des tables
SELECT '=== ÉTAT RLS DES TABLES ===' as etape;

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
AND tablename IN ('loyalty_points_history', 'loyalty_tiers_advanced', 'referrals', 'client_loyalty_points')
ORDER BY tablename;

-- 4. Lister toutes les politiques RLS existantes
SELECT '=== POLITIQUES RLS EXISTANTES ===' as etape;

SELECT 
    tablename,
    policyname as nom_politique,
    cmd as commande,
    qual as condition,
    with_check as verification,
    CASE 
        WHEN qual LIKE '%workshop_id = auth.uid()%' AND qual LIKE '%auth.uid() IS NOT NULL%' THEN '✅ Ultra-strict'
        WHEN qual LIKE '%workshop_id = auth.uid()%' THEN '⚠️ Standard'
        WHEN qual LIKE '%auth.uid()%' THEN '⚠️ Utilise auth.uid() mais pas workshop_id'
        WHEN qual IS NULL THEN '❌ Aucune condition'
        ELSE '❌ Autre condition'
    END as type_isolation
FROM pg_policies 
WHERE tablename IN ('loyalty_points_history', 'loyalty_tiers_advanced', 'referrals', 'client_loyalty_points')
ORDER BY tablename, policyname;

-- 5. Vérifier les triggers sur les tables
SELECT '=== TRIGGERS SUR LES TABLES ===' as etape;

SELECT 
    trigger_name as nom_trigger,
    event_object_table as table_cible,
    event_manipulation as evenement,
    action_timing as moment,
    action_statement as action
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
AND event_object_table IN ('loyalty_points_history', 'loyalty_tiers_advanced', 'referrals', 'client_loyalty_points')
ORDER BY event_object_table, trigger_name;

-- 6. Test d'isolation avec utilisateur actuel
SELECT '=== TEST ISOLATION UTILISATEUR ACTUEL ===' as etape;

DO $$
DECLARE
    v_user_id UUID;
    v_table_name TEXT;
    v_count_without_filter INTEGER;
    v_count_with_filter INTEGER;
    v_other_users_count INTEGER;
    v_orphan_count INTEGER;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE NOTICE '❌ Aucun utilisateur connecté - test impossible';
        RETURN;
    END IF;
    
    RAISE NOTICE '✅ Test d''isolation pour l''utilisateur: %', v_user_id;
    
    -- Tester chaque table de fidélité
    FOR v_table_name IN 
        SELECT unnest(ARRAY['loyalty_points_history', 'loyalty_tiers_advanced', 'referrals', 'client_loyalty_points'])
    LOOP
        RAISE NOTICE '';
        RAISE NOTICE '🔍 Test de la table: %', v_table_name;
        
        -- Test 1: Compter tous les enregistrements (devrait être limité par RLS)
        EXECUTE format('SELECT COUNT(*) FROM %I', v_table_name) INTO v_count_without_filter;
        RAISE NOTICE '  📊 Enregistrements visibles sans filtrage: %', v_count_without_filter;
        
        -- Test 2: Compter les enregistrements avec filtrage workshop_id
        EXECUTE format('SELECT COUNT(*) FROM %I WHERE workshop_id = $1', v_table_name) USING v_user_id INTO v_count_with_filter;
        RAISE NOTICE '  📊 Mes enregistrements (avec filtrage): %', v_count_with_filter;
        
        -- Test 3: Compter les enregistrements d'autres utilisateurs
        EXECUTE format('SELECT COUNT(*) FROM %I WHERE workshop_id != $1', v_table_name) USING v_user_id INTO v_other_users_count;
        RAISE NOTICE '  📊 Enregistrements d''autres utilisateurs: %', v_other_users_count;
        
        -- Test 4: Compter les enregistrements orphelins
        EXECUTE format('SELECT COUNT(*) FROM %I WHERE workshop_id IS NULL', v_table_name) INTO v_orphan_count;
        RAISE NOTICE '  📊 Enregistrements orphelins: %', v_orphan_count;
        
        -- Analyse
        IF v_other_users_count > 0 THEN
            RAISE NOTICE '  ❌ PROBLÈME: Vous pouvez voir des enregistrements d''autres utilisateurs';
        ELSE
            RAISE NOTICE '  ✅ Isolation correcte: seuls vos enregistrements sont visibles';
        END IF;
        
        IF v_orphan_count > 0 THEN
            RAISE NOTICE '  ⚠️ ATTENTION: % enregistrements orphelins (sans workshop_id)', v_orphan_count;
        END IF;
        
        IF v_count_without_filter = v_count_with_filter THEN
            RAISE NOTICE '  ✅ RLS fonctionne: même nombre avec et sans filtrage';
        ELSE
            RAISE NOTICE '  ⚠️ RLS ne filtre pas: différence entre avec et sans filtrage';
        END IF;
    END LOOP;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 7. Vérifier les données par utilisateur dans chaque table
SELECT '=== DONNÉES PAR UTILISATEUR - LOYALTY_POINTS_HISTORY ===' as etape;

SELECT 
    workshop_id,
    COUNT(*) as nombre_enregistrements,
    CASE 
        WHEN workshop_id = auth.uid() THEN '✅ Mes enregistrements'
        WHEN workshop_id IS NULL THEN '⚠️ Sans workshop_id'
        ELSE '❌ Enregistrements d''autres utilisateurs'
    END as propriete
FROM loyalty_points_history 
GROUP BY workshop_id
ORDER BY nombre_enregistrements DESC;

SELECT '=== DONNÉES PAR UTILISATEUR - LOYALTY_TIERS_ADVANCED ===' as etape;

SELECT 
    workshop_id,
    COUNT(*) as nombre_enregistrements,
    CASE 
        WHEN workshop_id = auth.uid() THEN '✅ Mes enregistrements'
        WHEN workshop_id IS NULL THEN '⚠️ Sans workshop_id'
        ELSE '❌ Enregistrements d''autres utilisateurs'
    END as propriete
FROM loyalty_tiers_advanced 
GROUP BY workshop_id
ORDER BY nombre_enregistrements DESC;

SELECT '=== DONNÉES PAR UTILISATEUR - REFERRALS ===' as etape;

SELECT 
    workshop_id,
    COUNT(*) as nombre_enregistrements,
    CASE 
        WHEN workshop_id = auth.uid() THEN '✅ Mes enregistrements'
        WHEN workshop_id IS NULL THEN '⚠️ Sans workshop_id'
        ELSE '❌ Enregistrements d''autres utilisateurs'
    END as propriete
FROM referrals 
GROUP BY workshop_id
ORDER BY nombre_enregistrements DESC;

SELECT '=== DONNÉES PAR UTILISATEUR - CLIENT_LOYALTY_POINTS ===' as etape;

SELECT 
    workshop_id,
    COUNT(*) as nombre_enregistrements,
    CASE 
        WHEN workshop_id = auth.uid() THEN '✅ Mes enregistrements'
        WHEN workshop_id IS NULL THEN '⚠️ Sans workshop_id'
        ELSE '❌ Enregistrements d''autres utilisateurs'
    END as propriete
FROM client_loyalty_points 
GROUP BY workshop_id
ORDER BY nombre_enregistrements DESC;

-- 8. Vérifier les contraintes de clés étrangères
SELECT '=== CONTRAINTES CLÉS ÉTRANGÈRES ===' as etape;

SELECT 
    tc.table_name as table_cible,
    kcu.column_name as colonne_cible,
    ccu.table_name AS table_source,
    ccu.column_name AS colonne_source,
    tc.constraint_name as nom_contrainte
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name IN ('loyalty_points_history', 'loyalty_tiers_advanced', 'referrals', 'client_loyalty_points')
ORDER BY tc.table_name, kcu.column_name;

-- 9. Test de simulation d'insertion
SELECT '=== TEST SIMULATION INSERTION ===' as etape;

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
        RAISE NOTICE '❌ Aucun utilisateur connecté - test d''insertion impossible';
        RETURN;
    END IF;
    
    RAISE NOTICE '🧪 Test d''insertion pour l''utilisateur: %', v_user_id;
    
    -- Créer un client de test
    BEGIN
        INSERT INTO clients (
            first_name, last_name, email, phone, address, user_id
        ) VALUES (
            'Test', 'LoyaltyIsolation', 'test.loyalty.isolation@example.com', '0123456789', '123 Test Street', v_user_id
        ) RETURNING id INTO v_test_client_id;
        
        RAISE NOTICE '✅ Client de test créé - ID: %', v_test_client_id;
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors de la création du client: %', SQLERRM;
        RETURN;
    END;
    
    -- Test d'insertion dans loyalty_points_history
    BEGIN
        INSERT INTO loyalty_points_history (
            client_id, points_change, description, type
        ) VALUES (
            v_test_client_id, 100, 'Test d''isolation', 'earned'
        );
        
        v_insert_success := TRUE;
        RAISE NOTICE '✅ Point de fidélité inséré avec succès';
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors de l''insertion du point: %', SQLERRM;
    END;
    
    -- Test de sélection
    IF v_insert_success THEN
        BEGIN
            IF EXISTS (
                SELECT 1 FROM loyalty_points_history 
                WHERE client_id = v_test_client_id 
                AND workshop_id = v_user_id
            ) THEN
                v_select_success := TRUE;
                RAISE NOTICE '✅ Point de fidélité visible après insertion';
            ELSE
                RAISE NOTICE '❌ Point de fidélité non visible après insertion';
            END IF;
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Erreur lors de la vérification: %', SQLERRM;
        END;
    END IF;
    
    -- Nettoyer le test
    IF v_test_client_id IS NOT NULL THEN
        DELETE FROM loyalty_points_history WHERE client_id = v_test_client_id;
        DELETE FROM clients WHERE id = v_test_client_id;
        RAISE NOTICE '✅ Test nettoyé';
    END IF;
    
    -- Résumé du test
    RAISE NOTICE '📊 Résumé du test d''insertion:';
    RAISE NOTICE '  - Insertion: %', CASE WHEN v_insert_success THEN 'OK' ELSE 'ÉCHEC' END;
    RAISE NOTICE '  - Sélection: %', CASE WHEN v_select_success THEN 'OK' ELSE 'ÉCHEC' END;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test d''insertion: %', SQLERRM;
END $$;

-- 10. Recommandations finales
SELECT '=== RECOMMANDATIONS FINALES ===' as etape;

DO $$
DECLARE
    v_table_count INTEGER;
    v_rls_enabled_count INTEGER;
    v_policy_count INTEGER;
    v_workshop_id_column_count INTEGER;
    v_orphan_data_count INTEGER;
    v_other_users_data_count INTEGER;
    v_trigger_count INTEGER;
BEGIN
    -- Compter les tables existantes
    SELECT COUNT(*) INTO v_table_count
    FROM information_schema.tables 
    WHERE table_schema = 'public'
    AND table_name IN ('loyalty_points_history', 'loyalty_tiers_advanced', 'referrals', 'client_loyalty_points');
    
    -- Compter les tables avec RLS activé
    SELECT COUNT(*) INTO v_rls_enabled_count
    FROM pg_tables 
    WHERE schemaname = 'public'
    AND tablename IN ('loyalty_points_history', 'loyalty_tiers_advanced', 'referrals', 'client_loyalty_points')
    AND rowsecurity = true;
    
    -- Compter les politiques
    SELECT COUNT(*) INTO v_policy_count
    FROM pg_policies 
    WHERE tablename IN ('loyalty_points_history', 'loyalty_tiers_advanced', 'referrals', 'client_loyalty_points');
    
    -- Compter les colonnes workshop_id
    SELECT COUNT(*) INTO v_workshop_id_column_count
    FROM information_schema.columns 
    WHERE table_schema = 'public'
    AND table_name IN ('loyalty_points_history', 'loyalty_tiers_advanced', 'referrals', 'client_loyalty_points')
    AND column_name = 'workshop_id';
    
    -- Compter les données orphelines
    SELECT 
        (SELECT COUNT(*) FROM loyalty_points_history WHERE workshop_id IS NULL) +
        (SELECT COUNT(*) FROM loyalty_tiers_advanced WHERE workshop_id IS NULL) +
        (SELECT COUNT(*) FROM referrals WHERE workshop_id IS NULL) +
        (SELECT COUNT(*) FROM client_loyalty_points WHERE workshop_id IS NULL)
    INTO v_orphan_data_count;
    
    -- Compter les données d'autres utilisateurs
    SELECT 
        (SELECT COUNT(*) FROM loyalty_points_history WHERE workshop_id != auth.uid() AND workshop_id IS NOT NULL) +
        (SELECT COUNT(*) FROM loyalty_tiers_advanced WHERE workshop_id != auth.uid() AND workshop_id IS NOT NULL) +
        (SELECT COUNT(*) FROM referrals WHERE workshop_id != auth.uid() AND workshop_id IS NOT NULL) +
        (SELECT COUNT(*) FROM client_loyalty_points WHERE workshop_id != auth.uid() AND workshop_id IS NOT NULL)
    INTO v_other_users_data_count;
    
    -- Compter les triggers
    SELECT COUNT(*) INTO v_trigger_count
    FROM information_schema.triggers 
    WHERE event_object_schema = 'public'
    AND event_object_table IN ('loyalty_points_history', 'loyalty_tiers_advanced', 'referrals', 'client_loyalty_points');
    
    RAISE NOTICE '📊 État complet des tables de fidélité:';
    RAISE NOTICE '  - Tables existantes: %/4', v_table_count;
    RAISE NOTICE '  - Tables avec RLS activé: %/4', v_rls_enabled_count;
    RAISE NOTICE '  - Politiques: %', v_policy_count;
    RAISE NOTICE '  - Colonnes workshop_id: %/4', v_workshop_id_column_count;
    RAISE NOTICE '  - Triggers: %', v_trigger_count;
    RAISE NOTICE '  - Données orphelines: %', v_orphan_data_count;
    RAISE NOTICE '  - Données autres utilisateurs: %', v_other_users_data_count;
    
    RAISE NOTICE '';
    RAISE NOTICE '🔧 Actions selon le problème:';
    
    IF v_table_count < 4 THEN
        RAISE NOTICE '  🚨 URGENT: Certaines tables de fidélité sont manquantes';
        RAISE NOTICE '     Vérifier la création des tables dans le schéma';
    END IF;
    
    IF v_workshop_id_column_count < 4 THEN
        RAISE NOTICE '  🚨 URGENT: Colonnes workshop_id manquantes';
        RAISE NOTICE '     Exécuter: correction_isolation_loyalty_complete.sql';
    END IF;
    
    IF v_rls_enabled_count < 4 THEN
        RAISE NOTICE '  🚨 URGENT: RLS non activé sur toutes les tables';
        RAISE NOTICE '     Exécuter: correction_isolation_loyalty_complete.sql';
    END IF;
    
    IF v_policy_count = 0 THEN
        RAISE NOTICE '  🚨 URGENT: Aucune politique RLS';
        RAISE NOTICE '     Exécuter: correction_isolation_loyalty_complete.sql';
    END IF;
    
    IF v_trigger_count < 4 THEN
        RAISE NOTICE '  🚨 URGENT: Triggers manquants';
        RAISE NOTICE '     Exécuter: correction_isolation_loyalty_complete.sql';
    END IF;
    
    IF v_orphan_data_count > 0 THEN
        RAISE NOTICE '  ⚠️ Données orphelines détectées';
        RAISE NOTICE '     Exécuter: correction_isolation_loyalty_complete.sql';
    END IF;
    
    IF v_other_users_data_count > 0 THEN
        RAISE NOTICE '  🚨 CRITIQUE: Données d''autres utilisateurs visibles';
        RAISE NOTICE '     Exécuter: correction_isolation_loyalty_complete.sql';
        RAISE NOTICE '     Vérifier que RLS fonctionne correctement';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '🎯 Solution complète:';
    RAISE NOTICE '  1. Exécuter: correction_isolation_loyalty_complete.sql';
    RAISE NOTICE '  2. Vérifier que toutes les tables ont RLS activé';
    RAISE NOTICE '  3. Vérifier que toutes les politiques sont créées';
    RAISE NOTICE '  4. Vérifier que tous les triggers sont créés';
    RAISE NOTICE '  5. Tester l''isolation avec différents utilisateurs';
    RAISE NOTICE '  6. Redéployer l''application';
    
END $$;
