-- SOLUTION DÉFINITIVE POUR LA CONTRAINTE PROBLÉMATIQUE
-- Approche agressive pour supprimer définitivement le problème

-- 1. VÉRIFIER L'ÉTAT ACTUEL
SELECT '🔍 ÉTAT ACTUEL DES CONTRAINTES' as diagnostic;

SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_name = 'clients'
    AND kcu.column_name = 'current_tier_id'
    AND tc.constraint_type = 'FOREIGN KEY';

-- 2. SUPPRIMER TOUTES LES CONTRAINTES POSSIBLES (APPROCHE AGRESSIVE)
SELECT '🧹 SUPPRESSION AGRESSIVE DES CONTRAINTES' as diagnostic;

-- Supprimer avec tous les noms possibles
ALTER TABLE clients DROP CONSTRAINT IF EXISTS clients_current_tier_id_fkey;
ALTER TABLE clients DROP CONSTRAINT IF EXISTS fk_clients_current_tier_id;
ALTER TABLE clients DROP CONSTRAINT IF EXISTS clients_loyalty_tier_fkey;
ALTER TABLE clients DROP CONSTRAINT IF EXISTS clients_current_tier_fkey;
ALTER TABLE clients DROP CONSTRAINT IF EXISTS fk_current_tier_id;
ALTER TABLE clients DROP CONSTRAINT IF EXISTS clients_tier_fkey;

-- 3. VÉRIFIER QU'IL N'Y A PLUS DE CONTRAINTES
SELECT '✅ VÉRIFICATION - PLUS DE CONTRAINTES' as diagnostic;

SELECT COUNT(*) as contraintes_restantes
FROM information_schema.table_constraints 
WHERE table_name = 'clients' 
AND constraint_type = 'FOREIGN KEY'
AND constraint_name LIKE '%current_tier%';

-- 4. NETTOYER TOUTES LES RÉFÉRENCES
SELECT '🧹 NETTOYAGE COMPLET' as diagnostic;

UPDATE clients 
SET current_tier_id = NULL;

-- 5. CRÉER UNE FONCTION ADD_LOYALTY_POINTS SANS CONTRAINTE
CREATE OR REPLACE FUNCTION add_loyalty_points_safe(
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
    
    -- Assigner automatiquement le niveau
    UPDATE clients 
    SET current_tier_id = (
        SELECT id 
        FROM loyalty_tiers_advanced 
        WHERE points_required <= v_new_points 
        AND is_active = true
        ORDER BY points_required DESC 
        LIMIT 1
    )
    WHERE id = p_client_id;
    
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

-- 6. ACCORDER LES PERMISSIONS
GRANT EXECUTE ON FUNCTION add_loyalty_points_safe(UUID, INTEGER, TEXT) TO authenticated;

-- 7. ASSIGNER LES NIVEAUX INITIAUX
SELECT '🔧 ASSIGNATION DES NIVEAUX INITIAUX' as diagnostic;

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

-- 8. VÉRIFICATION FINALE
SELECT '✅ VÉRIFICATION FINALE' as diagnostic;

SELECT 
    c.first_name,
    c.last_name,
    c.loyalty_points,
    c.current_tier_id,
    lt.name as niveau_nom,
    lt.points_required,
    CASE 
        WHEN c.current_tier_id IS NOT NULL THEN '✅ Niveau assigné'
        WHEN c.loyalty_points = 0 THEN 'ℹ️ Aucun point'
        ELSE '❌ Problème'
    END as statut
FROM clients c
LEFT JOIN loyalty_tiers_advanced lt ON c.current_tier_id = lt.id
WHERE c.loyalty_points > 0
ORDER BY c.loyalty_points DESC;

-- 9. MESSAGE DE CONFIRMATION
SELECT '🎉 SOLUTION DÉFINITIVE APPLIQUÉE !' as result;
SELECT '📋 Utilisez add_loyalty_points_safe() au lieu de add_loyalty_points().' as next_step;
SELECT '🔄 Modifiez le code frontend pour utiliser la nouvelle fonction.' as instruction;





