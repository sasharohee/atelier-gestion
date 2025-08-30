-- CORRECTION FINALE DES POLITIQUES RLS POUR LE SYSTÈME DE FIDÉLITÉ
-- Ce script corrige définitivement les permissions d'accès

-- 1. DÉSACTIVER TEMPORAIREMENT RLS POUR LES TESTS
SELECT '🔧 DÉSACTIVATION TEMPORAIRE RLS' as action;

ALTER TABLE loyalty_config DISABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_tiers_advanced DISABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_points_history DISABLE ROW LEVEL SECURITY;

-- 2. SUPPRIMER TOUTES LES ANCIENNES POLITIQUES
SELECT '🗑️ SUPPRESSION DES ANCIENNES POLITIQUES' as action;

-- Supprimer toutes les politiques existantes sur loyalty_config
DROP POLICY IF EXISTS loyalty_config_select_policy ON loyalty_config;
DROP POLICY IF EXISTS loyalty_config_insert_policy ON loyalty_config;
DROP POLICY IF EXISTS loyalty_config_update_policy ON loyalty_config;
DROP POLICY IF EXISTS loyalty_config_delete_policy ON loyalty_config;
DROP POLICY IF EXISTS loyalty_config_all_policy ON loyalty_config;

-- Supprimer toutes les politiques existantes sur loyalty_tiers_advanced
DROP POLICY IF EXISTS loyalty_tiers_select_policy ON loyalty_tiers_advanced;
DROP POLICY IF EXISTS loyalty_tiers_insert_policy ON loyalty_tiers_advanced;
DROP POLICY IF EXISTS loyalty_tiers_update_policy ON loyalty_tiers_advanced;
DROP POLICY IF EXISTS loyalty_tiers_delete_policy ON loyalty_tiers_advanced;
DROP POLICY IF EXISTS loyalty_tiers_all_policy ON loyalty_tiers_advanced;

-- Supprimer toutes les politiques existantes sur loyalty_points_history
DROP POLICY IF EXISTS loyalty_points_select_policy ON loyalty_points_history;
DROP POLICY IF EXISTS loyalty_points_insert_policy ON loyalty_points_history;
DROP POLICY IF EXISTS loyalty_points_update_policy ON loyalty_points_history;
DROP POLICY IF EXISTS loyalty_points_delete_policy ON loyalty_points_history;
DROP POLICY IF EXISTS loyalty_points_all_policy ON loyalty_points_history;

-- 3. RÉACTIVER RLS
SELECT '🔒 RÉACTIVATION RLS' as action;

ALTER TABLE loyalty_config ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_tiers_advanced ENABLE ROW LEVEL SECURITY;
ALTER TABLE loyalty_points_history ENABLE ROW LEVEL SECURITY;

-- 4. CRÉER DES POLITIQUES PERMISSIVES POUR L'ADMINISTRATION
SELECT '✅ CRÉATION DE POLITIQUES PERMISSIVES' as action;

-- Politiques pour loyalty_config - Accès complet pour tous les utilisateurs authentifiés
CREATE POLICY loyalty_config_all_policy ON loyalty_config
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Politiques pour loyalty_tiers_advanced - Accès complet pour tous les utilisateurs authentifiés
CREATE POLICY loyalty_tiers_all_policy ON loyalty_tiers_advanced
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- Politiques pour loyalty_points_history - Accès complet pour tous les utilisateurs authentifiés
CREATE POLICY loyalty_points_all_policy ON loyalty_points_history
    FOR ALL
    TO authenticated
    USING (true)
    WITH CHECK (true);

-- 5. VÉRIFIER QUE LES POLITIQUES SONT CRÉÉES
SELECT '🔍 VÉRIFICATION DES POLITIQUES' as action;

SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename IN ('loyalty_config', 'loyalty_tiers_advanced', 'loyalty_points_history')
AND schemaname = 'public'
ORDER BY tablename, policyname;

-- 6. TESTER L'ACCÈS
SELECT '🧪 TEST D''ACCÈS' as action;

-- Test de lecture
SELECT '📖 Test de lecture loyalty_config:' as test;
SELECT COUNT(*) as total_config FROM loyalty_config;

SELECT '📖 Test de lecture loyalty_tiers_advanced:' as test;
SELECT COUNT(*) as total_tiers FROM loyalty_tiers_advanced;

-- 7. INSÉRER LES DONNÉES PAR DÉFAUT SI ELLES N'EXISTENT PAS
SELECT '📝 INSERTION DES DONNÉES PAR DÉFAUT' as action;

-- Configuration par défaut
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

-- Niveaux de fidélité par défaut
INSERT INTO loyalty_tiers_advanced (name, description, points_required, discount_percentage, color, benefits, is_active) VALUES
('Bronze', 'Niveau de base', 0, 0, '#CD7F32', ARRAY['Accès aux promotions de base'], true),
('Argent', 'Client régulier', 100, 5, '#C0C0C0', ARRAY['5% de réduction', 'Promotions exclusives'], true),
('Or', 'Client fidèle', 500, 10, '#FFD700', ARRAY['10% de réduction', 'Service prioritaire', 'Garantie étendue'], true),
('Platine', 'Client VIP', 1000, 15, '#E5E4E2', ARRAY['15% de réduction', 'Service VIP', 'Garantie étendue', 'Rendez-vous prioritaires'], true),
('Diamant', 'Client Premium', 2000, 20, '#B9F2FF', ARRAY['20% de réduction', 'Service Premium', 'Garantie étendue', 'Rendez-vous prioritaires', 'Support dédié'], true)
ON CONFLICT DO NOTHING;

-- 8. VÉRIFICATION FINALE
SELECT '✅ VÉRIFICATION FINALE' as action;

SELECT '📊 Configuration finale:' as section;
SELECT key, value, description FROM loyalty_config ORDER BY key;

SELECT '🏆 Niveaux de fidélité finaux:' as section;
SELECT name, points_required, discount_percentage, color, is_active FROM loyalty_tiers_advanced ORDER BY points_required;

-- 9. MESSAGE DE CONFIRMATION
SELECT '🎉 CORRECTION RLS TERMINÉE !' as result;
SELECT '📋 Vous pouvez maintenant utiliser l''interface de fidélité.' as next_step;
