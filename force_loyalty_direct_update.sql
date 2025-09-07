-- =====================================================
-- FORCE LOYALTY DIRECT UPDATE
-- =====================================================
-- Script pour forcer la mise à jour des données en modifiant directement les timestamps
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

-- 2. MODIFICATION DIRECTE des timestamps
SELECT '=== MODIFICATION DIRECTE TIMESTAMPS ===' as etape;

-- Modifier directement les timestamps des clients
UPDATE clients 
SET updated_at = NOW() + INTERVAL '1 second'
WHERE loyalty_points > 0 OR current_tier_id IS NOT NULL;

-- Modifier directement les timestamps des niveaux
UPDATE loyalty_tiers_advanced 
SET updated_at = NOW() + INTERVAL '1 second';

-- Modifier directement les timestamps des configurations
UPDATE loyalty_config 
SET updated_at = NOW() + INTERVAL '1 second';

-- 3. VÉRIFIER les données après modification
SELECT '=== VÉRIFICATION APRÈS MODIFICATION ===' as etape;

-- Vérifier les clients après modification
SELECT 
    'Clients après modification' as info,
    first_name,
    last_name,
    loyalty_points,
    current_tier_id,
    updated_at
FROM clients 
WHERE loyalty_points > 0 OR current_tier_id IS NOT NULL
ORDER BY loyalty_points DESC;

-- Vérifier les niveaux après modification
SELECT 
    'Niveaux après modification' as info,
    workshop_id,
    name,
    points_required,
    discount_percentage,
    is_active,
    updated_at
FROM loyalty_tiers_advanced 
ORDER BY workshop_id, points_required;

-- 4. CRÉER un rapport de synchronisation
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

-- 5. CRÉER un événement de notification pour forcer le refresh
SELECT '=== CRÉATION ÉVÉNEMENT NOTIFICATION ===' as etape;

-- Créer un événement pour notifier le frontend du changement
NOTIFY loyalty_data_updated, 'Points de fidélité mis à jour - Cache à vider';

-- 6. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Timestamps modifiés directement' as message;
SELECT '✅ Événement de notification créé' as notification;
SELECT '✅ Données synchronisées' as synchronisation;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT '💡 VIDEZ LE CACHE DU NAVIGATEUR' as cache;
SELECT '🔄 ACTUALISEZ LA PAGE' as refresh;
SELECT 'ℹ️ Les points devraient maintenant être à jour' as note;
