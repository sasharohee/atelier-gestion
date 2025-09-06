-- =====================================================
-- CRÉATION TRIGGER AUTOMATIQUE
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T14:40:00.000Z

-- Script pour créer un trigger qui ajoute automatiquement les nouveaux utilisateurs

-- =====================================================
-- ÉTAPE 1: SUPPRESSION DES ANCIENS TRIGGERS
-- =====================================================

-- Supprimer les triggers et fonctions existants
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- =====================================================
-- ÉTAPE 2: CRÉATION DE LA FONCTION
-- =====================================================

-- Créer la fonction pour gérer les nouveaux utilisateurs
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  -- Insérer le nouvel utilisateur dans subscription_status
  INSERT INTO subscription_status (
    user_id,
    first_name,
    last_name,
    email,
    is_active,
    subscription_type,
    notes,
    activated_at,
    created_at,
    updated_at
  ) VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'first_name', 'Utilisateur'),
    COALESCE(NEW.raw_user_meta_data->>'last_name', 'Test'),
    NEW.email,
    CASE 
      WHEN NEW.raw_user_meta_data->>'role' = 'admin' THEN true
      WHEN NEW.email = 'srohee32@gmail.com' THEN true
      WHEN NEW.email = 'repphonereparation@gmail.com' THEN true
      ELSE false
    END,
    CASE 
      WHEN NEW.raw_user_meta_data->>'role' = 'admin' THEN 'premium'
      WHEN NEW.email = 'srohee32@gmail.com' THEN 'premium'
      WHEN NEW.email = 'repphonereparation@gmail.com' THEN 'premium'
      ELSE 'free'
    END,
    CASE 
      WHEN NEW.raw_user_meta_data->>'role' = 'admin' THEN 'Administrateur - accès complet'
      WHEN NEW.email = 'srohee32@gmail.com' THEN 'Administrateur principal'
      WHEN NEW.email = 'repphonereparation@gmail.com' THEN 'Compte principal'
      ELSE 'Nouveau compte - en attente d''activation'
    END,
    CASE 
      WHEN NEW.raw_user_meta_data->>'role' = 'admin' THEN NEW.created_at
      WHEN NEW.email = 'srohee32@gmail.com' THEN NEW.created_at
      WHEN NEW.email = 'repphonereparation@gmail.com' THEN NEW.created_at
      ELSE NULL
    END,
    NEW.created_at,
    NOW()
  );
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- En cas d'erreur, continuer sans bloquer l'inscription
    RAISE NOTICE 'Erreur lors de l''ajout à subscription_status: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- ÉTAPE 3: CRÉATION DU TRIGGER
-- =====================================================

-- Créer le trigger sur la table auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- =====================================================
-- ÉTAPE 4: VÉRIFICATION
-- =====================================================

-- Vérifier que le trigger a été créé
SELECT 
  'Trigger créé' as info,
  trigger_name,
  event_manipulation,
  action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'on_auth_user_created';

-- Vérifier que la fonction a été créée
SELECT 
  'Fonction créée' as info,
  routine_name,
  routine_type,
  security_type
FROM information_schema.routines 
WHERE routine_name = 'handle_new_user';

-- =====================================================
-- ÉTAPE 5: TEST DU TRIGGER
-- =====================================================

-- Créer un utilisateur de test pour vérifier le trigger
DO $$
DECLARE
  test_user_id UUID := gen_random_uuid();
  test_email TEXT := 'test_trigger_' || extract(epoch from now())::text || '@test.com';
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
    '{"first_name": "Test", "last_name": "Trigger"}'
  );
  
  -- Vérifier le résultat
  IF EXISTS (SELECT 1 FROM subscription_status WHERE user_id = test_user_id) THEN
    RAISE NOTICE '✅ SUCCÈS: L''utilisateur de test a été ajouté automatiquement par le trigger';
  ELSE
    RAISE NOTICE '❌ ÉCHEC: L''utilisateur de test n''a PAS été ajouté par le trigger';
  END IF;
  
  -- Nettoyer
  DELETE FROM subscription_status WHERE user_id = test_user_id;
  DELETE FROM auth.users WHERE id = test_user_id;
  
END $$;

-- =====================================================
-- ÉTAPE 6: RAPPORT FINAL
-- =====================================================

SELECT 
  'Trigger configuré' as status,
  'Les nouveaux utilisateurs seront automatiquement ajoutés à subscription_status' as message;
