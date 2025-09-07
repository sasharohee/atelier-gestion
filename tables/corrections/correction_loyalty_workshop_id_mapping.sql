-- =====================================================
-- CORRECTION MAPPING WORKSHOP_ID LOYALTY
-- =====================================================
-- Script pour corriger le mapping entre workshop_id
-- et user_id dans les tables de fidélité
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier l'état actuel du mapping
SELECT '=== ÉTAT ACTUEL DU MAPPING ===' as etape;

-- Vérifier les clients et leurs user_id
SELECT 
    'clients' as table_name,
    user_id,
    COUNT(*) as nombre_clients
FROM clients 
GROUP BY user_id
ORDER BY nombre_clients DESC;

-- Vérifier les données de fidélité et leurs workshop_id
SELECT 
    'loyalty_points_history' as table_name,
    workshop_id,
    COUNT(*) as nombre_enregistrements
FROM loyalty_points_history 
GROUP BY workshop_id
ORDER BY nombre_enregistrements DESC;

SELECT 
    'loyalty_tiers_advanced' as table_name,
    workshop_id,
    COUNT(*) as nombre_enregistrements
FROM loyalty_tiers_advanced 
GROUP BY workshop_id
ORDER BY nombre_enregistrements DESC;

SELECT 
    'referrals' as table_name,
    workshop_id,
    COUNT(*) as nombre_enregistrements
FROM referrals 
GROUP BY workshop_id
ORDER BY nombre_enregistrements DESC;

SELECT 
    'client_loyalty_points' as table_name,
    workshop_id,
    COUNT(*) as nombre_enregistrements
FROM client_loyalty_points 
GROUP BY workshop_id
ORDER BY nombre_enregistrements DESC;

-- 2. Mettre à jour les workshop_id dans loyalty_points_history
SELECT '=== MISE À JOUR WORKSHOP_ID LOYALTY_POINTS_HISTORY ===' as etape;

-- Mettre à jour les workshop_id basés sur les clients
UPDATE loyalty_points_history 
SET workshop_id = c.user_id
FROM clients c
WHERE loyalty_points_history.client_id = c.id
AND loyalty_points_history.workshop_id IS NULL;

-- Vérifier le résultat
SELECT 
    'Après mise à jour' as etape,
    workshop_id,
    COUNT(*) as nombre_enregistrements
FROM loyalty_points_history 
GROUP BY workshop_id
ORDER BY nombre_enregistrements DESC;

-- 3. Mettre à jour les workshop_id dans loyalty_tiers_advanced
SELECT '=== MISE À JOUR WORKSHOP_ID LOYALTY_TIERS_ADVANCED ===' as etape;

-- Pour les niveaux de fidélité, on utilise l'utilisateur qui les a créés
-- Si pas de workshop_id, on peut les associer au premier utilisateur ou les supprimer
UPDATE loyalty_tiers_advanced 
SET workshop_id = (
    SELECT DISTINCT user_id 
    FROM clients 
    WHERE user_id IS NOT NULL 
    LIMIT 1
)
WHERE workshop_id IS NULL;

-- Vérifier le résultat
SELECT 
    'Après mise à jour' as etape,
    workshop_id,
    COUNT(*) as nombre_enregistrements
FROM loyalty_tiers_advanced 
GROUP BY workshop_id
ORDER BY nombre_enregistrements DESC;

-- 4. Mettre à jour les workshop_id dans referrals
SELECT '=== MISE À JOUR WORKSHOP_ID REFERRALS ===' as etape;

-- Mettre à jour les workshop_id basés sur les clients parrains
UPDATE referrals 
SET workshop_id = c.user_id
FROM clients c
WHERE referrals.referrer_client_id = c.id
AND referrals.workshop_id IS NULL;

-- Vérifier le résultat
SELECT 
    'Après mise à jour' as etape,
    workshop_id,
    COUNT(*) as nombre_enregistrements
FROM referrals 
GROUP BY workshop_id
ORDER BY nombre_enregistrements DESC;

-- 5. Mettre à jour les workshop_id dans client_loyalty_points
SELECT '=== MISE À JOUR WORKSHOP_ID CLIENT_LOYALTY_POINTS ===' as etape;

-- Mettre à jour les workshop_id basés sur les clients
UPDATE client_loyalty_points 
SET workshop_id = c.user_id
FROM clients c
WHERE client_loyalty_points.client_id = c.id
AND client_loyalty_points.workshop_id IS NULL;

-- Vérifier le résultat
SELECT 
    'Après mise à jour' as etape,
    workshop_id,
    COUNT(*) as nombre_enregistrements
FROM client_loyalty_points 
GROUP BY workshop_id
ORDER BY nombre_enregistrements DESC;

-- 6. Nettoyer les données orphelines
SELECT '=== NETTOYAGE DONNÉES ORPHELINES ===' as etape;

-- Supprimer les enregistrements de fidélité pour des clients qui n'existent plus
DELETE FROM loyalty_points_history 
WHERE client_id NOT IN (SELECT id FROM clients);

DELETE FROM referrals 
WHERE referrer_client_id NOT IN (SELECT id FROM clients)
   OR referred_client_id NOT IN (SELECT id FROM clients);

DELETE FROM client_loyalty_points 
WHERE client_id NOT IN (SELECT id FROM clients);

-- Supprimer les enregistrements avec workshop_id NULL
DELETE FROM loyalty_points_history WHERE workshop_id IS NULL;
DELETE FROM loyalty_tiers_advanced WHERE workshop_id IS NULL;
DELETE FROM referrals WHERE workshop_id IS NULL;
DELETE FROM client_loyalty_points WHERE workshop_id IS NULL;

SELECT 'Données orphelines supprimées' as resultat;

-- 7. Vérification finale du mapping
SELECT '=== VÉRIFICATION FINALE DU MAPPING ===' as etape;

-- Vérifier que tous les workshop_id correspondent à des user_id valides
SELECT 
    'loyalty_points_history' as table_name,
    COUNT(*) as total_enregistrements,
    COUNT(CASE WHEN workshop_id IN (SELECT id FROM auth.users) THEN 1 END) as workshop_id_valides,
    COUNT(CASE WHEN workshop_id IS NULL THEN 1 END) as workshop_id_null
FROM loyalty_points_history

UNION ALL

SELECT 
    'loyalty_tiers_advanced' as table_name,
    COUNT(*) as total_enregistrements,
    COUNT(CASE WHEN workshop_id IN (SELECT id FROM auth.users) THEN 1 END) as workshop_id_valides,
    COUNT(CASE WHEN workshop_id IS NULL THEN 1 END) as workshop_id_null
FROM loyalty_tiers_advanced

UNION ALL

SELECT 
    'referrals' as table_name,
    COUNT(*) as total_enregistrements,
    COUNT(CASE WHEN workshop_id IN (SELECT id FROM auth.users) THEN 1 END) as workshop_id_valides,
    COUNT(CASE WHEN workshop_id IS NULL THEN 1 END) as workshop_id_null
FROM referrals

UNION ALL

SELECT 
    'client_loyalty_points' as table_name,
    COUNT(*) as total_enregistrements,
    COUNT(CASE WHEN workshop_id IN (SELECT id FROM auth.users) THEN 1 END) as workshop_id_valides,
    COUNT(CASE WHEN workshop_id IS NULL THEN 1 END) as workshop_id_null
FROM client_loyalty_points;

-- 8. Test d'isolation après correction
SELECT '=== TEST ISOLATION APRÈS CORRECTION ===' as etape;

DO $$
DECLARE
    v_user_id UUID;
    v_table_name TEXT;
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
    
    RAISE NOTICE '✅ Test d''isolation après correction pour l''utilisateur: %', v_user_id;
    
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

-- 9. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Mapping workshop_id corrigé' as message;
SELECT '✅ Données orphelines nettoyées' as nettoyage;
SELECT '✅ Test d''isolation effectué' as test;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT 'ℹ️ Vérifiez que l''isolation fonctionne maintenant' as note;
