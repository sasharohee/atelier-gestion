-- =====================================================
-- CORRECTION RAPIDE NIVEAU ACTUEL
-- =====================================================
-- Problème : La colonne "Niveau Actuel" ne s'affiche pas
-- Solution rapide : Mettre à jour les current_tier_id manquants
-- =====================================================

-- 1. Mettre à jour tous les niveaux actuels manquants
UPDATE client_loyalty_points 
SET current_tier_id = (
    SELECT id 
    FROM loyalty_tiers 
    WHERE min_points <= (client_loyalty_points.total_points - client_loyalty_points.used_points)
    ORDER BY min_points DESC 
    LIMIT 1
)
WHERE current_tier_id IS NULL;

-- 2. Vérifier le résultat
SELECT 
    c.first_name,
    c.last_name,
    clp.total_points,
    clp.used_points,
    (clp.total_points - clp.used_points) as points_disponibles,
    lt.name as niveau_actuel,
    lt.color as couleur_niveau
FROM client_loyalty_points clp
LEFT JOIN clients c ON clp.client_id = c.id
LEFT JOIN loyalty_tiers lt ON clp.current_tier_id = lt.id
ORDER BY (clp.total_points - clp.used_points) DESC;

SELECT '✅ Correction rapide terminée' as status;
