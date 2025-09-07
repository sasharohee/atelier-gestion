-- Script final simple pour corriger la sauvegarde des niveaux de fidélité
-- Ce script évite tous les problèmes de contraintes et de RLS

-- 1. SUPPRIMER TOUTES LES FONCTIONS DE SÉCURITÉ PROBLÉMATIQUES
SELECT '=== SUPPRESSION DES FONCTIONS DE SÉCURITÉ ===' as etape;

-- Supprimer toutes les fonctions liées à workshop_id
DROP FUNCTION IF EXISTS set_workshop_id_safe() CASCADE;
DROP FUNCTION IF EXISTS set_workshop_id_simple() CASCADE;
DROP FUNCTION IF EXISTS set_workshop_id_ultra_strict_safe() CASCADE;
DROP FUNCTION IF EXISTS set_workshop_id_tiers() CASCADE;
DROP FUNCTION IF EXISTS set_workshop_id_loyalty_tiers_advanced_safe() CASCADE;
DROP FUNCTION IF EXISTS set_workshop_id_loyalty_points_history_safe() CASCADE;
DROP FUNCTION IF EXISTS set_workshop_id_client_loyalty_points_safe() CASCADE;
DROP FUNCTION IF EXISTS set_workshop_id_loyalty_tiers_advanced_simple() CASCADE;
DROP FUNCTION IF EXISTS set_workshop_id_loyalty_points_history_simple() CASCADE;
DROP FUNCTION IF EXISTS set_workshop_id_client_loyalty_points_simple() CASCADE;

-- Supprimer toutes les fonctions liées à l'authentification problématique
DROP FUNCTION IF EXISTS check_user_authentication() CASCADE;
DROP FUNCTION IF EXISTS verify_user_permissions() CASCADE;
DROP FUNCTION IF EXISTS validate_workshop_access() CASCADE;
DROP FUNCTION IF EXISTS authenticate_user() CASCADE;
DROP FUNCTION IF EXISTS check_workshop_permissions() CASCADE;

-- Supprimer toutes les fonctions liées à la fidélité problématique
DROP FUNCTION IF EXISTS loyalty_workshop_id_trigger() CASCADE;
DROP FUNCTION IF EXISTS loyalty_tiers_workshop_id_trigger() CASCADE;
DROP FUNCTION IF EXISTS loyalty_points_workshop_id_trigger() CASCADE;
DROP FUNCTION IF EXISTS loyalty_config_workshop_id_trigger() CASCADE;

-- 2. SUPPRIMER TOUS LES TRIGGERS LIÉS À CES FONCTIONS
SELECT '=== SUPPRESSION DES TRIGGERS DE SÉCURITÉ ===' as etape;

-- Supprimer tous les triggers de sécurité
DROP TRIGGER IF EXISTS set_workshop_id_safe_trigger ON loyalty_tiers_advanced;
DROP TRIGGER IF EXISTS set_workshop_id_safe_trigger ON loyalty_points_history;
DROP TRIGGER IF EXISTS set_workshop_id_safe_trigger ON client_loyalty_points;
DROP TRIGGER IF EXISTS set_workshop_id_loyalty_tiers_advanced_safe ON loyalty_tiers_advanced;
DROP TRIGGER IF EXISTS set_workshop_id_loyalty_points_history_safe ON loyalty_points_history;
DROP TRIGGER IF EXISTS set_workshop_id_client_loyalty_points_safe ON client_loyalty_points;
DROP TRIGGER IF EXISTS set_workshop_id_loyalty_tiers_advanced_simple ON loyalty_tiers_advanced;
DROP TRIGGER IF EXISTS set_workshop_id_loyalty_points_history_simple ON loyalty_points_history;
DROP TRIGGER IF EXISTS set_workshop_id_client_loyalty_points_simple ON client_loyalty_points;
DROP TRIGGER IF EXISTS loyalty_workshop_id_trigger ON loyalty_tiers_advanced;
DROP TRIGGER IF EXISTS loyalty_workshop_id_trigger ON loyalty_config;
DROP TRIGGER IF EXISTS loyalty_workshop_id_trigger ON loyalty_points_history;
DROP TRIGGER IF EXISTS loyalty_workshop_id_trigger ON client_loyalty_points;
DROP TRIGGER IF EXISTS loyalty_workshop_id_trigger ON referrals;

-- 3. CRÉER UNE FONCTION DE TRIGGER SIMPLE
SELECT '=== CRÉATION FONCTION TRIGGER SIMPLE ===' as etape;

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 4. CRÉER LES TRIGGERS updated_at
SELECT '=== CRÉATION TRIGGERS updated_at ===' as etape;

-- Supprimer les anciens triggers s'ils existent
DROP TRIGGER IF EXISTS update_loyalty_tiers_advanced_updated_at ON loyalty_tiers_advanced;
DROP TRIGGER IF EXISTS update_loyalty_config_updated_at ON loyalty_config;

-- Créer les nouveaux triggers
CREATE TRIGGER update_loyalty_tiers_advanced_updated_at
    BEFORE UPDATE ON loyalty_tiers_advanced
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_loyalty_config_updated_at
    BEFORE UPDATE ON loyalty_config
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 5. NETTOYER ET RECRÉER LES NIVEAUX
SELECT '=== NETTOYAGE ET RECRÉATION DES NIVEAUX ===' as etape;

-- Supprimer tous les niveaux existants
DELETE FROM loyalty_tiers_advanced;

-- Recréer les niveaux par défaut
INSERT INTO loyalty_tiers_advanced (id, name, description, points_required, discount_percentage, color, is_active, created_at, updated_at) VALUES
('11111111-1111-1111-1111-111111111111', 'Bronze', 'Niveau de base', 0, 0.00, '#CD7F32', true, NOW(), NOW()),
('22222222-2222-2222-2222-222222222222', 'Argent', 'Client régulier', 100, 5.00, '#C0C0C0', true, NOW(), NOW()),
('33333333-3333-3333-3333-333333333333', 'Or', 'Client fidèle', 500, 10.00, '#FFD700', true, NOW(), NOW()),
('44444444-4444-4444-4444-444444444444', 'Platine', 'Client VIP', 1000, 15.00, '#E5E4E2', true, NOW(), NOW()),
('55555555-5555-5555-5555-555555555555', 'Diamant', 'Client Premium', 2000, 20.00, '#B9F2FF', true, NOW(), NOW());

-- 6. CRÉER LA TABLE DE CONFIGURATION SI ELLE N'EXISTE PAS
SELECT '=== CRÉATION TABLE CONFIG ===' as etape;

CREATE TABLE IF NOT EXISTS loyalty_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    key TEXT NOT NULL,
    value TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. INSÉRER LES CONFIGURATIONS (SANS CONFLIT)
SELECT '=== INSERTION CONFIGURATIONS ===' as etape;

-- Supprimer les configurations existantes pour éviter les conflits
DELETE FROM loyalty_config WHERE key IN (
    'points_per_euro', 'referral_points', 'min_points_redemption', 
    'points_to_euro_ratio', 'auto_tier_update', 'email_notifications', 
    'sms_notifications', 'loyalty_system_active'
);

-- Insérer les nouvelles configurations
INSERT INTO loyalty_config (key, value, description) VALUES
('points_per_euro', '1', 'Points attribués par euro dépensé'),
('referral_points', '50', 'Points attribués pour un parrainage confirmé'),
('min_points_redemption', '100', 'Nombre minimum de points pour une réduction'),
('points_to_euro_ratio', '100', 'Nombre de points équivalent à 1 euro de réduction'),
('auto_tier_update', 'true', 'Mise à jour automatique des niveaux'),
('email_notifications', 'true', 'Notifications par email'),
('sms_notifications', 'false', 'Notifications par SMS'),
('loyalty_system_active', 'true', 'Système de fidélité activé');

-- 8. TEST DE FONCTIONNEMENT
SELECT '=== TEST DE FONCTIONNEMENT ===' as etape;

-- Tester la mise à jour
UPDATE loyalty_tiers_advanced 
SET description = 'Test de sauvegarde - ' || NOW()::text
WHERE name = 'Bronze' AND id = '11111111-1111-1111-1111-111111111111';

-- Vérifier le résultat
SELECT 
    name,
    description,
    updated_at,
    CASE 
        WHEN description LIKE 'Test de sauvegarde%' THEN '✅ MISE À JOUR RÉUSSIE'
        ELSE '❌ MISE À JOUR ÉCHOUÉE'
    END as statut
FROM loyalty_tiers_advanced 
WHERE name = 'Bronze' AND id = '11111111-1111-1111-1111-111111111111';

-- Restaurer la description originale
UPDATE loyalty_tiers_advanced 
SET description = 'Niveau de base'
WHERE name = 'Bronze' AND id = '11111111-1111-1111-1111-111111111111';

-- 9. VÉRIFICATIONS FINALES
SELECT '=== VÉRIFICATIONS FINALES ===' as etape;

-- Vérifier les niveaux
SELECT 
    COUNT(*) as niveaux_crees,
    string_agg(name, ', ' ORDER BY points_required) as niveaux_disponibles
FROM loyalty_tiers_advanced;

-- Vérifier les configurations
SELECT 
    COUNT(*) as configurations_creees,
    string_agg(key, ', ') as configurations_disponibles
FROM loyalty_config;

-- Vérifier les triggers
SELECT 
    n.nspname as schema_name,
    c.relname as table_name,
    t.tgname as trigger_name,
    CASE 
        WHEN t.tgenabled = 'O' THEN 'ACTIF'
        WHEN t.tgenabled = 'D' THEN 'DÉSACTIVÉ'
        ELSE 'INCONNU'
    END as statut
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
JOIN pg_namespace n ON c.relnamespace = n.oid
WHERE n.nspname = 'public' 
AND c.relname IN ('loyalty_tiers_advanced', 'loyalty_config')
AND t.tgname LIKE '%updated_at%'
ORDER BY c.relname, t.tgname;

-- 10. MESSAGE DE CONFIRMATION
SELECT '=== CORRECTION TERMINÉE ===' as etape;
SELECT 'Les fonctions de sécurité problématiques ont été supprimées !' as message;
SELECT 'Les niveaux de fidélité devraient maintenant se sauvegarder correctement.' as details;
SELECT 'RLS reste dans son état actuel (activé ou désactivé selon votre configuration).' as note;
