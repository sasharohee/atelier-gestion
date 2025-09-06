-- DIAGNOSTIC : POURQUOI LES NIVEAUX ACTUELS NE S'AFFICHENT PAS
-- Ce script vérifie la relation entre clients et niveaux de fidélité

-- 1. VÉRIFIER LES CLIENTS ET LEURS POINTS
SELECT '👤 CLIENTS ET POINTS' as diagnostic;

SELECT 
    id,
    first_name,
    last_name,
    email,
    loyalty_points,
    current_tier_id,
    created_at
FROM clients
WHERE loyalty_points > 0
ORDER BY loyalty_points DESC;

-- 2. VÉRIFIER LES NIVEAUX DISPONIBLES
SELECT '🏆 NIVEAUX DISPONIBLES' as diagnostic;

SELECT 
    id,
    name,
    points_required,
    discount_percentage,
    is_active
FROM loyalty_tiers_advanced
ORDER BY points_required;

-- 3. VÉRIFIER LES RELATIONS CLIENTS-NIVEAUX
SELECT '🔗 RELATIONS CLIENTS-NIVEAUX' as diagnostic;

SELECT 
    c.id as client_id,
    c.first_name,
    c.last_name,
    c.loyalty_points,
    c.current_tier_id,
    lt.id as tier_id,
    lt.name as tier_name,
    lt.points_required,
    CASE 
        WHEN c.current_tier_id IS NULL THEN '❌ Aucun niveau assigné'
        WHEN lt.id IS NULL THEN '❌ Niveau introuvable'
        ELSE '✅ Niveau correct'
    END as status
FROM clients c
LEFT JOIN loyalty_tiers_advanced lt ON c.current_tier_id = lt.id
WHERE c.loyalty_points > 0
ORDER BY c.loyalty_points DESC;

-- 4. CALCULER LES NIVEAUX THÉORIQUES
SELECT '🧮 NIVEAUX THÉORIQUES' as diagnostic;

SELECT 
    c.id as client_id,
    c.first_name,
    c.last_name,
    c.loyalty_points,
    c.current_tier_id as niveau_actuel_id,
    lt_actuel.name as niveau_actuel_nom,
    lt_theorique.id as niveau_theorique_id,
    lt_theorique.name as niveau_theorique_nom,
    lt_theorique.points_required,
    CASE 
        WHEN c.current_tier_id = lt_theorique.id THEN '✅ Correct'
        WHEN c.current_tier_id IS NULL THEN '⚠️ Non assigné'
        ELSE '❌ Incorrect'
    END as statut
FROM clients c
LEFT JOIN loyalty_tiers_advanced lt_actuel ON c.current_tier_id = lt_actuel.id
LEFT JOIN loyalty_tiers_advanced lt_theorique ON c.loyalty_points >= lt_theorique.points_required
    AND lt_theorique.is_active = true
    AND lt_theorique.points_required = (
        SELECT MAX(points_required) 
        FROM loyalty_tiers_advanced 
        WHERE points_required <= c.loyalty_points 
        AND is_active = true
    )
WHERE c.loyalty_points > 0
ORDER BY c.loyalty_points DESC;

-- 5. CORRIGER LES NIVEAUX MANQUANTS
SELECT '🔧 CORRECTION DES NIVEAUX' as diagnostic;

-- Mettre à jour les clients qui n'ont pas de niveau assigné
UPDATE clients 
SET current_tier_id = (
    SELECT id 
    FROM loyalty_tiers_advanced 
    WHERE points_required <= clients.loyalty_points 
    AND is_active = true
    ORDER BY points_required DESC 
    LIMIT 1
)
WHERE current_tier_id IS NULL 
AND loyalty_points > 0;

-- 6. VÉRIFICATION APRÈS CORRECTION
SELECT '✅ VÉRIFICATION APRÈS CORRECTION' as diagnostic;

SELECT 
    c.id as client_id,
    c.first_name,
    c.last_name,
    c.loyalty_points,
    c.current_tier_id,
    lt.name as niveau_nom,
    lt.points_required,
    lt.discount_percentage
FROM clients c
LEFT JOIN loyalty_tiers_advanced lt ON c.current_tier_id = lt.id
WHERE c.loyalty_points > 0
ORDER BY c.loyalty_points DESC;

-- 7. MESSAGE DE CONFIRMATION
SELECT '🎉 DIAGNOSTIC TERMINÉ !' as result;
SELECT '📋 Les niveaux devraient maintenant s''afficher correctement.' as next_step;





