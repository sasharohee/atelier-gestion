-- NETTOYAGE COMPLET DES DOUBLONS MASSIFS
-- Ce script supprime TOUS les enregistrements et recrée des données propres

-- 1. VÉRIFIER L'ÉTAT ACTUEL
SELECT '🔍 ÉTAT ACTUEL' as action;

SELECT '📊 Nombre total de configurations:' as info;
SELECT COUNT(*) as total_config FROM loyalty_config;

SELECT '🏆 Nombre total de niveaux:' as info;
SELECT COUNT(*) as total_tiers FROM loyalty_tiers_advanced;

SELECT '📋 Répartition des niveaux:' as info;
SELECT name, COUNT(*) as nombre
FROM loyalty_tiers_advanced
GROUP BY name
ORDER BY name;

-- 2. SUPPRIMER TOUT
SELECT '🗑️ SUPPRESSION COMPLÈTE' as action;

-- Vider complètement les tables
TRUNCATE TABLE loyalty_config RESTART IDENTITY CASCADE;
TRUNCATE TABLE loyalty_tiers_advanced RESTART IDENTITY CASCADE;

-- 3. RÉINSÉRER LES DONNÉES PROPRES
SELECT '📝 RÉINSERTION DES DONNÉES PROPRES' as action;

-- Configuration propre
INSERT INTO loyalty_config (key, value, description) VALUES
('points_per_euro', '1', 'Nombre de points attribués par euro dépensé'),
('minimum_purchase_for_points', '5', 'Montant minimum en euros pour obtenir des points'),
('bonus_threshold_50', '50', 'Seuil en euros pour bonus de 10% de points'),
('bonus_threshold_100', '100', 'Seuil en euros pour bonus de 20% de points'),
('bonus_threshold_200', '200', 'Seuil en euros pour bonus de 30% de points'),
('points_expiry_months', '24', 'Durée de validité des points en mois'),
('auto_tier_upgrade', 'true', 'Mise à jour automatique des niveaux de fidélité');

-- Niveaux propres (un seul de chaque)
INSERT INTO loyalty_tiers_advanced (name, description, points_required, discount_percentage, color, benefits, is_active) VALUES
('Bronze', 'Niveau de base', 0, 0, '#CD7F32', ARRAY['Accès aux promotions de base'], true),
('Argent', 'Client régulier', 100, 5, '#C0C0C0', ARRAY['5% de réduction', 'Promotions exclusives'], true),
('Or', 'Client fidèle', 500, 10, '#FFD700', ARRAY['10% de réduction', 'Service prioritaire', 'Garantie étendue'], true),
('Platine', 'Client VIP', 1000, 15, '#E5E4E2', ARRAY['15% de réduction', 'Service VIP', 'Garantie étendue', 'Rendez-vous prioritaires'], true),
('Diamant', 'Client Premium', 2000, 20, '#B9F2FF', ARRAY['20% de réduction', 'Service Premium', 'Garantie étendue', 'Rendez-vous prioritaires', 'Support dédié'], true);

-- 4. VÉRIFICATION FINALE
SELECT '✅ VÉRIFICATION FINALE' as action;

SELECT '📊 Configuration finale:' as section;
SELECT key, value, description FROM loyalty_config ORDER BY key;

SELECT '🏆 Niveaux finaux:' as section;
SELECT name, points_required, discount_percentage, color, is_active FROM loyalty_tiers_advanced ORDER BY points_required;

SELECT '📊 Comptage final:' as section;
SELECT 
    'loyalty_config' as table_name,
    COUNT(*) as total_records
FROM loyalty_config
UNION ALL
SELECT 
    'loyalty_tiers_advanced' as table_name,
    COUNT(*) as total_records
FROM loyalty_tiers_advanced;

-- 5. MESSAGE DE CONFIRMATION
SELECT '🎉 NETTOYAGE COMPLET TERMINÉ !' as result;
SELECT '📋 Vous devriez maintenant avoir exactement 7 configurations et 5 niveaux uniques.' as next_step;


