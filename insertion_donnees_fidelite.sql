-- INSERTION DES DONNÉES DE BASE POUR LE SYSTÈME DE FIDÉLITÉ
-- Ce script insère les données de configuration et les niveaux par défaut

-- 1. INSÉRER LA CONFIGURATION PAR DÉFAUT
INSERT INTO loyalty_config (key, value, description) VALUES
('points_per_euro', '1', 'Nombre de points attribués par euro dépensé'),
('minimum_purchase_for_points', '5', 'Montant minimum en euros pour obtenir des points'),
('bonus_threshold_50', '50', 'Seuil en euros pour bonus de 10% de points'),
('bonus_threshold_100', '100', 'Seuil en euros pour bonus de 20% de points'),
('bonus_threshold_200', '200', 'Seuil en euros pour bonus de 30% de points'),
('points_expiry_months', '24', 'Durée de validité des points en mois'),
('auto_tier_upgrade', 'true', 'Mise à jour automatique des niveaux de fidélité')
ON CONFLICT (key) DO UPDATE SET
    value = EXCLUDED.value,
    description = EXCLUDED.description,
    updated_at = NOW();

-- 2. INSÉRER LES NIVEAUX DE FIDÉLITÉ PAR DÉFAUT
INSERT INTO loyalty_tiers_advanced (name, description, points_required, discount_percentage, color, benefits, is_active) VALUES
('Bronze', 'Niveau de base', 0, 0, '#CD7F32', ARRAY['Accès aux promotions de base'], true),
('Argent', 'Client régulier', 100, 5, '#C0C0C0', ARRAY['5% de réduction', 'Promotions exclusives'], true),
('Or', 'Client fidèle', 500, 10, '#FFD700', ARRAY['10% de réduction', 'Service prioritaire', 'Garantie étendue'], true),
('Platine', 'Client VIP', 1000, 15, '#E5E4E2', ARRAY['15% de réduction', 'Service VIP', 'Garantie étendue', 'Rendez-vous prioritaires'], true),
('Diamant', 'Client Premium', 2000, 20, '#B9F2FF', ARRAY['20% de réduction', 'Service Premium', 'Garantie étendue', 'Rendez-vous prioritaires', 'Support dédié'], true)
ON CONFLICT DO NOTHING;

-- 3. VÉRIFIER L'INSERTION
SELECT '✅ VÉRIFICATION DES DONNÉES INSÉRÉES' as status;

SELECT '📊 Configuration:' as section;
SELECT key, value, description FROM loyalty_config ORDER BY key;

SELECT '🏆 Niveaux de fidélité:' as section;
SELECT name, points_required, discount_percentage, color, is_active FROM loyalty_tiers_advanced ORDER BY points_required;

-- 4. TESTER LA FONCTION RPC
SELECT '🧪 Test de la fonction RPC:' as section;
SELECT get_loyalty_statistics();

-- 5. MESSAGE DE CONFIRMATION
SELECT '🎉 Données de fidélité insérées avec succès !' as result;
SELECT '📋 Vous pouvez maintenant modifier les paramètres dans l''interface.' as next_step;


