-- =====================================================
-- CORRECTION AFFICHAGE NIVEAU ACTUEL
-- =====================================================
-- Problème : La colonne "Niveau Actuel" ne s'affiche pas
-- Solution : Mettre à jour les current_tier_id manquants
-- Date: 2025-01-23
-- =====================================================

-- 1. VÉRIFICATION DE LA STRUCTURE ACTUELLE
SELECT '=== VÉRIFICATION STRUCTURE ===' as etape;

-- Vérifier la structure de client_loyalty_points
SELECT 
    'STRUCTURE client_loyalty_points' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'client_loyalty_points' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Vérifier les niveaux de fidélité existants
SELECT 
    'NIVEAUX FIDÉLITÉ' as info,
    id,
    name,
    min_points,
    discount_percentage,
    color
FROM loyalty_tiers
ORDER BY min_points;

-- 2. DIAGNOSTIC DES DONNÉES ACTUELLES
SELECT '=== DIAGNOSTIC DONNÉES ===' as etape;

-- Vérifier les clients avec points et leurs niveaux actuels
SELECT 
    'CLIENTS AVEC POINTS' as info,
    clp.id,
    clp.client_id,
    c.first_name,
    c.last_name,
    clp.total_points,
    clp.used_points,
    (clp.total_points - clp.used_points) as points_disponibles,
    clp.current_tier_id,
    lt.name as niveau_actuel,
    lt.color as couleur_niveau
FROM client_loyalty_points clp
LEFT JOIN clients c ON clp.client_id = c.id
LEFT JOIN loyalty_tiers lt ON clp.current_tier_id = lt.id
ORDER BY (clp.total_points - clp.used_points) DESC;

-- 3. CORRECTION DES NIVEAUX ACTUELS
SELECT '=== CORRECTION NIVEAUX ===' as etape;

-- Fonction pour calculer le niveau correct basé sur les points disponibles
CREATE OR REPLACE FUNCTION calculate_correct_tier(points_available INTEGER)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_tier_id UUID;
BEGIN
    -- Trouver le niveau le plus élevé que le client peut atteindre avec ses points
    SELECT id INTO v_tier_id
    FROM loyalty_tiers
    WHERE min_points <= points_available
    ORDER BY min_points DESC
    LIMIT 1;
    
    RETURN v_tier_id;
END;
$$;

-- Mettre à jour tous les current_tier_id manquants ou incorrects
UPDATE client_loyalty_points 
SET current_tier_id = calculate_correct_tier(total_points - used_points)
WHERE current_tier_id IS NULL 
   OR current_tier_id != calculate_correct_tier(total_points - used_points);

-- 4. VÉRIFICATION APRÈS CORRECTION
SELECT '=== VÉRIFICATION APRÈS CORRECTION ===' as etape;

-- Vérifier les clients avec points et leurs niveaux actuels (après correction)
SELECT 
    'CLIENTS CORRIGÉS' as info,
    clp.id,
    clp.client_id,
    c.first_name,
    c.last_name,
    clp.total_points,
    clp.used_points,
    (clp.total_points - clp.used_points) as points_disponibles,
    clp.current_tier_id,
    lt.name as niveau_actuel,
    lt.color as couleur_niveau
FROM client_loyalty_points clp
LEFT JOIN clients c ON clp.client_id = c.id
LEFT JOIN loyalty_tiers lt ON clp.current_tier_id = lt.id
ORDER BY (clp.total_points - clp.used_points) DESC;

-- 5. AMÉLIORATION DE LA FONCTION add_loyalty_points
SELECT '=== AMÉLIORATION FONCTION ===' as etape;

-- Améliorer la fonction add_loyalty_points pour s'assurer que current_tier_id est toujours mis à jour
CREATE OR REPLACE FUNCTION add_loyalty_points(
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
    v_new_tier_id UUID;
    v_result JSON;
BEGIN
    -- Insérer ou mettre à jour les points du client
    INSERT INTO client_loyalty_points (client_id, total_points, used_points)
    VALUES (p_client_id, p_points, 0)
    ON CONFLICT (client_id) 
    DO UPDATE SET 
        total_points = client_loyalty_points.total_points + p_points,
        updated_at = NOW();
    
    -- Calculer les points disponibles
    SELECT total_points - used_points INTO v_current_points
    FROM client_loyalty_points
    WHERE client_id = p_client_id;
    
    -- Calculer le nouveau niveau
    v_new_tier_id := calculate_correct_tier(v_current_points);
    
    -- Mettre à jour le niveau actuel
    UPDATE client_loyalty_points
    SET current_tier_id = v_new_tier_id
    WHERE client_id = p_client_id;
    
    -- Ajouter l'historique
    INSERT INTO loyalty_points_history (
        client_id, points_change, points_type, source_type, 
        source_id, description, created_by
    ) VALUES (
        p_client_id, p_points, 'earned', 'manual',
        NULL, p_description, auth.uid()
    );
    
    -- Retourner le résultat
    SELECT json_build_object(
        'success', true,
        'data', json_build_object(
            'client_id', p_client_id,
            'points_added', p_points,
            'total_points', v_current_points,
            'new_tier_id', v_new_tier_id
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

-- 6. TEST DE LA CORRECTION
SELECT '=== TEST CORRECTION ===' as etape;

-- Tester avec un client existant (remplacer par un vrai client_id si nécessaire)
-- SELECT add_loyalty_points('client_id_ici', 50, 'Test correction niveau');

-- 7. VÉRIFICATION FINALE
SELECT '=== VÉRIFICATION FINALE ===' as etape;

-- Compter les clients avec et sans niveau
SELECT 
    'STATISTIQUES NIVEAUX' as info,
    COUNT(*) as total_clients,
    COUNT(current_tier_id) as clients_avec_niveau,
    COUNT(*) - COUNT(current_tier_id) as clients_sans_niveau
FROM client_loyalty_points;

-- Afficher les clients sans niveau (s'il y en a)
SELECT 
    'CLIENTS SANS NIVEAU' as info,
    clp.client_id,
    c.first_name,
    c.last_name,
    clp.total_points,
    clp.used_points,
    (clp.total_points - clp.used_points) as points_disponibles
FROM client_loyalty_points clp
LEFT JOIN clients c ON clp.client_id = c.id
WHERE clp.current_tier_id IS NULL;

SELECT '✅ CORRECTION TERMINÉE' as status;
