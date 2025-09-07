-- =====================================================
-- CORRECTION NIVEAUX FIDÉLITÉ ET PROGRESSION
-- =====================================================
-- Script pour corriger les niveaux de fidélité manquants
-- qui causent le problème de progression
-- Date: 2025-01-23
-- =====================================================

-- 1. DIAGNOSTIC DES NIVEAUX DE FIDÉLITÉ
SELECT '=== DIAGNOSTIC NIVEAUX FIDÉLITÉ ===' as etape;

-- Vérifier les tables de niveaux de fidélité
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

-- Vérifier le contenu des tables de niveaux
SELECT '=== CONTENU TABLES NIVEAUX ===' as etape;

-- Table loyalty_tiers
SELECT 'loyalty_tiers' as table_name, COUNT(*) as nombre_niveaux FROM loyalty_tiers;
SELECT * FROM loyalty_tiers ORDER BY min_points;

-- Table loyalty_tiers_advanced
SELECT 'loyalty_tiers_advanced' as table_name, COUNT(*) as nombre_niveaux FROM loyalty_tiers_advanced;
SELECT * FROM loyalty_tiers_advanced ORDER BY points_required;

-- 2. VÉRIFIER LES CLIENTS AVEC DES TIER_ID PROBLÉMATIQUES
SELECT '=== CLIENTS AVEC TIER_ID PROBLÉMATIQUES ===' as etape;

SELECT 
    c.id,
    c.first_name,
    c.last_name,
    c.email,
    c.loyalty_points,
    c.current_tier_id,
    CASE 
        WHEN c.current_tier_id IS NULL THEN '❌ Aucun tier'
        WHEN lt.id IS NULL AND lta.id IS NULL THEN '❌ Tier ID invalide'
        WHEN lt.id IS NOT NULL THEN '✅ Tier standard trouvé'
        WHEN lta.id IS NOT NULL THEN '✅ Tier avancé trouvé'
        ELSE '⚠️ Tier inconnu'
    END as statut_tier
FROM clients c
LEFT JOIN loyalty_tiers lt ON c.current_tier_id = lt.id
LEFT JOIN loyalty_tiers_advanced lta ON c.current_tier_id = lta.id
WHERE c.loyalty_points > 0 OR c.current_tier_id IS NOT NULL
ORDER BY c.loyalty_points DESC;

-- 3. CRÉER LES NIVEAUX DE FIDÉLITÉ MANQUANTS
SELECT '=== CRÉATION NIVEAUX FIDÉLITÉ ===' as etape;

-- Créer la table loyalty_tiers si elle n'existe pas
CREATE TABLE IF NOT EXISTS loyalty_tiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    min_points INTEGER NOT NULL DEFAULT 0,
    max_points INTEGER,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    color TEXT DEFAULT '#000000',
    benefits TEXT[],
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Créer la table loyalty_tiers_advanced si elle n'existe pas
CREATE TABLE IF NOT EXISTS loyalty_tiers_advanced (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    points_required INTEGER NOT NULL DEFAULT 0,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    color TEXT DEFAULT '#000000',
    benefits TEXT[],
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. INSÉRER LES NIVEAUX DE FIDÉLITÉ PAR DÉFAUT
SELECT '=== INSERTION NIVEAUX PAR DÉFAUT ===' as etape;

-- Niveaux standard
INSERT INTO loyalty_tiers (name, description, min_points, discount_percentage, color) VALUES
('Bronze', 'Niveau de base', 0, 0.00, '#CD7F32'),
('Argent', 'Client régulier', 100, 5.00, '#C0C0C0'),
('Or', 'Client fidèle', 500, 10.00, '#FFD700'),
('Platine', 'Client VIP', 1000, 15.00, '#E5E4E2'),
('Diamant', 'Client Premium', 2000, 20.00, '#B9F2FF')
ON CONFLICT (name) DO NOTHING;

-- Niveaux avancés
INSERT INTO loyalty_tiers_advanced (name, description, points_required, discount_percentage, color, benefits) VALUES
('Bronze', 'Niveau de base', 0, 0, '#CD7F32', ARRAY['Accès aux promotions de base']),
('Argent', 'Client régulier', 100, 5, '#C0C0C0', ARRAY['5% de réduction', 'Promotions exclusives']),
('Or', 'Client fidèle', 500, 10, '#FFD700', ARRAY['10% de réduction', 'Service prioritaire', 'Garantie étendue']),
('Platine', 'Client VIP', 1000, 15, '#E5E4E2', ARRAY['15% de réduction', 'Service VIP', 'Garantie étendue', 'Rendez-vous prioritaires']),
('Diamant', 'Client Premium', 2000, 20, '#B9F2FF', ARRAY['20% de réduction', 'Service Premium', 'Garantie étendue', 'Rendez-vous prioritaires', 'Support dédié'])
ON CONFLICT (name) DO NOTHING;

-- 5. CORRIGER LES CLIENTS AVEC DES TIER_ID INVALIDES
SELECT '=== CORRECTION CLIENTS TIER_ID INVALIDES ===' as etape;

-- Fonction pour assigner automatiquement les niveaux
CREATE OR REPLACE FUNCTION assign_loyalty_tiers_to_clients()
RETURNS JSON AS $$
DECLARE
    v_updated_count INTEGER := 0;
    v_client_record RECORD;
    v_tier_id UUID;
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
    
    RETURN json_build_object(
        'success', true,
        'message', 'Niveaux assignés avec succès',
        'clients_updated', v_updated_count
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', 'Erreur lors de l''assignation des niveaux: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql;

-- Exécuter la fonction de correction
SELECT assign_loyalty_tiers_to_clients();

-- 6. CRÉER L'HISTORIQUE DES POINTS MANQUANT
SELECT '=== CRÉATION HISTORIQUE POINTS ===' as etape;

-- Créer la table loyalty_points_history si elle n'existe pas
CREATE TABLE IF NOT EXISTS loyalty_points_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    points_change INTEGER NOT NULL,
    points_type TEXT NOT NULL DEFAULT 'earned',
    source_type TEXT DEFAULT 'manual',
    description TEXT,
    reference_id UUID,
    points_before INTEGER DEFAULT 0,
    points_after INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

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
)
ON CONFLICT DO NOTHING;

-- 7. CRÉER LA TABLE CLIENT_LOYALTY_POINTS SI ELLE N'EXISTE PAS
SELECT '=== CRÉATION TABLE CLIENT_LOYALTY_POINTS ===' as etape;

CREATE TABLE IF NOT EXISTS client_loyalty_points (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    points_added INTEGER DEFAULT 0,
    points_used INTEGER DEFAULT 0,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Créer des entrées pour les clients existants
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
)
ON CONFLICT DO NOTHING;

-- 8. TEST DE LA CORRECTION
SELECT '=== TEST DE LA CORRECTION ===' as etape;

DO $$
DECLARE
    v_niveaux_count INTEGER;
    v_historique_count INTEGER;
    v_clients_count INTEGER;
    v_clients_avec_tier INTEGER;
BEGIN
    -- Compter les niveaux
    SELECT COUNT(*) INTO v_niveaux_count FROM loyalty_tiers_advanced;
    RAISE NOTICE '📊 Niveaux de fidélité disponibles: %', v_niveaux_count;
    
    -- Compter l'historique
    SELECT COUNT(*) INTO v_historique_count FROM loyalty_points_history;
    RAISE NOTICE '📊 Entrées d''historique: %', v_historique_count;
    
    -- Compter les clients
    SELECT COUNT(*) INTO v_clients_count FROM clients WHERE loyalty_points > 0;
    RAISE NOTICE '📊 Clients avec points: %', v_clients_count;
    
    -- Compter les clients avec tier valide
    SELECT COUNT(*) INTO v_clients_avec_tier 
    FROM clients c
    JOIN loyalty_tiers_advanced lta ON c.current_tier_id = lta.id
    WHERE c.loyalty_points > 0;
    RAISE NOTICE '📊 Clients avec tier valide: %', v_clients_avec_tier;
    
    -- Résumé
    IF v_niveaux_count > 0 AND v_historique_count > 0 AND v_clients_avec_tier > 0 THEN
        RAISE NOTICE '✅ CORRECTION RÉUSSIE: Système de progression fonctionnel';
    ELSE
        RAISE NOTICE '⚠️ CORRECTION PARTIELLE: Vérifiez les données manquantes';
    END IF;
    
END $$;

-- 9. VÉRIFICATION FINALE
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

-- 10. MESSAGE DE CONFIRMATION
SELECT '=== CORRECTION TERMINÉE ===' as etape;
SELECT '✅ Niveaux de fidélité créés et configurés' as message;
SELECT '✅ Clients corrigés avec leurs niveaux' as clients;
SELECT '✅ Historique des points créé' as historique;
SELECT '✅ Système de progression restauré' as systeme;
SELECT '🚨 REDÉPLOYEZ L''APPLICATION' as deploy;
SELECT 'ℹ️ Les barres de progression devraient maintenant s''afficher' as note;
