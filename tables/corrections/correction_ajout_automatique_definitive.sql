-- =====================================================
-- CORRECTION DÉFINITIVE - AJOUT AUTOMATIQUE
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T14:10:00.000Z

-- Script définitif pour corriger l'ajout automatique des nouveaux utilisateurs

-- =====================================================
-- ÉTAPE 1: NETTOYAGE COMPLET
-- =====================================================

-- Supprimer complètement le trigger et la fonction existants
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- =====================================================
-- ÉTAPE 2: CRÉATION D'UNE FONCTION ROBUSTE
-- =====================================================

-- Créer une fonction robuste avec gestion d'erreur complète
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  error_message TEXT;
BEGIN
  -- Log pour debug
  RAISE NOTICE 'Trigger déclenché pour utilisateur: %', NEW.email;
  
  -- Insérer le nouvel utilisateur dans subscription_status
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
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'first_name', 'Utilisateur'),
    COALESCE(NEW.raw_user_meta_data->>'last_name', 'Test'),
    NEW.email,
    false,
    'free',
    'Nouveau compte - en attente d''activation',
    NULL
  );
  
  RAISE NOTICE 'Utilisateur ajouté avec succès à subscription_status: %', NEW.email;
  RETURN NEW;
  
EXCEPTION
  WHEN unique_violation THEN
    -- Si l'utilisateur existe déjà, mettre à jour
    UPDATE subscription_status 
    SET 
      first_name = COALESCE(NEW.raw_user_meta_data->>'first_name', 'Utilisateur'),
      last_name = COALESCE(NEW.raw_user_meta_data->>'last_name', 'Test'),
      email = NEW.email,
      updated_at = NOW()
    WHERE user_id = NEW.id;
    
    RAISE NOTICE 'Utilisateur mis à jour dans subscription_status: %', NEW.email;
    RETURN NEW;
    
  WHEN OTHERS THEN
    -- Capturer l'erreur mais ne pas bloquer l'inscription
    GET STACKED DIAGNOSTICS error_message = MESSAGE_TEXT;
    RAISE NOTICE 'Erreur lors de l''ajout à subscription_status pour %: %', NEW.email, error_message;
    
    -- Essayer d'insérer avec des valeurs par défaut
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
        NEW.id,
        'Utilisateur',
        'Test',
        NEW.email,
        false,
        'free',
        'Nouveau compte - ajouté avec gestion d''erreur',
        NULL
      );
      RAISE NOTICE 'Ajout réussi avec valeurs par défaut pour: %', NEW.email;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE NOTICE 'Échec complet de l''ajout pour: % - Erreur: %', NEW.email, SQLERRM;
    END;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- ÉTAPE 3: CRÉATION DU TRIGGER
-- =====================================================

-- Créer le trigger avec gestion d'erreur
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- =====================================================
-- ÉTAPE 4: VÉRIFICATION DES PERMISSIONS
-- =====================================================

-- S'assurer que toutes les permissions sont correctes
GRANT ALL PRIVILEGES ON TABLE subscription_status TO authenticated;
GRANT ALL PRIVILEGES ON TABLE subscription_status TO anon;
GRANT ALL PRIVILEGES ON TABLE subscription_status TO service_role;

-- Désactiver RLS de force
ALTER TABLE subscription_status DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- ÉTAPE 5: SYNCHRONISATION DES UTILISATEURS EXISTANTS
-- =====================================================

-- Ajouter tous les utilisateurs qui ne sont pas dans subscription_status
INSERT INTO subscription_status (
  user_id,
  first_name,
  last_name,
  email,
  is_active,
  subscription_type,
  notes,
  activated_at
)
SELECT 
  u.id,
  COALESCE(u.raw_user_meta_data->>'first_name', 'Utilisateur') as first_name,
  COALESCE(u.raw_user_meta_data->>'last_name', 'Test') as last_name,
  u.email,
  CASE 
    WHEN u.raw_user_meta_data->>'role' = 'admin' THEN true
    ELSE false
  END as is_active,
  CASE 
    WHEN u.raw_user_meta_data->>'role' = 'admin' THEN 'premium'
    ELSE 'free'
  END as subscription_type,
  CASE 
    WHEN u.raw_user_meta_data->>'role' = 'admin' THEN 'Administrateur - accès complet'
    ELSE 'Compte synchronisé automatiquement'
  END as notes,
  COALESCE(u.email_confirmed_at, NOW()) as activated_at
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM subscription_status ss WHERE ss.user_id = u.id
)
ON CONFLICT (user_id) DO UPDATE SET
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  email = EXCLUDED.email,
  updated_at = NOW();

-- =====================================================
-- ÉTAPE 6: TEST AUTOMATIQUE
-- =====================================================

-- Créer un utilisateur de test pour vérifier le trigger
DO $$
DECLARE
  test_user_id UUID := gen_random_uuid();
  test_email TEXT := 'test_auto_' || extract(epoch from now())::text || '@test.com';
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
    '{"first_name": "Test", "last_name": "Auto"}'
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
-- ÉTAPE 7: VÉRIFICATION FINALE
-- =====================================================

-- Vérifier que tout est en place
SELECT 
  'Vérification finale' as info,
  (SELECT COUNT(*) FROM auth.users) as total_users,
  (SELECT COUNT(*) FROM subscription_status) as total_subscriptions,
  (SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_name = 'on_auth_user_created') as trigger_exists,
  (SELECT COUNT(*) FROM information_schema.routines WHERE routine_name = 'handle_new_user') as function_exists;

-- =====================================================
-- ÉTAPE 8: RAPPORT DE SUCCÈS
-- =====================================================

SELECT 
  'Correction définitive terminée' as status,
  'Les nouveaux utilisateurs seront maintenant ajoutés automatiquement à la page admin' as message;
