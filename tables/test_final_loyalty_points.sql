-- Test final du système de points de fidélité
-- Ce script vérifie que tout fonctionne correctement

-- 1. VÉRIFIER LA STRUCTURE COMPLÈTE
SELECT '🔍 VÉRIFICATION DE LA STRUCTURE COMPLÈTE:' as info;

-- Vérifier les tables
SELECT 
    table_name,
    CASE 
        WHEN table_name IN ('clients', 'loyalty_tiers', 'loyalty_points_history') THEN '✅ Table principale'
        ELSE '📋 Table support'
    END as type_table
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('clients', 'loyalty_tiers', 'loyalty_points_history', 'client_loyalty_points')
ORDER BY table_name;

-- 2. VÉRIFIER LES COLONNES DE FIDÉLITÉ
SELECT '🎯 VÉRIFICATION DES COLONNES DE FIDÉLITÉ:' as info;

SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'clients'
AND column_name IN ('loyalty_points', 'current_tier_id', 'created_by')
ORDER BY column_name;

-- 3. VÉRIFIER LES NIVEAUX DE FIDÉLITÉ
SELECT '🏆 NIVEAUX DE FIDÉLITÉ DISPONIBLES:' as info;

SELECT 
    id,
    name,
    description,
    points_required,
    discount_percentage,
    color,
    is_active
FROM loyalty_tiers
ORDER BY points_required;

-- 4. VÉRIFIER LES CLIENTS
SELECT '👥 ÉTAT DES CLIENTS:' as info;

SELECT 
    id,
    first_name || ' ' || last_name as nom_complet,
    email,
    COALESCE(loyalty_points, 0) as points,
    current_tier_id,
    created_at
FROM clients
ORDER BY COALESCE(loyalty_points, 0) DESC
LIMIT 10;

-- 5. TEST COMPLET DU SYSTÈME
SELECT '🧪 TEST COMPLET DU SYSTÈME:' as info;

DO $$ 
DECLARE
    v_client_id UUID;
    v_points_avant INTEGER;
    v_result JSON;
    v_points_apres INTEGER;
    v_tier_avant UUID;
    v_tier_apres UUID;
BEGIN
    -- Récupérer un client pour le test
    SELECT id, COALESCE(loyalty_points, 0), current_tier_id
    INTO v_client_id, v_points_avant, v_tier_avant
    FROM clients 
    LIMIT 1;
    
    IF v_client_id IS NULL THEN
        RAISE NOTICE '❌ Aucun client trouvé pour le test';
        RETURN;
    END IF;
    
    RAISE NOTICE '🧪 Test avec client: % (points avant: %, tier avant: %)', 
        v_client_id, v_points_avant, v_tier_avant;
    
    -- Test 1: Ajouter des points
    RAISE NOTICE '📈 Test 1: Ajout de 100 points...';
    SELECT add_loyalty_points(v_client_id, 100, 'Test final - Ajout points') INTO v_result;
    
    IF v_result->>'success' = 'true' THEN
        RAISE NOTICE '✅ Points ajoutés avec succès';
        
        -- Vérifier les points après
        SELECT COALESCE(loyalty_points, 0), current_tier_id
        INTO v_points_apres, v_tier_apres
        FROM clients 
        WHERE id = v_client_id;
        
        RAISE NOTICE '📊 Points avant: %, Points après: %, Différence: %', 
            v_points_avant, v_points_apres, v_points_apres - v_points_avant;
        
        IF v_points_apres = v_points_avant + 100 THEN
            RAISE NOTICE '✅ Points correctement ajoutés !';
        ELSE
            RAISE NOTICE '❌ Problème: les points n''ont pas été ajoutés correctement';
        END IF;
        
        -- Vérifier le changement de niveau
        IF v_tier_apres != v_tier_avant THEN
            RAISE NOTICE '🏆 Niveau mis à jour: % -> %', v_tier_avant, v_tier_apres;
        ELSE
            RAISE NOTICE '📊 Niveau inchangé: %', v_tier_avant;
        END IF;
        
    ELSE
        RAISE NOTICE '❌ Erreur lors de l''ajout de points: %', v_result->>'error';
        RETURN;
    END IF;
    
    -- Test 2: Utiliser des points
    RAISE NOTICE '📉 Test 2: Utilisation de 30 points...';
    SELECT use_loyalty_points(v_client_id, 30, 'Test final - Utilisation points') INTO v_result;
    
    IF v_result->>'success' = 'true' THEN
        RAISE NOTICE '✅ Points utilisés avec succès';
        
        -- Vérifier les points après utilisation
        SELECT COALESCE(loyalty_points, 0)
        INTO v_points_apres
        FROM clients 
        WHERE id = v_client_id;
        
        RAISE NOTICE '📊 Points après utilisation: %', v_points_apres;
        
        IF v_points_apres = v_points_avant + 100 - 30 THEN
            RAISE NOTICE '✅ Points correctement utilisés !';
        ELSE
            RAISE NOTICE '❌ Problème: les points n''ont pas été utilisés correctement';
        END IF;
        
    ELSE
        RAISE NOTICE '❌ Erreur lors de l''utilisation de points: %', v_result->>'error';
    END IF;
    
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE '💥 Exception lors du test: %', SQLERRM;
END $$;

-- 6. VÉRIFIER L'HISTORIQUE
SELECT '📊 HISTORIQUE DES POINTS:' as info;

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
LIMIT 10;

-- 7. VÉRIFIER LES FONCTIONS
SELECT '⚙️ FONCTIONS DISPONIBLES:' as info;

SELECT 
    p.proname as nom_fonction,
    pg_get_function_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE n.nspname = 'public' 
AND p.proname IN ('add_loyalty_points', 'use_loyalty_points', 'refresh_client_loyalty_data')
ORDER BY p.proname;

-- 8. STATISTIQUES FINALES
SELECT '📈 STATISTIQUES FINALES:' as info;

SELECT 
    COUNT(*) as total_clients,
    COUNT(CASE WHEN COALESCE(loyalty_points, 0) > 0 THEN 1 END) as clients_avec_points,
    AVG(COALESCE(loyalty_points, 0)) as moyenne_points,
    MAX(COALESCE(loyalty_points, 0)) as max_points,
    MIN(COALESCE(loyalty_points, 0)) as min_points
FROM clients;

-- 9. VÉRIFIER LA VUE
SELECT '👁️ TEST DE LA VUE CLIENT_LOYALTY_POINTS:' as info;

SELECT 
    id,
    first_name || ' ' || last_name as nom_complet,
    total_points,
    tier_name,
    tier_points_required
FROM client_loyalty_points
LIMIT 5;

-- 10. RÉSUMÉ FINAL
SELECT '🎯 RÉSUMÉ FINAL:' as info;

SELECT 
    'Système de points de fidélité' as composant,
    CASE 
        WHEN EXISTS (SELECT 1 FROM clients WHERE COALESCE(loyalty_points, 0) > 0) THEN '✅ Fonctionnel'
        ELSE '⚠️ À vérifier'
    END as statut

UNION ALL

SELECT 
    'Fonction add_loyalty_points' as composant,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'add_loyalty_points') THEN '✅ Disponible'
        ELSE '❌ Manquante'
    END as statut

UNION ALL

SELECT 
    'Fonction use_loyalty_points' as composant,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'use_loyalty_points') THEN '✅ Disponible'
        ELSE '❌ Manquante'
    END as statut

UNION ALL

SELECT 
    'Vue client_loyalty_points' as composant,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'client_loyalty_points') THEN '✅ Disponible'
        ELSE '❌ Manquante'
    END as statut

UNION ALL

SELECT 
    'Table loyalty_points_history' as composant,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'loyalty_points_history') THEN '✅ Disponible'
        ELSE '❌ Manquante'
    END as statut;

SELECT '✅ Test final terminé !' as result;
