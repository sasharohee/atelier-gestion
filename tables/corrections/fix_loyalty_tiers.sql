-- Script de correction rapide pour les niveaux de fidélité
-- Ce script vérifie et crée les niveaux de fidélité nécessaires

-- 1. Vérifier les niveaux existants
SELECT '=== VÉRIFICATION NIVEAUX EXISTANTS ===' as etape;

SELECT 
    id,
    name,
    points_required,
    discount_percentage,
    color
FROM loyalty_tiers_advanced 
ORDER BY points_required;

-- 2. Créer la table si elle n'existe pas
CREATE TABLE IF NOT EXISTS loyalty_tiers_advanced (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    points_required INTEGER NOT NULL DEFAULT 0,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    color TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Insérer les niveaux s'ils n'existent pas
INSERT INTO loyalty_tiers_advanced (id, name, description, points_required, discount_percentage, color) 
SELECT * FROM (VALUES
    ('11111111-1111-1111-1111-111111111111', 'Bronze', 'Niveau de base', 0, 0.00, '#CD7F32'),
    ('22222222-2222-2222-2222-222222222222', 'Argent', 'Client régulier', 100, 5.00, '#C0C0C0'),
    ('33333333-3333-3333-3333-333333333333', 'Or', 'Client fidèle', 500, 10.00, '#FFD700'),
    ('44444444-4444-4444-4444-444444444444', 'Platine', 'Client VIP', 1000, 15.00, '#E5E4E2'),
    ('55555555-5555-5555-5555-555555555555', 'Diamant', 'Client Premium', 2000, 20.00, '#B9F2FF')
) AS v(id, name, description, points_required, discount_percentage, color)
WHERE NOT EXISTS (
    SELECT 1 FROM loyalty_tiers_advanced WHERE name = v.name
);

-- 4. Vérification finale
SELECT '=== VÉRIFICATION FINALE ===' as etape;

SELECT 
    COUNT(*) as total_niveaux,
    string_agg(name, ', ' ORDER BY points_required) as niveaux_disponibles
FROM loyalty_tiers_advanced;

-- 5. Test avec les clients existants
SELECT '=== TEST AVEC CLIENTS ===' as etape;

SELECT 
    c.first_name,
    c.last_name,
    c.loyalty_points,
    c.current_tier_id,
    lta.name as tier_name,
    lta.color as tier_color
FROM clients c
LEFT JOIN loyalty_tiers_advanced lta ON c.current_tier_id = lta.id
WHERE c.loyalty_points > 0 OR c.current_tier_id IS NOT NULL
ORDER BY c.loyalty_points DESC;
