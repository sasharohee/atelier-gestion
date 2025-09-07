-- =====================================================
-- DIAGNOSTIC AVANT CORRECTION POINTS DE FIDÉLITÉ
-- =====================================================
-- Script pour vérifier l'état des tables de fidélité
-- avant d'appliquer la correction d'isolation
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

-- 2. Vérifier la structure des tables existantes
SELECT '=== STRUCTURE DES TABLES EXISTANTES ===' as etape;

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

-- 3. Vérifier l'état RLS des tables existantes
SELECT '=== ÉTAT RLS DES TABLES ===' as etape;

SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename IN ('loyalty_points_history', 'loyalty_tiers_advanced', 'referrals', 'client_loyalty_points')
ORDER BY tablename;

-- 4. Vérifier les politiques existantes
SELECT '=== POLITIQUES EXISTANTES ===' as etape;

SELECT 
    tablename,
    policyname as nom_politique,
    cmd as commande
FROM pg_policies 
WHERE tablename IN ('loyalty_points_history', 'loyalty_tiers_advanced', 'referrals', 'client_loyalty_points')
ORDER BY tablename, policyname;

-- 5. Vérifier les contraintes de clés étrangères
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

-- 6. Compter les enregistrements dans chaque table
SELECT '=== NOMBRE D''ENREGISTREMENTS ===' as etape;

-- Compter les enregistrements dans loyalty_points_history
SELECT 
    'loyalty_points_history' as table_name,
    COUNT(*) as nombre_enregistrements
FROM loyalty_points_history

UNION ALL

-- Compter les enregistrements dans loyalty_tiers_advanced
SELECT 
    'loyalty_tiers_advanced' as table_name,
    COUNT(*) as nombre_enregistrements
FROM loyalty_tiers_advanced

UNION ALL

-- Compter les enregistrements dans referrals
SELECT 
    'referrals' as table_name,
    COUNT(*) as nombre_enregistrements
FROM referrals

UNION ALL

-- Compter les enregistrements dans client_loyalty_points
SELECT 
    'client_loyalty_points' as table_name,
    COUNT(*) as nombre_enregistrements
FROM client_loyalty_points;

-- 7. Vérifier les données orphelines (si les colonnes existent)
SELECT '=== VÉRIFICATION DONNÉES ORPHELINES ===' as etape;

-- Vérifier les données orphelines dans loyalty_points_history
SELECT 
    'loyalty_points_history' as table_name,
    'client_id NULL' as type_probleme,
    COUNT(*) as nombre
FROM loyalty_points_history 
WHERE client_id IS NULL

UNION ALL

SELECT 
    'loyalty_points_history' as table_name,
    'client_id orphelin' as type_probleme,
    COUNT(*) as nombre
FROM loyalty_points_history 
WHERE client_id IS NOT NULL 
AND client_id NOT IN (SELECT id FROM clients)

UNION ALL

-- Vérifier les données orphelines dans referrals
SELECT 
    'referrals' as table_name,
    'referrer_client_id NULL' as type_probleme,
    COUNT(*) as nombre
FROM referrals 
WHERE referrer_client_id IS NULL

UNION ALL

SELECT 
    'referrals' as table_name,
    'referred_client_id NULL' as type_probleme,
    COUNT(*) as nombre
FROM referrals 
WHERE referred_client_id IS NULL

UNION ALL

SELECT 
    'referrals' as table_name,
    'referrer_client_id orphelin' as type_probleme,
    COUNT(*) as nombre
FROM referrals 
WHERE referrer_client_id IS NOT NULL 
AND referrer_client_id NOT IN (SELECT id FROM clients)

UNION ALL

SELECT 
    'referrals' as table_name,
    'referred_client_id orphelin' as type_probleme,
    COUNT(*) as nombre
FROM referrals 
WHERE referred_client_id IS NOT NULL 
AND referred_client_id NOT IN (SELECT id FROM clients)

UNION ALL

-- Vérifier les données orphelines dans client_loyalty_points
SELECT 
    'client_loyalty_points' as table_name,
    'client_id NULL' as type_probleme,
    COUNT(*) as nombre
FROM client_loyalty_points 
WHERE client_id IS NULL

UNION ALL

SELECT 
    'client_loyalty_points' as table_name,
    'client_id orphelin' as type_probleme,
    COUNT(*) as nombre
FROM client_loyalty_points 
WHERE client_id IS NOT NULL 
AND client_id NOT IN (SELECT id FROM clients);

-- 8. Résumé et recommandations
SELECT '=== RÉSUMÉ ET RECOMMANDATIONS ===' as etape;

DO $$
DECLARE
    v_table_count INTEGER;
    v_rls_enabled_count INTEGER;
    v_policy_count INTEGER;
    v_workshop_id_column_count INTEGER;
    v_orphan_data_count INTEGER;
    v_total_records INTEGER;
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
        (SELECT COUNT(*) FROM loyalty_points_history WHERE client_id IS NULL OR client_id NOT IN (SELECT id FROM clients)) +
        (SELECT COUNT(*) FROM referrals WHERE referrer_client_id IS NULL OR referred_client_id IS NULL OR referrer_client_id NOT IN (SELECT id FROM clients) OR referred_client_id NOT IN (SELECT id FROM clients)) +
        (SELECT COUNT(*) FROM client_loyalty_points WHERE client_id IS NULL OR client_id NOT IN (SELECT id FROM clients))
    INTO v_orphan_data_count;
    
    -- Compter le total des enregistrements
    SELECT 
        (SELECT COUNT(*) FROM loyalty_points_history) +
        (SELECT COUNT(*) FROM loyalty_tiers_advanced) +
        (SELECT COUNT(*) FROM referrals) +
        (SELECT COUNT(*) FROM client_loyalty_points)
    INTO v_total_records;
    
    RAISE NOTICE '📊 État des tables de fidélité:';
    RAISE NOTICE '  - Tables existantes: %/4', v_table_count;
    RAISE NOTICE '  - Tables avec RLS activé: %/4', v_rls_enabled_count;
    RAISE NOTICE '  - Politiques: %', v_policy_count;
    RAISE NOTICE '  - Colonnes workshop_id: %/4', v_workshop_id_column_count;
    RAISE NOTICE '  - Données orphelines: %', v_orphan_data_count;
    RAISE NOTICE '  - Total enregistrements: %', v_total_records;
    
    RAISE NOTICE '';
    RAISE NOTICE '🔧 Actions recommandées:';
    
    IF v_table_count < 4 THEN
        RAISE NOTICE '  ⚠️ Certaines tables de fidélité sont manquantes';
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
    
    IF v_orphan_data_count > 0 THEN
        RAISE NOTICE '  ⚠️ Données orphelines détectées';
        RAISE NOTICE '     Exécuter: correction_isolation_loyalty_complete.sql';
    END IF;
    
    RAISE NOTICE '';
    RAISE NOTICE '🎯 Prochaines étapes:';
    RAISE NOTICE '  1. Exécuter: diagnostic_isolation_loyalty.sql';
    RAISE NOTICE '  2. Exécuter: correction_isolation_loyalty_complete.sql';
    RAISE NOTICE '  3. Vérifier l''isolation avec différents utilisateurs';
    RAISE NOTICE '  4. Redéployer l''application';
    
END $$;
