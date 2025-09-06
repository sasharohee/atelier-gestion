-- Correction du conflit de surcharge de fonction add_loyalty_points
-- Date: 2024-01-24

-- ============================================================================
-- 1. DIAGNOSTIC DU PROBLÈME
-- ============================================================================

-- Vérifier les fonctions existantes
SELECT '=== FONCTIONS EXISTANTES ===' as section;

SELECT 
    p.proname as function_name,
    pg_get_function_arguments(p.oid) as arguments,
    pg_get_function_result(p.oid) as return_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
AND p.proname = 'add_loyalty_points'
ORDER BY p.proname;

-- ============================================================================
-- 2. SUPPRESSION DES FONCTIONS EN CONFLIT
-- ============================================================================

SELECT '=== SUPPRESSION DES FONCTIONS EN CONFLIT ===' as section;

-- Supprimer toutes les versions de la fonction
DROP FUNCTION IF EXISTS add_loyalty_points(UUID, INTEGER, TEXT, TEXT, UUID, TEXT, UUID);
DROP FUNCTION IF EXISTS add_loyalty_points(UUID, INTEGER, TEXT);
DROP FUNCTION IF EXISTS add_loyalty_points(UUID, INTEGER);

-- ============================================================================
-- 3. CRÉATION DE LA FONCTION UNIFIÉE
-- ============================================================================

SELECT '=== CRÉATION DE LA FONCTION UNIFIÉE ===' as section;

-- Créer une version unifiée de la fonction add_loyalty_points
CREATE OR REPLACE FUNCTION add_loyalty_points(
    p_client_id UUID,
    p_points INTEGER,
    p_description TEXT DEFAULT 'Points ajoutés manuellement',
    p_points_type TEXT DEFAULT 'earned',
    p_source_type TEXT DEFAULT 'manual',
    p_source_id UUID DEFAULT NULL,
    p_created_by UUID DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_client_loyalty client_loyalty_points%ROWTYPE;
    v_tier loyalty_tiers%ROWTYPE;
    v_user_id UUID;
    v_current_points INTEGER;
    v_result JSON;
BEGIN
    -- Récupérer le user_id du client
    SELECT user_id INTO v_user_id
    FROM public.clients
    WHERE id = p_client_id;
    
    -- Si p_created_by n'est pas fourni, utiliser l'utilisateur connecté
    IF p_created_by IS NULL THEN
        p_created_by := auth.uid();
    END IF;
    
    -- Vérifier que l'utilisateur connecté a accès à ce client
    IF v_user_id != auth.uid() THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Accès non autorisé à ce client'
        );
    END IF;
    
    -- Vérifier si le client existe déjà dans la table des points
    SELECT * INTO v_client_loyalty
    FROM client_loyalty_points
    WHERE client_id = p_client_id;
    
    IF v_client_loyalty IS NULL THEN
        -- Créer une nouvelle entrée
        INSERT INTO client_loyalty_points (client_id, total_points, used_points, user_id)
        VALUES (p_client_id, p_points, 0, v_user_id)
        RETURNING * INTO v_client_loyalty;
    ELSE
        -- Mettre à jour les points existants
        UPDATE client_loyalty_points
        SET 
            total_points = client_loyalty_points.total_points + p_points,
            updated_at = NOW()
        WHERE client_id = p_client_id
        RETURNING * INTO v_client_loyalty;
    END IF;
    
    -- Calculer les points disponibles
    v_current_points := v_client_loyalty.total_points - v_client_loyalty.used_points;
    
    -- Calculer le nouveau niveau
    SELECT * INTO v_tier
    FROM loyalty_tiers
    WHERE min_points <= v_current_points
    ORDER BY min_points DESC
    LIMIT 1;
    
    -- Mettre à jour le niveau si nécessaire
    IF v_tier.id != v_client_loyalty.current_tier_id THEN
        UPDATE client_loyalty_points
        SET current_tier_id = v_tier.id
        WHERE client_id = p_client_id;
    END IF;
    
    -- Ajouter l'historique
    INSERT INTO loyalty_points_history (
        client_id, 
        points_change, 
        points_type, 
        source_type, 
        source_id,
        description, 
        created_by,
        user_id
    ) VALUES (
        p_client_id, 
        p_points, 
        p_points_type, 
        p_source_type, 
        p_source_id,
        p_description,
        p_created_by,
        v_user_id
    );
    
    -- Construire la réponse
    SELECT json_build_object(
        'success', true,
        'data', json_build_object(
            'client_id', v_client_loyalty.client_id,
            'points_added', p_points,
            'total_points', v_client_loyalty.total_points,
            'used_points', v_client_loyalty.used_points,
            'available_points', v_current_points,
            'current_tier', COALESCE(v_tier.name, 'Aucun niveau'),
            'new_tier_id', v_tier.id
        ),
        'message', 'Points ajoutés avec succès'
    ) INTO v_result;
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors de l''ajout des points: ' || SQLERRM
        );
END;
$$;

-- ============================================================================
-- 4. CONFIGURATION DES PERMISSIONS
-- ============================================================================

SELECT '=== CONFIGURATION DES PERMISSIONS ===' as section;

-- Accorder les permissions d'exécution
GRANT EXECUTE ON FUNCTION add_loyalty_points(UUID, INTEGER, TEXT, TEXT, TEXT, UUID, UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION add_loyalty_points(UUID, INTEGER, TEXT, TEXT, TEXT, UUID, UUID) TO anon;

-- ============================================================================
-- 5. TEST DE LA FONCTION
-- ============================================================================

SELECT '=== TEST DE LA FONCTION ===' as section;

-- Vérifier que la fonction existe
SELECT 
    p.proname as function_name,
    pg_get_function_arguments(p.oid) as arguments,
    pg_get_function_result(p.oid) as return_type
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
AND p.proname = 'add_loyalty_points'
ORDER BY p.proname;

-- ============================================================================
-- 6. VÉRIFICATION FINALE
-- ============================================================================

SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Compter les fonctions add_loyalty_points
SELECT 
    COUNT(*) as nombre_fonctions,
    'add_loyalty_points' as nom_fonction
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
AND p.proname = 'add_loyalty_points';

-- Afficher un message de succès
SELECT '✅ Fonction add_loyalty_points corrigée avec succès !' as result;
