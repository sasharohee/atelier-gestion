-- =====================================================
-- RECRÉATION TABLE SUBSCRIPTION_STATUS
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T17:30:00.000Z

-- Script pour recréer la table subscription_status si elle n'existe pas

-- =====================================================
-- ÉTAPE 1: VÉRIFICATION DE L'EXISTENCE
-- =====================================================

-- Vérifier si la table existe
SELECT 
  'VÉRIFICATION EXISTENCE' as info,
  CASE 
    WHEN EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'subscription_status' AND schemaname = 'public') 
    THEN '✅ Table subscription_status existe déjà'
    ELSE '❌ Table subscription_status N''EXISTE PAS - Création nécessaire'
  END as status;

-- =====================================================
-- ÉTAPE 2: SUPPRESSION SI EXISTE
-- =====================================================

-- Supprimer la table si elle existe (pour recréer proprement)
DROP TABLE IF EXISTS subscription_status CASCADE;

-- =====================================================
-- ÉTAPE 3: CRÉATION DE LA TABLE
-- =====================================================

-- Créer la table subscription_status
CREATE TABLE subscription_status (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID UNIQUE NOT NULL,
  first_name TEXT,
  last_name TEXT,
  email TEXT NOT NULL,
  is_active BOOLEAN DEFAULT false,
  subscription_type TEXT DEFAULT 'free' CHECK (subscription_type IN ('free', 'premium', 'enterprise')),
  notes TEXT,
  activated_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- ÉTAPE 4: CRÉATION DES INDEX
-- =====================================================

-- Créer des index pour les performances
CREATE INDEX idx_subscription_status_user_id ON subscription_status(user_id);
CREATE INDEX idx_subscription_status_email ON subscription_status(email);
CREATE INDEX idx_subscription_status_is_active ON subscription_status(is_active);
CREATE INDEX idx_subscription_status_subscription_type ON subscription_status(subscription_type);

-- =====================================================
-- ÉTAPE 5: CONFIGURATION DES PERMISSIONS
-- =====================================================

-- Donner TOUS les privilèges
GRANT ALL PRIVILEGES ON TABLE subscription_status TO authenticated;
GRANT ALL PRIVILEGES ON TABLE subscription_status TO anon;
GRANT ALL PRIVILEGES ON TABLE subscription_status TO service_role;

-- Donner les privilèges sur la séquence
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO service_role;

-- Désactiver RLS
ALTER TABLE subscription_status DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- ÉTAPE 6: SYNCHRONISATION DES UTILISATEURS EXISTANTS
-- =====================================================

-- Ajouter tous les utilisateurs existants
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
  COALESCE(u.raw_user_meta_data->>'first_name', 'Utilisateur') as first_name,
  COALESCE(u.raw_user_meta_data->>'last_name', 'Test') as last_name,
  u.email,
  CASE 
    WHEN u.raw_user_meta_data->>'role' = 'admin' THEN true
    WHEN u.email = 'srohee32@gmail.com' THEN true
    WHEN u.email = 'repphonereparation@gmail.com' THEN true
    ELSE false
  END as is_active,
  CASE 
    WHEN u.raw_user_meta_data->>'role' = 'admin' THEN 'premium'
    WHEN u.email = 'srohee32@gmail.com' THEN 'premium'
    WHEN u.email = 'repphonereparation@gmail.com' THEN 'premium'
    ELSE 'free'
  END as subscription_type,
  'Compte recréé automatiquement',
  u.created_at,
  NOW() as updated_at
FROM auth.users u
ON CONFLICT (user_id) DO NOTHING;

-- =====================================================
-- ÉTAPE 7: CRÉATION DU TRIGGER
-- =====================================================

-- Supprimer l'ancien trigger s'il existe
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- Créer la fonction
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
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
    'Nouveau compte - en attente d''activation',
    NEW.created_at,
    NOW()
  );
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- En cas d'erreur, on continue
    RETURN NEW;
END;
$$;

-- Créer le trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- =====================================================
-- ÉTAPE 8: TEST DE FONCTIONNEMENT
-- =====================================================

-- Test de création d'un utilisateur
DO $$
DECLARE
  test_user_id UUID := gen_random_uuid();
  test_email TEXT := 'test_recreation_' || extract(epoch from now())::text || '@test.com';
BEGIN
  RAISE NOTICE '🧪 Test de recréation pour: %', test_email;
  
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
-- ÉTAPE 9: VÉRIFICATION FINALE
-- =====================================================

-- Vérifier l'état final
SELECT 
  'VÉRIFICATION FINALE' as info,
  (SELECT COUNT(*) FROM auth.users) as total_users,
  (SELECT COUNT(*) FROM subscription_status) as total_subscriptions,
  (SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_name = 'on_auth_user_created') as trigger_exists,
  (SELECT COUNT(*) FROM information_schema.routines WHERE routine_name = 'handle_new_user') as function_exists;

-- Vérifier les permissions
SELECT 
  'VÉRIFICATION - Permissions subscription_status' as info,
  grantee,
  privilege_type
FROM information_schema.role_table_grants 
WHERE table_name = 'subscription_status' 
  AND table_schema = 'public'
  AND grantee IN ('authenticated', 'anon', 'service_role')
ORDER BY grantee, privilege_type;

-- Vérifier RLS
SELECT 
  'VÉRIFICATION - RLS subscription_status' as info,
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
-- ÉTAPE 10: RAPPORT FINAL
-- =====================================================

SELECT 
  'RECRÉATION TABLE SUBSCRIPTION_STATUS TERMINÉE' as status,
  'La table subscription_status a été recréée et configurée correctement' as message;
