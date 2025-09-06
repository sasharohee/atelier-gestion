-- 🔍 DIAGNOSTIC AVANCÉ - Clients Manquants
-- Script de diagnostic approfondi pour identifier le problème exact
-- Date: 2025-01-23

-- ============================================================================
-- 1. VÉRIFICATION COMPLÈTE DU WORKSHOP_ID
-- ============================================================================

SELECT '=== VÉRIFICATION WORKSHOP_ID ===' as section;

-- Vérifier le workshop_id actuel
SELECT 
    'Workshop ID actuel' as info,
    key,
    value as current_workshop_id,
    CASE 
        WHEN value IS NULL THEN '❌ PROBLÈME: workshop_id NULL'
        WHEN value = '00000000-0000-0000-0000-000000000000' THEN '❌ PROBLÈME: workshop_id par défaut'
        ELSE '✅ OK: workshop_id défini'
    END as status
FROM system_settings 
WHERE key = 'workshop_id';

-- ============================================================================
-- 2. VÉRIFICATION COMPLÈTE DE LA TABLE CLIENTS
-- ============================================================================

SELECT '=== VÉRIFICATION TABLE CLIENTS ===' as section;

-- Vérifier la structure de la table clients
SELECT 
    'Structure table clients' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'clients'
ORDER BY ordinal_position;

-- Compter tous les clients (sans RLS)
SELECT 
    'Tous les clients (sans RLS)' as check_type,
    COUNT(*) as total_clients
FROM clients;

-- Vérifier les workshop_id des clients
SELECT 
    'Workshop_id des clients' as check_type,
    workshop_id,
    COUNT(*) as client_count,
    CASE 
        WHEN workshop_id IS NULL THEN 'NULL'
        WHEN workshop_id = '00000000-0000-0000-0000-000000000000'::UUID THEN 'Défaut'
        WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 'Actuel'
        ELSE 'Autre'
    END as workshop_type
FROM clients 
GROUP BY workshop_id
ORDER BY client_count DESC;

-- ============================================================================
-- 3. VÉRIFICATION DÉTAILLÉE DES POLITIQUES RLS
-- ============================================================================

SELECT '=== VÉRIFICATION POLITIQUES RLS ===' as section;

-- Vérifier l'activation RLS
SELECT 
    'Activation RLS' as info,
    tablename,
    CASE WHEN rowsecurity THEN 'Active' ELSE 'Inactive' END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' 
    AND tablename = 'clients';

-- Vérifier toutes les politiques RLS
SELECT 
    'Politiques RLS clients' as info,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename = 'clients'
ORDER BY policyname;

-- ============================================================================
-- 4. TEST D'ACCÈS AVEC RLS ACTIF
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

-- Test 3: Vérifier les clients avec workshop_id NULL
SELECT 
    'Clients avec workshop_id NULL' as check_type,
    COUNT(*) as null_workshop_clients
FROM clients 
WHERE workshop_id IS NULL;

-- Test 4: Vérifier les clients avec workshop_id par défaut
SELECT 
    'Clients avec workshop_id par défaut' as check_type,
    COUNT(*) as default_workshop_clients
FROM clients 
WHERE workshop_id = '00000000-0000-0000-0000-000000000000'::UUID;

-- ============================================================================
-- 5. TEST SANS RLS
-- ============================================================================

SELECT '=== TEST SANS RLS ===' as section;

-- Désactiver temporairement RLS pour le test
ALTER TABLE clients DISABLE ROW LEVEL SECURITY;

-- Compter tous les clients sans RLS
SELECT 
    'Clients sans RLS' as check_type,
    COUNT(*) as total_clients_without_rls
FROM clients;

-- Afficher quelques clients sans RLS
SELECT 
    'Exemples de clients (sans RLS)' as info,
    id,
    first_name,
    last_name,
    email,
    workshop_id,
    CASE 
        WHEN workshop_id IS NULL THEN 'NULL'
        WHEN workshop_id = '00000000-0000-0000-0000-000000000000'::UUID THEN 'Défaut'
        WHEN workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1) THEN 'Actuel'
        ELSE 'Autre'
    END as workshop_status
FROM clients 
ORDER BY first_name, last_name
LIMIT 10;

-- Réactiver RLS
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 6. DIAGNOSTIC DES POLITIQUES RLS
-- ============================================================================

SELECT '=== DIAGNOSTIC POLITIQUES RLS ===' as section;

-- Vérifier si les politiques RLS utilisent le bon workshop_id
SELECT 
    'Analyse des politiques RLS' as info,
    policyname,
    CASE 
        WHEN qual LIKE '%workshop_id%' THEN '✅ Utilise workshop_id'
        WHEN qual LIKE '%user_id%' THEN '⚠️ Utilise user_id'
        WHEN qual LIKE '%auth.uid%' THEN '⚠️ Utilise auth.uid'
        ELSE '❓ Autre condition'
    END as policy_type,
    qual as condition
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename = 'clients'
ORDER BY policyname;

-- ============================================================================
-- 7. SOLUTION PROPOSÉE
-- ============================================================================

SELECT '=== SOLUTION PROPOSÉE ===' as section;

-- Identifier le problème exact
SELECT 
    'Diagnostic du problème' as info,
    (SELECT COUNT(*) FROM clients) as total_clients,
    (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)) as clients_with_correct_workshop,
    (SELECT COUNT(*) FROM clients WHERE workshop_id IS NULL) as clients_without_workshop,
    (SELECT COUNT(*) FROM clients WHERE workshop_id = '00000000-0000-0000-0000-000000000000'::UUID) as clients_with_default_workshop,
    (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'clients') as rls_policies_count,
    CASE 
        WHEN (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)) = 0 
        THEN '🚨 PROBLÈME: Aucun client avec le bon workshop_id'
        WHEN (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'clients') = 0 
        THEN '🚨 PROBLÈME: Aucune politique RLS'
        WHEN (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)) > 0 
        AND (SELECT COUNT(*) FROM clients) = 0 
        THEN '🚨 PROBLÈME: Clients existent mais RLS les cache'
        ELSE '✅ DIAGNOSTIC: Problème identifié'
    END as problem_identification;

-- Recommandations spécifiques
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)) = 0 
        THEN '🔧 ACTION: Mettre à jour les workshop_id des clients'
        ELSE '✅ Aucune action requise pour les workshop_id'
    END as recommendation_1
UNION ALL
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'clients') = 0 
        THEN '🔧 ACTION: Créer les politiques RLS'
        ELSE '✅ Politiques RLS présentes'
    END as recommendation_2
UNION ALL
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM clients WHERE workshop_id = (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)) > 0 
        AND (SELECT COUNT(*) FROM clients) = 0 
        THEN '🔧 ACTION: Corriger les politiques RLS'
        ELSE '✅ Politiques RLS fonctionnent'
    END as recommendation_3;
