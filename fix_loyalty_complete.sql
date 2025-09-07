-- Script complet de correction de la fidélité
-- Ce script corrige les niveaux ET les configurations

-- ===========================================
-- PARTIE 1: CORRECTION DES NIVEAUX
-- ===========================================

-- 1. Vérifier l'état actuel des niveaux
SELECT '=== ÉTAT ACTUEL NIVEAUX ===' as etape;

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

-- 4. Mettre à jour les clients avec les nouveaux IDs de niveaux
SELECT '=== MISE À JOUR CLIENTS ===' as etape;

UPDATE clients 
SET current_tier_id = CASE
    WHEN loyalty_points >= 2000 THEN '55555555-5555-5555-5555-555555555555' -- Diamant
    WHEN loyalty_points >= 1000 THEN '44444444-4444-4444-4444-444444444444' -- Platine
    WHEN loyalty_points >= 500 THEN '33333333-3333-3333-3333-333333333333'  -- Or
    WHEN loyalty_points >= 100 THEN '22222222-2222-2222-2222-222222222222'  -- Argent
    ELSE '11111111-1111-1111-1111-111111111111'                              -- Bronze
END
WHERE loyalty_points > 0 OR current_tier_id IS NOT NULL;

-- ===========================================
-- PARTIE 2: CORRECTION DES CONFIGURATIONS
-- ===========================================

-- 5. Créer la table de configuration si elle n'existe pas
SELECT '=== CRÉATION TABLE CONFIG ===' as etape;

CREATE TABLE IF NOT EXISTS loyalty_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT UNIQUE NOT NULL,
    value TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Insérer les configurations par défaut
SELECT '=== INSERTION CONFIGURATIONS ===' as etape;

INSERT INTO loyalty_config (key, value, description) VALUES
('points_per_euro', '1', 'Points attribués par euro dépensé'),
('referral_points', '50', 'Points attribués pour un parrainage confirmé'),
('min_points_redemption', '100', 'Nombre minimum de points pour une réduction'),
('points_to_euro_ratio', '100', 'Nombre de points équivalent à 1 euro de réduction'),
('auto_tier_update', 'true', 'Mise à jour automatique des niveaux'),
('email_notifications', 'true', 'Notifications par email'),
('sms_notifications', 'false', 'Notifications par SMS'),
('loyalty_system_active', 'true', 'Système de fidélité activé')
ON CONFLICT (key) DO UPDATE SET 
    value = EXCLUDED.value,
    updated_at = NOW();

-- ===========================================
-- PARTIE 3: VÉRIFICATIONS FINALES
-- ===========================================

-- 7. Vérifier les niveaux créés
SELECT '=== VÉRIFICATION NIVEAUX ===' as etape;

SELECT 
    id,
    name,
    points_required,
    discount_percentage,
    color
FROM loyalty_tiers_advanced 
ORDER BY points_required;

-- 8. Vérifier les configurations créées
SELECT '=== VÉRIFICATION CONFIGURATIONS ===' as etape;

SELECT 
    key,
    value,
    description
FROM loyalty_config 
ORDER BY key;

-- 9. Vérifier les clients mis à jour
SELECT '=== VÉRIFICATION CLIENTS ===' as etape;

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

-- 10. Résumé final
SELECT '=== RÉSUMÉ FINAL ===' as etape;

SELECT 
    (SELECT COUNT(*) FROM loyalty_tiers_advanced) as niveaux_crees,
    (SELECT COUNT(*) FROM loyalty_config) as configurations_creees,
    (SELECT COUNT(*) FROM clients WHERE loyalty_points > 0) as clients_avec_points;
