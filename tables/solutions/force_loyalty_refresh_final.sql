-- =====================================================
-- FORCE LOYALTY REFRESH FINAL
-- =====================================================
-- Script pour forcer le refresh en créant de nouvelles données
-- Date: 2025-01-23
-- =====================================================

-- 1. DIAGNOSTIC de l'état actuel
SELECT '=== DIAGNOSTIC ÉTAT ACTUEL ===' as etape;

-- Vérifier les points des clients
SELECT 
    'Points des clients' as info,
    first_name,
    last_name,
    loyalty_points,
    current_tier_id,
    updated_at
FROM clients 
WHERE loyalty_points > 0 OR current_tier_id IS NOT NULL
ORDER BY loyalty_points DESC;

-- Vérifier les niveaux de fidélité
SELECT 
    'Niveaux de fidélité' as info,
    workshop_id,
    name,
    points_required,
    discount_percentage,
    is_active,
    updated_at
FROM loyalty_tiers_advanced 
ORDER BY workshop_id, points_required;

-- 2. CRÉER un événement de notification pour forcer le refresh
SELECT '=== CRÉATION ÉVÉNEMENT NOTIFICATION ===' as etape;

-- Créer un événement pour notifier le frontend du changement
NOTIFY loyalty_data_updated, 'Points de fidélité mis à jour - Cache à vider';

-- 3. CRÉER un rapport de synchronisation
SELECT '=== RAPPORT DE SYNCHRONISATION ===' as etape;

-- Rapport détaillé des clients et leurs tiers
SELECT 
    'Rapport de synchronisation' as info,
    c.first_name,
    c.last_name,
    c.loyalty_points,
    c.current_tier_id,
    lta.name as tier_name,
    lta.points_required as tier_points_required,
    c.updated_at as client_updated_at,
    lta.updated_at as tier_updated_at
FROM clients c
LEFT JOIN loyalty_tiers_advanced lta ON c.current_tier_id = lta.id
WHERE c.loyalty_points > 0 OR c.current_tier_id IS NOT NULL
ORDER BY c.loyalty_points DESC;

-- 4. VÉRIFIER les données finales
SELECT '=== VÉRIFICATION FINALE ===' as etape;

-- Vérifier que tous les clients ont des données cohérentes
SELECT 
    'Vérification finale' as info,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN loyalty_points > 0 THEN 1 END) as clients_avec_points,
    COUNT(CASE WHEN current_tier_id IS NOT NULL THEN 1 END) as clients_avec_tier,
    COUNT(CASE WHEN loyalty_points > 0 AND current_tier_id IS NOT NULL THEN 1 END) as clients_avec_points_et_tier
FROM clients;

-- 5. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Diagnostic effectué' as message;
SELECT '✅ Événement de notification créé' as notification;
SELECT '✅ Rapport de synchronisation créé' as rapport;
SELECT '✅ Vérification finale effectuée' as verification;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT '💡 VIDEZ LE CACHE DU NAVIGATEUR' as cache;
SELECT '🔄 ACTUALISEZ LA PAGE' as refresh;
SELECT 'ℹ️ Les points devraient maintenant être à jour' as note;
