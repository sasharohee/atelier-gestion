-- Diagnostic complet du système de points de fidélité
-- Ce script vérifie l'état actuel et identifie les problèmes

-- 1. VÉRIFICATION DE LA STRUCTURE DES TABLES
SELECT '🔍 VÉRIFICATION DE LA STRUCTURE DES TABLES...' as info;

-- Vérifier la table clients
SELECT 
    'clients' as table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'clients' 
AND table_schema = 'public'
AND column_name IN ('loyalty_points', 'current_tier_id', 'created_by')
ORDER BY column_name;

-- Vérifier la table loyalty_tiers
SELECT 
    'loyalty_tiers' as table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'loyalty_tiers' 
AND table_schema = 'public'
ORDER BY column_name;

-- Vérifier la table loyalty_points_history
SELECT 
    'loyalty_points_history' as table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'loyalty_points_history' 
AND table_schema = 'public'
ORDER BY column_name;

-- 2. VÉRIFICATION DES CONTRAINTES DE CLÉ ÉTRANGÈRE
SELECT '🔗 VÉRIFICATION DES CONTRAINTES...' as info;

SELECT 
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_schema = 'public'
AND (tc.table_name = 'clients' OR tc.table_name = 'loyalty_points_history');

-- 3. VÉRIFICATION DES DONNÉES
SELECT '📊 VÉRIFICATION DES DONNÉES...' as info;

-- Compter les clients
SELECT 
    COUNT(*) as total_clients,
    COUNT(CASE WHEN loyalty_points IS NOT NULL THEN 1 END) as clients_avec_points,
    COUNT(CASE WHEN current_tier_id IS NOT NULL THEN 1 END) as clients_avec_niveau,
    AVG(COALESCE(loyalty_points, 0)) as moyenne_points
FROM clients;

-- Afficher quelques clients avec leurs points
SELECT 
    id,
    first_name,
    last_name,
    loyalty_points,
    current_tier_id,
    created_at
FROM clients 
ORDER BY COALESCE(loyalty_points, 0) DESC
LIMIT 5;

-- Vérifier les niveaux de fidélité
SELECT 
    id,
    name,
    description,
    min_points,
    points_required,
    discount_percentage,
    color,
    is_active
FROM loyalty_tiers
ORDER BY points_required;

-- Vérifier l'historique des points
SELECT 
    COUNT(*) as total_operations,
    COUNT(CASE WHEN points_change > 0 THEN 1 END) as ajouts,
    COUNT(CASE WHEN points_change < 0 THEN 1 END) as utilisations,
    AVG(points_change) as moyenne_changement
FROM loyalty_points_history;

-- 4. VÉRIFICATION DES FONCTIONS
SELECT '⚙️ VÉRIFICATION DES FONCTIONS...' as info;

-- Lister les fonctions existantes
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public'
AND routine_name LIKE '%loyalty%'
ORDER BY routine_name;

-- 5. TEST DES FONCTIONS
SELECT '🧪 TEST DES FONCTIONS...' as info;

DO $$ 
DECLARE
    v_client_id UUID;
    v_result JSON;
    v_test_points INTEGER;
BEGIN
    -- Récupérer un client pour le test
    SELECT id INTO v_client_id FROM clients LIMIT 1;
    
    IF v_client_id IS NOT NULL THEN
        -- Récupérer les points actuels
        SELECT COALESCE(loyalty_points, 0) INTO v_test_points
        FROM clients WHERE id = v_client_id;
        
        RAISE NOTICE 'Client de test: %, Points actuels: %', v_client_id, v_test_points;
        
        -- Test d'ajout de points
        SELECT add_loyalty_points(v_client_id, 25, 'Test diagnostic') INTO v_result;
        
        IF v_result->>'success' = 'true' THEN
            RAISE NOTICE '✅ Test add_loyalty_points réussi: %', v_result;
        ELSE
            RAISE NOTICE '❌ Test add_loyalty_points échoué: %', v_result->>'error';
        END IF;
        
        -- Vérifier les points après ajout
        SELECT COALESCE(loyalty_points, 0) INTO v_test_points
        FROM clients WHERE id = v_client_id;
        
        RAISE NOTICE 'Points après ajout: %', v_test_points;
        
    ELSE
        RAISE NOTICE '⚠️ Aucun client trouvé pour le test';
    END IF;
END $$;

-- 6. VÉRIFICATION DES POLITIQUES RLS
SELECT '🔒 VÉRIFICATION DES POLITIQUES RLS...' as info;

SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public'
AND tablename IN ('clients', 'loyalty_tiers', 'loyalty_points_history');

-- 7. VÉRIFICATION DES TRIGGERS
SELECT '🎯 VÉRIFICATION DES TRIGGERS...' as info;

SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'public'
AND event_object_table IN ('clients', 'loyalty_tiers', 'loyalty_points_history');

-- 8. RÉSUMÉ DES PROBLÈMES POTENTIELS
SELECT '🚨 ANALYSE DES PROBLÈMES POTENTIELS...' as info;

-- Vérifier les clients sans niveau de fidélité
SELECT 
    COUNT(*) as clients_sans_niveau
FROM clients 
WHERE current_tier_id IS NULL;

-- Vérifier les clients avec des points négatifs
SELECT 
    COUNT(*) as clients_points_negatifs
FROM clients 
WHERE COALESCE(loyalty_points, 0) < 0;

-- Vérifier les incohérences entre points et niveaux
SELECT 
    COUNT(*) as incohérences_niveaux
FROM clients c
LEFT JOIN loyalty_tiers lt ON c.current_tier_id = lt.id
WHERE c.loyalty_points < lt.points_required;

-- 9. RECOMMANDATIONS
SELECT '💡 RECOMMANDATIONS...' as info;

SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM clients WHERE current_tier_id IS NULL) > 0 
        THEN 'Assigner un niveau par défaut aux clients sans niveau'
        ELSE 'Tous les clients ont un niveau assigné'
    END as recommandation_1,
    
    CASE 
        WHEN (SELECT COUNT(*) FROM clients WHERE COALESCE(loyalty_points, 0) < 0) > 0 
        THEN 'Corriger les points négatifs'
        ELSE 'Aucun point négatif détecté'
    END as recommandation_2,
    
    CASE 
        WHEN (SELECT COUNT(*) FROM clients c LEFT JOIN loyalty_tiers lt ON c.current_tier_id = lt.id WHERE c.loyalty_points < lt.points_required) > 0 
        THEN 'Recalculer les niveaux basés sur les points actuels'
        ELSE 'Les niveaux sont cohérents avec les points'
    END as recommandation_3;

SELECT '✅ Diagnostic terminé !' as result;
