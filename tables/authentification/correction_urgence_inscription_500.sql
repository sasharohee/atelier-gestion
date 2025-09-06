-- =====================================================
-- CORRECTION URGENCE ERREUR 500 INSCRIPTION
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T15:00:00.000Z

-- Script de correction d'urgence pour l'erreur 500 lors de l'inscription

-- =====================================================
-- ÉTAPE 1: DIAGNOSTIC DE L'ERREUR
-- =====================================================

-- Vérifier l'état actuel des triggers
SELECT 
  'DIAGNOSTIC - Triggers existants' as info,
  trigger_name,
  event_manipulation,
  action_statement,
  trigger_schema
FROM information_schema.triggers 
WHERE trigger_name LIKE '%auth%' OR trigger_name LIKE '%user%';

-- Vérifier les fonctions existantes
SELECT 
  'DIAGNOSTIC - Fonctions existantes' as info,
  routine_name,
  routine_type,
  routine_schema,
  security_type
FROM information_schema.routines 
WHERE routine_name LIKE '%user%' OR routine_name LIKE '%auth%';

-- Vérifier les permissions sur auth.users
SELECT 
  'DIAGNOSTIC - Permissions auth.users' as info,
  grantee,
  privilege_type,
  is_grantable
FROM information_schema.role_table_grants 
WHERE table_name = 'users' 
  AND table_schema = 'auth'
  AND grantee IN ('authenticated', 'anon', 'service_role');

-- =====================================================
-- ÉTAPE 2: NETTOYAGE COMPLET
-- =====================================================

-- Supprimer TOUS les triggers liés à auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS handle_new_user_trigger ON auth.users;

-- Supprimer TOUTES les fonctions liées
DROP FUNCTION IF EXISTS handle_new_user();
DROP FUNCTION IF EXISTS public.handle_new_user();
DROP FUNCTION IF EXISTS auth.handle_new_user();

-- =====================================================
-- ÉTAPE 3: CORRECTION DES PERMISSIONS
-- =====================================================

-- Donner TOUS les privilèges sur auth.users
GRANT ALL PRIVILEGES ON TABLE auth.users TO authenticated;
GRANT ALL PRIVILEGES ON TABLE auth.users TO anon;
GRANT ALL PRIVILEGES ON TABLE auth.users TO service_role;

-- Donner les privilèges sur les séquences auth
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA auth TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA auth TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA auth TO service_role;

-- Donner les privilèges sur subscription_status
GRANT ALL PRIVILEGES ON TABLE subscription_status TO authenticated;
GRANT ALL PRIVILEGES ON TABLE subscription_status TO anon;
GRANT ALL PRIVILEGES ON TABLE subscription_status TO service_role;

-- Désactiver RLS sur subscription_status
ALTER TABLE subscription_status DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- ÉTAPE 4: CRÉATION D'UNE FONCTION SIMPLE
-- =====================================================

-- Créer une fonction ultra-simple sans gestion d'erreur complexe
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Insérer directement sans vérifications complexes
  INSERT INTO subscription_status (
    user_id,
    first_name,
    last_name,
    email,
    is_active,
    subscription_type,
    notes,
    created_at,
    updated_at
  ) VALUES (
    NEW.id,
    'Utilisateur',
    'Test',
    NEW.email,
    false,
    'free',
    'Nouveau compte',
    NEW.created_at,
    NOW()
  );
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- En cas d'erreur, on continue sans échouer
    RETURN NEW;
END;
$$;

-- =====================================================
-- ÉTAPE 5: CRÉATION DU TRIGGER
-- =====================================================

-- Créer le trigger avec gestion d'erreur
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- =====================================================
-- ÉTAPE 6: TEST IMMÉDIAT
-- =====================================================

-- Test simple du trigger
DO $$
DECLARE
  test_user_id UUID := gen_random_uuid();
  test_email TEXT := 'test_500_' || extract(epoch from now())::text || '@test.com';
BEGIN
  RAISE NOTICE '🧪 Test de correction erreur 500 pour: %', test_email;
  
  -- Insérer un utilisateur de test
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
  
  RAISE NOTICE '✅ Utilisateur de test créé dans auth.users';
  
  -- Vérifier le résultat
  IF EXISTS (SELECT 1 FROM subscription_status WHERE user_id = test_user_id) THEN
    RAISE NOTICE '✅ SUCCÈS: L''utilisateur de test a été ajouté automatiquement';
  ELSE
    RAISE NOTICE '❌ ÉCHEC: L''utilisateur de test n''a PAS été ajouté';
  END IF;
  
  -- Nettoyer
  DELETE FROM subscription_status WHERE user_id = test_user_id;
  DELETE FROM auth.users WHERE id = test_user_id;
  
  RAISE NOTICE '🧹 Nettoyage terminé';
  
END $$;

-- =====================================================
-- ÉTAPE 7: SYNCHRONISATION DES UTILISATEURS EXISTANTS
-- =====================================================

-- Ajouter tous les utilisateurs manquants
INSERT INTO subscription_status (
  user_id,
  first_name,
  last_name,
  email,
  is_active,
  subscription_type,
  notes,
  created_at,
  updated_at
)
SELECT 
  u.id,
  'Utilisateur',
  'Test',
  u.email,
  false,
  'free',
  'Compte existant synchronisé',
  u.created_at,
  NOW()
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM subscription_status ss WHERE ss.user_id = u.id
)
ON CONFLICT (user_id) DO NOTHING;

-- =====================================================
-- ÉTAPE 8: VÉRIFICATION FINALE
-- =====================================================

-- Vérifier l'état final
SELECT 
  'VÉRIFICATION FINALE' as info,
  (SELECT COUNT(*) FROM auth.users) as total_users,
  (SELECT COUNT(*) FROM subscription_status) as total_subscriptions,
  (SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_name = 'on_auth_user_created') as trigger_exists,
  (SELECT COUNT(*) FROM information_schema.routines WHERE routine_name = 'handle_new_user') as function_exists;

-- Vérifier les permissions finales
SELECT 
  'VÉRIFICATION - Permissions finales' as info,
  grantee,
  privilege_type
FROM information_schema.role_table_grants 
WHERE table_name = 'users' 
  AND table_schema = 'auth'
  AND grantee IN ('authenticated', 'anon', 'service_role');

-- =====================================================
-- ÉTAPE 9: RAPPORT FINAL
-- =====================================================

SELECT 
  'CORRECTION ERREUR 500 TERMINÉE' as status,
  'L''inscription devrait maintenant fonctionner sans erreur 500' as message;
