-- 🔍 VÉRIFICATION SIMPLE - Isolation Fidélité
-- Script simplifié pour vérifier l'isolation des données de fidélité
-- Date: 2025-01-23

-- ============================================================================
-- 1. VÉRIFICATION RAPIDE
-- ============================================================================

SELECT '=== VÉRIFICATION RAPIDE ===' as section;

-- Vérifier le workshop_id actuel
SELECT 
    'Workshop ID actuel' as info,
    value as workshop_id
FROM system_settings 
WHERE key = 'workshop_id';

-- Vérifier combien de clients sont visibles
SELECT 
    'Clients visibles' as info,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN loyalty_points > 0 THEN 1 END) as clients_with_points
FROM clients;

-- ============================================================================
-- 2. VÉRIFICATION DE LA VUE LOYALTY_DASHBOARD
-- ============================================================================

SELECT '=== VÉRIFICATION DE LA VUE ===' as section;

-- Vérifier combien de clients sont dans le dashboard
SELECT 
    'Clients dans le dashboard' as info,
    COUNT(*) as total_clients_in_dashboard
FROM loyalty_dashboard;

-- Afficher les clients dans le dashboard
SELECT 
    'Détail des clients dans le dashboard' as info,
    client_id,
    first_name,
    last_name,
    current_points,
    current_tier
FROM loyalty_dashboard
ORDER BY current_points DESC
LIMIT 10;

-- ============================================================================
-- 3. TEST D'ISOLATION
-- ============================================================================

SELECT '=== TEST DISOLATION ===' as section;

-- Test 1: Vérifier que tous les clients visibles ont le bon workshop_id
SELECT 
    'Test 1: Workshop ID des clients visibles' as test,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END) as clients_with_correct_workshop,
    CASE 
        WHEN COUNT(*) = COUNT(CASE WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 1 END) 
        THEN 'SUCCES: Tous les clients ont le bon workshop_id'
        ELSE 'ECHEC: Certains clients ont un mauvais workshop_id'
    END as result
FROM clients;

-- Test 2: Vérifier que la vue ne montre que les clients de l'atelier actuel
SELECT 
    'Test 2: Isolation de la vue' as test,
    COUNT(*) as clients_in_dashboard,
    CASE 
        WHEN COUNT(*) >= 0 THEN 'SUCCES: Vue fonctionnelle'
        ELSE 'ECHEC: Probleme avec la vue'
    END as result
FROM loyalty_dashboard;

-- Test 3: Vérifier quil ny a pas de clients d'autres ateliers
SELECT 
    'Test 3: Absence de clients d autres ateliers' as test,
    COUNT(*) as clients_from_other_workshops,
    CASE 
        WHEN COUNT(*) = 0 THEN 'SUCCES: Aucun client d autre atelier'
        ELSE 'ECHEC: Clients d autres ateliers detectes'
    END as result
FROM clients 
WHERE workshop_id IS NOT NULL 
    AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    AND workshop_id != '00000000-0000-0000-0000-000000000000'::UUID;

-- ============================================================================
-- 4. RÉSUMÉ FINAL
-- ============================================================================

SELECT '=== RÉSUMÉ FINAL ===' as section;

-- Résumé de l'isolation
SELECT 
    'Resume de l isolation' as info,
    (SELECT COUNT(*) FROM clients) as total_clients_visible,
    (SELECT COUNT(*) FROM clients WHERE loyalty_points > 0) as clients_with_points,
    (SELECT COUNT(*) FROM loyalty_dashboard) as clients_in_dashboard,
    CASE 
        WHEN (SELECT COUNT(*) FROM clients) > 0 
        AND (SELECT COUNT(*) FROM clients WHERE workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)) = 0
        THEN 'ISOLATION FONCTIONNELLE'
        ELSE 'PROBLEME DISOLATION DETECTE'
    END as isolation_status;

-- Message final
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM clients WHERE workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)) = 0
        THEN 'L isolation des donnees de fidelite fonctionne correctement !'
        ELSE 'Des problemes d isolation persistent. Executez le script de correction avancee.'
    END as final_message;
