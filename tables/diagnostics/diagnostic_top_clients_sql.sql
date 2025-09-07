-- =====================================================
-- DIAGNOSTIC TOP 10 CLIENTS - SQL
-- =====================================================
-- Script SQL pour diagnostiquer le problème du top 10 des clients
-- dans les statistiques
-- Date: 2025-01-23
-- =====================================================

-- 1. Vérifier l'utilisateur actuel
SELECT '=== UTILISATEUR ACTUEL ===' as etape;
SELECT 
    auth.uid() as user_id,
    CASE 
        WHEN auth.uid() IS NOT NULL THEN '✅ Utilisateur connecté'
        ELSE '❌ Aucun utilisateur connecté'
    END as status;

-- 2. Vérifier les clients de l'utilisateur
SELECT '=== CLIENTS DE L''UTILISATEUR ===' as etape;
SELECT 
    COUNT(*) as total_clients,
    COUNT(CASE WHEN user_id = auth.uid() THEN 1 END) as clients_utilisateur,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as clients_sans_user_id,
    COUNT(CASE WHEN user_id != auth.uid() THEN 1 END) as clients_autres_utilisateurs
FROM clients;

-- 3. Vérifier les réparations de l'utilisateur
SELECT '=== RÉPARATIONS DE L''UTILISATEUR ===' as etape;
SELECT 
    COUNT(*) as total_repairs,
    COUNT(CASE WHEN user_id = auth.uid() THEN 1 END) as repairs_utilisateur,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as repairs_sans_user_id,
    COUNT(CASE WHEN user_id != auth.uid() THEN 1 END) as repairs_autres_utilisateurs
FROM repairs;

-- 4. Vérifier la correspondance clients-réparations
SELECT '=== CORRESPONDANCE CLIENTS-RÉPARATIONS ===' as etape;

-- Réparations avec clients valides
WITH repairs_with_valid_clients AS (
    SELECT 
        r.id as repair_id,
        r.repair_number,
        r.client_id,
        r.total_price,
        r.user_id as repair_user_id,
        c.id as client_exists,
        c.first_name,
        c.last_name,
        c.user_id as client_user_id
    FROM repairs r
    LEFT JOIN clients c ON r.client_id = c.id
    WHERE r.user_id = auth.uid()
)
SELECT 
    COUNT(*) as total_repairs_utilisateur,
    COUNT(CASE WHEN client_exists IS NOT NULL THEN 1 END) as repairs_avec_clients_valides,
    COUNT(CASE WHEN client_exists IS NULL THEN 1 END) as repairs_avec_clients_invalides,
    COUNT(CASE WHEN client_exists IS NOT NULL AND client_user_id = auth.uid() THEN 1 END) as repairs_avec_clients_utilisateur
FROM repairs_with_valid_clients;

-- 5. Calculer le top 10 des clients (simulation)
SELECT '=== TOP 10 CLIENTS (SIMULATION) ===' as etape;

WITH client_repair_stats AS (
    SELECT 
        c.id as client_id,
        c.first_name,
        c.last_name,
        c.email,
        COUNT(r.id) as total_repairs,
        COALESCE(SUM(CAST(r.total_price AS DECIMAL)), 0) as total_revenue
    FROM clients c
    LEFT JOIN repairs r ON c.id = r.client_id AND r.user_id = auth.uid()
    WHERE c.user_id = auth.uid()
    GROUP BY c.id, c.first_name, c.last_name, c.email
    HAVING COUNT(r.id) > 0
    ORDER BY total_repairs DESC, total_revenue DESC
    LIMIT 10
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY total_repairs DESC, total_revenue DESC) as rank,
    first_name,
    last_name,
    email,
    total_repairs,
    total_revenue
FROM client_repair_stats;

-- 6. Vérifier les données orphelines
SELECT '=== DONNÉES ORPHELINES ===' as etape;

-- Réparations avec des client_id qui n'existent pas
SELECT 
    'Réparations avec clients inexistants' as type_probleme,
    COUNT(*) as nombre
FROM repairs r
LEFT JOIN clients c ON r.client_id = c.id
WHERE r.user_id = auth.uid() AND c.id IS NULL

UNION ALL

-- Clients sans réparations
SELECT 
    'Clients sans réparations' as type_probleme,
    COUNT(*) as nombre
FROM clients c
LEFT JOIN repairs r ON c.id = r.client_id AND r.user_id = auth.uid()
WHERE c.user_id = auth.uid() AND r.id IS NULL;

-- 7. Vérifier l'isolation des données
SELECT '=== VÉRIFICATION ISOLATION ===' as etape;

-- Vérifier si RLS est activé
SELECT 
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename IN ('clients', 'repairs')
ORDER BY tablename;

-- Vérifier les politiques RLS
SELECT 
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%user_id = auth.uid()%' THEN '✅ Isolation par user_id'
        ELSE '❌ Autre condition'
    END as isolation_type
FROM pg_policies 
WHERE tablename IN ('clients', 'repairs')
ORDER BY tablename, policyname;

-- 8. Test d'insertion pour vérifier l'isolation
SELECT '=== TEST D''ISOLATION ===' as etape;

DO $$
DECLARE
    v_user_id UUID;
    v_test_client_id UUID;
    v_test_repair_id UUID;
BEGIN
    -- Obtenir l'utilisateur actuel
    v_user_id := auth.uid();
    
    IF v_user_id IS NULL THEN
        RAISE NOTICE '❌ Aucun utilisateur connecté - test impossible';
        RETURN;
    END IF;
    
    RAISE NOTICE '✅ Test d''isolation pour l''utilisateur: %', v_user_id;
    
    -- Test 1: Vérifier qu'on ne peut voir que ses propres clients
    IF EXISTS (
        SELECT 1 FROM clients 
        WHERE user_id != v_user_id 
        LIMIT 1
    ) THEN
        RAISE NOTICE '❌ Problème d''isolation: clients d''autres utilisateurs visibles';
    ELSE
        RAISE NOTICE '✅ Isolation clients OK';
    END IF;
    
    -- Test 2: Vérifier qu'on ne peut voir que ses propres réparations
    IF EXISTS (
        SELECT 1 FROM repairs 
        WHERE user_id != v_user_id 
        LIMIT 1
    ) THEN
        RAISE NOTICE '❌ Problème d''isolation: réparations d''autres utilisateurs visibles';
    ELSE
        RAISE NOTICE '✅ Isolation réparations OK';
    END IF;
    
    -- Test 3: Vérifier la cohérence des données
    IF EXISTS (
        SELECT 1 FROM repairs r
        LEFT JOIN clients c ON r.client_id = c.id
        WHERE r.user_id = v_user_id 
        AND c.id IS NULL
        LIMIT 1
    ) THEN
        RAISE NOTICE '⚠️ Données incohérentes: réparations avec clients inexistants';
    ELSE
        RAISE NOTICE '✅ Cohérence des données OK';
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test: %', SQLERRM;
END $$;

-- 9. Instructions finales
SELECT '=== INSTRUCTIONS FINALES ===' as etape;
SELECT '✅ Vérifiez les résultats ci-dessus' as instruction_1;
SELECT '✅ Si le top 10 est vide, vérifiez l''isolation des données' as instruction_2;
SELECT '✅ Si des données orphelines existent, nettoyez-les' as instruction_3;
SELECT '✅ Testez maintenant l''interface des statistiques' as instruction_4;
