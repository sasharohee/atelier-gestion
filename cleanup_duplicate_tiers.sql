-- Script de nettoyage des doublons de niveaux de fidélité
-- Ce script supprime les doublons et garde seulement les niveaux uniques

-- 1. Vérifier l'état actuel
SELECT '=== ÉTAT ACTUEL ===' as etape;

SELECT 
    name,
    COUNT(*) as nombre_doublons,
    string_agg(id::text, ', ') as ids
FROM loyalty_tiers_advanced 
GROUP BY name
ORDER BY name;

-- 2. Supprimer tous les niveaux existants
SELECT '=== SUPPRESSION TOUS NIVEAUX ===' as etape;

DELETE FROM loyalty_tiers_advanced;

-- 3. Recréer les niveaux uniques avec des IDs fixes
SELECT '=== CRÉATION NIVEAUX UNIQUES ===' as etape;

INSERT INTO loyalty_tiers_advanced (id, name, description, points_required, discount_percentage, color, is_active) VALUES
('11111111-1111-1111-1111-111111111111', 'Bronze', 'Niveau de base', 0, 0.00, '#CD7F32', true),
('22222222-2222-2222-2222-222222222222', 'Argent', 'Client régulier', 100, 5.00, '#C0C0C0', true),
('33333333-3333-3333-3333-333333333333', 'Or', 'Client fidèle', 500, 10.00, '#FFD700', true),
('44444444-4444-4444-4444-444444444444', 'Platine', 'Client VIP', 1000, 15.00, '#E5E4E2', true),
('55555555-5555-5555-5555-555555555555', 'Diamant', 'Client Premium', 2000, 20.00, '#B9F2FF', true);

-- 4. Vérification finale
SELECT '=== VÉRIFICATION FINALE ===' as etape;

SELECT 
    id,
    name,
    points_required,
    discount_percentage,
    color
FROM loyalty_tiers_advanced 
ORDER BY points_required;

-- 5. Compter les niveaux
SELECT 
    COUNT(*) as total_niveaux,
    string_agg(name, ', ' ORDER BY points_required) as niveaux_disponibles
FROM loyalty_tiers_advanced;

-- 6. Mettre à jour les clients avec les nouveaux IDs de niveaux
SELECT '=== MISE À JOUR CLIENTS ===' as etape;

-- Mettre à jour les clients selon leurs points
UPDATE clients 
SET current_tier_id = CASE
    WHEN loyalty_points >= 2000 THEN '55555555-5555-5555-5555-555555555555' -- Diamant
    WHEN loyalty_points >= 1000 THEN '44444444-4444-4444-4444-444444444444' -- Platine
    WHEN loyalty_points >= 500 THEN '33333333-3333-3333-3333-333333333333'  -- Or
    WHEN loyalty_points >= 100 THEN '22222222-2222-2222-2222-222222222222'  -- Argent
    ELSE '11111111-1111-1111-1111-111111111111'                              -- Bronze
END
WHERE loyalty_points > 0 OR current_tier_id IS NOT NULL;

-- 7. Vérifier les clients mis à jour
SELECT 
    c.first_name,
    c.last_name,
    c.loyalty_points,
    lta.name as tier_name,
    lta.color as tier_color
FROM clients c
LEFT JOIN loyalty_tiers_advanced lta ON c.current_tier_id = lta.id
WHERE c.loyalty_points > 0 OR c.current_tier_id IS NOT NULL
ORDER BY c.loyalty_points DESC;
