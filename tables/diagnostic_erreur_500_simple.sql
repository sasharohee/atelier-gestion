-- =====================================================
-- DIAGNOSTIC SIMPLIFIÉ ERREUR 500
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T15:10:00.000Z

-- Script de diagnostic simplifié pour l'erreur 500 lors de l'inscription

-- =====================================================
-- ÉTAPE 1: VÉRIFICATION DES TRIGGERS ACTIFS
-- =====================================================

-- Lister tous les triggers actifs
SELECT 
  'DIAGNOSTIC - Tous les triggers actifs' as info,
  trigger_schema,
  trigger_name,
  event_manipulation,
  action_statement,
  action_timing
FROM information_schema.triggers 
ORDER BY trigger_schema, trigger_name;

-- Vérifier spécifiquement les triggers sur auth.users
SELECT 
  'DIAGNOSTIC - Triggers sur auth.users' as info,
  trigger_name,
  event_manipulation,
  action_statement,
  action_timing,
  CASE 
    WHEN trigger_name IS NOT NULL THEN '✅ Actif'
    ELSE '❌ Aucun trigger'
  END as status
FROM information_schema.triggers 
WHERE event_object_table = 'users' 
  AND event_object_schema = 'auth';

-- =====================================================
-- ÉTAPE 2: VÉRIFICATION DES FONCTIONS
-- =====================================================

-- Lister toutes les fonctions liées à l'authentification
SELECT 
  'DIAGNOSTIC - Fonctions liées à l''auth' as info,
  routine_schema,
  routine_name,
  routine_type,
  security_type,
  data_type
FROM information_schema.routines 
WHERE routine_name LIKE '%user%' 
   OR routine_name LIKE '%auth%'
   OR routine_name LIKE '%handle%'
ORDER BY routine_schema, routine_name;

-- =====================================================
-- ÉTAPE 3: VÉRIFICATION DES PERMISSIONS
-- =====================================================

-- Permissions sur auth.users
SELECT 
  'DIAGNOSTIC - Permissions auth.users' as info,
  grantee,
  privilege_type,
  is_grantable,
  CASE 
    WHEN privilege_type = 'ALL' THEN '✅ Tous privilèges'
    WHEN privilege_type IN ('INSERT', 'SELECT', 'UPDATE', 'DELETE') THEN '✅ Privilège spécifique'
    ELSE '⚠️ Privilège limité'
  END as status
FROM information_schema.role_table_grants 
WHERE table_name = 'users' 
  AND table_schema = 'auth'
  AND grantee IN ('authenticated', 'anon', 'service_role')
ORDER BY grantee, privilege_type;

-- Permissions sur subscription_status
SELECT 
  'DIAGNOSTIC - Permissions subscription_status' as info,
  grantee,
  privilege_type,
  is_grantable
FROM information_schema.role_table_grants 
WHERE table_name = 'subscription_status' 
  AND table_schema = 'public'
  AND grantee IN ('authenticated', 'anon', 'service_role')
ORDER BY grantee, privilege_type;

-- =====================================================
-- ÉTAPE 4: VÉRIFICATION RLS
-- =====================================================

-- Vérifier RLS sur subscription_status
SELECT 
  'DIAGNOSTIC - RLS subscription_status' as info,
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
-- ÉTAPE 5: TEST DE SIMULATION D'ERREUR
-- =====================================================

-- Test de simulation d'une insertion avec erreur
DO $$
DECLARE
  test_user_id UUID := gen_random_uuid();
  test_email TEXT := 'test_diagnostic_simple_' || extract(epoch from now())::text || '@test.com';
  error_occurred BOOLEAN := false;
BEGIN
  RAISE NOTICE '🧪 Test de diagnostic simplifié pour: %', test_email;
  
  BEGIN
    -- Essayer d'insérer un utilisateur
    INSERT INTO auth.users (
      id,
      email,
      encrypted_password,
      email_confirmed_at,
      created_at,
      updated_at
    ) VALUES (
      test_user_id,
      test_email,
      'test_password_hash',
      NOW(),
      NOW(),
      NOW()
    );
    
    RAISE NOTICE '✅ Insertion réussie dans auth.users';
    
    -- Vérifier si le trigger a fonctionné
    IF EXISTS (SELECT 1 FROM subscription_status WHERE user_id = test_user_id) THEN
      RAISE NOTICE '✅ Trigger fonctionne - Utilisateur ajouté à subscription_status';
    ELSE
      RAISE NOTICE '❌ Trigger ne fonctionne pas - Utilisateur manquant dans subscription_status';
    END IF;
    
  EXCEPTION
    WHEN OTHERS THEN
      error_occurred := true;
      RAISE NOTICE '❌ ERREUR lors de l''insertion: %', SQLERRM;
  END;
  
  -- Nettoyer
  IF NOT error_occurred THEN
    DELETE FROM subscription_status WHERE user_id = test_user_id;
    DELETE FROM auth.users WHERE id = test_user_id;
    RAISE NOTICE '🧹 Nettoyage terminé';
  END IF;
  
END $$;

-- =====================================================
-- ÉTAPE 6: RAPPORT DE DIAGNOSTIC
-- =====================================================

-- Résumé du diagnostic
SELECT 
  'RAPPORT DE DIAGNOSTIC SIMPLIFIÉ' as info,
  (SELECT COUNT(*) FROM information_schema.triggers WHERE event_object_table = 'users' AND event_object_schema = 'auth') as triggers_auth_users,
  (SELECT COUNT(*) FROM information_schema.routines WHERE routine_name LIKE '%user%' OR routine_name LIKE '%auth%') as fonctions_auth,
  (SELECT COUNT(*) FROM information_schema.role_table_grants WHERE table_name = 'users' AND table_schema = 'auth' AND grantee = 'authenticated') as permissions_auth_users,
  (SELECT COUNT(*) FROM auth.users) as total_users,
  (SELECT COUNT(*) FROM subscription_status) as total_subscriptions;

-- Recommandations
SELECT 
  'RECOMMANDATIONS SIMPLIFIÉES' as info,
  CASE 
    WHEN (SELECT COUNT(*) FROM information_schema.triggers WHERE event_object_table = 'users' AND event_object_schema = 'auth') = 0 
    THEN '❌ Aucun trigger sur auth.users - Créer le trigger'
    ELSE '✅ Trigger présent sur auth.users'
  END as trigger_status,
  CASE 
    WHEN (SELECT COUNT(*) FROM information_schema.role_table_grants WHERE table_name = 'users' AND table_schema = 'auth' AND grantee = 'authenticated' AND privilege_type = 'ALL') > 0 
    THEN '✅ Permissions complètes sur auth.users'
    ELSE '❌ Permissions insuffisantes sur auth.users'
  END as permissions_status,
  CASE 
    WHEN (SELECT COUNT(*) FROM auth.users) = (SELECT COUNT(*) FROM subscription_status) 
    THEN '✅ Synchronisation complète'
    ELSE '❌ Utilisateurs manquants dans subscription_status'
  END as sync_status;
