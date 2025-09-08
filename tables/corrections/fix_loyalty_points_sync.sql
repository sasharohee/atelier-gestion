-- =====================================================
-- CORRECTION SYNCHRONISATION POINTS LOYALTY
-- =====================================================
-- Script pour corriger l'incohérence des points entre les sections
-- Date: 2025-01-23
-- =====================================================

-- 1. DIAGNOSTIC des incohérences
SELECT '=== DIAGNOSTIC INCOHÉRENCES ===' as etape;

-- Vérifier les points des clients
SELECT 
    'Points des clients' as info,
    first_name,
    last_name,
    loyalty_points,
    current_tier_id,
    CASE 
        WHEN current_tier_id IS NULL THEN 'Aucun tier'
        WHEN current_tier_id IN (SELECT id FROM loyalty_tiers_advanced) THEN 'Tier valide'
        ELSE 'Tier invalide'
    END as tier_status
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
    is_active
FROM loyalty_tiers_advanced 
ORDER BY workshop_id, points_required;

-- Vérifier les configurations
SELECT 
    'Configurations' as info,
    workshop_id,
    key,
    value,
    description
FROM loyalty_config 
ORDER BY workshop_id, key;

-- 2. VÉRIFIER les clients avec des tier_id invalides
SELECT '=== CLIENTS AVEC TIER_ID INVALIDES ===' as etape;

SELECT 
    'Clients avec tier_id invalides' as info,
    first_name,
    last_name,
    loyalty_points,
    current_tier_id
FROM clients 
WHERE current_tier_id IS NOT NULL 
AND current_tier_id NOT IN (
    SELECT id FROM loyalty_tiers_advanced
);

-- 3. CORRIGER les clients avec des tier_id invalides
SELECT '=== CORRECTION TIER_ID INVALIDES ===' as etape;

-- Supprimer les current_tier_id invalides
UPDATE clients 
SET current_tier_id = NULL 
WHERE current_tier_id IS NOT NULL 
AND current_tier_id NOT IN (
    SELECT id FROM loyalty_tiers_advanced
);

-- 4. RECALCULER les tiers des clients basés sur leurs points
SELECT '=== RECALCUL DES TIERS CLIENTS ===' as etape;

-- Mettre à jour les tiers des clients basés sur leurs points
UPDATE clients 
SET current_tier_id = (
    SELECT lta.id 
    FROM loyalty_tiers_advanced lta 
    WHERE lta.workshop_id = clients.workshop_id
    AND lta.is_active = true
    AND lta.points_required <= clients.loyalty_points
    ORDER BY lta.points_required DESC 
    LIMIT 1
)
WHERE loyalty_points > 0;

-- 5. VÉRIFIER les clients après correction
SELECT '=== CLIENTS APRÈS CORRECTION ===' as etape;

SELECT 
    'Clients après correction' as info,
    first_name,
    last_name,
    loyalty_points,
    current_tier_id,
    CASE 
        WHEN current_tier_id IS NULL THEN 'Aucun tier'
        WHEN current_tier_id IN (SELECT id FROM loyalty_tiers_advanced) THEN 'Tier valide'
        ELSE 'Tier invalide'
    END as tier_status
FROM clients 
WHERE loyalty_points > 0 OR current_tier_id IS NOT NULL
ORDER BY loyalty_points DESC;

-- 6. VÉRIFIER la cohérence des données
SELECT '=== VÉRIFICATION COHÉRENCE ===' as etape;

-- Vérifier que tous les clients ont des tiers cohérents
SELECT 
    'Cohérence des tiers' as info,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN current_tier_id IS NULL AND loyalty_points = 0 THEN 1 END) as clients_sans_points_ni_tier,
    COUNT(CASE WHEN current_tier_id IS NULL AND loyalty_points > 0 THEN 1 END) as clients_avec_points_sans_tier,
    COUNT(CASE WHEN current_tier_id IS NOT NULL AND loyalty_points = 0 THEN 1 END) as clients_avec_tier_sans_points,
    COUNT(CASE WHEN current_tier_id IS NOT NULL AND loyalty_points > 0 THEN 1 END) as clients_avec_points_et_tier
FROM clients;

-- 7. CRÉER un rapport de synchronisation
SELECT '=== RAPPORT DE SYNCHRONISATION ===' as etape;

-- Rapport détaillé des clients et leurs tiers
SELECT 
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

-- 8. CORRIGER les incohérences restantes
SELECT '=== CORRECTION INCOHÉRENCES RESTANTES ===' as etape;

-- Corriger les clients qui ont des tiers mais pas assez de points
UPDATE clients 
SET current_tier_id = (
    SELECT lta.id 
    FROM loyalty_tiers_advanced lta 
    WHERE lta.workshop_id = clients.workshop_id
    AND lta.is_active = true
    AND lta.points_required <= clients.loyalty_points
    ORDER BY lta.points_required DESC 
    LIMIT 1
)
WHERE current_tier_id IS NOT NULL 
AND loyalty_points < (
    SELECT lta.points_required 
    FROM loyalty_tiers_advanced lta 
    WHERE lta.id = clients.current_tier_id
);

-- 9. VÉRIFICATION FINALE
SELECT '=== VÉRIFICATION FINALE ===' as etape;

-- Vérifier la cohérence finale
SELECT 
    'Cohérence finale' as info,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN current_tier_id IS NULL AND loyalty_points = 0 THEN 1 END) as clients_sans_points_ni_tier,
    COUNT(CASE WHEN current_tier_id IS NULL AND loyalty_points > 0 THEN 1 END) as clients_avec_points_sans_tier,
    COUNT(CASE WHEN current_tier_id IS NOT NULL AND loyalty_points = 0 THEN 1 END) as clients_avec_tier_sans_points,
    COUNT(CASE WHEN current_tier_id IS NOT NULL AND loyalty_points > 0 THEN 1 END) as clients_avec_points_et_tier
FROM clients;

-- Rapport final des clients et leurs tiers
SELECT 
    'Rapport final' as info,
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

-- 10. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Tier_id invalides supprimés' as message;
SELECT '✅ Tiers recalculés basés sur les points' as recalcul;
SELECT '✅ Incohérences corrigées' as correction;
SELECT '✅ Synchronisation des points terminée' as synchronisation;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT 'ℹ️ Les points devraient maintenant être cohérents entre les sections' as note;
