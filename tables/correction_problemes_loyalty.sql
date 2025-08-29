-- Correction des problèmes courants du système de points de fidélité
-- Ce script corrige les problèmes identifiés par le diagnostic

-- 1. CORRECTION DES CLIENTS SANS NIVEAU
SELECT '🔧 CORRECTION DES CLIENTS SANS NIVEAU...' as info;

-- Assigner le niveau Bronze aux clients sans niveau
UPDATE clients 
SET current_tier_id = (SELECT id FROM loyalty_tiers WHERE name = 'Bronze' LIMIT 1)
WHERE current_tier_id IS NULL;

-- 2. CORRECTION DES POINTS NÉGATIFS
SELECT '🔧 CORRECTION DES POINTS NÉGATIFS...' as info;

-- Mettre les points négatifs à 0
UPDATE clients 
SET loyalty_points = 0
WHERE COALESCE(loyalty_points, 0) < 0;

-- 3. RECALCUL DES NIVEAUX BASÉS SUR LES POINTS
SELECT '🔧 RECALCUL DES NIVEAUX...' as info;

-- Mettre à jour les niveaux basés sur les points actuels
UPDATE clients 
SET current_tier_id = (
    SELECT id 
    FROM loyalty_tiers 
    WHERE points_required <= COALESCE(clients.loyalty_points, 0)
    ORDER BY points_required DESC 
    LIMIT 1
)
WHERE current_tier_id IS NOT NULL;

-- 4. ASSURER QUE TOUS LES CLIENTS ONT DES POINTS INITIALISÉS
SELECT '🔧 INITIALISATION DES POINTS...' as info;

-- Mettre les points NULL à 0
UPDATE clients 
SET loyalty_points = 0
WHERE loyalty_points IS NULL;

-- 5. VÉRIFICATION ET CORRECTION DES DONNÉES D'HISTORIQUE
SELECT '🔧 CORRECTION DE L''HISTORIQUE...' as info;

-- Supprimer les enregistrements d'historique orphelins
DELETE FROM loyalty_points_history 
WHERE client_id NOT IN (SELECT id FROM clients);

-- 6. CRÉATION D'UN TRIGGER POUR MAINTENIR LA COHÉRENCE
SELECT '🔧 CRÉATION D''UN TRIGGER DE COHÉRENCE...' as info;

-- Supprimer le trigger s'il existe
DROP TRIGGER IF EXISTS update_client_tier_trigger ON clients;

-- Créer un trigger pour mettre à jour automatiquement le niveau
CREATE OR REPLACE FUNCTION update_client_tier()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Mettre à jour le niveau basé sur les points
    NEW.current_tier_id = (
        SELECT id 
        FROM loyalty_tiers 
        WHERE points_required <= COALESCE(NEW.loyalty_points, 0)
        ORDER BY points_required DESC 
        LIMIT 1
    );
    
    RETURN NEW;
END;
$$;

-- Créer le trigger
CREATE TRIGGER update_client_tier_trigger
    BEFORE UPDATE ON clients
    FOR EACH ROW
    WHEN (OLD.loyalty_points IS DISTINCT FROM NEW.loyalty_points)
    EXECUTE FUNCTION update_client_tier();

-- 7. FONCTION DE SYNCHRONISATION
SELECT '🔧 CRÉATION D''UNE FONCTION DE SYNCHRONISATION...' as info;

CREATE OR REPLACE FUNCTION sync_loyalty_data()
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSON;
    v_clients_updated INTEGER;
    v_tiers_updated INTEGER;
BEGIN
    -- Mettre à jour les niveaux de tous les clients
    UPDATE clients 
    SET current_tier_id = (
        SELECT id 
        FROM loyalty_tiers 
        WHERE points_required <= COALESCE(clients.loyalty_points, 0)
        ORDER BY points_required DESC 
        LIMIT 1
    )
    WHERE current_tier_id IS NULL OR current_tier_id != (
        SELECT id 
        FROM loyalty_tiers 
        WHERE points_required <= COALESCE(clients.loyalty_points, 0)
        ORDER BY points_required DESC 
        LIMIT 1
    );
    
    GET DIAGNOSTICS v_clients_updated = ROW_COUNT;
    
    -- Compter les clients avec des points
    SELECT COUNT(*) INTO v_tiers_updated
    FROM clients 
    WHERE COALESCE(loyalty_points, 0) > 0;
    
    v_result := json_build_object(
        'success', true,
        'clients_updated', v_clients_updated,
        'clients_with_points', v_tiers_updated,
        'message', 'Synchronisation terminée'
    );
    
    RETURN v_result;
END;
$$;

-- 8. ACCORDER LES PERMISSIONS
GRANT EXECUTE ON FUNCTION sync_loyalty_data() TO authenticated;
GRANT EXECUTE ON FUNCTION sync_loyalty_data() TO anon;

-- 9. EXÉCUTER LA SYNCHRONISATION
SELECT '🔄 EXÉCUTION DE LA SYNCHRONISATION...' as info;

SELECT sync_loyalty_data();

-- 10. VÉRIFICATION FINALE
SELECT '🔍 VÉRIFICATION FINALE...' as info;

-- Statistiques finales
SELECT 
    COUNT(*) as total_clients,
    COUNT(CASE WHEN COALESCE(loyalty_points, 0) > 0 THEN 1 END) as clients_avec_points,
    COUNT(CASE WHEN current_tier_id IS NOT NULL THEN 1 END) as clients_avec_niveau,
    AVG(COALESCE(loyalty_points, 0)) as moyenne_points
FROM clients;

-- Afficher la répartition par niveau
SELECT 
    lt.name as niveau,
    COUNT(c.id) as nombre_clients,
    AVG(COALESCE(c.loyalty_points, 0)) as moyenne_points
FROM loyalty_tiers lt
LEFT JOIN clients c ON lt.id = c.current_tier_id
GROUP BY lt.id, lt.name, lt.points_required
ORDER BY lt.points_required;

SELECT '✅ Corrections terminées !' as result;
