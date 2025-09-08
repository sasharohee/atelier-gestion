-- Script de création des configurations de fidélité
-- Ce script crée les configurations nécessaires pour que les paramètres fonctionnent

-- 1. Créer la table de configuration si elle n'existe pas
CREATE TABLE IF NOT EXISTS loyalty_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT UNIQUE NOT NULL,
    value TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Insérer les configurations par défaut
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

-- 3. Vérifier les configurations créées
SELECT '=== CONFIGURATIONS CRÉÉES ===' as etape;

SELECT 
    key,
    value,
    description
FROM loyalty_config 
ORDER BY key;

-- 4. Compter les configurations
SELECT 
    COUNT(*) as total_configurations,
    string_agg(key, ', ') as configurations_disponibles
FROM loyalty_config;
