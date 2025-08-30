-- CORRECTION DES NIVEAUX ACTUELS
-- Diagnostique et corrige le problème d'affichage des niveaux

-- 1. DIAGNOSTIC DE L'ÉTAT ACTUEL
SELECT '🔍 DIAGNOSTIC DES NIVEAUX' as diagnostic;

SELECT 
    c.id as client_id,
    c.first_name,
    c.last_name,
    c.loyalty_points,
    c.current_tier_id,
    lt.id as tier_id,
    lt.name as tier_name,
    lt.points_required,
    CASE 
        WHEN c.current_tier_id IS NULL THEN '❌ Aucun niveau assigné'
        WHEN lt.id IS NULL THEN '❌ Niveau introuvable'
        ELSE '✅ Niveau correct'
    END as status
FROM clients c
LEFT JOIN loyalty_tiers_advanced lt ON c.current_tier_id = lt.id
WHERE c.loyalty_points > 0
ORDER BY c.loyalty_points DESC;

-- 2. VÉRIFIER LES NIVEAUX DISPONIBLES
SELECT '🏆 NIVEAUX DISPONIBLES' as diagnostic;

SELECT 
    id,
    name,
    points_required,
    discount_percentage,
    is_active
FROM loyalty_tiers_advanced 
ORDER BY points_required;

-- 3. CORRIGER LES NIVEAUX MANQUANTS
SELECT '🔧 CORRECTION DES NIVEAUX' as diagnostic;

-- Supprimer toutes les références incorrectes
UPDATE clients 
SET current_tier_id = NULL 
WHERE current_tier_id IS NOT NULL;

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

-- 4. VÉRIFICATION APRÈS CORRECTION
SELECT '✅ VÉRIFICATION APRÈS CORRECTION' as diagnostic;

SELECT 
    c.id as client_id,
    c.first_name,
    c.last_name,
    c.loyalty_points,
    c.current_tier_id,
    lt.name as niveau_nom,
    lt.points_required,
    lt.discount_percentage,
    CASE 
        WHEN c.current_tier_id IS NOT NULL THEN '✅ Niveau assigné'
        WHEN c.loyalty_points = 0 THEN 'ℹ️ Aucun point'
        ELSE '❌ Problème'
    END as statut
FROM clients c
LEFT JOIN loyalty_tiers_advanced lt ON c.current_tier_id = lt.id
WHERE c.loyalty_points > 0
ORDER BY c.loyalty_points DESC;

-- 5. CRÉER UNE FONCTION POUR MAINTENIR LES NIVEAUX À JOUR
CREATE OR REPLACE FUNCTION update_client_tiers()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_updated_count INTEGER;
BEGIN
    -- Mettre à jour les niveaux de tous les clients avec des points
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
        'message', 'Niveaux mis à jour avec succès',
        'clients_updated', v_updated_count
    );
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Erreur lors de la mise à jour des niveaux: ' || SQLERRM
        );
END;
$$;

-- 6. ACCORDER LES PERMISSIONS
GRANT EXECUTE ON FUNCTION update_client_tiers() TO authenticated;

-- 7. TESTER LA FONCTION
SELECT '🧪 TEST DE LA FONCTION' as diagnostic;

SELECT update_client_tiers();

-- 8. VÉRIFICATION FINALE
SELECT '✅ VÉRIFICATION FINALE' as diagnostic;

SELECT 
    c.first_name,
    c.last_name,
    c.loyalty_points,
    lt.name as niveau_actuel,
    lt.points_required,
    lt.discount_percentage
FROM clients c
LEFT JOIN loyalty_tiers_advanced lt ON c.current_tier_id = lt.id
WHERE c.loyalty_points > 0
ORDER BY c.loyalty_points DESC;

-- 9. MESSAGE DE CONFIRMATION
SELECT '🎉 NIVEAUX CORRIGÉS !' as result;
SELECT '📋 Les niveaux actuels devraient maintenant s''afficher correctement.' as next_step;
SELECT '🔄 Rafraîchissez la page pour voir les changements.' as instruction;
