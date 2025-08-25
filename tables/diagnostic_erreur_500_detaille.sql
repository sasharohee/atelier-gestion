-- =====================================================
-- DIAGNOSTIC DÉTAILLÉ ERREUR 500
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T15:00:00.000Z

-- Script de diagnostic détaillé pour l'erreur 500 lors de l'inscription

-- =====================================================
-- ÉTAPE 1: VÉRIFICATION DES LOGS D'ERREUR
-- =====================================================

-- Vérifier les erreurs récentes dans les logs
SELECT 
  'DIAGNOSTIC - Erreurs récentes' as info,
  'Vérifier les logs Supabase pour les erreurs 500' as message;

-- =====================================================
-- ÉTAPE 2: VÉRIFICATION DES TRIGGERS ACTIFS
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
-- ÉTAPE 3: VÉRIFICATION DES FONCTIONS
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
-- ÉTAPE 4: VÉRIFICATION DES PERMISSIONS DÉTAILLÉES
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

-- Permissions sur les séquences auth
SELECT 
  'DIAGNOSTIC - Permissions séquences auth' as info,
  grantee,
  privilege_type,
  is_grantable
FROM information_schema.role_usage_grants 
WHERE object_schema = 'auth'
  AND grantee IN ('authenticated', 'anon', 'service_role')
ORDER BY grantee, privilege_type;

-- =====================================================
-- ÉTAPE 5: VÉRIFICATION DE LA STRUCTURE
-- =====================================================

-- Vérifier la structure de auth.users
SELECT 
  'DIAGNOSTIC - Structure auth.users' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
  AND table_schema = 'auth'
ORDER BY ordinal_position;

-- Vérifier la structure de subscription_status
SELECT 
  'DIAGNOSTIC - Structure subscription_status' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'subscription_status' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- =====================================================
-- ÉTAPE 6: VÉRIFICATION DES CONTRAINTES
-- =====================================================

-- Contraintes sur auth.users
SELECT 
  'DIAGNOSTIC - Contraintes auth.users' as info,
  constraint_name,
  constraint_type,
  table_name
FROM information_schema.table_constraints 
WHERE table_name = 'users' 
  AND table_schema = 'auth';

-- Contraintes sur subscription_status
SELECT 
  'DIAGNOSTIC - Contraintes subscription_status' as info,
  constraint_name,
  constraint_type,
  table_name
FROM information_schema.table_constraints 
WHERE table_name = 'subscription_status' 
  AND table_schema = 'public';

-- =====================================================
-- ÉTAPE 7: TEST DE SIMULATION D'ERREUR
-- =====================================================

-- Test de simulation d'une insertion avec erreur
DO $$
DECLARE
  test_user_id UUID := gen_random_uuid();
  test_email TEXT := 'test_diagnostic_' || extract(epoch from now())::text || '@test.com';
  error_occurred BOOLEAN := false;
BEGIN
  RAISE NOTICE '🧪 Test de diagnostic pour: %', test_email;
  
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
-- ÉTAPE 8: VÉRIFICATION DES SESSIONS
-- =====================================================

-- Vérifier l'état des sessions
SELECT 
  'DIAGNOSTIC - Sessions actives' as info,
  COUNT(*) as total_sessions
FROM auth.sessions 
WHERE not_after > NOW();

-- Vérifier les sessions expirées
SELECT 
  'DIAGNOSTIC - Sessions expirées' as info,
  COUNT(*) as expired_sessions
FROM auth.sessions 
WHERE not_after <= NOW();

-- =====================================================
-- ÉTAPE 9: RAPPORT DE DIAGNOSTIC
-- =====================================================

-- Résumé du diagnostic
SELECT 
  'RAPPORT DE DIAGNOSTIC' as info,
  (SELECT COUNT(*) FROM information_schema.triggers WHERE event_object_table = 'users' AND event_object_schema = 'auth') as triggers_auth_users,
  (SELECT COUNT(*) FROM information_schema.routines WHERE routine_name LIKE '%user%' OR routine_name LIKE '%auth%') as fonctions_auth,
  (SELECT COUNT(*) FROM information_schema.role_table_grants WHERE table_name = 'users' AND table_schema = 'auth' AND grantee = 'authenticated') as permissions_auth_users,
  (SELECT COUNT(*) FROM auth.users) as total_users,
  (SELECT COUNT(*) FROM subscription_status) as total_subscriptions;

-- Recommandations
SELECT 
  'RECOMMANDATIONS' as info,
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
