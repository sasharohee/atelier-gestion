-- =====================================================
-- VÉRIFICATION ÉTAT ACTUEL SIMPLE
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T17:35:00.000Z

-- Script de vérification simple pour l'état actuel des tables

-- =====================================================
-- ÉTAPE 1: VÉRIFICATION DES TABLES EXISTANTES
-- =====================================================

-- Lister toutes les tables dans le schéma public
SELECT 
  'TABLES EXISTANTES' as info,
  tablename,
  tableowner,
  CASE 
    WHEN rowsecurity = false THEN 'Unrestricted'
    ELSE 'Restricted'
  END as rls_status
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- =====================================================
-- ÉTAPE 2: VÉRIFICATION SPÉCIFIQUE SUBSCRIPTION_STATUS
-- =====================================================

-- Vérifier si subscription_status existe
SELECT 
  'VÉRIFICATION SUBSCRIPTION_STATUS' as info,
  CASE 
    WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'subscription_status' AND schemaname = 'public') 
    THEN '✅ Table subscription_status existe'
    ELSE '❌ Table subscription_status N''EXISTE PAS'
  END as status;

-- =====================================================
-- ÉTAPE 3: COMPTE DES UTILISATEURS
-- =====================================================

-- Compter les utilisateurs dans auth.users
SELECT 
  'COMPTE UTILISATEURS AUTH' as info,
  (SELECT COUNT(*) FROM auth.users) as total_users_auth;

-- Compter les utilisateurs dans subscription_status (si la table existe)
SELECT 
  'COMPTE SUBSCRIPTION_STATUS' as info,
  CASE 
    WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'subscription_status' AND schemaname = 'public') 
    THEN (SELECT COUNT(*) FROM subscription_status)
    ELSE 0
  END as total_users_subscription;

-- =====================================================
-- ÉTAPE 4: VÉRIFICATION DES TRIGGERS
-- =====================================================

-- Triggers actifs
SELECT 
  'TRIGGERS ACTIFS' as info,
  trigger_name,
  event_object_table,
  event_manipulation,
  action_statement
FROM information_schema.triggers 
WHERE trigger_schema = 'public' OR event_object_schema = 'auth'
ORDER BY trigger_name;

-- =====================================================
-- ÉTAPE 5: VÉRIFICATION DES PERMISSIONS
-- =====================================================

-- Permissions sur subscription_status (si la table existe)
SELECT 
  'PERMISSIONS SUBSCRIPTION_STATUS' as info,
  grantee,
  privilege_type,
  is_grantable
FROM information_schema.role_table_grants 
WHERE table_name = 'subscription_status' 
  AND table_schema = 'public'
  AND grantee IN ('authenticated', 'anon', 'service_role')
ORDER BY grantee, privilege_type;

-- =====================================================
-- ÉTAPE 6: RAPPORT FINAL
-- =====================================================

-- Rapport final
SELECT 
  'RAPPORT FINAL' as info,
  (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public') as total_tables,
  (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = false) as tables_unrestricted,
  (SELECT COUNT(*) FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = true) as tables_restricted,
  CASE 
    WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'subscription_status' AND schemaname = 'public') 
    THEN '✅ subscription_status existe'
    ELSE '❌ subscription_status manquante'
  END as subscription_status_status,
  (SELECT COUNT(*) FROM information_schema.triggers WHERE event_object_table = 'users' AND event_object_schema = 'auth') as triggers_auth_users;
