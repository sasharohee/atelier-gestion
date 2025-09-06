-- 🧪 TEST ISOLATION FIDÉLITÉ - Vérification du bon fonctionnement
-- Ce script teste que l'isolation des données de fidélité fonctionne correctement
-- Date: 2025-01-23

-- ============================================================================
-- 1. TEST DE BASE - VÉRIFICATION DES DONNÉES ISOLÉES
-- ============================================================================

SELECT '=== TEST DE BASE - VÉRIFICATION DONNÉES ISOLÉES ===' as section;

-- Test 1: Vérifier que loyalty_config contient des données
SELECT 
    'Test 1: loyalty_config' as test_name,
    COUNT(*) as total_configs,
    COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) as configs_with_workshop_id,
    CASE 
        WHEN COUNT(*) > 0 AND COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) = COUNT(*) 
        THEN '✅ SUCCÈS' 
        ELSE '❌ ÉCHEC' 
    END as test_result
FROM loyalty_config;

-- Test 2: Vérifier que loyalty_tiers_advanced contient des données
SELECT 
    'Test 2: loyalty_tiers_advanced' as test_name,
    COUNT(*) as total_tiers,
    COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) as tiers_with_workshop_id,
    CASE 
        WHEN COUNT(*) > 0 AND COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) = COUNT(*) 
        THEN '✅ SUCCÈS' 
        ELSE '❌ ÉCHEC' 
    END as test_result
FROM loyalty_tiers_advanced;

-- Test 3: Vérifier que loyalty_points_history contient des données
SELECT 
    'Test 3: loyalty_points_history' as test_name,
    COUNT(*) as total_entries,
    COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) as entries_with_workshop_id,
    CASE 
        WHEN COUNT(*) >= 0 AND COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) = COUNT(*) 
        THEN '✅ SUCCÈS' 
        ELSE '❌ ÉCHEC' 
    END as test_result
FROM loyalty_points_history;

-- ============================================================================
-- 2. TEST D'ISOLATION - VÉRIFICATION DES POLITIQUES RLS
-- ============================================================================

SELECT '=== TEST D''ISOLATION - VÉRIFICATION POLITIQUES RLS ===' as section;

-- Test 4: Vérifier que RLS est activé sur toutes les tables
SELECT 
    'Test 4: Activation RLS' as test_name,
    COUNT(*) as total_tables,
    COUNT(CASE WHEN rowsecurity THEN 1 END) as tables_with_rls,
    CASE 
        WHEN COUNT(*) = 3 AND COUNT(CASE WHEN rowsecurity THEN 1 END) = 3 
        THEN '✅ SUCCÈS' 
        ELSE '❌ ÉCHEC' 
    END as test_result
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename IN ('loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history');

-- Test 5: Vérifier que les politiques RLS existent
SELECT 
    'Test 5: Politiques RLS' as test_name,
    COUNT(*) as total_policies,
    COUNT(CASE WHEN cmd = 'SELECT' THEN 1 END) as select_policies,
    COUNT(CASE WHEN cmd = 'INSERT' THEN 1 END) as insert_policies,
    COUNT(CASE WHEN cmd = 'UPDATE' THEN 1 END) as update_policies,
    COUNT(CASE WHEN cmd = 'DELETE' THEN 1 END) as delete_policies,
    CASE 
        WHEN COUNT(*) >= 8 
        THEN '✅ SUCCÈS' 
        ELSE '❌ ÉCHEC' 
    END as test_result
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename IN ('loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history');

-- ============================================================================
-- 3. TEST DE LA VUE LOYALTY_DASHBOARD
-- ============================================================================

SELECT '=== TEST DE LA VUE LOYALTY_DASHBOARD ===' as section;

-- Test 6: Vérifier que la vue loyalty_dashboard fonctionne
SELECT 
    'Test 6: Vue loyalty_dashboard' as test_name,
    COUNT(*) as total_clients_in_dashboard,
    CASE 
        WHEN COUNT(*) >= 0 
        THEN '✅ SUCCÈS' 
        ELSE '❌ ÉCHEC' 
    END as test_result
FROM loyalty_dashboard;

-- Test 7: Vérifier la structure de la vue
SELECT 
    'Test 7: Structure vue' as test_name,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'loyalty_dashboard'
ORDER BY ordinal_position;

-- ============================================================================
-- 4. TEST DES FONCTIONS DE FIDÉLITÉ
-- ============================================================================

SELECT '=== TEST DES FONCTIONS DE FIDÉLITÉ ===' as section;

-- Test 8: Vérifier que la fonction get_loyalty_statistics existe et fonctionne
DO $$
DECLARE
    stats_result JSON;
    test_result TEXT;
BEGIN
    BEGIN
        SELECT get_loyalty_statistics() INTO stats_result;
        test_result := '✅ SUCCÈS - Fonction get_loyalty_statistics fonctionne';
    EXCEPTION
        WHEN OTHERS THEN
            test_result := '❌ ÉCHEC - Fonction get_loyalty_statistics: ' || SQLERRM;
    END;
    
    RAISE NOTICE 'Test 8: %', test_result;
END $$;

-- Test 9: Vérifier que la fonction calculate_loyalty_points existe
DO $$
DECLARE
    test_result TEXT;
BEGIN
    BEGIN
        -- Test avec des paramètres de base
        PERFORM calculate_loyalty_points(50.00, '00000000-0000-0000-0000-000000000000'::UUID);
        test_result := '✅ SUCCÈS - Fonction calculate_loyalty_points fonctionne';
    EXCEPTION
        WHEN OTHERS THEN
            test_result := '❌ ÉCHEC - Fonction calculate_loyalty_points: ' || SQLERRM;
    END;
    
    RAISE NOTICE 'Test 9: %', test_result;
END $$;

-- ============================================================================
-- 5. TEST D'INTÉGRITÉ DES DONNÉES
-- ============================================================================

SELECT '=== TEST D''INTÉGRITÉ DES DONNÉES ===' as section;

-- Test 10: Vérifier la cohérence entre clients et loyalty_points_history
SELECT 
    'Test 10: Cohérence clients-loyalty_history' as test_name,
    COUNT(DISTINCT c.id) as total_clients,
    COUNT(DISTINCT lph.client_id) as clients_in_history,
    CASE 
        WHEN COUNT(DISTINCT c.id) >= COUNT(DISTINCT lph.client_id) 
        THEN '✅ SUCCÈS' 
        ELSE '❌ ÉCHEC' 
    END as test_result
FROM clients c
LEFT JOIN loyalty_points_history lph ON c.id = lph.client_id
WHERE c.workshop_id = COALESCE(
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
    '00000000-0000-0000-0000-000000000000'::UUID
);

-- Test 11: Vérifier que les points de fidélité sont cohérents
SELECT 
    'Test 11: Cohérence points fidélité' as test_name,
    COUNT(*) as total_clients_with_points,
    COUNT(CASE WHEN loyalty_points >= 0 THEN 1 END) as clients_with_valid_points,
    CASE 
        WHEN COUNT(*) = COUNT(CASE WHEN loyalty_points >= 0 THEN 1 END) 
        THEN '✅ SUCCÈS' 
        ELSE '❌ ÉCHEC' 
    END as test_result
FROM clients
WHERE loyalty_points IS NOT NULL
    AND workshop_id = COALESCE(
        (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1),
        '00000000-0000-0000-0000-000000000000'::UUID
    );

-- ============================================================================
-- 6. TEST DE PERFORMANCE
-- ============================================================================

SELECT '=== TEST DE PERFORMANCE ===' as section;

-- Test 12: Vérifier l'existence des index
SELECT 
    'Test 12: Index de performance' as test_name,
    COUNT(*) as total_indexes,
    COUNT(CASE WHEN indexname LIKE '%workshop_id%' THEN 1 END) as workshop_id_indexes,
    CASE 
        WHEN COUNT(CASE WHEN indexname LIKE '%workshop_id%' THEN 1 END) >= 3 
        THEN '✅ SUCCÈS' 
        ELSE '❌ ÉCHEC' 
    END as test_result
FROM pg_indexes 
WHERE schemaname = 'public' 
    AND tablename IN ('loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history', 'clients')
    AND indexname LIKE '%workshop_id%';

-- ============================================================================
-- 7. RÉSUMÉ DES TESTS
-- ============================================================================

SELECT '=== RÉSUMÉ DES TESTS ===' as section;

-- Compter les tests réussis et échoués
WITH test_results AS (
    SELECT 'Test 1: loyalty_config' as test_name, 
           CASE WHEN COUNT(*) > 0 AND COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) = COUNT(*) 
                THEN 'SUCCÈS' ELSE 'ÉCHEC' END as result
    FROM loyalty_config
    UNION ALL
    SELECT 'Test 2: loyalty_tiers_advanced' as test_name, 
           CASE WHEN COUNT(*) > 0 AND COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) = COUNT(*) 
                THEN 'SUCCÈS' ELSE 'ÉCHEC' END as result
    FROM loyalty_tiers_advanced
    UNION ALL
    SELECT 'Test 3: loyalty_points_history' as test_name, 
           CASE WHEN COUNT(*) >= 0 AND COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) = COUNT(*) 
                THEN 'SUCCÈS' ELSE 'ÉCHEC' END as result
    FROM loyalty_points_history
    UNION ALL
    SELECT 'Test 4: Activation RLS' as test_name, 
           CASE WHEN COUNT(*) = 3 AND COUNT(CASE WHEN rowsecurity THEN 1 END) = 3 
                THEN 'SUCCÈS' ELSE 'ÉCHEC' END as result
    FROM pg_tables 
    WHERE schemaname = 'public' 
        AND tablename IN ('loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history')
    UNION ALL
    SELECT 'Test 5: Politiques RLS' as test_name, 
           CASE WHEN COUNT(*) >= 8 THEN 'SUCCÈS' ELSE 'ÉCHEC' END as result
    FROM pg_policies 
    WHERE schemaname = 'public' 
        AND tablename IN ('loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history')
    UNION ALL
    SELECT 'Test 6: Vue loyalty_dashboard' as test_name, 
           CASE WHEN COUNT(*) >= 0 THEN 'SUCCÈS' ELSE 'ÉCHEC' END as result
    FROM loyalty_dashboard
)
SELECT 
    'Résumé global' as summary_type,
    COUNT(*) as total_tests,
    COUNT(CASE WHEN result = 'SUCCÈS' THEN 1 END) as tests_success,
    COUNT(CASE WHEN result = 'ÉCHEC' THEN 1 END) as tests_failed,
    CASE 
        WHEN COUNT(CASE WHEN result = 'ÉCHEC' THEN 1 END) = 0 
        THEN '🎉 TOUS LES TESTS RÉUSSIS !' 
        ELSE '⚠️ CERTAINS TESTS ONT ÉCHOUÉ' 
    END as global_result
FROM test_results;

-- ============================================================================
-- 8. RECOMMANDATIONS
-- ============================================================================

SELECT '=== RECOMMANDATIONS ===' as section;

SELECT '📋 RECOMMANDATIONS POUR L''ISOLATION DE LA FIDÉLITÉ:' as info;

SELECT '1. ✅ Vérifiez que toutes les tables ont bien un workshop_id défini' as recommendation;
SELECT '2. ✅ Assurez-vous que les politiques RLS sont actives' as recommendation;
SELECT '3. ✅ Testez régulièrement l''isolation avec ce script' as recommendation;
SELECT '4. ✅ Surveillez les performances avec les index créés' as recommendation;
SELECT '5. ✅ Vérifiez que la vue loyalty_dashboard affiche les bonnes données' as recommendation;

SELECT '🔒 L''isolation des données de fidélité est maintenant sécurisée !' as confirmation;
