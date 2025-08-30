-- 🔍 DIAGNOSTIC COMPLET ISOLATION DES DONNÉES
-- Script pour diagnostiquer pourquoi l'isolation ne fonctionne pas
-- Date: 2025-01-23

-- ============================================================================
-- 1. VÉRIFICATION DU WORKSHOP_ID ACTUEL
-- ============================================================================

SELECT '=== VÉRIFICATION DU WORKSHOP_ID ACTUEL ===' as section;

-- Vérifier le workshop_id actuel dans system_settings
SELECT 
    'Workshop ID actuel' as info,
    key,
    value,
    value::UUID as workshop_uuid
FROM system_settings 
WHERE key = 'workshop_id';

-- ============================================================================
-- 2. VÉRIFICATION DES CLIENTS PAR WORKSHOP
-- ============================================================================

SELECT '=== VÉRIFICATION DES CLIENTS PAR WORKSHOP ===' as section;

-- Voir tous les clients avec leur workshop_id
SELECT 
    'Tous les clients avec workshop_id' as info,
    id,
    first_name,
    last_name,
    email,
    workshop_id,
    created_at
FROM clients 
ORDER BY workshop_id, created_at;

-- Compter les clients par workshop
SELECT 
    'Répartition des clients par workshop' as info,
    workshop_id,
    COUNT(*) as nombre_clients,
    COUNT(CASE WHEN email IS NOT NULL THEN 1 END) as clients_avec_email
FROM clients 
GROUP BY workshop_id
ORDER BY workshop_id;

-- ============================================================================
-- 3. TEST DE L'ISOLATION ACTUELLE
-- ============================================================================

SELECT '=== TEST DE L'ISOLATION ACTUELLE ===' as section;

-- Test 1: Clients visibles via la vue
SELECT 
    'Test 1: Clients visibles via clients_isolated_final' as test,
    COUNT(*) as clients_visibles
FROM clients_isolated_final;

-- Test 2: Clients visibles via la fonction RPC
SELECT 
    'Test 2: Clients visibles via get_isolated_clients()' as test,
    json_array_length(get_isolated_clients()) as clients_visibles;

-- Test 3: Clients du workshop actuel
SELECT 
    'Test 3: Clients du workshop actuel' as test,
    COUNT(*) as clients_workshop_actuel
FROM clients 
WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);

-- Test 4: Clients d'autres workshops
SELECT 
    'Test 4: Clients d''autres workshops' as test,
    COUNT(*) as clients_autres_workshops
FROM clients 
WHERE workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
    OR workshop_id IS NULL;

-- ============================================================================
-- 4. VÉRIFICATION DES POLITIQUES RLS
-- ============================================================================

SELECT '=== VÉRIFICATION DES POLITIQUES RLS ===' as section;

-- Vérifier si RLS est activé sur clients
SELECT 
    'RLS sur table clients' as info,
    schemaname,
    tablename,
    rowsecurity as rls_active
FROM pg_tables 
WHERE tablename = 'clients';

-- Vérifier les politiques RLS existantes
SELECT 
    'Politiques RLS sur clients' as info,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'clients';

-- ============================================================================
-- 5. VÉRIFICATION DES FONCTIONS RPC
-- ============================================================================

SELECT '=== VÉRIFICATION DES FONCTIONS RPC ===' as section;

-- Vérifier les fonctions RPC existantes
SELECT 
    'Fonctions RPC isolées' as info,
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_name LIKE '%isolated%'
    AND routine_schema = 'public'
ORDER BY routine_name;

-- ============================================================================
-- 6. TEST DE CRÉATION D'UN CLIENT
-- ============================================================================

SELECT '=== TEST DE CRÉATION D''UN CLIENT ===' as section;

-- Créer un client de test pour vérifier l'isolation
SELECT 
    'Test création client isolé' as info,
    create_isolated_client(
        'Test Isolation', 
        'Compte A', 
        'test.isolation.' || extract(epoch from now())::TEXT || '@example.com', 
        '8888888888', 
        'Adresse test isolation'
    ) as resultat_creation;

-- ============================================================================
-- 7. VÉRIFICATION APRÈS CRÉATION
-- ============================================================================

SELECT '=== VÉRIFICATION APRÈS CRÉATION ===' as section;

-- Vérifier les clients après création
SELECT 
    'Clients après création de test' as info,
    id,
    first_name,
    last_name,
    email,
    workshop_id,
    created_at
FROM clients 
WHERE first_name = 'Test Isolation'
ORDER BY created_at DESC;

-- ============================================================================
-- 8. DIAGNOSTIC DES PROBLÈMES
-- ============================================================================

SELECT '=== DIAGNOSTIC DES PROBLÈMES ===' as section;

-- Diagnostic 1: Workshop_id NULL
SELECT 
    'Diagnostic 1: Clients sans workshop_id' as diagnostic,
    COUNT(*) as nombre_clients_sans_workshop
FROM clients 
WHERE workshop_id IS NULL;

-- Diagnostic 2: Workshop_id incorrect
SELECT 
    'Diagnostic 2: Workshop_id incorrect' as diagnostic,
    workshop_id,
    COUNT(*) as nombre_clients
FROM clients 
WHERE workshop_id IS NOT NULL
    AND workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
GROUP BY workshop_id;

-- Diagnostic 3: Problème de vue
SELECT 
    'Diagnostic 3: Problème de vue' as diagnostic,
    (SELECT COUNT(*) FROM clients) as total_clients,
    (SELECT COUNT(*) FROM clients_isolated_final) as clients_vue,
    (SELECT json_array_length(get_isolated_clients())) as clients_rpc,
    CASE 
        WHEN (SELECT COUNT(*) FROM clients_isolated_final) = (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1))
        THEN '✅ Vue correcte'
        ELSE '❌ Problème avec la vue'
    END as status_vue,
    CASE 
        WHEN (SELECT json_array_length(get_isolated_clients())) = (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1))
        THEN '✅ RPC correct'
        ELSE '❌ Problème avec RPC'
    END as status_rpc;

-- ============================================================================
-- 9. RÉSUMÉ DU DIAGNOSTIC
-- ============================================================================

SELECT '=== RÉSUMÉ DU DIAGNOSTIC ===' as section;

-- Résumé final
SELECT 
    'Résumé du diagnostic d''isolation' as info,
    (SELECT COUNT(*) FROM clients) as total_clients,
    (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)) as clients_workshop_actuel,
    (SELECT COUNT(*) FROM clients WHERE workshop_id != (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) OR workshop_id IS NULL) as clients_autres_workshops,
    (SELECT COUNT(*) FROM clients_isolated_final) as clients_visibles_vue,
    (SELECT json_array_length(get_isolated_clients())) as clients_visibles_rpc,
    (SELECT COUNT(*) FROM information_schema.routines WHERE routine_name LIKE '%isolated%' AND routine_schema = 'public') as fonctions_rpc_existantes,
    CASE 
        WHEN (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)) = (SELECT COUNT(*) FROM clients_isolated_final)
        THEN '✅ Isolation fonctionnelle'
        ELSE '❌ Problème d''isolation détecté'
    END as status_isolation;

-- Message de diagnostic
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)) = (SELECT COUNT(*) FROM clients_isolated_final)
        THEN '🎯 DIAGNOSTIC: L''isolation semble fonctionnelle'
        ELSE '🚨 DIAGNOSTIC: Problème d''isolation détecté - voir détails ci-dessus'
    END as diagnostic_message;
