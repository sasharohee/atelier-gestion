-- =====================================================
-- DIAGNOSTIC ISOLATION POINTS DE FIDÉLITÉ
-- =====================================================
-- Script pour diagnostiquer les problèmes d'isolation
-- dans les tables liées aux points de fidélité
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier l'état RLS des tables de fidélité
SELECT '=== ÉTAT RLS TABLES FIDÉLITÉ ===' as etape;

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

-- 2. Lister toutes les politiques existantes sur les tables de fidélité
SELECT '=== POLITIQUES EXISTANTES FIDÉLITÉ ===' as etape;

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

-- 3. Vérifier la structure des tables de fidélité
SELECT '=== STRUCTURE TABLES FIDÉLITÉ ===' as etape;

SELECT 
    table_name as table_cible,
    column_name as colonne,
    data_type as type,
    is_nullable as nullable,
    column_default as valeur_par_defaut
FROM information_schema.columns 
WHERE table_schema = 'public'
AND table_name IN ('loyalty_points_history', 'loyalty_tiers_advanced', 'referrals', 'client_loyalty_points')
ORDER BY table_name, ordinal_position;

-- 4. Vérifier les triggers sur les tables de fidélité
SELECT '=== TRIGGERS FIDÉLITÉ ===' as etape;

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

-- 5. Test d'isolation actuel pour les points de fidélité
SELECT '=== TEST ISOLATION POINTS FIDÉLITÉ ===' as etape;

DO $$
DECLARE
    v_user_id UUID;
    v_count_without_filter INTEGER;
    v_count_with_filter INTEGER;
    v_other_users_count INTEGER;
    v_table_name TEXT;
    v_count INTEGER;
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
        
        -- Test 2: Compter les enregistrements avec filtrage
        EXECUTE format('SELECT COUNT(*) FROM %I WHERE workshop_id = $1', v_table_name) USING v_user_id INTO v_count_with_filter;
        RAISE NOTICE '  📊 Mes enregistrements (avec filtrage): %', v_count_with_filter;
        
        -- Test 3: Compter les enregistrements d'autres utilisateurs
        EXECUTE format('SELECT COUNT(*) FROM %I WHERE workshop_id != $1', v_table_name) USING v_user_id INTO v_other_users_count;
        RAISE NOTICE '  📊 Enregistrements d''autres utilisateurs: %', v_other_users_count;
        
        -- Analyse
        IF v_other_users_count > 0 THEN
            RAISE NOTICE '  ❌ PROBLÈME: Vous pouvez voir des enregistrements d''autres utilisateurs';
        ELSE
            RAISE NOTICE '  ✅ Isolation correcte: seuls vos enregistrements sont visibles';
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

-- 6. Vérifier les données par utilisateur dans les tables de fidélité
SELECT '=== DONNÉES PAR UTILISATEUR FIDÉLITÉ ===' as etape;

-- loyalty_points_history
SELECT 
    'loyalty_points_history' as table_name,
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

-- loyalty_tiers_advanced
SELECT 
    'loyalty_tiers_advanced' as table_name,
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

-- referrals
SELECT 
    'referrals' as table_name,
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

-- client_loyalty_points
SELECT 
    'client_loyalty_points' as table_name,
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

-- 7. Vérifier les données orphelines
SELECT '=== VÉRIFICATION DONNÉES ORPHELINES ===' as etape;

-- Chercher des enregistrements sans workshop_id
SELECT 
    'loyalty_points_history sans workshop_id' as type_probleme,
    COUNT(*) as nombre
FROM loyalty_points_history 
WHERE workshop_id IS NULL

UNION ALL

SELECT 
    'loyalty_tiers_advanced sans workshop_id' as type_probleme,
    COUNT(*) as nombre
FROM loyalty_tiers_advanced 
WHERE workshop_id IS NULL

UNION ALL

SELECT 
    'referrals sans workshop_id' as type_probleme,
    COUNT(*) as nombre
FROM referrals 
WHERE workshop_id IS NULL

UNION ALL

SELECT 
    'client_loyalty_points sans workshop_id' as type_probleme,
    COUNT(*) as nombre
FROM client_loyalty_points 
WHERE workshop_id IS NULL;

-- 8. Recommandations spécifiques
SELECT '=== RECOMMANDATIONS SPÉCIFIQUES ===' as etape;

DO $$
DECLARE
    v_rls_enabled_count INTEGER;
    v_policy_count INTEGER;
    v_workshop_id_column_count INTEGER;
    v_orphan_data_count INTEGER;
    v_total_records INTEGER;
    v_user_records INTEGER;
    v_other_records INTEGER;
    v_table_name TEXT;
BEGIN
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
    
    RAISE NOTICE '📊 État des tables de fidélité:';
    RAISE NOTICE '  - Tables avec RLS activé: %/4', v_rls_enabled_count;
    RAISE NOTICE '  - Politiques: %', v_policy_count;
    RAISE NOTICE '  - Colonnes workshop_id: %/4', v_workshop_id_column_count;
    RAISE NOTICE '  - Données orphelines: %', v_orphan_data_count;
    
    RAISE NOTICE '';
    RAISE NOTICE '🔧 Actions selon le problème:';
    
    IF v_rls_enabled_count < 4 THEN
        RAISE NOTICE '  🚨 URGENT: Activer RLS sur toutes les tables de fidélité';
        RAISE NOTICE '     Exécuter: correction_isolation_loyalty_complete.sql';
    END IF;
    
    IF v_policy_count = 0 THEN
        RAISE NOTICE '  🚨 URGENT: Créer des politiques RLS';
        RAISE NOTICE '     Exécuter: correction_isolation_loyalty_complete.sql';
    END IF;
    
    IF v_workshop_id_column_count < 4 THEN
        RAISE NOTICE '  🚨 URGENT: Ajouter les colonnes workshop_id';
        RAISE NOTICE '     Exécuter: correction_isolation_loyalty_complete.sql';
    END IF;
    
    IF v_orphan_data_count > 0 THEN
        RAISE NOTICE '  ⚠️ Nettoyer les données orphelines';
        RAISE NOTICE '     Exécuter: correction_isolation_loyalty_complete.sql';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '🎯 Solution complète:';
    RAISE NOTICE '  1. Exécuter correction_isolation_loyalty_complete.sql';
    RAISE NOTICE '  2. Vérifier que toutes les tables ont RLS activé';
    RAISE NOTICE '  3. Vérifier que toutes les politiques sont créées';
    RAISE NOTICE '  4. Tester l''isolation avec différents utilisateurs';
    RAISE NOTICE '  5. Redéployer l''application';
    
END $$;
