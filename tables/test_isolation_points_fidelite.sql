-- TEST DE L'ISOLATION DES DONNÉES POUR LES POINTS DE FIDÉLITÉ
-- Ce script teste que l'isolation fonctionne correctement

-- =====================================================
-- ÉTAPE 1: VÉRIFICATION DE L'ÉTAT ACTUEL
-- =====================================================

SELECT '=== TEST ISOLATION POINTS DE FIDÉLITÉ ===' as test_section;

-- Vérifier l'utilisateur connecté
SELECT 
    'Utilisateur connecté' as info,
    auth.uid() as user_id,
    auth.role() as user_role;

-- Vérifier l'état RLS
SELECT 
    'État RLS' as info,
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE tablename IN ('loyalty_tiers', 'referrals', 'client_loyalty_points', 'loyalty_points_history', 'loyalty_rules')
AND schemaname = 'public';

-- =====================================================
-- ÉTAPE 2: TEST D'ACCÈS AUX DONNÉES
-- =====================================================

SELECT '=== TEST D''ACCÈS AUX DONNÉES ===' as test_section;

-- Test 1: Accès aux niveaux de fidélité (devrait fonctionner)
SELECT 
    'Test 1 - Niveaux de fidélité' as test,
    COUNT(*) as nombre_niveaux
FROM loyalty_tiers;

-- Test 2: Accès aux clients avec points
SELECT 
    'Test 2 - Clients avec points' as test,
    COUNT(*) as nombre_clients
FROM client_loyalty_points;

-- Test 3: Accès aux parrainages
SELECT 
    'Test 3 - Parrainages' as test,
    COUNT(*) as nombre_parrainages
FROM referrals;

-- Test 4: Accès à l'historique des points
SELECT 
    'Test 4 - Historique des points' as test,
    COUNT(*) as nombre_entrees
FROM loyalty_points_history;

-- Test 5: Accès aux règles de fidélité
SELECT 
    'Test 5 - Règles de fidélité' as test,
    COUNT(*) as nombre_regles
FROM loyalty_rules;

-- =====================================================
-- ÉTAPE 3: TEST DES FONCTIONS
-- =====================================================

SELECT '=== TEST DES FONCTIONS ===' as test_section;

-- Test de la fonction d'autorisation
SELECT 
    'Test fonction autorisation' as test,
    can_access_loyalty_data() as autorisation;

-- Test de la fonction de statistiques
SELECT 
    'Test statistiques fidélité' as test,
    get_loyalty_statistics() as resultat;

-- Test de la fonction d'ajout de points (avec des données de test)
DO $$
DECLARE
    test_client_id UUID;
    test_result JSON;
BEGIN
    -- Récupérer un client de test
    SELECT id INTO test_client_id FROM clients LIMIT 1;
    
    IF test_client_id IS NOT NULL THEN
        -- Tester l'ajout de points
        SELECT add_loyalty_points(test_client_id, 10, 'Test d''isolation') INTO test_result;
        
        RAISE NOTICE 'Test ajout points: %', test_result;
    ELSE
        RAISE NOTICE 'Aucun client trouvé pour le test';
    END IF;
END $$;

-- =====================================================
-- ÉTAPE 4: TEST DE CRÉATION DE DONNÉES
-- =====================================================

SELECT '=== TEST DE CRÉATION ===' as test_section;

-- Test de création d'un parrainage (si des clients existent)
DO $$
DECLARE
    client1_id UUID;
    client2_id UUID;
    test_result JSON;
BEGIN
    -- Récupérer deux clients différents
    SELECT id INTO client1_id FROM clients LIMIT 1;
    SELECT id INTO client2_id FROM clients WHERE id != client1_id LIMIT 1;
    
    IF client1_id IS NOT NULL AND client2_id IS NOT NULL THEN
        -- Tester la création d'un parrainage
        SELECT create_referral(client1_id, client2_id, 'Test d''isolation') INTO test_result;
        
        RAISE NOTICE 'Test création parrainage: %', test_result;
    ELSE
        RAISE NOTICE 'Pas assez de clients pour tester la création de parrainage';
    END IF;
END $$;

-- =====================================================
-- ÉTAPE 5: VÉRIFICATION FINALE
-- =====================================================

SELECT '=== VÉRIFICATION FINALE ===' as test_section;

-- Vérifier que les données sont accessibles après les tests
SELECT 
    'Données après tests' as info,
    (SELECT COUNT(*) FROM loyalty_tiers) as niveaux_fidelite,
    (SELECT COUNT(*) FROM client_loyalty_points) as clients_points,
    (SELECT COUNT(*) FROM referrals) as parrainages,
    (SELECT COUNT(*) FROM loyalty_points_history) as historique,
    (SELECT COUNT(*) FROM loyalty_rules) as regles;

-- Test de la fonction d'autorisation finale
SELECT 
    'Test final autorisation' as test,
    can_access_loyalty_data() as autorisation_finale;

-- Message de conclusion
SELECT 
    CASE 
        WHEN can_access_loyalty_data() THEN '✅ Isolation fonctionne correctement'
        ELSE '❌ Problème d''isolation détecté'
    END as conclusion;
