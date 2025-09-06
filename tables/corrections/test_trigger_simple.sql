-- =====================================================
-- TEST SIMPLE DU TRIGGER
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T14:15:00.000Z

-- Script de test simple pour vérifier le trigger

-- =====================================================
-- ÉTAPE 1: VÉRIFICATION PRÉ-TEST
-- =====================================================

-- Vérifier l'état avant le test
SELECT 
  'État avant test' as info,
  (SELECT COUNT(*) FROM auth.users) as total_users,
  (SELECT COUNT(*) FROM subscription_status) as total_subscriptions;

-- =====================================================
-- ÉTAPE 2: TEST DU TRIGGER
-- =====================================================

-- Créer un utilisateur de test
DO $$
DECLARE
  test_user_id UUID := gen_random_uuid();
  test_email TEXT := 'test_' || extract(epoch from now())::text || '@test.com';
BEGIN
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
    '{"first_name": "Test", "last_name": "User"}'
  );
  
  -- Vérifier le résultat
  IF EXISTS (SELECT 1 FROM subscription_status WHERE user_id = test_user_id) THEN
    RAISE NOTICE '✅ SUCCÈS: L''utilisateur de test a été ajouté automatiquement';
  ELSE
    RAISE NOTICE '❌ ÉCHEC: L''utilisateur de test n''a PAS été ajouté';
  END IF;
  
  -- Nettoyer
  DELETE FROM subscription_status WHERE user_id = test_user_id;
  DELETE FROM auth.users WHERE id = test_user_id;
  
END $$;

-- =====================================================
-- ÉTAPE 3: VÉRIFICATION POST-TEST
-- =====================================================

-- Vérifier l'état après le test
SELECT 
  'État après test' as info,
  (SELECT COUNT(*) FROM auth.users) as total_users,
  (SELECT COUNT(*) FROM subscription_status) as total_subscriptions;

-- =====================================================
-- ÉTAPE 4: RAPPORT FINAL
-- =====================================================

SELECT 
  'Test terminé' as info,
  'Vérifiez les messages NOTICE ci-dessus pour le résultat' as message;
