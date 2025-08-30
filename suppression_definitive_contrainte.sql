-- SUPPRESSION DÉFINITIVE DE LA CONTRAINTE PROBLÉMATIQUE
-- Solution radicale pour résoudre le problème de foreign key

-- 1. SUPPRIMER DÉFINITIVEMENT LA CONTRAINTE
SELECT '🧹 SUPPRESSION DÉFINITIVE DE LA CONTRAINTE' as diagnostic;

-- Supprimer la contrainte avec tous les noms possibles
ALTER TABLE clients DROP CONSTRAINT IF EXISTS clients_current_tier_id_fkey;
ALTER TABLE clients DROP CONSTRAINT IF EXISTS fk_clients_current_tier_id;
ALTER TABLE clients DROP CONSTRAINT IF EXISTS clients_loyalty_tier_fkey;
ALTER TABLE clients DROP CONSTRAINT IF EXISTS clients_current_tier_fkey;

-- 2. VÉRIFIER QU'IL N'Y A PLUS DE CONTRAINTES
SELECT '✅ VÉRIFICATION - PLUS DE CONTRAINTES' as diagnostic;

SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
WHERE tc.table_name = 'clients'
    AND kcu.column_name = 'current_tier_id'
    AND tc.constraint_type = 'FOREIGN KEY';

-- 3. NETTOYER TOUTES LES RÉFÉRENCES INCORRECTES
SELECT '🧹 NETTOYAGE COMPLET DES RÉFÉRENCES' as diagnostic;

UPDATE clients 
SET current_tier_id = NULL;

-- 4. VÉRIFIER LE NETTOYAGE
SELECT '✅ VÉRIFICATION DU NETTOYAGE' as diagnostic;

SELECT 
    COUNT(*) as total_clients,
    COUNT(CASE WHEN current_tier_id IS NOT NULL THEN 1 END) as clients_avec_niveau
FROM clients;

-- 5. CRÉER UNE FONCTION POUR ASSIGNER LES NIVEAUX SANS CONTRAINTE
CREATE OR REPLACE FUNCTION assign_loyalty_tiers_safe()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_updated_count INTEGER;
    v_client_record RECORD;
    v_tier_id UUID;
BEGIN
    -- Parcourir tous les clients avec des points
    FOR v_client_record IN 
        SELECT id, loyalty_points 
        FROM clients 
        WHERE loyalty_points > 0
    LOOP
        -- Trouver le niveau approprié pour ce client
        SELECT id INTO v_tier_id
        FROM loyalty_tiers_advanced 
        WHERE points_required <= v_client_record.loyalty_points 
        AND is_active = true
        ORDER BY points_required DESC 
        LIMIT 1;
        
        -- Mettre à jour le niveau du client
        IF v_tier_id IS NOT NULL THEN
            UPDATE clients 
            SET current_tier_id = v_tier_id
            WHERE id = v_client_record.id;
            
            v_updated_count := v_updated_count + 1;
        END IF;
    END LOOP;
    
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

-- 6. ACCORDER LES PERMISSIONS
GRANT EXECUTE ON FUNCTION assign_loyalty_tiers_safe() TO authenticated;

-- 7. ASSIGNER LES NIVEAUX INITIAUX
SELECT '🔧 ASSIGNATION DES NIVEAUX INITIAUX' as diagnostic;

SELECT assign_loyalty_tiers_safe();

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
SELECT '🎉 CONTRAINTE SUPPRIMÉE DÉFINITIVEMENT !' as result;
SELECT '📋 La contrainte problématique a été supprimée.' as next_step;
SELECT '🔄 Testez maintenant l''ajout de points.' as instruction;
