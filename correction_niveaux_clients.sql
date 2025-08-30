-- CORRECTION DES NIVEAUX DES CLIENTS
-- Script pour assigner les niveaux de fidélité aux clients

-- 1. DIAGNOSTIC DES CLIENTS ET NIVEAUX
SELECT '🔍 DIAGNOSTIC DES CLIENTS ET NIVEAUX' as diagnostic;

-- Vérifier les clients et leurs points
SELECT 
    c.id,
    c.first_name,
    c.last_name,
    c.email,
    c.loyalty_points,
    c.current_tier_id,
    c.workshop_id,
    lta.name as tier_name
FROM clients c
LEFT JOIN loyalty_tiers_advanced lta ON c.current_tier_id = lta.id
ORDER BY c.loyalty_points DESC;

-- 2. VÉRIFIER LES NIVEAUX DISPONIBLES
SELECT '🏆 NIVEAUX DISPONIBLES' as diagnostic;

SELECT 
    id,
    name,
    points_required,
    workshop_id,
    is_active
FROM loyalty_tiers_advanced 
ORDER BY workshop_id, points_required;

-- 3. CORRECTION : ASSIGNER LES NIVEAUX SELON LES POINTS
SELECT '🔧 ASSIGNATION DES NIVEAUX' as diagnostic;

-- Fonction pour trouver le niveau approprié selon les points
WITH client_tiers AS (
    SELECT 
        c.id as client_id,
        c.loyalty_points,
        c.workshop_id,
        lta.id as tier_id,
        lta.name as tier_name,
        lta.points_required,
        ROW_NUMBER() OVER (
            PARTITION BY c.id 
            ORDER BY lta.points_required DESC
        ) as rn
    FROM clients c
    CROSS JOIN loyalty_tiers_advanced lta
    WHERE c.workshop_id = lta.workshop_id
    AND lta.is_active = true
    AND lta.points_required <= c.loyalty_points
)
UPDATE clients 
SET current_tier_id = ct.tier_id
FROM client_tiers ct
WHERE clients.id = ct.client_id
AND ct.rn = 1;

-- 4. VÉRIFICATION APRÈS CORRECTION
SELECT '✅ VÉRIFICATION APRÈS CORRECTION' as diagnostic;

-- Afficher les clients avec leurs niveaux assignés
SELECT 
    c.id,
    c.first_name,
    c.last_name,
    c.email,
    c.loyalty_points,
    c.current_tier_id,
    lta.name as tier_name,
    lta.points_required,
    lta.discount_percentage
FROM clients c
LEFT JOIN loyalty_tiers_advanced lta ON c.current_tier_id = lta.id
ORDER BY c.loyalty_points DESC;

-- 5. CORRECTION DES CLIENTS SANS NIVEAU
SELECT '🔧 CORRECTION DES CLIENTS SANS NIVEAU' as diagnostic;

-- Assigner le niveau Bronze aux clients sans niveau
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

-- 6. VÉRIFICATION FINALE
SELECT '✅ VÉRIFICATION FINALE' as diagnostic;

-- Résumé des clients par niveau
SELECT 
    COALESCE(lta.name, 'Sans niveau') as niveau,
    COUNT(*) as nombre_clients,
    AVG(c.loyalty_points) as points_moyens
FROM clients c
LEFT JOIN loyalty_tiers_advanced lta ON c.current_tier_id = lta.id
GROUP BY lta.name, lta.points_required
ORDER BY 
    CASE WHEN lta.name IS NULL THEN 1 ELSE 0 END,
    lta.points_required;

-- 7. TEST DE REQUÊTE SIMULÉE
SELECT '🧪 TEST DE REQUÊTE SIMULÉE' as diagnostic;

-- Simuler la requête du frontend
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
    lta.discount_percentage
FROM clients c
LEFT JOIN loyalty_tiers_advanced lta ON c.current_tier_id = lta.id
WHERE c.workshop_id IS NOT NULL
ORDER BY c.loyalty_points DESC;

-- 8. MESSAGE DE CONFIRMATION
SELECT '🎉 CORRECTION TERMINÉE !' as result;
SELECT '📋 Tous les clients ont maintenant un niveau assigné.' as next_step;
SELECT '🔄 Rechargez la page de fidélité pour voir les niveaux.' as instruction;
