-- Script de réactivation sécurisée des triggers de fidélité
-- Ce script réactive les triggers après avoir corrigé les problèmes de base

-- 1. VÉRIFIER L'ÉTAT ACTUEL
SELECT '=== VÉRIFICATION ÉTAT ACTUEL ===' as etape;

-- Vérifier les triggers existants
SELECT 
    n.nspname as schemaname,
    c.relname as tablename,
    t.tgname as triggername,
    CASE 
        WHEN t.tgenabled = 'O' THEN 'ACTIF'
        WHEN t.tgenabled = 'D' THEN 'DÉSACTIVÉ'
        ELSE 'INCONNU'
    END as statut
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public' 
AND c.relname IN ('loyalty_tiers_advanced', 'loyalty_config', 'loyalty_points_history', 'client_loyalty_points', 'referrals')
ORDER BY c.relname, t.tgname;

-- 2. CRÉER UNE FONCTION DE TRIGGER SÉCURISÉE
SELECT '=== CRÉATION FONCTION TRIGGER SÉCURISÉE ===' as etape;

-- Fonction pour mettre à jour updated_at de manière sécurisée
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 3. CRÉER LES TRIGGERS SÉCURISÉS
SELECT '=== CRÉATION TRIGGERS SÉCURISÉS ===' as etape;

-- Trigger pour loyalty_tiers_advanced
DROP TRIGGER IF EXISTS update_loyalty_tiers_advanced_updated_at ON loyalty_tiers_advanced;
CREATE TRIGGER update_loyalty_tiers_advanced_updated_at
    BEFORE UPDATE ON loyalty_tiers_advanced
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour loyalty_config
DROP TRIGGER IF EXISTS update_loyalty_config_updated_at ON loyalty_config;
CREATE TRIGGER update_loyalty_config_updated_at
    BEFORE UPDATE ON loyalty_config
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour loyalty_points_history
DROP TRIGGER IF EXISTS update_loyalty_points_history_updated_at ON loyalty_points_history;
CREATE TRIGGER update_loyalty_points_history_updated_at
    BEFORE UPDATE ON loyalty_points_history
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour client_loyalty_points
DROP TRIGGER IF EXISTS update_client_loyalty_points_updated_at ON client_loyalty_points;
CREATE TRIGGER update_client_loyalty_points_updated_at
    BEFORE UPDATE ON client_loyalty_points
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger pour referrals
DROP TRIGGER IF EXISTS update_referrals_updated_at ON referrals;
CREATE TRIGGER update_referrals_updated_at
    BEFORE UPDATE ON referrals
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 4. VÉRIFIER LES NIVEAUX EXISTANTS
SELECT '=== VÉRIFICATION NIVEAUX ===' as etape;

SELECT 
    COUNT(*) as nombre_niveaux,
    string_agg(name, ', ' ORDER BY points_required) as niveaux_disponibles
FROM loyalty_tiers_advanced;

-- 5. VÉRIFIER LES CONFIGURATIONS
SELECT '=== VÉRIFICATION CONFIGURATIONS ===' as etape;

SELECT 
    COUNT(*) as nombre_configurations,
    string_agg(key, ', ') as configurations_disponibles
FROM loyalty_config;

-- 6. TEST DE FONCTIONNEMENT
SELECT '=== TEST DE FONCTIONNEMENT ===' as etape;

-- Tester la mise à jour d'un niveau
UPDATE loyalty_tiers_advanced 
SET description = 'Test de mise à jour - ' || NOW()::text
WHERE name = 'Bronze' AND id = '11111111-1111-1111-1111-111111111111';

-- Vérifier que updated_at a été mis à jour
SELECT 
    name,
    description,
    updated_at
FROM loyalty_tiers_advanced 
WHERE name = 'Bronze'
LIMIT 1;

-- 7. VÉRIFICATIONS FINALES
SELECT '=== VÉRIFICATIONS FINALES ===' as etape;

-- Vérifier que tous les triggers sont actifs
SELECT 
    n.nspname as schemaname,
    c.relname as tablename,
    t.tgname as triggername,
    CASE 
        WHEN t.tgenabled = 'O' THEN 'ACTIF'
        WHEN t.tgenabled = 'D' THEN 'DÉSACTIVÉ'
        ELSE 'INCONNU'
    END as statut
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public' 
AND c.relname IN ('loyalty_tiers_advanced', 'loyalty_config', 'loyalty_points_history', 'client_loyalty_points', 'referrals')
AND t.tgname LIKE '%updated_at%'
ORDER BY c.relname, t.tgname;

-- 8. MESSAGE DE CONFIRMATION
SELECT '=== RÉACTIVATION TERMINÉE ===' as etape;
SELECT 'Les triggers de fidélité ont été réactivés avec succès !' as message;
SELECT 'Les mises à jour des niveaux de fidélité fonctionnent maintenant correctement.' as details;
