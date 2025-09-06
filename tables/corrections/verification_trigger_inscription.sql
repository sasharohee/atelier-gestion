-- =====================================================
-- VÉRIFICATION TRIGGER INSCRIPTION
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T14:50:00.000Z

-- Script pour vérifier si le trigger a été exécuté lors de l'inscription

-- =====================================================
-- ÉTAPE 1: VÉRIFICATION DES DERNIERS UTILISATEURS
-- =====================================================

-- Vérifier les utilisateurs récents (dernières 24h)
SELECT 
  'Utilisateurs récents (24h)' as info,
  u.id,
  u.email,
  u.created_at,
  CASE 
    WHEN ss.user_id IS NOT NULL THEN '✅ Dans subscription_status'
    ELSE '❌ Manquant dans subscription_status'
  END as status
FROM auth.users u
LEFT JOIN subscription_status ss ON u.id = ss.user_id
WHERE u.created_at > NOW() - INTERVAL '24 hours'
ORDER BY u.created_at DESC;

-- =====================================================
-- ÉTAPE 2: VÉRIFICATION DES UTILISATEURS MANQUANTS
-- =====================================================

-- Lister tous les utilisateurs qui ne sont pas dans subscription_status
SELECT 
  'Utilisateurs manquants dans subscription_status' as info,
  u.id,
  u.email,
  u.created_at,
  u.raw_user_meta_data
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM subscription_status ss WHERE ss.user_id = u.id
)
ORDER BY u.created_at DESC;

-- =====================================================
-- ÉTAPE 3: VÉRIFICATION DU TRIGGER
-- =====================================================

-- Vérifier si le trigger existe et est actif
SELECT 
  'État du trigger' as info,
  trigger_name,
  event_manipulation,
  action_statement,
  trigger_schema,
  CASE 
    WHEN trigger_name IS NOT NULL THEN '✅ Actif'
    ELSE '❌ Manquant'
  END as status
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

-- Vérifier si la fonction existe
SELECT 
  'État de la fonction' as info,
  routine_name,
  routine_type,
  routine_schema,
  security_type,
  CASE 
    WHEN routine_name IS NOT NULL THEN '✅ Existe'
    ELSE '❌ Manquante'
  END as status
FROM information_schema.routines 
WHERE routine_name = 'handle_new_user';

-- =====================================================
-- ÉTAPE 4: TEST MANUEL DU TRIGGER
-- =====================================================

-- Créer un utilisateur de test pour vérifier le trigger
DO $$
DECLARE
  test_user_id UUID := gen_random_uuid();
  test_email TEXT := 'test_verification_' || extract(epoch from now())::text || '@test.com';
BEGIN
  RAISE NOTICE '🧪 Test du trigger pour: %', test_email;
  
  -- Insérer un utilisateur de test
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
    '{"first_name": "Test", "last_name": "Verification"}'
  );
  
  RAISE NOTICE '✅ Utilisateur de test créé dans auth.users';
  
  -- Vérifier le résultat
  IF EXISTS (SELECT 1 FROM subscription_status WHERE user_id = test_user_id) THEN
    RAISE NOTICE '✅ SUCCÈS: L''utilisateur de test a été ajouté automatiquement par le trigger';
  ELSE
    RAISE NOTICE '❌ ÉCHEC: L''utilisateur de test n''a PAS été ajouté par le trigger';
  END IF;
  
  -- Nettoyer
  DELETE FROM subscription_status WHERE user_id = test_user_id;
  DELETE FROM auth.users WHERE id = test_user_id;
  
  RAISE NOTICE '🧹 Nettoyage terminé';
  
END $$;

-- =====================================================
-- ÉTAPE 5: VÉRIFICATION DES PERMISSIONS
-- =====================================================

-- Vérifier les permissions sur subscription_status
SELECT 
  'Permissions subscription_status' as info,
  grantee,
  privilege_type,
  is_grantable
FROM information_schema.role_table_grants 
WHERE table_name = 'subscription_status' 
  AND table_schema = 'public'
  AND grantee IN ('authenticated', 'anon', 'service_role');

-- Vérifier RLS
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
-- ÉTAPE 6: RAPPORT FINAL
-- =====================================================

SELECT 
  'Vérification terminée' as info,
  'Voir les résultats ci-dessus pour identifier le problème' as message;
