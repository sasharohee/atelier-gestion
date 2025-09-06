-- Correction rapide pour la colonne points_type manquante
-- Ce script corrige l'erreur de contrainte NOT NULL sur points_type

-- 1. AJOUTER LES COLONNES MANQUANTES
SELECT '🔧 AJOUT DES COLONNES MANQUANTES...' as info;

DO $$ 
BEGIN
    -- Ajouter points_type si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'loyalty_points_history' 
        AND column_name = 'points_type'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE loyalty_points_history ADD COLUMN points_type TEXT NOT NULL DEFAULT 'manual';
        RAISE NOTICE 'Colonne points_type ajoutée avec succès';
    ELSE
        RAISE NOTICE 'Colonne points_type existe déjà';
    END IF;
    
    -- Ajouter source_type si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'loyalty_points_history' 
        AND column_name = 'source_type'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE loyalty_points_history ADD COLUMN source_type TEXT NOT NULL DEFAULT 'manual';
        RAISE NOTICE 'Colonne source_type ajoutée avec succès';
    ELSE
        RAISE NOTICE 'Colonne source_type existe déjà';
    END IF;
    
    -- Ajouter user_id si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'loyalty_points_history' 
        AND column_name = 'user_id'
        AND table_schema = 'public'
    ) THEN
        ALTER TABLE loyalty_points_history ADD COLUMN user_id UUID;
        RAISE NOTICE 'Colonne user_id ajoutée avec succès';
    ELSE
        RAISE NOTICE 'Colonne user_id existe déjà';
    END IF;
END $$;

-- 2. METTRE À JOUR LES ENREGISTREMENTS EXISTANTS
SELECT '🔄 MISE À JOUR DES ENREGISTREMENTS EXISTANTS...' as info;

UPDATE loyalty_points_history 
SET points_type = 'manual' 
WHERE points_type IS NULL OR points_type = '';

UPDATE loyalty_points_history 
SET source_type = 'manual' 
WHERE source_type IS NULL OR source_type = '';

-- Mettre à jour user_id avec une valeur par défaut si nécessaire
UPDATE loyalty_points_history 
SET user_id = (SELECT id FROM auth.users LIMIT 1)
WHERE user_id IS NULL;

-- 3. SUPPRIMER LES FONCTIONS EXISTANTES
SELECT '🗑️ SUPPRESSION DES FONCTIONS EXISTANTES...' as info;

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

-- 4. CRÉER LA FONCTION ADD_LOYALTY_POINTS CORRIGÉE
SELECT '✅ CRÉATION DE LA FONCTION ADD_LOYALTY_POINTS CORRIGÉE...' as info;

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
    v_result JSON;
BEGIN
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
        auth.uid(),
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
        'description', p_description
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

-- 5. CRÉER LA FONCTION USE_LOYALTY_POINTS CORRIGÉE
SELECT '✅ CRÉATION DE LA FONCTION USE_LOYALTY_POINTS CORRIGÉE...' as info;

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
    v_result JSON;
BEGIN
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
        auth.uid(),
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
        'description', p_description
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

-- 6. ACCORDER LES PERMISSIONS
GRANT EXECUTE ON FUNCTION add_loyalty_points(UUID, INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION add_loyalty_points(UUID, INTEGER, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION use_loyalty_points(UUID, INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION use_loyalty_points(UUID, INTEGER, TEXT) TO anon;

-- 7. VÉRIFICATION FINALE
SELECT '🔍 VÉRIFICATION FINALE...' as info;

SELECT 
    p.proname as nom_fonction,
    pg_get_function_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
AND p.proname IN ('add_loyalty_points', 'use_loyalty_points')
ORDER BY p.proname;

SELECT '✅ Correction de la colonne points_type terminée !' as result;
