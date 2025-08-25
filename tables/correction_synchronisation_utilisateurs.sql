-- =====================================================
-- CORRECTION SYNCHRONISATION UTILISATEURS
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T18:15:00.000Z

-- Script pour synchroniser automatiquement les utilisateurs avec subscription_status

-- =====================================================
-- ÉTAPE 1: DIAGNOSTIC DES UTILISATEURS MANQUANTS
-- =====================================================

-- Vérifier les utilisateurs dans auth.users qui ne sont pas dans subscription_status
SELECT 
  'DIAGNOSTIC UTILISATEURS MANQUANTS' as info,
  (SELECT COUNT(*) FROM auth.users) as total_auth_users,
  (SELECT COUNT(*) FROM subscription_status) as total_subscription_users,
  (SELECT COUNT(*) FROM auth.users u 
   WHERE NOT EXISTS (SELECT 1 FROM subscription_status ss WHERE ss.user_id = u.id)) as users_manquants;

-- Afficher les utilisateurs manquants
SELECT 
  'UTILISATEURS MANQUANTS' as info,
  u.id as user_id,
  u.email,
  u.raw_user_meta_data->>'first_name' as first_name,
  u.raw_user_meta_data->>'last_name' as last_name,
  u.raw_user_meta_data->>'role' as role,
  u.created_at
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM subscription_status ss WHERE ss.user_id = u.id
)
ORDER BY u.created_at DESC;

-- =====================================================
-- ÉTAPE 2: CRÉATION DE LA FONCTION DE SYNCHRONISATION
-- =====================================================

-- Créer une fonction pour synchroniser automatiquement les utilisateurs
CREATE OR REPLACE FUNCTION sync_user_to_subscription_status()
RETURNS TRIGGER AS $$
BEGIN
  -- Insérer l'utilisateur dans subscription_status s'il n'existe pas déjà
  INSERT INTO subscription_status (
    user_id,
    first_name,
    last_name,
    email,
    is_active,
    subscription_type,
    notes,
    created_at,
    updated_at,
    status
  )
  SELECT 
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'first_name', 'Utilisateur') as first_name,
    COALESCE(NEW.raw_user_meta_data->>'last_name', 'Test') as last_name,
    NEW.email,
    CASE 
      WHEN NEW.raw_user_meta_data->>'role' = 'admin' THEN true
      WHEN NEW.email = 'srohee32@gmail.com' THEN true
      WHEN NEW.email = 'repphonereparation@gmail.com' THEN true
      ELSE false
    END as is_active,
    CASE 
      WHEN NEW.raw_user_meta_data->>'role' = 'admin' THEN 'premium'
      WHEN NEW.email = 'srohee32@gmail.com' THEN 'premium'
      WHEN NEW.email = 'repphonereparation@gmail.com' THEN 'premium'
      ELSE 'free'
    END as subscription_type,
    'Compte créé automatiquement',
    NEW.created_at,
    NOW() as updated_at,
    CASE 
      WHEN NEW.raw_user_meta_data->>'role' = 'admin' THEN 'ACTIF'
      WHEN NEW.email = 'srohee32@gmail.com' THEN 'ACTIF'
      WHEN NEW.email = 'repphonereparation@gmail.com' THEN 'ACTIF'
      ELSE 'INACTIF'
    END as status
  WHERE NOT EXISTS (
    SELECT 1 FROM subscription_status ss WHERE ss.user_id = NEW.id
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- ÉTAPE 3: CRÉATION DU TRIGGER
-- =====================================================

-- Supprimer le trigger s'il existe déjà
DROP TRIGGER IF EXISTS trigger_sync_user_to_subscription_status ON auth.users;

-- Créer le trigger pour synchroniser automatiquement
CREATE TRIGGER trigger_sync_user_to_subscription_status
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION sync_user_to_subscription_status();

-- =====================================================
-- ÉTAPE 4: SYNCHRONISATION MANUELLE DES UTILISATEURS EXISTANTS
-- =====================================================

-- Synchroniser tous les utilisateurs existants qui ne sont pas dans subscription_status
INSERT INTO subscription_status (
  user_id,
  first_name,
  last_name,
  email,
  is_active,
  subscription_type,
  notes,
  created_at,
  updated_at,
  status
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
  'Compte synchronisé automatiquement',
  u.created_at,
  NOW() as updated_at,
  CASE 
    WHEN u.raw_user_meta_data->>'role' = 'admin' THEN 'ACTIF'
    WHEN u.email = 'srohee32@gmail.com' THEN 'ACTIF'
    WHEN u.email = 'repphonereparation@gmail.com' THEN 'ACTIF'
    ELSE 'INACTIF'
  END as status
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM subscription_status ss WHERE ss.user_id = u.id
);

-- =====================================================
-- ÉTAPE 5: CORRECTION DES POLITIQUES RLS
-- =====================================================

-- Supprimer les politiques RLS existantes sur subscription_status
DROP POLICY IF EXISTS "Users can view their own subscription status" ON subscription_status;
DROP POLICY IF EXISTS "Admins can view all subscription statuses" ON subscription_status;
DROP POLICY IF EXISTS "Users can update their own subscription status" ON subscription_status;
DROP POLICY IF EXISTS "Admins can update all subscription statuses" ON subscription_status;

-- Activer RLS sur subscription_status
ALTER TABLE subscription_status ENABLE ROW LEVEL SECURITY;

-- Créer une politique pour permettre à tous les utilisateurs authentifiés de voir leur propre statut
CREATE POLICY "Users can view their own subscription status" ON subscription_status
  FOR SELECT USING (auth.uid() = user_id);

-- Créer une politique pour permettre aux admins de voir tous les statuts
CREATE POLICY "Admins can view all subscription statuses" ON subscription_status
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = auth.uid() 
        AND (raw_user_meta_data->>'role' = 'admin' 
             OR email = 'srohee32@gmail.com' 
             OR email = 'repphonereparation@gmail.com')
    )
  );

-- Créer une politique pour permettre aux admins de modifier tous les statuts
CREATE POLICY "Admins can update all subscription statuses" ON subscription_status
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = auth.uid() 
        AND (raw_user_meta_data->>'role' = 'admin' 
             OR email = 'srohee32@gmail.com' 
             OR email = 'repphonereparation@gmail.com')
    )
  );

-- Créer une politique pour permettre aux admins d'insérer des statuts
CREATE POLICY "Admins can insert subscription statuses" ON subscription_status
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = auth.uid() 
        AND (raw_user_meta_data->>'role' = 'admin' 
             OR email = 'srohee32@gmail.com' 
             OR email = 'repphonereparation@gmail.com')
    )
  );

-- =====================================================
-- ÉTAPE 6: TEST DE LA SYNCHRONISATION
-- =====================================================

-- Test de la fonction de synchronisation
DO $$
DECLARE
  test_uuid UUID := gen_random_uuid();
  test_result RECORD;
BEGIN
  -- Simuler l'insertion d'un nouvel utilisateur
  INSERT INTO auth.users (
    id,
    email,
    raw_user_meta_data,
    created_at
  ) VALUES (
    test_uuid,
    'test_sync_' || test_uuid || '@example.com',
    '{"first_name": "Test", "last_name": "Sync", "role": "technician"}'::jsonb,
    NOW()
  );
  
  -- Vérifier que l'utilisateur a été synchronisé
  SELECT * INTO test_result FROM subscription_status WHERE user_id = test_uuid;
  
  IF test_result IS NOT NULL THEN
    RAISE NOTICE '✅ Test de synchronisation réussi pour l''utilisateur: %', test_uuid;
    RAISE NOTICE '✅ Données synchronisées: email=%, is_active=%, status=%', 
      test_result.email, test_result.is_active, test_result.status;
  ELSE
    RAISE NOTICE '❌ Test de synchronisation échoué pour l''utilisateur: %', test_uuid;
  END IF;
  
  -- Nettoyer le test
  DELETE FROM subscription_status WHERE user_id = test_uuid;
  DELETE FROM auth.users WHERE id = test_uuid;
  RAISE NOTICE '✅ Test nettoyé';
END $$;

-- =====================================================
-- ÉTAPE 7: VÉRIFICATION FINALE
-- =====================================================

-- Vérifier l'état final
SELECT 
  'VÉRIFICATION FINALE' as info,
  (SELECT COUNT(*) FROM auth.users) as total_auth_users,
  (SELECT COUNT(*) FROM subscription_status) as total_subscription_users,
  (SELECT COUNT(*) FROM auth.users u 
   WHERE NOT EXISTS (SELECT 1 FROM subscription_status ss WHERE ss.user_id = u.id)) as users_manquants;

-- Afficher un exemple d'utilisateur synchronisé
SELECT 
  'EXEMPLE UTILISATEUR SYNCHRONISÉ' as info,
  ss.user_id,
  ss.email,
  ss.first_name,
  ss.last_name,
  ss.is_active,
  ss.status,
  ss.subscription_type,
  ss.created_at
FROM subscription_status ss
JOIN auth.users u ON ss.user_id = u.id
ORDER BY ss.created_at DESC
LIMIT 1;

-- Vérifier les politiques RLS
SELECT 
  'VÉRIFICATION POLITIQUES RLS' as info,
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'subscription_status';

-- =====================================================
-- ÉTAPE 8: RAPPORT FINAL
-- =====================================================

SELECT 
  'CORRECTION SYNCHRONISATION UTILISATEURS TERMINÉE' as status,
  'Les utilisateurs sont maintenant automatiquement synchronisés avec subscription_status' as message;
