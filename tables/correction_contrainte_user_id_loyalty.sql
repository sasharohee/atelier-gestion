-- Correction de la contrainte de clé étrangère user_id
-- Ce script corrige l'erreur de contrainte foreign key sur user_id

-- 1. VÉRIFIER LA CONTRAINTE EXISTANTE
SELECT '🔍 VÉRIFICATION DE LA CONTRAINTE USER_ID...' as info;

SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
LEFT JOIN information_schema.constraint_column_usage ccu 
    ON tc.constraint_name = ccu.constraint_name
WHERE tc.table_name = 'loyalty_points_history' 
AND tc.table_schema = 'public'
AND kcu.column_name = 'user_id';

-- 2. VÉRIFIER SI LA COLONNE USER_ID EXISTE
SELECT '🔍 VÉRIFICATION DE LA COLONNE USER_ID...' as info;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'loyalty_points_history' 
AND table_schema = 'public'
AND column_name = 'user_id';

-- 3. AJOUTER LA COLONNE USER_ID SI ELLE N'EXISTE PAS
SELECT '🔧 AJOUT DE LA COLONNE USER_ID...' as info;

DO $$ 
BEGIN
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

-- 4. SUPPRIMER LA CONTRAINTE EXISTANTE SI ELLE EXISTE
SELECT '🗑️ SUPPRESSION DE LA CONTRAINTE EXISTANTE...' as info;

DO $$ 
DECLARE
    constraint_name text;
BEGIN
    SELECT tc.constraint_name INTO constraint_name
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu 
        ON tc.constraint_name = kcu.constraint_name
    WHERE tc.table_name = 'loyalty_points_history' 
    AND tc.table_schema = 'public'
    AND kcu.column_name = 'user_id'
    AND tc.constraint_type = 'FOREIGN KEY';
    
    IF constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE loyalty_points_history DROP CONSTRAINT ' || constraint_name;
        RAISE NOTICE 'Contrainte % supprimée', constraint_name;
    ELSE
        RAISE NOTICE 'Aucune contrainte user_id trouvée';
    END IF;
END $$;

-- 5. METTRE À JOUR LES ENREGISTREMENTS EXISTANTS
SELECT '🔄 MISE À JOUR DES ENREGISTREMENTS EXISTANTS...' as info;

-- Mettre à jour user_id avec l'utilisateur actuel ou un utilisateur par défaut
UPDATE loyalty_points_history 
SET user_id = COALESCE(auth.uid(), (SELECT id FROM auth.users LIMIT 1))
WHERE user_id IS NULL;

-- 6. CRÉER UNE NOUVELLE CONTRAINTE PLUS FLEXIBLE
SELECT '🔗 CRÉATION D''UNE NOUVELLE CONTRAINTE...' as info;

-- Créer une contrainte qui permet NULL pour user_id
ALTER TABLE loyalty_points_history 
ADD CONSTRAINT loyalty_points_history_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;

-- 7. MODIFIER LES FONCTIONS POUR GÉRER USER_ID
SELECT '⚙️ MODIFICATION DES FONCTIONS...' as info;

-- Fonction add_loyalty_points avec gestion de user_id
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

-- Fonction use_loyalty_points avec gestion de user_id
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

-- 8. ACCORDER LES PERMISSIONS
GRANT EXECUTE ON FUNCTION add_loyalty_points(UUID, INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION add_loyalty_points(UUID, INTEGER, TEXT) TO anon;
GRANT EXECUTE ON FUNCTION use_loyalty_points(UUID, INTEGER, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION use_loyalty_points(UUID, INTEGER, TEXT) TO anon;

-- 9. VÉRIFICATION FINALE
SELECT '🔍 VÉRIFICATION FINALE...' as info;

SELECT 
    p.proname as nom_fonction,
    pg_get_function_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
AND p.proname IN ('add_loyalty_points', 'use_loyalty_points')
ORDER BY p.proname;

SELECT '✅ Correction de la contrainte user_id terminée !' as result;
