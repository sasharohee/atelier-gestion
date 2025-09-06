-- NETTOYAGE DES DOUBLONS DANS LE SYSTÈME DE FIDÉLITÉ
-- Ce script supprime les doublons et garde une seule entrée par niveau

-- 1. VÉRIFIER LES DOUBLONS ACTUELS
SELECT '🔍 VÉRIFICATION DES DOUBLONS' as action;

SELECT '📊 Doublons dans loyalty_config:' as section;
SELECT key, COUNT(*) as nombre_doublons
FROM loyalty_config
GROUP BY key
HAVING COUNT(*) > 1
ORDER BY key;

SELECT '🏆 Doublons dans loyalty_tiers_advanced:' as section;
SELECT name, COUNT(*) as nombre_doublons
FROM loyalty_tiers_advanced
GROUP BY name
HAVING COUNT(*) > 1
ORDER BY name;

-- 2. NETTOYER LES DOUBLONS DE CONFIGURATION
SELECT '🧹 NETTOYAGE CONFIGURATION' as action;

-- Supprimer tous les enregistrements de configuration
DELETE FROM loyalty_config;

-- Réinsérer une seule fois chaque configuration
INSERT INTO loyalty_config (key, value, description) VALUES
('points_per_euro', '1', 'Nombre de points attribués par euro dépensé'),
('minimum_purchase_for_points', '5', 'Montant minimum en euros pour obtenir des points'),
('bonus_threshold_50', '50', 'Seuil en euros pour bonus de 10% de points'),
('bonus_threshold_100', '100', 'Seuil en euros pour bonus de 20% de points'),
('bonus_threshold_200', '200', 'Seuil en euros pour bonus de 30% de points'),
('points_expiry_months', '24', 'Durée de validité des points en mois'),
('auto_tier_upgrade', 'true', 'Mise à jour automatique des niveaux de fidélité');

-- 3. NETTOYER LES DOUBLONS DE NIVEAUX
SELECT '🧹 NETTOYAGE NIVEAUX' as action;

-- Supprimer tous les enregistrements de niveaux
DELETE FROM loyalty_tiers_advanced;

-- Réinsérer une seule fois chaque niveau
INSERT INTO loyalty_tiers_advanced (name, description, points_required, discount_percentage, color, benefits, is_active) VALUES
('Bronze', 'Niveau de base', 0, 0, '#CD7F32', ARRAY['Accès aux promotions de base'], true),
('Argent', 'Client régulier', 100, 5, '#C0C0C0', ARRAY['5% de réduction', 'Promotions exclusives'], true),
('Or', 'Client fidèle', 500, 10, '#FFD700', ARRAY['10% de réduction', 'Service prioritaire', 'Garantie étendue'], true),
('Platine', 'Client VIP', 1000, 15, '#E5E4E2', ARRAY['15% de réduction', 'Service VIP', 'Garantie étendue', 'Rendez-vous prioritaires'], true),
('Diamant', 'Client Premium', 2000, 20, '#B9F2FF', ARRAY['20% de réduction', 'Service Premium', 'Garantie étendue', 'Rendez-vous prioritaires', 'Support dédié'], true);

-- 4. VÉRIFIER LE NETTOYAGE
SELECT '✅ VÉRIFICATION DU NETTOYAGE' as action;

SELECT '📊 Configuration après nettoyage:' as section;
SELECT key, value, description FROM loyalty_config ORDER BY key;

SELECT '🏆 Niveaux après nettoyage:' as section;
SELECT name, points_required, discount_percentage, color, is_active FROM loyalty_tiers_advanced ORDER BY points_required;

-- 5. COMPTER LES ENREGISTREMENTS
SELECT '📊 COMPTAGE FINAL' as action;

SELECT 
    'loyalty_config' as table_name,
    COUNT(*) as total_records
FROM loyalty_config
UNION ALL
SELECT 
    'loyalty_tiers_advanced' as table_name,
    COUNT(*) as total_records
FROM loyalty_tiers_advanced;

-- 6. MESSAGE DE CONFIRMATION
SELECT '🎉 NETTOYAGE TERMINÉ !' as result;
SELECT '📋 Chaque niveau n''apparaît plus qu''une seule fois.' as next_step;





