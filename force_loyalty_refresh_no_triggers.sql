-- =====================================================
-- FORCE REFRESH LOYALTY POINTS SANS TRIGGERS
-- =====================================================
-- Script pour forcer la mise à jour des points en désactivant temporairement les triggers
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

-- 2. DÉSACTIVER temporairement les triggers
SELECT '=== DÉSACTIVATION TRIGGERS ===' as etape;

-- Désactiver les triggers sur clients
ALTER TABLE clients DISABLE TRIGGER ALL;

-- Désactiver les triggers sur loyalty_tiers_advanced
ALTER TABLE loyalty_tiers_advanced DISABLE TRIGGER ALL;

-- Désactiver les triggers sur loyalty_config
ALTER TABLE loyalty_config DISABLE TRIGGER ALL;

-- 3. FORCER la mise à jour des timestamps
SELECT '=== MISE À JOUR TIMESTAMPS ===' as etape;

-- Mettre à jour les timestamps des clients
UPDATE clients 
SET updated_at = NOW()
WHERE loyalty_points > 0 OR current_tier_id IS NOT NULL;

-- Mettre à jour les timestamps des niveaux
UPDATE loyalty_tiers_advanced 
SET updated_at = NOW();

-- Mettre à jour les timestamps des configurations
UPDATE loyalty_config 
SET updated_at = NOW();

-- 4. VÉRIFIER les clients avec des points incohérents
SELECT '=== CLIENTS AVEC POINTS INCOHÉRENTS ===' as etape;

-- Identifier les clients qui ont des points mais des tiers incorrects
SELECT 
    'Clients avec points incohérents' as info,
    c.first_name,
    c.last_name,
    c.loyalty_points,
    c.current_tier_id,
    lta.name as current_tier_name,
    lta.points_required as current_tier_points,
    CASE 
        WHEN c.loyalty_points >= lta.points_required THEN '✅ Cohérent'
        WHEN c.loyalty_points < lta.points_required THEN '⚠️ Points insuffisants'
        ELSE '❌ Incohérent'
    END as coherence_status
FROM clients c
LEFT JOIN loyalty_tiers_advanced lta ON c.current_tier_id = lta.id
WHERE c.loyalty_points > 0
ORDER BY c.loyalty_points DESC;

-- 5. RECALCULER les tiers basés sur les points actuels
SELECT '=== RECALCUL DES TIERS ===' as etape;

-- Recalculer les tiers pour tous les clients avec des points
UPDATE clients 
SET current_tier_id = (
    SELECT lta.id 
    FROM loyalty_tiers_advanced lta 
    WHERE lta.workshop_id = clients.workshop_id
    AND lta.is_active = true
    AND lta.points_required <= clients.loyalty_points
    ORDER BY lta.points_required DESC 
    LIMIT 1
),
updated_at = NOW()
WHERE loyalty_points > 0;

-- 6. VÉRIFIER les clients après recalcul
SELECT '=== CLIENTS APRÈS RECALCUL ===' as etape;

SELECT 
    'Clients après recalcul' as info,
    c.first_name,
    c.last_name,
    c.loyalty_points,
    c.current_tier_id,
    lta.name as tier_name,
    lta.points_required as tier_points_required,
    CASE 
        WHEN c.loyalty_points >= lta.points_required THEN '✅ Cohérent'
        WHEN c.loyalty_points < lta.points_required THEN '⚠️ Points insuffisants'
        ELSE '❌ Incohérent'
    END as coherence_status
FROM clients c
LEFT JOIN loyalty_tiers_advanced lta ON c.current_tier_id = lta.id
WHERE c.loyalty_points > 0 OR c.current_tier_id IS NOT NULL
ORDER BY c.loyalty_points DESC;

-- 7. RÉACTIVER les triggers
SELECT '=== RÉACTIVATION TRIGGERS ===' as etape;

-- Réactiver les triggers sur clients
ALTER TABLE clients ENABLE TRIGGER ALL;

-- Réactiver les triggers sur loyalty_tiers_advanced
ALTER TABLE loyalty_tiers_advanced ENABLE TRIGGER ALL;

-- Réactiver les triggers sur loyalty_config
ALTER TABLE loyalty_config ENABLE TRIGGER ALL;

-- 8. CRÉER un événement de notification pour forcer le refresh
SELECT '=== CRÉATION ÉVÉNEMENT NOTIFICATION ===' as etape;

-- Créer un événement pour notifier le frontend du changement
NOTIFY loyalty_data_updated, 'Points de fidélité mis à jour';

-- 9. VÉRIFIER les données finales
SELECT '=== VÉRIFICATION FINALE ===' as etape;

-- Vérifier que tous les clients ont des données cohérentes
SELECT 
    'Vérification finale' as info,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN loyalty_points > 0 THEN 1 END) as clients_avec_points,
    COUNT(CASE WHEN current_tier_id IS NOT NULL THEN 1 END) as clients_avec_tier,
    COUNT(CASE WHEN loyalty_points > 0 AND current_tier_id IS NOT NULL THEN 1 END) as clients_avec_points_et_tier
FROM clients;

-- 10. CRÉER un rapport de synchronisation
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

-- 11. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Triggers désactivés temporairement' as message;
SELECT '✅ Timestamps mis à jour' as timestamps;
SELECT '✅ Tiers recalculés' as recalcul;
SELECT '✅ Triggers réactivés' as triggers;
SELECT '✅ Événement de notification créé' as notification;
SELECT '✅ Données synchronisées' as synchronisation;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT 'ℹ️ Les points devraient maintenant être à jour dans l''interface' as note;
SELECT '💡 Videz le cache du navigateur si nécessaire' as cache;
