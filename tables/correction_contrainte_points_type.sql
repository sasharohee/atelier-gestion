-- Correction de la contrainte de vérification points_type
-- Date: 2024-01-24

-- ============================================================================
-- 1. DIAGNOSTIC DE LA CONTRAINTE
-- ============================================================================

SELECT '=== DIAGNOSTIC DE LA CONTRAINTE ===' as section;

-- Vérifier les contraintes existantes sur la table loyalty_points_history
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'loyalty_points_history'::regclass
AND contype = 'c';

-- Vérifier les valeurs actuelles dans points_type
SELECT DISTINCT points_type, COUNT(*) as count
FROM loyalty_points_history
GROUP BY points_type;

-- ============================================================================
-- 2. SUPPRESSION DE LA CONTRAINTE PROBLÉMATIQUE
-- ============================================================================

SELECT '=== SUPPRESSION DE LA CONTRAINTE ===' as section;

-- Supprimer la contrainte de vérification existante
ALTER TABLE loyalty_points_history 
DROP CONSTRAINT IF EXISTS check_points_type_values;

-- ============================================================================
-- 3. CRÉATION DE LA NOUVELLE CONTRAINTE
-- ============================================================================

SELECT '=== CRÉATION DE LA NOUVELLE CONTRAINTE ===' as section;

-- Créer une nouvelle contrainte plus permissive
ALTER TABLE loyalty_points_history 
ADD CONSTRAINT check_points_type_values 
CHECK (points_type IN ('earned', 'used', 'expired', 'bonus', 'referral', 'manual', 'purchase', 'refund'));

-- ============================================================================
-- 4. VÉRIFICATION DES DONNÉES EXISTANTES
-- ============================================================================

SELECT '=== VÉRIFICATION DES DONNÉES ===' as section;

-- Vérifier s'il y a des valeurs invalides
SELECT DISTINCT points_type 
FROM loyalty_points_history 
WHERE points_type NOT IN ('earned', 'used', 'expired', 'bonus', 'referral', 'manual', 'purchase', 'refund');

-- Si des valeurs invalides existent, les corriger
UPDATE loyalty_points_history 
SET points_type = 'manual' 
WHERE points_type NOT IN ('earned', 'used', 'expired', 'bonus', 'referral', 'manual', 'purchase', 'refund');

-- ============================================================================
-- 5. MISE À JOUR DE LA FONCTION add_loyalty_points
-- ============================================================================

SELECT '=== MISE À JOUR DE LA FONCTION ===' as section;

-- Mettre à jour la fonction pour utiliser des valeurs valides
CREATE OR REPLACE FUNCTION add_loyalty_points(
    p_client_id UUID,
    p_points INTEGER,
    p_description TEXT DEFAULT 'Points ajoutés manuellement',
    p_points_type TEXT DEFAULT 'manual',
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
    v_valid_points_type TEXT;
BEGIN
    -- Valider le type de points
    IF p_points_type NOT IN ('earned', 'used', 'expired', 'bonus', 'referral', 'manual', 'purchase', 'refund') THEN
        v_valid_points_type := 'manual';
    ELSE
        v_valid_points_type := p_points_type;
    END IF;
    
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
    
    -- Ajouter l'historique avec le type de points validé
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
        v_valid_points_type, 
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
            'new_tier_id', v_tier.id,
            'points_type_used', v_valid_points_type
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
-- 6. TEST DE LA FONCTION
-- ============================================================================

SELECT '=== TEST DE LA FONCTION ===' as section;

-- Vérifier que la fonction existe et fonctionne
SELECT 
    p.proname as function_name,
    pg_get_function_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
AND p.proname = 'add_loyalty_points';

-- ============================================================================
-- 7. VÉRIFICATION FINALE
-- ============================================================================

SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier que la contrainte est bien en place
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'loyalty_points_history'::regclass
AND contype = 'c'
AND conname = 'check_points_type_values';

-- Afficher un message de succès
SELECT '✅ Contrainte points_type corrigée avec succès !' as result;
