-- 🔍 DIAGNOSTIC - Clients Manquants Après Isolation
-- Script pour diagnostiquer pourquoi les clients ne s'affichent plus
-- Date: 2025-01-23

-- ============================================================================
-- 1. DIAGNOSTIC RAPIDE
-- ============================================================================

SELECT '=== DIAGNOSTIC RAPIDE ===' as section;

-- Vérifier le workshop_id actuel
SELECT 
    'Workshop ID actuel' as info,
    value as current_workshop_id
FROM system_settings 
WHERE key = 'workshop_id';

-- ============================================================================
-- 2. VÉRIFICATION DES CLIENTS
-- ============================================================================

SELECT '=== VÉRIFICATION DES CLIENTS ===' as section;

-- Compter tous les clients (sans RLS)
SELECT 
    'Tous les clients (sans RLS)' as check_type,
    COUNT(*) as total_clients
FROM clients;

-- Vérifier les workshop_id des clients
SELECT 
    'Workshop_id des clients' as check_type,
    workshop_id,
    COUNT(*) as client_count
FROM clients 
GROUP BY workshop_id
ORDER BY client_count DESC;

-- Vérifier les clients sans workshop_id
SELECT 
    'Clients sans workshop_id' as check_type,
    COUNT(*) as clients_without_workshop
FROM clients 
WHERE workshop_id IS NULL;

-- Vérifier les clients avec workshop_id par défaut
SELECT 
    'Clients avec workshop_id par défaut' as check_type,
    COUNT(*) as clients_with_default_workshop
FROM clients 
WHERE workshop_id = '00000000-0000-0000-0000-000000000000'::UUID;

-- ============================================================================
-- 3. VÉRIFICATION DES POLITIQUES RLS
-- ============================================================================

SELECT '=== VÉRIFICATION DES POLITIQUES RLS ===' as section;

-- Vérifier les politiques RLS sur la table clients
SELECT 
    'Politiques RLS clients' as info,
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename = 'clients'
ORDER BY policyname;

-- ============================================================================
-- 4. TEST D'ACCÈS AVEC RLS
-- ============================================================================

SELECT '=== TEST D''ACCÈS AVEC RLS ===' as section;

-- Test 1: Compter les clients visibles avec RLS actif
SELECT 
    'Clients visibles (RLS actif)' as check_type,
    COUNT(*) as visible_clients
FROM clients;

-- Test 2: Vérifier si des clients correspondent au workshop_id actuel
SELECT 
    'Clients correspondant au workshop_id actuel' as check_type,
    COUNT(*) as matching_clients
FROM clients 
WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1);

-- ============================================================================
-- 5. SOLUTION PROPOSÉE
-- ============================================================================

SELECT '=== SOLUTION PROPOSÉE ===' as section;

-- Afficher les clients qui devraient être visibles
SELECT 
    'Clients qui devraient être visibles' as info,
    id,
    first_name,
    last_name,
    email,
    workshop_id,
    CASE 
        WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) 
        THEN '✅ Workshop_id correct'
        WHEN workshop_id IS NULL 
        THEN '❌ Workshop_id NULL'
        WHEN workshop_id = '00000000-0000-0000-0000-000000000000'::UUID 
        THEN '❌ Workshop_id par défaut'
        ELSE '❌ Workshop_id incorrect'
    END as status
FROM clients 
ORDER BY status, first_name, last_name
LIMIT 10;

-- ============================================================================
-- 6. RÉSUMÉ ET RECOMMANDATIONS
-- ============================================================================

SELECT '=== RÉSUMÉ ET RECOMMANDATIONS ===' as section;

-- Résumé du problème
SELECT 
    'Résumé du problème' as info,
    (SELECT COUNT(*) FROM clients) as total_clients,
    (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)) as clients_with_correct_workshop,
    (SELECT COUNT(*) FROM clients WHERE workshop_id IS NULL) as clients_without_workshop,
    (SELECT COUNT(*) FROM clients WHERE workshop_id = '00000000-0000-0000-0000-000000000000'::UUID) as clients_with_default_workshop,
    CASE 
        WHEN (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)) = 0 
        THEN '❌ AUCUN CLIENT AVEC LE BON WORKSHOP_ID'
        ELSE '✅ CLIENTS AVEC LE BON WORKSHOP_ID TROUVÉS'
    END as diagnosis;

-- Recommandations
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM clients WHERE workshop_id IS NULL) > 0 
        THEN '🔧 ACTION REQUISE: Mettre à jour les clients sans workshop_id'
        ELSE '✅ Aucune action requise pour les clients sans workshop_id'
    END as recommendation_1
UNION ALL
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM clients WHERE workshop_id = '00000000-0000-0000-0000-000000000000'::UUID) > 0 
        THEN '🔧 ACTION REQUISE: Mettre à jour les clients avec workshop_id par défaut'
        ELSE '✅ Aucune action requise pour les clients avec workshop_id par défaut'
    END as recommendation_2
UNION ALL
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)) = 0 
        THEN '🚨 PROBLÈME CRITIQUE: Aucun client avec le bon workshop_id - Exécuter la correction'
        ELSE '✅ Clients avec le bon workshop_id présents'
    END as recommendation_3;
