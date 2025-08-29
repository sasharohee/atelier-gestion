-- Recréation complète du système de points de fidélité
-- Ce script supprime tout et recrée le système de zéro

-- 1. SUPPRESSION COMPLÈTE
SELECT '🗑️ SUPPRESSION COMPLÈTE DU SYSTÈME...' as info;

-- Supprimer les triggers
DROP TRIGGER IF EXISTS update_client_tier_trigger ON clients;

-- Supprimer les fonctions
DROP FUNCTION IF EXISTS add_loyalty_points(UUID, INTEGER, TEXT, TEXT, TEXT, UUID, UUID);
DROP FUNCTION IF EXISTS add_loyalty_points(UUID, INTEGER, TEXT, TEXT, UUID, TEXT, UUID);
DROP FUNCTION IF EXISTS add_loyalty_points(UUID, INTEGER, TEXT, TEXT, UUID, TEXT);
DROP FUNCTION IF EXISTS add_loyalty_points(UUID, INTEGER, TEXT, TEXT, UUID);
DROP FUNCTION IF EXISTS add_loyalty_points(UUID, INTEGER, TEXT, TEXT);
DROP FUNCTION IF EXISTS add_loyalty_points(UUID, INTEGER, TEXT);
DROP FUNCTION IF EXISTS add_loyalty_points(UUID, INTEGER);
DROP FUNCTION IF EXISTS add_loyalty_points(UUID, INTEGER, TEXT, UUID);
DROP FUNCTION IF EXISTS add_loyalty_points(UUID, INTEGER, UUID);

DROP FUNCTION IF EXISTS use_loyalty_points(UUID, INTEGER, TEXT, TEXT, TEXT, UUID, UUID);
DROP FUNCTION IF EXISTS use_loyalty_points(UUID, INTEGER, TEXT, TEXT, UUID, TEXT, UUID);
DROP FUNCTION IF EXISTS use_loyalty_points(UUID, INTEGER, TEXT, TEXT, UUID, TEXT);
DROP FUNCTION IF EXISTS use_loyalty_points(UUID, INTEGER, TEXT, TEXT, UUID);
DROP FUNCTION IF EXISTS use_loyalty_points(UUID, INTEGER, TEXT, TEXT);
DROP FUNCTION IF EXISTS use_loyalty_points(UUID, INTEGER, TEXT);
DROP FUNCTION IF EXISTS use_loyalty_points(UUID, INTEGER);
DROP FUNCTION IF EXISTS use_loyalty_points(UUID, INTEGER, TEXT, UUID);
DROP FUNCTION IF EXISTS use_loyalty_points(UUID, INTEGER, UUID);

DROP FUNCTION IF EXISTS update_client_tier();
DROP FUNCTION IF EXISTS sync_loyalty_data();
DROP FUNCTION IF EXISTS refresh_client_loyalty_data();

-- Supprimer les contraintes de clé étrangère
ALTER TABLE clients DROP CONSTRAINT IF EXISTS clients_current_tier_id_fkey;
ALTER TABLE loyalty_points_history DROP CONSTRAINT IF EXISTS loyalty_points_history_client_id_fkey;

-- Supprimer les tables
DROP TABLE IF EXISTS loyalty_points_history CASCADE;
DROP TABLE IF EXISTS loyalty_tiers CASCADE;

-- Supprimer les colonnes de la table clients
ALTER TABLE clients DROP COLUMN IF EXISTS loyalty_points;
ALTER TABLE clients DROP COLUMN IF EXISTS current_tier_id;

-- 2. RECRÉATION COMPLÈTE
SELECT '🏗️ RECRÉATION COMPLÈTE DU SYSTÈME...' as info;

-- Ajouter les colonnes à la table clients
ALTER TABLE clients ADD COLUMN loyalty_points INTEGER DEFAULT 0;
ALTER TABLE clients ADD COLUMN current_tier_id UUID;

-- Créer la table loyalty_tiers
CREATE TABLE loyalty_tiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    min_points INTEGER NOT NULL DEFAULT 0,
    points_required INTEGER NOT NULL DEFAULT 0,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    color TEXT DEFAULT '#000000',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Créer la table loyalty_points_history
CREATE TABLE loyalty_points_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL,
    points_change INTEGER NOT NULL,
    points_before INTEGER NOT NULL,
    points_after INTEGER NOT NULL,
    description TEXT,
    points_type TEXT DEFAULT 'manual',
    source_type TEXT DEFAULT 'manual',
    user_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. AJOUTER LES CONTRAINTES
SELECT '🔗 AJOUT DES CONTRAINTES...' as info;

-- Contrainte de clé étrangère pour clients.current_tier_id
ALTER TABLE clients 
ADD CONSTRAINT clients_current_tier_id_fkey 
FOREIGN KEY (current_tier_id) REFERENCES loyalty_tiers(id) ON DELETE SET NULL;

-- Contrainte de clé étrangère pour loyalty_points_history.client_id
ALTER TABLE loyalty_points_history 
ADD CONSTRAINT loyalty_points_history_client_id_fkey 
FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;

-- 4. INSÉRER LES NIVEAUX DE FIDÉLITÉ
SELECT '🎯 CRÉATION DES NIVEAUX DE FIDÉLITÉ...' as info;

INSERT INTO loyalty_tiers (name, description, min_points, points_required, discount_percentage, color) 
VALUES 
    ('Bronze', 'Niveau de base', 0, 0, 0, '#CD7F32'),
    ('Argent', 'Client régulier', 0, 100, 5, '#C0C0C0'),
    ('Or', 'Client fidèle', 100, 500, 10, '#FFD700'),
    ('Platine', 'Client VIP', 500, 1000, 15, '#E5E4E2'),
    ('Diamant', 'Client premium', 1000, 2000, 20, '#B9F2FF');

-- 5. CRÉER LES FONCTIONS
SELECT '⚙️ CRÉATION DES FONCTIONS...' as info;

-- Fonction add_loyalty_points
CREATE OR REPLACE FUNCTION add_loyalty_points(
    p_client_id UUID,
    p_points INTEGER,
    p_description TEXT DEFAULT 'Points ajoutés manuellement'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_client_exists BOOLEAN;
    v_current_points INTEGER;
    v_new_points INTEGER;
    v_current_tier_id UUID;
    v_new_tier_id UUID;
    v_user_id UUID;
    v_result JSON;
BEGIN
    -- Récupérer l'utilisateur actuel
    v_user_id := auth.uid();
    
    -- Vérifier que le client existe
    SELECT EXISTS(SELECT 1 FROM clients WHERE id = p_client_id) INTO v_client_exists;
    
    IF NOT v_client_exists THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Client non trouvé'
        );
    END IF;
    
    -- Vérifier que les points sont positifs
    IF p_points <= 0 THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Le nombre de points doit être positif'
        );
    END IF;
    
    -- Récupérer les points actuels du client
    SELECT COALESCE(loyalty_points, 0) INTO v_current_points
    FROM clients 
    WHERE id = p_client_id;
    
    -- Calculer les nouveaux points
    v_new_points := v_current_points + p_points;
    
    -- Récupérer le niveau actuel
    SELECT current_tier_id INTO v_current_tier_id
    FROM clients 
    WHERE id = p_client_id;
    
    -- Déterminer le nouveau niveau basé sur les points
    SELECT id INTO v_new_tier_id
    FROM loyalty_tiers
    WHERE points_required <= v_new_points
    ORDER BY points_required DESC
    LIMIT 1;
    
    -- Mettre à jour les points et le niveau du client
    UPDATE clients 
    SET 
        loyalty_points = v_new_points,
        current_tier_id = COALESCE(v_new_tier_id, v_current_tier_id),
        updated_at = NOW()
    WHERE id = p_client_id;
    
    -- Insérer l'historique des points
    INSERT INTO loyalty_points_history (
        client_id,
        points_change,
        points_before,
        points_after,
        description,
        points_type,
        source_type,
        user_id,
        created_at
    ) VALUES (
        p_client_id,
        p_points,
        v_current_points,
        v_new_points,
        p_description,
        'manual',
        'manual',
        v_user_id,
        NOW()
    );
    
    -- Retourner le résultat
    v_result := json_build_object(
        'success', true,
        'client_id', p_client_id,
        'points_added', p_points,
        'points_before', v_current_points,
        'points_after', v_new_points,
        'new_tier_id', v_new_tier_id,
        'description', p_description,
        'user_id', v_user_id
    );
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$;

-- Fonction use_loyalty_points
CREATE OR REPLACE FUNCTION use_loyalty_points(
    p_client_id UUID,
    p_points INTEGER,
    p_description TEXT DEFAULT 'Points utilisés'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_client_exists BOOLEAN;
    v_current_points INTEGER;
    v_new_points INTEGER;
    v_current_tier_id UUID;
    v_new_tier_id UUID;
    v_user_id UUID;
    v_result JSON;
BEGIN
    -- Récupérer l'utilisateur actuel
    v_user_id := auth.uid();
    
    -- Vérifier que le client existe
    SELECT EXISTS(SELECT 1 FROM clients WHERE id = p_client_id) INTO v_client_exists;
    
    IF NOT v_client_exists THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Client non trouvé'
        );
    END IF;
    
    -- Vérifier que les points sont positifs
    IF p_points <= 0 THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Le nombre de points doit être positif'
        );
    END IF;
    
    -- Récupérer les points actuels du client
    SELECT COALESCE(loyalty_points, 0) INTO v_current_points
    FROM clients 
    WHERE id = p_client_id;
    
    -- Vérifier que le client a assez de points
    IF v_current_points < p_points THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Points insuffisants. Points actuels: ' || v_current_points || ', Points demandés: ' || p_points
        );
    END IF;
    
    -- Calculer les nouveaux points
    v_new_points := v_current_points - p_points;
    
    -- Récupérer le niveau actuel
    SELECT current_tier_id INTO v_current_tier_id
    FROM clients 
    WHERE id = p_client_id;
    
    -- Déterminer le nouveau niveau basé sur les points
    SELECT id INTO v_new_tier_id
    FROM loyalty_tiers
    WHERE points_required <= v_new_points
    ORDER BY points_required DESC
    LIMIT 1;
    
    -- Mettre à jour les points et le niveau du client
    UPDATE clients 
    SET 
        loyalty_points = v_new_points,
        current_tier_id = COALESCE(v_new_tier_id, v_current_tier_id),
        updated_at = NOW()
    WHERE id = p_client_id;
    
    -- Insérer l'historique des points (points négatifs pour utilisation)
    INSERT INTO loyalty_points_history (
        client_id,
        points_change,
        points_before,
        points_after,
        description,
        points_type,
        source_type,
        user_id,
        created_at
    ) VALUES (
        p_client_id,
        -p_points, -- Points négatifs pour indiquer une utilisation
        v_current_points,
        v_new_points,
        p_description,
        'usage',
        'manual',
        v_user_id,
        NOW()
    );
    
    -- Retourner le résultat
    v_result := json_build_object(
        'success', true,
        'client_id', p_client_id,
        'points_used', p_points,
        'points_before', v_current_points,
        'points_after', v_new_points,
        'new_tier_id', v_new_tier_id,
        'description', p_description,
        'user_id', v_user_id
    );
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM
        );
END;
$$;

-- 6. CRÉER LE TRIGGER
SELECT '🎯 CRÉATION DU TRIGGER...' as info;

-- Fonction du trigger
CREATE OR REPLACE FUNCTION update_client_tier()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Mettre à jour le niveau basé sur les points
    NEW.current_tier_id = (
        SELECT id 
        FROM loyalty_tiers 
        WHERE points_required <= COALESCE(NEW.loyalty_points, 0)
        ORDER BY points_required DESC 
        LIMIT 1
    );
    
    RETURN NEW;
END;
$$;

-- Créer le trigger
CREATE TRIGGER update_client_tier_trigger
    BEFORE UPDATE ON clients
    FOR EACH ROW
    WHEN (OLD.loyalty_points IS DISTINCT FROM NEW.loyalty_points)
    EXECUTE FUNCTION update_client_tier();

-- 7. ACCORDER LES PERMISSIONS
SELECT '🔐 ACCORD DES PERMISSIONS...' as info;

GRANT EXECUTE ON FUNCTION add_loyalty_points(UUID, INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION add_loyalty_points(UUID, INTEGER, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION use_loyalty_points(UUID, INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION use_loyalty_points(UUID, INTEGER, TEXT) TO anon;

-- 8. INITIALISER LES CLIENTS EXISTANTS
SELECT '🔄 INITIALISATION DES CLIENTS...' as info;

-- Assigner le niveau Bronze à tous les clients
UPDATE clients 
SET current_tier_id = (SELECT id FROM loyalty_tiers WHERE name = 'Bronze' LIMIT 1)
WHERE current_tier_id IS NULL;

-- S'assurer que tous les clients ont des points initialisés
UPDATE clients 
SET loyalty_points = 0
WHERE loyalty_points IS NULL;

-- 9. TEST COMPLET
SELECT '🧪 TEST COMPLET DU SYSTÈME...' as info;

DO $$ 
DECLARE
    v_client_id UUID;
    v_result JSON;
    v_test_points INTEGER;
BEGIN
    -- Récupérer un client pour le test
    SELECT id INTO v_client_id FROM clients LIMIT 1;
    
    IF v_client_id IS NOT NULL THEN
        -- Récupérer les points actuels
        SELECT COALESCE(loyalty_points, 0) INTO v_test_points
        FROM clients WHERE id = v_client_id;
        
        RAISE NOTICE 'Client de test: %, Points actuels: %', v_client_id, v_test_points;
        
        -- Test d'ajout de points
        SELECT add_loyalty_points(v_client_id, 100, 'Test recréation complète') INTO v_result;
        
        IF v_result->>'success' = 'true' THEN
            RAISE NOTICE '✅ Test add_loyalty_points réussi: %', v_result;
        ELSE
            RAISE NOTICE '❌ Test add_loyalty_points échoué: %', v_result->>'error';
        END IF;
        
        -- Vérifier les points après ajout
        SELECT COALESCE(loyalty_points, 0) INTO v_test_points
        FROM clients WHERE id = v_client_id;
        
        RAISE NOTICE 'Points après ajout: %', v_test_points;
        
        -- Test d'utilisation de points
        SELECT use_loyalty_points(v_client_id, 25, 'Test utilisation') INTO v_result;
        
        IF v_result->>'success' = 'true' THEN
            RAISE NOTICE '✅ Test use_loyalty_points réussi: %', v_result;
        ELSE
            RAISE NOTICE '❌ Test use_loyalty_points échoué: %', v_result->>'error';
        END IF;
        
        -- Vérifier les points après utilisation
        SELECT COALESCE(loyalty_points, 0) INTO v_test_points
        FROM clients WHERE id = v_client_id;
        
        RAISE NOTICE 'Points après utilisation: %', v_test_points;
        
    ELSE
        RAISE NOTICE '⚠️ Aucun client trouvé pour le test';
    END IF;
END $$;

-- 10. VÉRIFICATION FINALE
SELECT '🔍 VÉRIFICATION FINALE...' as info;

-- Statistiques finales
SELECT 
    COUNT(*) as total_clients,
    COUNT(CASE WHEN COALESCE(loyalty_points, 0) > 0 THEN 1 END) as clients_avec_points,
    COUNT(CASE WHEN current_tier_id IS NOT NULL THEN 1 END) as clients_avec_niveau,
    AVG(COALESCE(loyalty_points, 0)) as moyenne_points
FROM clients;

-- Afficher la répartition par niveau
SELECT 
    lt.name as niveau,
    COUNT(c.id) as nombre_clients,
    AVG(COALESCE(c.loyalty_points, 0)) as moyenne_points
FROM loyalty_tiers lt
LEFT JOIN clients c ON lt.id = c.current_tier_id
GROUP BY lt.id, lt.name, lt.points_required
ORDER BY lt.points_required;

SELECT '✅ Recréation complète terminée avec succès !' as result;
