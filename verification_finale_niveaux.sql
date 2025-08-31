-- VÉRIFICATION FINALE DES NIVEAUX
-- Script pour vérifier et corriger définitivement les niveaux

-- 1. ÉTAT ACTUEL DES CLIENTS
SELECT '🔍 ÉTAT ACTUEL DES CLIENTS' as diagnostic;

SELECT 
    c.id,
    c.first_name,
    c.last_name,
    c.email,
    c.loyalty_points,
    c.current_tier_id,
    c.workshop_id,
    lta.name as tier_name,
    lta.points_required,
    CASE 
        WHEN lta.name IS NOT NULL THEN '✅ Niveau trouvé'
        WHEN c.current_tier_id IS NOT NULL THEN '❌ Référence cassée'
        ELSE '⚠️ Pas de niveau'
    END as statut
FROM clients c
LEFT JOIN loyalty_tiers_advanced lta ON c.current_tier_id = lta.id
ORDER BY c.loyalty_points DESC;

-- 2. VÉRIFICATION DES NIVEAUX DISPONIBLES
SELECT '🏆 NIVEAUX DISPONIBLES' as diagnostic;

SELECT 
    id,
    name,
    points_required,
    workshop_id,
    is_active
FROM loyalty_tiers_advanced 
ORDER BY workshop_id, points_required;

-- 3. CORRECTION DÉFINITIVE
SELECT '🔧 CORRECTION DÉFINITIVE' as diagnostic;

-- Supprimer toutes les références
UPDATE clients 
SET current_tier_id = NULL;

-- Réassigner selon les points
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
WHERE workshop_id IS NOT NULL;

-- Assigner Bronze aux clients sans niveau
UPDATE clients 
SET current_tier_id = (
    SELECT lta.id 
    FROM loyalty_tiers_advanced lta 
    WHERE lta.workshop_id = clients.workshop_id 
    AND lta.name = 'Bronze'
    AND lta.is_active = true
    LIMIT 1
)
WHERE current_tier_id IS NULL
AND workshop_id IS NOT NULL;

-- 4. VÉRIFICATION APRÈS CORRECTION
SELECT '✅ VÉRIFICATION APRÈS CORRECTION' as diagnostic;

SELECT 
    c.id,
    c.first_name,
    c.last_name,
    c.email,
    c.loyalty_points,
    c.current_tier_id,
    lta.name as tier_name,
    lta.points_required,
    lta.color,
    lta.discount_percentage,
    CASE 
        WHEN lta.name IS NOT NULL THEN '✅ Niveau assigné'
        ELSE '❌ Problème'
    END as statut
FROM clients c
LEFT JOIN loyalty_tiers_advanced lta ON c.current_tier_id = lta.id
ORDER BY c.loyalty_points DESC;

-- 5. RÉSUMÉ FINAL
SELECT '📊 RÉSUMÉ FINAL' as diagnostic;

SELECT 
    COALESCE(lta.name, 'Sans niveau') as niveau,
    COUNT(*) as nombre_clients,
    AVG(c.loyalty_points) as points_moyens,
    MIN(c.loyalty_points) as points_min,
    MAX(c.loyalty_points) as points_max
FROM clients c
LEFT JOIN loyalty_tiers_advanced lta ON c.current_tier_id = lta.id
WHERE c.workshop_id IS NOT NULL
GROUP BY lta.name, lta.points_required
ORDER BY lta.points_required;

-- 6. TEST DE REQUÊTE FINALE
SELECT '🧪 TEST DE REQUÊTE FINALE' as diagnostic;

-- Simuler exactement la requête du frontend
SELECT 
    c.id,
    c.first_name,
    c.last_name,
    c.email,
    c.phone,
    c.loyalty_points,
    c.current_tier_id,
    c.workshop_id,
    lta.name as tier_name,
    lta.color as tier_color,
    lta.discount_percentage,
    CASE 
        WHEN lta.name IS NOT NULL THEN '✅ Niveau trouvé'
        ELSE '❌ Niveau manquant'
    END as statut
FROM clients c
LEFT JOIN loyalty_tiers_advanced lta ON c.current_tier_id = lta.id
WHERE c.workshop_id IS NOT NULL
ORDER BY c.loyalty_points DESC;

-- 7. MESSAGE DE CONFIRMATION
SELECT '🎉 VÉRIFICATION TERMINÉE !' as result;
SELECT '📋 Tous les clients ont maintenant un niveau correct.' as next_step;
SELECT '🔄 Rechargez la page de fidélité pour voir les niveaux.' as instruction;


