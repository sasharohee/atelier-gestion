-- CORRECTION DES RÉFÉRENCES DES NIVEAUX
-- Script pour corriger les current_tier_id des clients

-- 1. DIAGNOSTIC DES RÉFÉRENCES
SELECT '🔍 DIAGNOSTIC DES RÉFÉRENCES' as diagnostic;

-- Vérifier les clients et leurs références
SELECT 
    c.id,
    c.first_name,
    c.last_name,
    c.loyalty_points,
    c.current_tier_id,
    c.workshop_id,
    lta.id as tier_id,
    lta.name as tier_name,
    lta.points_required
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

-- 3. CORRECTION : RÉASSIGNER LES NIVEAUX SELON LES POINTS
SELECT '🔧 RÉASSIGNATION DES NIVEAUX' as diagnostic;

-- Supprimer toutes les références incorrectes
UPDATE clients 
SET current_tier_id = NULL;

-- Réassigner les niveaux selon les points
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

-- 4. CORRECTION DES CLIENTS SANS NIVEAU
SELECT '🔧 CORRECTION DES CLIENTS SANS NIVEAU' as diagnostic;

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

-- 5. VÉRIFICATION APRÈS CORRECTION
SELECT '✅ VÉRIFICATION APRÈS CORRECTION' as diagnostic;

-- Afficher les clients avec leurs nouveaux niveaux
SELECT 
    c.id,
    c.first_name,
    c.last_name,
    c.email,
    c.loyalty_points,
    c.current_tier_id,
    lta.name as tier_name,
    lta.points_required,
    lta.discount_percentage,
    lta.color
FROM clients c
LEFT JOIN loyalty_tiers_advanced lta ON c.current_tier_id = lta.id
ORDER BY c.loyalty_points DESC;

-- 6. TEST DE CORRESPONDANCE
SELECT '🧪 TEST DE CORRESPONDANCE' as diagnostic;

-- Vérifier que tous les clients ont un niveau valide
SELECT 
    COUNT(*) as total_clients,
    COUNT(CASE WHEN current_tier_id IS NOT NULL THEN 1 END) as clients_avec_niveau,
    COUNT(CASE WHEN current_tier_id IS NULL THEN 1 END) as clients_sans_niveau
FROM clients
WHERE workshop_id IS NOT NULL;

-- 7. RÉSUMÉ PAR NIVEAU
SELECT '📊 RÉSUMÉ PAR NIVEAU' as diagnostic;

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

-- 8. TEST DE REQUÊTE FINALE
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

-- 9. MESSAGE DE CONFIRMATION
SELECT '🎉 CORRECTION TERMINÉE !' as result;
SELECT '📋 Toutes les références ont été corrigées.' as next_step;
SELECT '🔄 Rechargez la page de fidélité pour voir les niveaux.' as instruction;


