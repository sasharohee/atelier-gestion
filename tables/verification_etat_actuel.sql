-- =====================================================
-- VÉRIFICATION DE L'ÉTAT ACTUEL
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T14:05:00.000Z

-- Script pour vérifier l'état actuel et identifier les problèmes

-- =====================================================
-- ÉTAPE 1: VÉRIFICATION DES PERMISSIONS AUTH.USERS
-- =====================================================

-- Vérifier les permissions sur auth.users
SELECT 
  'Permissions auth.users' as info,
  grantee,
  privilege_type,
  is_grantable
FROM information_schema.role_table_grants 
WHERE table_name = 'users' 
  AND table_schema = 'auth'
  AND grantee IN ('authenticated', 'anon', 'service_role');

-- =====================================================
-- ÉTAPE 2: VÉRIFICATION DES SÉQUENCES
-- =====================================================

-- Vérifier les permissions sur les séquences auth
SELECT 
  'Permissions séquences auth' as info,
  grantee,
  privilege_type
FROM information_schema.role_usage_grants 
WHERE object_schema = 'auth'
  AND grantee IN ('authenticated', 'anon', 'service_role');

-- =====================================================
-- ÉTAPE 3: VÉRIFICATION DU TRIGGER
-- =====================================================

-- Vérifier si le trigger existe
SELECT 
  'Trigger on_auth_user_created' as info,
  trigger_name,
  event_manipulation,
  action_statement,
  CASE 
    WHEN trigger_name IS NOT NULL THEN '✅ Existe'
    ELSE '❌ Manquant'
  END as status
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

-- =====================================================
-- ÉTAPE 4: VÉRIFICATION DE LA FONCTION
-- =====================================================

-- Vérifier si la fonction existe
SELECT 
  'Fonction handle_new_user' as info,
  routine_name,
  routine_type,
  CASE 
    WHEN routine_name IS NOT NULL THEN '✅ Existe'
    ELSE '❌ Manquante'
  END as status
FROM information_schema.routines 
WHERE routine_name = 'handle_new_user'
  AND routine_schema = 'public';

-- =====================================================
-- ÉTAPE 5: VÉRIFICATION SUBSCRIPTION_STATUS
-- =====================================================

-- Vérifier l'état de subscription_status
SELECT 
  'État subscription_status' as info,
  (SELECT COUNT(*) FROM subscription_status) as total_entries,
  (SELECT COUNT(*) FROM auth.users) as total_users,
  CASE 
    WHEN (SELECT COUNT(*) FROM subscription_status) = (SELECT COUNT(*) FROM auth.users) 
    THEN '✅ Synchronisé'
    ELSE '❌ Non synchronisé'
  END as sync_status;

-- =====================================================
-- ÉTAPE 6: VÉRIFICATION RLS
-- =====================================================

-- Vérifier si RLS est activé sur subscription_status
SELECT 
  'RLS subscription_status' as info,
  schemaname,
  tablename,
  rowsecurity,
  CASE 
    WHEN rowsecurity = false THEN '✅ Désactivé (OK)'
    ELSE '❌ Activé (Problème)'
  END as status
FROM pg_tables 
WHERE tablename = 'subscription_status';

-- =====================================================
-- ÉTAPE 7: RAPPORT FINAL
-- =====================================================

SELECT 
  'Rapport final' as info,
  'Vérification terminée - voir les résultats ci-dessus' as message;
