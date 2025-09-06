-- CORRECTION TEMPORAIRE POUR LA FONCTION ADD_LOYALTY_POINTS
-- Crée une version qui évite le problème de contrainte de clé étrangère

-- 1. SUPPRIMER L'ANCIENNE FONCTION SI ELLE EXISTE
DROP FUNCTION IF EXISTS add_loyalty_points(p_client_id UUID, p_points INTEGER, p_description TEXT);

-- 2. CRÉER LA NOUVELLE FONCTION CORRIGÉE
CREATE OR REPLACE FUNCTION add_loyalty_points(
    p_client_id UUID,
    p_points INTEGER,
    p_description TEXT
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_client_exists BOOLEAN;
    v_new_points INTEGER;
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
    
    -- Mettre à jour les points du client (sans toucher current_tier_id)
    UPDATE clients 
    SET loyalty_points = loyalty_points + p_points
    WHERE id = p_client_id;
    
    -- Récupérer le nouveau total de points
    SELECT loyalty_points INTO v_new_points 
    FROM clients 
    WHERE id = p_client_id;
    
    -- Insérer dans l'historique des points
    INSERT INTO client_loyalty_points (
        client_id,
        points_added,
        points_used,
        description,
        created_at
    ) VALUES (
        p_client_id,
        p_points,
        0,
        p_description,
        NOW()
    );
    
    -- Retourner le succès
    RETURN json_build_object(
        'success', true,
        'message', 'Points ajoutés avec succès',
        'new_total', v_new_points,
        'points_added', p_points
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors de l''ajout des points: ' || SQLERRM
        );
END;
$$;

-- 3. ACCORDER LES PERMISSIONS
GRANT EXECUTE ON FUNCTION add_loyalty_points(UUID, INTEGER, TEXT) TO authenticated;

-- 4. CRÉER UNE FONCTION POUR ASSIGNER LES NIVEAUX MANUELLEMENT
CREATE OR REPLACE FUNCTION assign_loyalty_tiers()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_updated_count INTEGER;
BEGIN
    -- Assigner les niveaux selon les points
    UPDATE clients 
    SET current_tier_id = (
        SELECT id 
        FROM loyalty_tiers_advanced 
        WHERE points_required <= clients.loyalty_points 
        AND is_active = true
        ORDER BY points_required DESC 
        LIMIT 1
    )
    WHERE loyalty_points > 0;
    
    GET DIAGNOSTICS v_updated_count = ROW_COUNT;
    
    RETURN json_build_object(
        'success', true,
        'message', 'Niveaux assignés avec succès',
        'clients_updated', v_updated_count
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors de l''assignation des niveaux: ' || SQLERRM
        );
END;
$$;

-- 5. ACCORDER LES PERMISSIONS
GRANT EXECUTE ON FUNCTION assign_loyalty_tiers() TO authenticated;

-- 6. MESSAGE DE CONFIRMATION
SELECT '🎉 FONCTIONS CORRIGÉES !' as result;
SELECT '📋 add_loyalty_points ne met plus à jour current_tier_id automatiquement.' as next_step;
SELECT '🔧 Utilisez assign_loyalty_tiers() pour assigner les niveaux manuellement.' as instruction;





