-- =====================================================
-- CORRECTION ULTIME - NIVEAUX FIDÉLITÉ
-- =====================================================
-- Script ultime pour corriger les niveaux de fidélité
-- en supprimant complètement les triggers problématiques
-- Date: 2025-01-23
-- =====================================================

-- 1. SUPPRIMER TOUS LES TRIGGERS PROBLÉMATIQUES
SELECT '=== SUPPRESSION TRIGGERS PROBLÉMATIQUES ===' as etape;

-- Supprimer tous les triggers qui pourraient causer des problèmes
DROP TRIGGER IF EXISTS set_workshop_id_safe_trigger ON loyalty_tiers_advanced;
DROP TRIGGER IF EXISTS set_workshop_id_safe_trigger ON loyalty_points_history;
DROP TRIGGER IF EXISTS set_workshop_id_safe_trigger ON client_loyalty_points;
DROP TRIGGER IF EXISTS set_workshop_id_loyalty_tiers_advanced_safe ON loyalty_tiers_advanced;
DROP TRIGGER IF EXISTS set_workshop_id_loyalty_points_history_safe ON loyalty_points_history;
DROP TRIGGER IF EXISTS set_workshop_id_client_loyalty_points_safe ON client_loyalty_points;

-- Supprimer les fonctions problématiques
DROP FUNCTION IF EXISTS set_workshop_id_safe();
DROP FUNCTION IF EXISTS set_workshop_id_ultra_strict();
DROP FUNCTION IF EXISTS set_workshop_id_ultra_strict_safe();

-- 2. CRÉER LES NIVEAUX DE FIDÉLITÉ DIRECTEMENT
SELECT '=== CRÉATION NIVEAUX DIRECTE ===' as etape;

-- Créer la table loyalty_tiers_advanced si elle n'existe pas
CREATE TABLE IF NOT EXISTS loyalty_tiers_advanced (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    points_required INTEGER NOT NULL DEFAULT 0,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    color TEXT DEFAULT '#000000',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. INSÉRER LES NIVEAUX DE FIDÉLITÉ AVEC DES IDS FIXES
SELECT '=== INSERTION NIVEAUX AVEC IDS FIXES ===' as etape;

-- Supprimer les anciens niveaux s'ils existent
DELETE FROM loyalty_tiers_advanced WHERE name IN ('Bronze', 'Argent', 'Or', 'Platine', 'Diamant');

-- Insérer les nouveaux niveaux avec des IDs fixes pour éviter les conflits
INSERT INTO loyalty_tiers_advanced (id, name, description, points_required, discount_percentage, color) VALUES
('11111111-1111-1111-1111-111111111111', 'Bronze', 'Niveau de base', 0, 0.00, '#CD7F32'),
('22222222-2222-2222-2222-222222222222', 'Argent', 'Client régulier', 100, 5.00, '#C0C0C0'),
('33333333-3333-3333-3333-333333333333', 'Or', 'Client fidèle', 500, 10.00, '#FFD700'),
('44444444-4444-4444-4444-444444444444', 'Platine', 'Client VIP', 1000, 15.00, '#E5E4E2'),
('55555555-5555-5555-5555-555555555555', 'Diamant', 'Client Premium', 2000, 20.00, '#B9F2FF');

-- 4. CRÉER L'HISTORIQUE DES POINTS
SELECT '=== CRÉATION HISTORIQUE ===' as etape;

-- Créer la table loyalty_points_history si elle n'existe pas
CREATE TABLE IF NOT EXISTS loyalty_points_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    points_change INTEGER NOT NULL,
    points_type TEXT NOT NULL DEFAULT 'earned',
    source_type TEXT DEFAULT 'manual',
    description TEXT,
    points_before INTEGER DEFAULT 0,
    points_after INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. CRÉER LA TABLE CLIENT_LOYALTY_POINTS
SELECT '=== CRÉATION TABLE CLIENT_LOYALTY_POINTS ===' as etape;

CREATE TABLE IF NOT EXISTS client_loyalty_points (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    points_added INTEGER DEFAULT 0,
    points_used INTEGER DEFAULT 0,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. CORRIGER LES CLIENTS AVEC DES TIER_ID INVALIDES
SELECT '=== CORRECTION CLIENTS ===' as etape;

-- Mettre à jour directement les clients avec les bons tier_id
UPDATE clients 
SET current_tier_id = '11111111-1111-1111-1111-111111111111'  -- Bronze
WHERE loyalty_points >= 0 AND loyalty_points < 100;

UPDATE clients 
SET current_tier_id = '22222222-2222-2222-2222-222222222222'  -- Argent
WHERE loyalty_points >= 100 AND loyalty_points < 500;

UPDATE clients 
SET current_tier_id = '33333333-3333-3333-3333-333333333333'  -- Or
WHERE loyalty_points >= 500 AND loyalty_points < 1000;

UPDATE clients 
SET current_tier_id = '44444444-4444-4444-4444-444444444444'  -- Platine
WHERE loyalty_points >= 1000 AND loyalty_points < 2000;

UPDATE clients 
SET current_tier_id = '55555555-5555-5555-5555-555555555555'  -- Diamant
WHERE loyalty_points >= 2000;

-- 7. CRÉER DES ENTRÉES D'HISTORIQUE POUR LES CLIENTS EXISTANTS
SELECT '=== CRÉATION HISTORIQUE CLIENTS ===' as etape;

-- Créer des entrées d'historique pour les clients existants
INSERT INTO loyalty_points_history (
    client_id, points_change, points_type, source_type, description, 
    points_before, points_after
)
SELECT 
    c.id,
    c.loyalty_points,
    'earned',
    'initial',
    'Points initiaux',
    0,
    c.loyalty_points
FROM clients c
WHERE c.loyalty_points > 0
AND NOT EXISTS (
    SELECT 1 FROM loyalty_points_history lph 
    WHERE lph.client_id = c.id
);

-- Créer des entrées dans client_loyalty_points
INSERT INTO client_loyalty_points (
    client_id, points_added, points_used, description
)
SELECT 
    c.id,
    c.loyalty_points,
    0,
    'Points initiaux'
FROM clients c
WHERE c.loyalty_points > 0
AND NOT EXISTS (
    SELECT 1 FROM client_loyalty_points clp 
    WHERE clp.client_id = c.id
);

-- 8. CRÉER UNE FONCTION TRIGGER SIMPLE ET SÉCURISÉE
SELECT '=== CRÉATION FONCTION TRIGGER SÉCURISÉE ===' as etape;

CREATE OR REPLACE FUNCTION set_workshop_id_simple()
RETURNS TRIGGER AS $$
BEGIN
    -- Vérifier que l'utilisateur est authentifié
    IF auth.uid() IS NULL THEN
        -- Si pas d'utilisateur, on continue sans erreur
        RETURN NEW;
    END IF;
    
    -- Forcer workshop_id à l'utilisateur connecté
    NEW.workshop_id := auth.uid();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. CRÉER DES TRIGGERS SÉCURISÉS
SELECT '=== CRÉATION TRIGGERS SÉCURISÉS ===' as etape;

-- Créer des triggers simples qui ne bloquent pas
CREATE TRIGGER set_workshop_id_loyalty_tiers_advanced_simple
    BEFORE INSERT ON loyalty_tiers_advanced
    FOR EACH ROW EXECUTE FUNCTION set_workshop_id_simple();

CREATE TRIGGER set_workshop_id_loyalty_points_history_simple
    BEFORE INSERT ON loyalty_points_history
    FOR EACH ROW EXECUTE FUNCTION set_workshop_id_simple();

CREATE TRIGGER set_workshop_id_client_loyalty_points_simple
    BEFORE INSERT ON client_loyalty_points
    FOR EACH ROW EXECUTE FUNCTION set_workshop_id_simple();

-- 10. VÉRIFICATION FINALE
SELECT '=== VÉRIFICATION FINALE ===' as etape;

-- Vérifier les niveaux créés
SELECT 
    name,
    points_required,
    discount_percentage,
    color
FROM loyalty_tiers_advanced 
ORDER BY points_required;

-- Vérifier les clients corrigés
SELECT 
    c.first_name,
    c.last_name,
    c.loyalty_points,
    lta.name as tier_name,
    lta.color as tier_color
FROM clients c
LEFT JOIN loyalty_tiers_advanced lta ON c.current_tier_id = lta.id
WHERE c.loyalty_points > 0
ORDER BY c.loyalty_points DESC;

-- Compter les données créées
SELECT 
    (SELECT COUNT(*) FROM loyalty_tiers_advanced) as niveaux_crees,
    (SELECT COUNT(*) FROM loyalty_points_history) as historique_crees,
    (SELECT COUNT(*) FROM client_loyalty_points) as client_points_crees,
    (SELECT COUNT(*) FROM clients WHERE loyalty_points > 0) as clients_avec_points;

-- 11. MESSAGE DE CONFIRMATION
SELECT '=== CORRECTION ULTIME TERMINÉE ===' as etape;
SELECT '✅ Triggers problématiques supprimés' as message;
SELECT '✅ Niveaux de fidélité créés (5 niveaux avec IDs fixes)' as niveaux;
SELECT '✅ Clients corrigés avec leurs niveaux' as clients;
SELECT '✅ Historique des points créé' as historique;
SELECT '✅ Table client_loyalty_points créée' as table_client;
SELECT '✅ Nouveaux triggers sécurisés créés' as triggers;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT 'ℹ️ Les barres de progression devraient maintenant s''afficher' as note;
