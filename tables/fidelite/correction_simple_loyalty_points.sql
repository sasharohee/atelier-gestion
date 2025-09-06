-- Correction simple du système de points de fidélité
-- Ce script corrige directement le problème des points qui ne s'ajoutent pas

-- 1. VÉRIFIER ET AJOUTER LES COLONNES MANQUANTES
SELECT '🔧 VÉRIFICATION ET AJOUT DES COLONNES MANQUANTES...' as info;

DO $$ 
BEGIN
    -- Ajouter loyalty_points si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' 
        AND column_name = 'loyalty_points'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE clients ADD COLUMN loyalty_points INTEGER DEFAULT 0;
        RAISE NOTICE 'Colonne loyalty_points ajoutée';
    ELSE
        RAISE NOTICE 'Colonne loyalty_points existe déjà';
    END IF;
    
    -- Ajouter current_tier_id si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'clients' 
        AND column_name = 'current_tier_id'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE clients ADD COLUMN current_tier_id UUID;
        RAISE NOTICE 'Colonne current_tier_id ajoutée';
    ELSE
        RAISE NOTICE 'Colonne current_tier_id existe déjà';
    END IF;
END $$;

-- 2. CRÉER LES TABLES DE SUPPORT SI ELLES N'EXISTENT PAS
SELECT '🏗️ CRÉATION DES TABLES DE SUPPORT...' as info;

-- Créer loyalty_tiers si elle n'existe pas
CREATE TABLE IF NOT EXISTS loyalty_tiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    min_points INTEGER NOT NULL DEFAULT 0,
    points_required INTEGER NOT NULL DEFAULT 0,
    discount_percentage DECIMAL(5,2) DEFAULT 0,
    color TEXT DEFAULT '#000000',
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Créer loyalty_points_history si elle n'existe pas
CREATE TABLE IF NOT EXISTS loyalty_points_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    points_change INTEGER NOT NULL,
    points_before INTEGER NOT NULL,
    points_after INTEGER NOT NULL,
    description TEXT,
    points_type TEXT DEFAULT 'manual',
    source_type TEXT DEFAULT 'manual',
    user_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. CORRIGER ET INSÉRER LES NIVEAUX DE FIDÉLITÉ
SELECT '🎯 CORRECTION ET AJOUT DES NIVEAUX DE FIDÉLITÉ...' as info;

-- Ajouter la colonne min_points si elle n'existe pas
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'loyalty_tiers' 
        AND column_name = 'min_points'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE loyalty_tiers ADD COLUMN min_points INTEGER DEFAULT 0;
        RAISE NOTICE 'Colonne min_points ajoutée à loyalty_tiers';
    END IF;
END $$;

-- Mettre à jour les enregistrements existants avec min_points = 0 si NULL
UPDATE loyalty_tiers SET min_points = 0 WHERE min_points IS NULL;

-- Insérer ou mettre à jour les niveaux de fidélité
INSERT INTO loyalty_tiers (name, description, min_points, points_required, discount_percentage, color) 
VALUES 
    ('Bronze', 'Niveau de base', 0, 0, 0, '#CD7F32'),
    ('Argent', 'Client régulier', 0, 100, 5, '#C0C0C0'),
    ('Or', 'Client fidèle', 100, 500, 10, '#FFD700'),
    ('Platine', 'Client VIP', 500, 1000, 15, '#E5E4E2'),
    ('Diamant', 'Client premium', 1000, 2000, 20, '#B9F2FF')
ON CONFLICT (name) DO UPDATE SET
    description = EXCLUDED.description,
    min_points = EXCLUDED.min_points,
    points_required = EXCLUDED.points_required,
    discount_percentage = EXCLUDED.discount_percentage,
    color = EXCLUDED.color,
    updated_at = NOW();

-- 4. AJOUTER LA CONTRAINTE DE CLÉ ÉTRANGÈRE
SELECT '🔗 AJOUT DE LA CONTRAINTE DE CLÉ ÉTRANGÈRE...' as info;

-- Supprimer la contrainte existante si elle existe
ALTER TABLE clients DROP CONSTRAINT IF EXISTS clients_current_tier_id_fkey;

-- Ajouter la contrainte de clé étrangère
ALTER TABLE clients 
ADD CONSTRAINT clients_current_tier_id_fkey 
FOREIGN KEY (current_tier_id) REFERENCES loyalty_tiers(id) ON DELETE SET NULL;

-- 5. METTRE À JOUR LES CLIENTS EXISTANTS
SELECT '🔄 MISE À JOUR DES CLIENTS EXISTANTS...' as info;

-- Mettre à jour les points de fidélité
UPDATE clients 
SET loyalty_points = COALESCE(loyalty_points, 0)
WHERE loyalty_points IS NULL;

-- Mettre à jour le niveau de fidélité avec Bronze par défaut
UPDATE clients 
SET current_tier_id = COALESCE(current_tier_id, (SELECT id FROM loyalty_tiers WHERE name = 'Bronze' LIMIT 1))
WHERE current_tier_id IS NULL;

-- 6. SUPPRIMER ET RECRÉER LES FONCTIONS
SELECT '⚙️ RECRÉATION DES FONCTIONS...' as info;

-- Supprimer les fonctions existantes
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

-- 7. CRÉER LA FONCTION ADD_LOYALTY_POINTS SIMPLIFIÉE
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

-- 8. CRÉER LA FONCTION USE_LOYALTY_POINTS SIMPLIFIÉE
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

-- 9. ACCORDER LES PERMISSIONS
GRANT EXECUTE ON FUNCTION add_loyalty_points(UUID, INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION add_loyalty_points(UUID, INTEGER, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION use_loyalty_points(UUID, INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION use_loyalty_points(UUID, INTEGER, TEXT) TO anon;

-- 10. TEST RAPIDE
SELECT '🧪 TEST RAPIDE...' as info;

DO $$ 
DECLARE
    v_client_id UUID;
    v_result JSON;
BEGIN
    -- Récupérer un client pour le test
    SELECT id INTO v_client_id FROM clients LIMIT 1;
    
    IF v_client_id IS NOT NULL THEN
        -- Test d'ajout de points
        SELECT add_loyalty_points(v_client_id, 50, 'Test correction simple') INTO v_result;
        
        IF v_result->>'success' = 'true' THEN
            RAISE NOTICE '✅ Test réussi: Points ajoutés avec succès';
        ELSE
            RAISE NOTICE '❌ Test échoué: %', v_result->>'error';
        END IF;
    ELSE
        RAISE NOTICE '⚠️ Aucun client trouvé pour le test';
    END IF;
END $$;

-- 11. VÉRIFICATION FINALE
SELECT '🔍 VÉRIFICATION FINALE...' as info;

SELECT 
    COUNT(*) as total_clients,
    COUNT(CASE WHEN COALESCE(loyalty_points, 0) > 0 THEN 1 END) as clients_avec_points,
    AVG(COALESCE(loyalty_points, 0)) as moyenne_points
FROM clients;

SELECT '✅ Correction simple terminée !' as result;
