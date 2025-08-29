-- Test de la fonction add_loyalty_points
-- Ce script teste si la fonction fonctionne correctement

-- 1. SÉLECTIONNER UN CLIENT POUR LE TEST
SELECT '🧪 SÉLECTION D''UN CLIENT DE TEST:' as info;

WITH client_test AS (
    SELECT 
        id as client_id,
        first_name,
        last_name,
        COALESCE(loyalty_points, 0) as points_avant,
        current_tier_id
    FROM clients
    LIMIT 1
)
SELECT 
    client_id,
    first_name || ' ' || last_name as nom_complet,
    points_avant,
    current_tier_id
FROM client_test;

-- 2. TESTER LA FONCTION ADD_LOYALTY_POINTS
SELECT '🔧 TEST DE LA FONCTION ADD_LOYALTY_POINTS:' as info;

-- Test avec un client existant
DO $$ 
DECLARE
    v_client_id UUID;
    v_points_avant INTEGER;
    v_result JSON;
    v_points_apres INTEGER;
BEGIN
    -- Récupérer un client pour le test
    SELECT id, COALESCE(loyalty_points, 0) 
    INTO v_client_id, v_points_avant
    FROM clients 
    LIMIT 1;
    
    IF v_client_id IS NULL THEN
        RAISE NOTICE '❌ Aucun client trouvé pour le test';
        RETURN;
    END IF;
    
    RAISE NOTICE '🧪 Test avec client: % (points avant: %)', v_client_id, v_points_avant;
    
    -- Appeler la fonction
    SELECT add_loyalty_points(v_client_id, 50, 'Test de la fonction') INTO v_result;
    
    RAISE NOTICE '📊 Résultat de la fonction: %', v_result;
    
    -- Vérifier le résultat
    IF v_result->>'success' = 'true' THEN
        RAISE NOTICE '✅ Fonction exécutée avec succès';
        
        -- Vérifier les points après
        SELECT COALESCE(loyalty_points, 0) INTO v_points_apres
        FROM clients 
        WHERE id = v_client_id;
        
        RAISE NOTICE '📈 Points avant: %, Points après: %, Différence: %', 
            v_points_avant, v_points_apres, v_points_apres - v_points_avant;
        
        IF v_points_apres = v_points_avant + 50 THEN
            RAISE NOTICE '✅ Points correctement ajoutés !';
        ELSE
            RAISE NOTICE '❌ Problème: les points n''ont pas été ajoutés correctement';
        END IF;
        
    ELSE
        RAISE NOTICE '❌ Erreur dans la fonction: %', v_result->>'error';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '💥 Exception lors du test: %', SQLERRM;
END $$;

-- 3. VÉRIFIER L'HISTORIQUE
SELECT '📊 VÉRIFICATION DE L''HISTORIQUE:' as info;

SELECT 
    lph.client_id,
    c.first_name || ' ' || c.last_name as nom_client,
    lph.points_change,
    lph.points_before,
    lph.points_after,
    lph.description,
    lph.points_type,
    lph.source_type,
    lph.created_at
FROM loyalty_points_history lph
JOIN clients c ON lph.client_id = c.id
ORDER BY lph.created_at DESC
LIMIT 5;

-- 4. VÉRIFIER LES CLIENTS APRÈS LE TEST
SELECT '👥 ÉTAT DES CLIENTS APRÈS LE TEST:' as info;

SELECT 
    id,
    first_name || ' ' || last_name as nom_complet,
    COALESCE(loyalty_points, 0) as loyalty_points,
    current_tier_id,
    updated_at
FROM clients
ORDER BY updated_at DESC
LIMIT 5;

-- 5. TEST DE LA FONCTION USE_LOYALTY_POINTS
SELECT '🔧 TEST DE LA FONCTION USE_LOYALTY_POINTS:' as info;

DO $$ 
DECLARE
    v_client_id UUID;
    v_points_avant INTEGER;
    v_result JSON;
    v_points_apres INTEGER;
BEGIN
    -- Récupérer un client avec des points pour le test
    SELECT id, COALESCE(loyalty_points, 0) 
    INTO v_client_id, v_points_avant
    FROM clients 
    WHERE COALESCE(loyalty_points, 0) > 0
    LIMIT 1;
    
    IF v_client_id IS NULL THEN
        RAISE NOTICE '❌ Aucun client avec des points trouvé pour le test';
        RETURN;
    END IF;
    
    RAISE NOTICE '🧪 Test use_loyalty_points avec client: % (points avant: %)', v_client_id, v_points_avant;
    
    -- Appeler la fonction
    SELECT use_loyalty_points(v_client_id, 10, 'Test utilisation points') INTO v_result;
    
    RAISE NOTICE '📊 Résultat de la fonction: %', v_result;
    
    -- Vérifier le résultat
    IF v_result->>'success' = 'true' THEN
        RAISE NOTICE '✅ Fonction use_loyalty_points exécutée avec succès';
        
        -- Vérifier les points après
        SELECT COALESCE(loyalty_points, 0) INTO v_points_apres
        FROM clients 
        WHERE id = v_client_id;
        
        RAISE NOTICE '📈 Points avant: %, Points après: %, Différence: %', 
            v_points_avant, v_points_apres, v_points_apres - v_points_avant;
        
        IF v_points_apres = v_points_avant - 10 THEN
            RAISE NOTICE '✅ Points correctement utilisés !';
        ELSE
            RAISE NOTICE '❌ Problème: les points n''ont pas été utilisés correctement';
        END IF;
        
    ELSE
        RAISE NOTICE '❌ Erreur dans la fonction use_loyalty_points: %', v_result->>'error';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '💥 Exception lors du test use_loyalty_points: %', SQLERRM;
END $$;

-- 6. RÉSUMÉ DES TESTS
SELECT '📋 RÉSUMÉ DES TESTS:' as info;

SELECT 
    'Test add_loyalty_points' as test,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM loyalty_points_history 
            WHERE description = 'Test de la fonction'
            AND points_change = 50
        ) THEN '✅ Réussi'
        ELSE '❌ Échoué'
    END as result

UNION ALL

SELECT 
    'Test use_loyalty_points' as test,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM loyalty_points_history 
            WHERE description = 'Test utilisation points'
            AND points_change = -10
        ) THEN '✅ Réussi'
        ELSE '❌ Échoué'
    END as result;

SELECT '✅ Tests terminés !' as result;
