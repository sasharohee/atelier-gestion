-- =====================================================
-- DIAGNOSTIC ERREUR INSCRIPTION
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T14:25:00.000Z

-- Script de diagnostic pour identifier la cause de l'erreur 500

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
-- ÉTAPE 3: VÉRIFICATION DES TRIGGERS
-- =====================================================

-- Vérifier tous les triggers sur auth.users
SELECT 
  'Triggers auth.users' as info,
  trigger_name,
  event_manipulation,
  action_statement,
  trigger_schema
FROM information_schema.triggers 
WHERE event_object_table = 'users'
  AND event_object_schema = 'auth';

-- =====================================================
-- ÉTAPE 4: VÉRIFICATION DES FONCTIONS
-- =====================================================

-- Vérifier toutes les fonctions liées
SELECT 
  'Fonctions liées' as info,
  routine_name,
  routine_type,
  routine_schema,
  security_type
FROM information_schema.routines 
WHERE routine_name IN ('handle_new_user', 'on_auth_user_created')
  OR routine_name LIKE '%user%';

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

-- Vérifier RLS sur subscription_status
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
-- ÉTAPE 6: VÉRIFICATION DES CONTRAINTES
-- =====================================================

-- Vérifier les contraintes sur subscription_status
SELECT 
  'Contraintes subscription_status' as info,
  constraint_name,
  constraint_type,
  table_name
FROM information_schema.table_constraints 
WHERE table_name = 'subscription_status'
  AND table_schema = 'public';

-- =====================================================
-- ÉTAPE 7: TEST D'INSERTION MANUEL
-- =====================================================

-- Tester l'insertion manuelle dans subscription_status
DO $$
DECLARE
  test_user_id UUID := gen_random_uuid();
  test_email TEXT := 'test_diagnostic_' || extract(epoch from now())::text || '@test.com';
BEGIN
  -- Tester l'insertion dans auth.users
  BEGIN
    INSERT INTO auth.users (
      id,
      email,
      encrypted_password,
      email_confirmed_at,
      created_at,
      updated_at,
      raw_user_meta_data
    ) VALUES (
      test_user_id,
      test_email,
      'test_password_hash',
      NOW(),
      NOW(),
      NOW(),
      '{"first_name": "Test", "last_name": "Diagnostic"}'
    );
    
    RAISE NOTICE '✅ SUCCÈS: Insertion dans auth.users réussie';
    
    -- Tester l'insertion dans subscription_status
    BEGIN
      INSERT INTO subscription_status (
        user_id,
        first_name,
        last_name,
        email,
        is_active,
        subscription_type,
        notes,
        activated_at
      ) VALUES (
        test_user_id,
        'Test',
        'Diagnostic',
        test_email,
        false,
        'free',
        'Test de diagnostic',
        NULL
      );
      
      RAISE NOTICE '✅ SUCCÈS: Insertion dans subscription_status réussie';
      
    EXCEPTION
      WHEN OTHERS THEN
        RAISE NOTICE '❌ ÉCHEC: Insertion dans subscription_status échouée - %', SQLERRM;
    END;
    
    -- Nettoyer
    DELETE FROM subscription_status WHERE user_id = test_user_id;
    DELETE FROM auth.users WHERE id = test_user_id;
    
  EXCEPTION
    WHEN OTHERS THEN
      RAISE NOTICE '❌ ÉCHEC: Insertion dans auth.users échouée - %', SQLERRM;
  END;
  
END $$;

-- =====================================================
-- ÉTAPE 8: RAPPORT FINAL
-- =====================================================

SELECT 
  'Diagnostic terminé' as info,
  'Voir les résultats ci-dessus pour identifier le problème' as message;
