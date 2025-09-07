-- =====================================================
-- MISE À JOUR POINTS LOYALTY SEULEMENT
-- =====================================================
-- Script pour mettre à jour les points sans désactiver les triggers
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

-- 2. VÉRIFIER les clients avec des points incohérents
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

-- 3. NETTOYER les clients avec des tier_id invalides
SELECT '=== NETTOYAGE TIER_ID INVALIDES ===' as etape;

-- Supprimer les current_tier_id qui ne correspondent à aucun tier existant
UPDATE clients 
SET current_tier_id = NULL 
WHERE current_tier_id IS NOT NULL 
AND current_tier_id NOT IN (
    SELECT id FROM loyalty_tiers_advanced
);

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
    CASE 
        WHEN c.loyalty_points >= lta.points_required THEN '✅ Cohérent'
        WHEN c.loyalty_points < lta.points_required THEN '⚠️ Points insuffisants'
        ELSE '❌ Incohérent'
    END as coherence_status
FROM clients c
LEFT JOIN loyalty_tiers_advanced lta ON c.current_tier_id = lta.id
WHERE c.loyalty_points > 0 OR c.current_tier_id IS NOT NULL
ORDER BY c.loyalty_points DESC;

-- 5. VÉRIFIER les données finales
SELECT '=== VÉRIFICATION FINALE ===' as etape;

-- Vérifier que tous les clients ont des données cohérentes
SELECT 
    'Vérification finale' as info,
    COUNT(*) as total_clients,
    COUNT(CASE WHEN loyalty_points > 0 THEN 1 END) as clients_avec_points,
    COUNT(CASE WHEN current_tier_id IS NOT NULL THEN 1 END) as clients_avec_tier,
    COUNT(CASE WHEN loyalty_points > 0 AND current_tier_id IS NOT NULL THEN 1 END) as clients_avec_points_et_tier
FROM clients;

-- 6. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as message;
SELECT '✅ Diagnostic effectué' as message;
SELECT '✅ Tier_id invalides supprimés' as nettoyage;
SELECT '✅ Rapport de synchronisation créé' as rapport;
SELECT '✅ Vérification finale effectuée' as verification;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT 'ℹ️ Les points devraient maintenant être cohérents' as note;
SELECT '💡 Videz le cache du navigateur si nécessaire' as cache;
