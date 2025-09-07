-- =====================================================
-- CORRECTION NIVEAUX FIDÉLITÉ - VERSION SIMPLE
-- =====================================================
-- Script simplifié pour corriger les niveaux de fidélité
-- sans déclencher les triggers d'authentification
-- Date: 2025-01-23
-- =====================================================

-- 1. DIAGNOSTIC RAPIDE
SELECT '=== DIAGNOSTIC NIVEAUX FIDÉLITÉ ===' as etape;

-- Vérifier les tables existantes
SELECT 
    table_name,
    CASE 
        WHEN table_name IN ('loyalty_tiers', 'loyalty_tiers_advanced') 
        THEN '✅ Table niveaux'
        ELSE '⚠️ Autre table'
    END as type_table
FROM information_schema.tables 
WHERE table_schema = 'public'
AND table_name LIKE '%loyalty%'
ORDER BY table_name;

-- 2. CRÉER LES NIVEAUX DE FIDÉLITÉ SIMPLES
SELECT '=== CRÉATION NIVEAUX SIMPLES ===' as etape;

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

-- 3. INSÉRER LES NIVEAUX DE FIDÉLITÉ
SELECT '=== INSERTION NIVEAUX ===' as etape;

-- Supprimer les anciens niveaux s'ils existent
DELETE FROM loyalty_tiers_advanced WHERE name IN ('Bronze', 'Argent', 'Or', 'Platine', 'Diamant');

-- Insérer les nouveaux niveaux
INSERT INTO loyalty_tiers_advanced (name, description, points_required, discount_percentage, color) VALUES
('Bronze', 'Niveau de base', 0, 0.00, '#CD7F32'),
('Argent', 'Client régulier', 100, 5.00, '#C0C0C0'),
('Or', 'Client fidèle', 500, 10.00, '#FFD700'),
('Platine', 'Client VIP', 1000, 15.00, '#E5E4E2'),
('Diamant', 'Client Premium', 2000, 20.00, '#B9F2FF');

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

-- Fonction simple pour assigner les niveaux
DO $$
DECLARE
    v_client_record RECORD;
    v_tier_id UUID;
    v_updated_count INTEGER := 0;
BEGIN
    -- Parcourir tous les clients avec des points
    FOR v_client_record IN 
        SELECT id, loyalty_points, current_tier_id 
        FROM clients 
        WHERE loyalty_points > 0 OR current_tier_id IS NOT NULL
    LOOP
        -- Trouver le niveau approprié basé sur les points
        SELECT id INTO v_tier_id
        FROM loyalty_tiers_advanced
        WHERE points_required <= v_client_record.loyalty_points
        AND is_active = true
        ORDER BY points_required DESC
        LIMIT 1;
        
        -- Mettre à jour le client si un niveau a été trouvé
        IF v_tier_id IS NOT NULL THEN
            UPDATE clients 
            SET current_tier_id = v_tier_id
            WHERE id = v_client_record.id;
            
            v_updated_count := v_updated_count + 1;
        END IF;
    END LOOP;
    
    RAISE NOTICE '✅ Clients mis à jour: %', v_updated_count;
    
END $$;

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

-- 8. VÉRIFICATION FINALE
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

-- 9. MESSAGE DE CONFIRMATION
SELECT '=== CORRECTION TERMINÉE ===' as etape;
SELECT '✅ Niveaux de fidélité créés (5 niveaux)' as message;
SELECT '✅ Clients corrigés avec leurs niveaux' as clients;
SELECT '✅ Historique des points créé' as historique;
SELECT '✅ Table client_loyalty_points créée' as table_client;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT 'ℹ️ Les barres de progression devraient maintenant s''afficher' as note;
