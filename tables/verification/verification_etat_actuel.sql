-- VÉRIFICATION ET CORRECTION DE L'ÉTAT ACTUEL
-- Script simple pour diagnostiquer et corriger le problème des niveaux

-- 1. VÉRIFIER L'ÉTAT ACTUEL DES CLIENTS
SELECT '🔍 ÉTAT ACTUEL DES CLIENTS' as diagnostic;

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
    is_active,
    created_at
FROM loyalty_tiers_advanced 
ORDER BY points_required;

-- 3. VÉRIFIER LES RELATIONS
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

-- 4. CORRIGER LES NIVEAUX MANQUANTS
SELECT '🔧 CORRECTION EN COURS...' as diagnostic;

-- Supprimer les anciennes relations incorrectes
UPDATE clients 
SET current_tier_id = NULL 
WHERE current_tier_id IS NOT NULL 
AND loyalty_points > 0;

-- Assigner les nouveaux niveaux selon les points
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

-- 5. VÉRIFICATION APRÈS CORRECTION
SELECT '✅ VÉRIFICATION APRÈS CORRECTION' as diagnostic;

SELECT 
    c.id as client_id,
    c.first_name,
    c.last_name,
    c.loyalty_points,
    c.current_tier_id,
    lt.name as niveau_nom,
    lt.points_required,
    lt.discount_percentage,
    CASE 
        WHEN c.current_tier_id IS NOT NULL THEN '✅ Niveau assigné'
        ELSE '❌ Aucun niveau'
    END as statut
FROM clients c
LEFT JOIN loyalty_tiers_advanced lt ON c.current_tier_id = lt.id
WHERE c.loyalty_points > 0
ORDER BY c.loyalty_points DESC;

-- 6. MESSAGE DE CONFIRMATION
SELECT '🎉 CORRECTION TERMINÉE !' as result;
SELECT '📋 Rafraîchissez la page pour voir les changements.' as next_step;





