-- =====================================================
-- CRÉATION DE LA FONCTION USE_LOYALTY_POINTS
-- =====================================================
-- Fonction pour utiliser des points de fidélité
-- =====================================================

-- Fonction pour utiliser des points de fidélité
CREATE OR REPLACE FUNCTION use_loyalty_points(
    p_client_id UUID,
    p_points INTEGER,
    p_description TEXT DEFAULT ''
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_current_points INTEGER;
    v_available_points INTEGER;
    v_new_tier_id UUID;
    v_result JSON;
BEGIN
    -- Vérifier que le client existe
    IF NOT EXISTS (SELECT 1 FROM clients WHERE id = p_client_id) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Client non trouvé'
        );
    END IF;
    
    -- Vérifier que le client a des points de fidélité
    IF NOT EXISTS (SELECT 1 FROM client_loyalty_points WHERE client_id = p_client_id) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Ce client n''a pas de points de fidélité'
        );
    END IF;
    
    -- Récupérer les points actuels
    SELECT total_points, used_points, (total_points - used_points) 
    INTO v_current_points, v_available_points, v_available_points
    FROM client_loyalty_points
    WHERE client_id = p_client_id;
    
    -- Vérifier que le client a assez de points disponibles
    IF v_available_points < p_points THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Points insuffisants. Points disponibles: ' || v_available_points || ', Points demandés: ' || p_points
        );
    END IF;
    
    -- Vérifier que le nombre de points est positif
    IF p_points <= 0 THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Le nombre de points à utiliser doit être positif'
        );
    END IF;
    
    -- Mettre à jour les points utilisés
    UPDATE client_loyalty_points
    SET 
        used_points = used_points + p_points,
        updated_at = NOW()
    WHERE client_id = p_client_id;
    
    -- Recalculer les points disponibles
    SELECT (total_points - used_points) INTO v_available_points
    FROM client_loyalty_points
    WHERE client_id = p_client_id;
    
    -- Recalculer le niveau de fidélité
    v_new_tier_id := calculate_client_tier(p_client_id);
    
    -- Mettre à jour le niveau actuel
    UPDATE client_loyalty_points
    SET current_tier_id = v_new_tier_id
    WHERE client_id = p_client_id;
    
    -- Ajouter l'historique
    INSERT INTO loyalty_points_history (
        client_id, points_change, points_type, source_type, 
        source_id, description, created_by, user_id
    ) VALUES (
        p_client_id, -p_points, 'used', 'manual',
        NULL, p_description, COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::UUID),
        COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::UUID)
    );
    
    -- Retourner le résultat
    SELECT json_build_object(
        'success', true,
        'data', json_build_object(
            'client_id', p_client_id,
            'points_used', p_points,
            'available_points', v_available_points,
            'new_tier_id', v_new_tier_id
        ),
        'message', 'Points utilisés avec succès'
    ) INTO v_result;
    
    RETURN v_result;
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors de l''utilisation des points: ' || SQLERRM
        );
END;
$$;

-- Vérification de la création
SELECT '✅ Fonction use_loyalty_points créée avec succès' as status;

-- Test de la fonction (optionnel - à décommenter pour tester)
-- SELECT use_loyalty_points('client_id_ici', 10, 'Test utilisation points');
