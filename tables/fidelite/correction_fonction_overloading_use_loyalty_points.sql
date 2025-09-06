-- Correction du conflit de surcharge de fonction use_loyalty_points
-- Ce script résout l'erreur PGRST203 en supprimant toutes les versions de la fonction
-- et en créant une seule version unifiée

-- 1. AFFICHER TOUTES LES VERSIONS EXISTANTES DE LA FONCTION
SELECT '🔍 VERSIONS EXISTANTES DE use_loyalty_points:' as info;

SELECT 
    p.proname as nom_fonction,
    pg_get_function_arguments(p.oid) as arguments,
    p.oid as fonction_id
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
AND p.proname = 'use_loyalty_points'
ORDER BY p.oid;

-- 2. SUPPRIMER TOUTES LES VERSIONS DE LA FONCTION
SELECT '🗑️ SUPPRESSION DE TOUTES LES VERSIONS...' as info;

-- Supprimer toutes les versions possibles de la fonction
DROP FUNCTION IF EXISTS use_loyalty_points(UUID, INTEGER, TEXT, TEXT, TEXT, UUID, UUID);
DROP FUNCTION IF EXISTS use_loyalty_points(UUID, INTEGER, TEXT, TEXT, UUID, TEXT, UUID);
DROP FUNCTION IF EXISTS use_loyalty_points(UUID, INTEGER, TEXT, TEXT, UUID, TEXT);
DROP FUNCTION IF EXISTS use_loyalty_points(UUID, INTEGER, TEXT, TEXT, UUID);
DROP FUNCTION IF EXISTS use_loyalty_points(UUID, INTEGER, TEXT, TEXT);
DROP FUNCTION IF EXISTS use_loyalty_points(UUID, INTEGER, TEXT);
DROP FUNCTION IF EXISTS use_loyalty_points(UUID, INTEGER);
DROP FUNCTION IF EXISTS use_loyalty_points(UUID, INTEGER, TEXT, UUID);
DROP FUNCTION IF EXISTS use_loyalty_points(UUID, INTEGER, UUID);

-- 3. VÉRIFIER QUE TOUTES LES FONCTIONS ONT ÉTÉ SUPPRIMÉES
SELECT '🔍 VÉRIFICATION APRÈS SUPPRESSION:' as info;

SELECT 
    p.proname as nom_fonction,
    pg_get_function_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
AND p.proname = 'use_loyalty_points';

-- 4. CRÉER UNE SEULE VERSION UNIFIÉE DE LA FONCTION
SELECT '✅ CRÉATION DE LA VERSION UNIFIÉE...' as info;

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
        created_at
    ) VALUES (
        p_client_id,
        -p_points, -- Points négatifs pour indiquer une utilisation
        v_current_points,
        v_new_points,
        p_description,
        'usage',
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

-- 5. ACCORDER LES PERMISSIONS
GRANT EXECUTE ON FUNCTION use_loyalty_points(UUID, INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION use_loyalty_points(UUID, INTEGER, TEXT) TO anon;

-- 6. VÉRIFIER QUE LA FONCTION A ÉTÉ CRÉÉE CORRECTEMENT
SELECT '🔍 VÉRIFICATION FINALE:' as info;

SELECT 
    p.proname as nom_fonction,
    pg_get_function_arguments(p.oid) as arguments,
    p.oid as fonction_id
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
AND p.proname = 'use_loyalty_points';

-- 7. TESTER LA FONCTION
SELECT '🧪 TEST DE LA FONCTION...' as info;

-- Note: Ce test nécessite un client_id valide avec des points suffisants
-- SELECT use_loyalty_points('client_id_ici', 5, 'Test d''utilisation');

SELECT '✅ Correction du conflit de surcharge terminée !' as result;
SELECT '📋 Signature finale: use_loyalty_points(UUID, INTEGER, TEXT)' as signature;
