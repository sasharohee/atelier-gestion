-- 🔍 DIAGNOSTIC - Création de Client
-- Script pour diagnostiquer l'erreur PGRST116 lors de la création de client
-- Date: 2025-01-23

-- ============================================================================
-- 1. DIAGNOSTIC DE LA TABLE CLIENTS
-- ============================================================================

SELECT '=== DIAGNOSTIC TABLE CLIENTS ===' as section;

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

-- Vérifier les contraintes
SELECT 
    'Contraintes table clients' as info,
    constraint_name,
    constraint_type,
    table_name
FROM information_schema.table_constraints 
WHERE table_schema = 'public' 
    AND table_name = 'clients';

-- ============================================================================
-- 2. VÉRIFICATION DES POLITIQUES RLS
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
-- 3. VÉRIFICATION DU WORKSHOP_ID
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
-- 4. TEST DE CRÉATION DE CLIENT
-- ============================================================================

SELECT '=== TEST DE CRÉATION ===' as section;

-- Désactiver RLS temporairement pour le test
ALTER TABLE clients DISABLE ROW LEVEL SECURITY;

-- Tester l'insertion d'un client de test
INSERT INTO clients (
    first_name, 
    last_name, 
    email, 
    phone, 
    address, 
    workshop_id
) VALUES (
    'Test',
    'Client',
    'test@example.com',
    '0123456789',
    'Adresse de test',
    (SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1)
) RETURNING id, first_name, last_name, email, workshop_id;

-- Vérifier que le client a été créé
SELECT 
    'Client créé' as info,
    id,
    first_name,
    last_name,
    email,
    workshop_id
FROM clients 
WHERE email = 'test@example.com';

-- Réactiver RLS
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 5. TEST AVEC RLS ACTIF
-- ============================================================================

SELECT '=== TEST AVEC RLS ===' as section;

-- Compter les clients visibles avec RLS
SELECT 
    'Clients visibles avec RLS' as info,
    COUNT(*) as visible_clients
FROM clients;

-- Vérifier le client de test avec RLS
SELECT 
    'Client de test avec RLS' as info,
    id,
    first_name,
    last_name,
    email,
    workshop_id
FROM clients 
WHERE email = 'test@example.com';

-- ============================================================================
-- 6. DIAGNOSTIC DES POLITIQUES RLS
-- ============================================================================

SELECT '=== DIAGNOSTIC POLITIQUES RLS ===' as section;

-- Analyser les politiques RLS
SELECT 
    'Analyse des politiques RLS' as info,
    policyname,
    CASE 
        WHEN cmd = 'SELECT' THEN 'Lecture'
        WHEN cmd = 'INSERT' THEN 'Insertion'
        WHEN cmd = 'UPDATE' THEN 'Modification'
        WHEN cmd = 'DELETE' THEN 'Suppression'
        ELSE cmd
    END as operation,
    CASE 
        WHEN qual LIKE '%workshop_id%' THEN '✅ Utilise workshop_id'
        WHEN qual LIKE '%user_id%' THEN '⚠️ Utilise user_id'
        WHEN qual LIKE '%auth.uid%' THEN '⚠️ Utilise auth.uid'
        ELSE '❓ Autre condition'
    END as condition_type,
    qual as condition
FROM pg_policies 
WHERE schemaname = 'public' 
    AND tablename = 'clients'
ORDER BY cmd, policyname;

-- ============================================================================
-- 7. SOLUTION PROPOSÉE
-- ============================================================================

SELECT '=== SOLUTION PROPOSÉE ===' as section;

-- Identifier le problème
SELECT 
    'Diagnostic du problème' as info,
    (SELECT COUNT(*) FROM clients) as total_clients,
    (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'clients') as policies_count,
    (SELECT CASE WHEN rowsecurity THEN 'Active' ELSE 'Inactive' END FROM pg_tables WHERE schemaname = 'public' AND tablename = 'clients') as rls_status,
    CASE 
        WHEN (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'clients' AND cmd = 'INSERT') = 0 
        THEN '🚨 PROBLÈME: Aucune politique INSERT'
        WHEN (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'clients' AND cmd = 'SELECT') = 0 
        THEN '🚨 PROBLÈME: Aucune politique SELECT'
        WHEN (SELECT COUNT(*) FROM clients) = 0 
        THEN '🚨 PROBLÈME: Aucun client visible'
        ELSE '✅ DIAGNOSTIC: Problème identifié'
    END as problem_identification;

-- Recommandations
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'clients' AND cmd = 'INSERT') = 0 
        THEN '🔧 ACTION: Créer une politique INSERT'
        ELSE '✅ Politique INSERT présente'
    END as recommendation_1
UNION ALL
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM pg_policies WHERE schemaname = 'public' AND tablename = 'clients' AND cmd = 'SELECT') = 0 
        THEN '🔧 ACTION: Créer une politique SELECT'
        ELSE '✅ Politique SELECT présente'
    END as recommendation_2
UNION ALL
SELECT 
    CASE 
        WHEN (SELECT COUNT(*) FROM clients) = 0 
        THEN '🔧 ACTION: Vérifier les données et politiques RLS'
        ELSE '✅ Clients visibles'
    END as recommendation_3;
