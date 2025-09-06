-- Test de l'affichage des points utilisés
-- Ce script ajoute quelques utilisations de points pour tester l'affichage

-- 1. RÉCUPÉRER UN CLIENT POUR LE TEST
SELECT '🔍 RÉCUPÉRATION D''UN CLIENT POUR LE TEST...' as info;

DO $$ 
DECLARE
    v_client_id UUID;
    v_current_points INTEGER;
    v_result JSON;
BEGIN
    -- Récupérer un client avec des points
    SELECT id, COALESCE(loyalty_points, 0) INTO v_client_id, v_current_points
    FROM clients 
    WHERE COALESCE(loyalty_points, 0) > 0
    LIMIT 1;
    
    IF v_client_id IS NOT NULL THEN
        RAISE NOTICE 'Client de test: %, Points actuels: %', v_client_id, v_current_points;
        
        -- Ajouter d'abord des points si le client n'en a pas assez
        IF v_current_points < 200 THEN
            SELECT add_loyalty_points(v_client_id, 300, 'Ajout de points pour test') INTO v_result;
            RAISE NOTICE 'Points ajoutés: %', v_result;
        END IF;
        
        -- Utiliser 50 points
        SELECT use_loyalty_points(v_client_id, 50, 'Test utilisation - Réparation écran') INTO v_result;
        IF v_result->>'success' = 'true' THEN
            RAISE NOTICE '✅ 50 points utilisés: %', v_result;
        ELSE
            RAISE NOTICE '❌ Erreur utilisation: %', v_result->>'error';
        END IF;
        
        -- Utiliser 30 points supplémentaires
        SELECT use_loyalty_points(v_client_id, 30, 'Test utilisation - Changement batterie') INTO v_result;
        IF v_result->>'success' = 'true' THEN
            RAISE NOTICE '✅ 30 points utilisés: %', v_result;
        ELSE
            RAISE NOTICE '❌ Erreur utilisation: %', v_result->>'error';
        END IF;
        
    ELSE
        RAISE NOTICE '⚠️ Aucun client avec des points trouvé';
    END IF;
END $$;

-- 2. VÉRIFIER L'HISTORIQUE DES POINTS
SELECT '📊 VÉRIFICATION DE L''HISTORIQUE...' as info;

SELECT 
    lph.client_id,
    c.first_name,
    c.last_name,
    lph.points_change,
    lph.description,
    lph.created_at
FROM loyalty_points_history lph
JOIN clients c ON lph.client_id = c.id
ORDER BY lph.created_at DESC
LIMIT 10;

-- 3. CALCULER LES POINTS UTILISÉS PAR CLIENT
SELECT '🧮 CALCUL DES POINTS UTILISÉS...' as info;

SELECT 
    c.id,
    c.first_name,
    c.last_name,
    c.loyalty_points as points_totaux,
    COALESCE(SUM(CASE WHEN lph.points_change < 0 THEN ABS(lph.points_change) ELSE 0 END), 0) as points_utilises,
    c.loyalty_points - COALESCE(SUM(CASE WHEN lph.points_change < 0 THEN ABS(lph.points_change) ELSE 0 END), 0) as points_disponibles
FROM clients c
LEFT JOIN loyalty_points_history lph ON c.id = lph.client_id
GROUP BY c.id, c.first_name, c.last_name, c.loyalty_points
HAVING c.loyalty_points > 0 OR COALESCE(SUM(CASE WHEN lph.points_change < 0 THEN ABS(lph.points_change) ELSE 0 END), 0) > 0
ORDER BY points_utilises DESC;

-- 4. VÉRIFICATION FINALE
SELECT '✅ TEST TERMINÉ !' as result;
