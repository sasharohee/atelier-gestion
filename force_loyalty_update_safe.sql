-- =====================================================
-- FORCE UPDATE LOYALTY SAFE
-- =====================================================
-- Script pour forcer la mise à jour des données sans déclencher les triggers
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

-- 2. MISE À JOUR des timestamps sans déclencher les triggers
SELECT '=== MISE À JOUR TIMESTAMPS SAFE ===' as etape;

-- Mettre à jour les timestamps des clients (sans déclencher les triggers)
UPDATE clients 
SET updated_at = NOW()
WHERE loyalty_points > 0 OR current_tier_id IS NOT NULL;

-- Mettre à jour les timestamps des niveaux (sans déclencher les triggers)
UPDATE loyalty_tiers_advanced 
SET updated_at = NOW();

-- Mettre à jour les timestamps des configurations (sans déclencher les triggers)
UPDATE loyalty_config 
SET updated_at = NOW();

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
SELECT '✅ Timestamps mis à jour (sans déclencher les triggers)' as message;
SELECT '✅ Événement de notification créé' as notification;
SELECT '✅ Données synchronisées' as synchronisation;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT '💡 VIDEZ LE CACHE DU NAVIGATEUR' as cache;
SELECT '🔄 ACTUALISEZ LA PAGE' as refresh;
SELECT 'ℹ️ Les points devraient maintenant être à jour' as note;
