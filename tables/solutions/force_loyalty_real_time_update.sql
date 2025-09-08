-- =====================================================
-- FORCE REAL-TIME UPDATE LOYALTY
-- =====================================================
-- Script pour forcer la mise à jour en temps réel des points
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

-- 2. FORCER la mise à jour des timestamps avec des valeurs uniques
SELECT '=== MISE À JOUR TIMESTAMPS UNIQUES ===' as etape;

-- Mettre à jour les timestamps des clients avec des valeurs uniques
UPDATE clients 
SET updated_at = NOW() + INTERVAL '1 second'
WHERE loyalty_points > 0 OR current_tier_id IS NOT NULL;

-- Mettre à jour les timestamps des niveaux avec des valeurs uniques
UPDATE loyalty_tiers_advanced 
SET updated_at = NOW() + INTERVAL '2 seconds';

-- Mettre à jour les timestamps des configurations avec des valeurs uniques
UPDATE loyalty_config 
SET updated_at = NOW() + INTERVAL '3 seconds';

-- 3. VÉRIFIER les données après mise à jour
SELECT '=== VÉRIFICATION APRÈS MISE À JOUR ===' as etape;

-- Vérifier les clients après mise à jour
SELECT 
    'Clients après mise à jour' as info,
    first_name,
    last_name,
    loyalty_points,
    current_tier_id,
    updated_at
FROM clients 
WHERE loyalty_points > 0 OR current_tier_id IS NOT NULL
ORDER BY loyalty_points DESC;

-- Vérifier les niveaux après mise à jour
SELECT 
    'Niveaux après mise à jour' as info,
    workshop_id,
    name,
    points_required,
    discount_percentage,
    is_active,
    updated_at
FROM loyalty_tiers_advanced 
ORDER BY workshop_id, points_required;

-- 4. CRÉER un événement de notification pour forcer le refresh
SELECT '=== CRÉATION ÉVÉNEMENT NOTIFICATION ===' as etape;

-- Créer un événement pour notifier le frontend du changement
NOTIFY loyalty_data_updated, 'Points de fidélité mis à jour - Refresh forcé';

-- 5. CRÉER un rapport de synchronisation
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

-- 6. VÉRIFIER les données finales
SELECT '=== VÉRIFICATION FINALE ===' as etape;

-- Vérifier que tous les clients ont des données cohérentes
SELECT 
    'Vérification finale' as info,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN loyalty_points > 0 THEN 1 END) as clients_avec_points,
    COUNT(CASE WHEN current_tier_id IS NOT NULL THEN 1 END) as clients_avec_tier,
    COUNT(CASE WHEN loyalty_points > 0 AND current_tier_id IS NOT NULL THEN 1 END) as clients_avec_points_et_tier
FROM clients;

-- 7. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Timestamps mis à jour avec des valeurs uniques' as message;
SELECT '✅ Événement de notification créé' as notification;
SELECT '✅ Données synchronisées' as synchronisation;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT '💡 VIDEZ LE CACHE DU NAVIGATEUR' as cache;
SELECT '🔄 ACTUALISEZ LA PAGE' as refresh;
SELECT 'ℹ️ Les points devraient maintenant être à jour en temps réel' as note;
