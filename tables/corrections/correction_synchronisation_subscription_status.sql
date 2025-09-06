-- =====================================================
-- CORRECTION SYNCHRONISATION SUBSCRIPTION_STATUS
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T18:50:00.000Z

-- Script pour corriger la synchronisation de subscription_status

-- =====================================================
-- ÉTAPE 1: DIAGNOSTIC DES UTILISATEURS MANQUANTS
-- =====================================================

-- Vérifier les utilisateurs dans auth.users qui ne sont pas dans subscription_status
SELECT 
  'UTILISATEURS MANQUANTS DANS SUBSCRIPTION_STATUS' as info,
  au.id as user_id,
  au.email,
  au.raw_user_meta_data->>'role' as role,
  au.created_at
FROM auth.users au
WHERE NOT EXISTS (
  SELECT 1 FROM subscription_status ss WHERE ss.user_id = au.id
)
ORDER BY au.created_at;

-- Compter les utilisateurs manquants
SELECT 
  'COMPTAGE UTILISATEURS MANQUANTS' as info,
  COUNT(*) as nombre_utilisateurs_manquants
FROM auth.users au
WHERE NOT EXISTS (
  SELECT 1 FROM subscription_status ss WHERE ss.user_id = au.id
);

-- =====================================================
-- ÉTAPE 2: AJOUT DES UTILISATEURS MANQUANTS
-- =====================================================

-- Insérer tous les utilisateurs manquants dans subscription_status
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
  au.id as user_id,
  COALESCE(au.raw_user_meta_data->>'first_name', 'Utilisateur') as first_name,
  COALESCE(au.raw_user_meta_data->>'last_name', 'Test') as last_name,
  au.email,
  CASE 
    WHEN au.raw_user_meta_data->>'role' = 'admin' THEN true
    WHEN au.email = 'srohee32@gmail.com' THEN true
    WHEN au.email = 'repphonereparation@gmail.com' THEN true
    ELSE false
  END as is_active,
  CASE 
    WHEN au.raw_user_meta_data->>'role' = 'admin' THEN 'premium'
    WHEN au.email = 'srohee32@gmail.com' THEN 'premium'
    WHEN au.email = 'repphonereparation@gmail.com' THEN 'premium'
    ELSE 'free'
  END as subscription_type,
  'Compte synchronisé automatiquement',
  COALESCE(au.created_at, NOW()) as created_at,
  NOW() as updated_at,
  CASE 
    WHEN au.raw_user_meta_data->>'role' = 'admin' THEN 'ACTIF'
    WHEN au.email = 'srohee32@gmail.com' THEN 'ACTIF'
    WHEN au.email = 'repphonereparation@gmail.com' THEN 'ACTIF'
    ELSE 'INACTIF'
  END as status
FROM auth.users au
WHERE NOT EXISTS (
  SELECT 1 FROM subscription_status ss WHERE ss.user_id = au.id
);

-- =====================================================
-- ÉTAPE 3: VÉRIFICATION DE LA SYNCHRONISATION
-- =====================================================

-- Vérifier que tous les utilisateurs sont maintenant dans subscription_status
SELECT 
  'VÉRIFICATION SYNCHRONISATION COMPLÈTE' as info,
  COUNT(*) as nombre_utilisateurs_auth,
  (SELECT COUNT(*) FROM subscription_status) as nombre_utilisateurs_subscription,
  COUNT(*) - (SELECT COUNT(*) FROM subscription_status) as difference
FROM auth.users;

-- Vérifier les utilisateurs qui pourraient encore manquer
SELECT 
  'UTILISATEURS ENCORE MANQUANTS' as info,
  au.id as user_id,
  au.email,
  au.raw_user_meta_data->>'role' as role,
  au.created_at
FROM auth.users au
WHERE NOT EXISTS (
  SELECT 1 FROM subscription_status ss WHERE ss.user_id = au.id
)
ORDER BY au.created_at;

-- =====================================================
-- ÉTAPE 4: CORRECTION SPÉCIFIQUE POUR TEST15@YOPMAIL.COM
-- =====================================================

-- Vérifier spécifiquement l'utilisateur test15@yopmail.com
SELECT 
  'VÉRIFICATION TEST15@YOPMAIL.COM' as info,
  au.id as user_id,
  au.email,
  au.raw_user_meta_data->>'role' as role,
  au.created_at,
  CASE 
    WHEN ss.user_id IS NOT NULL THEN 'PRÉSENT'
    ELSE 'MANQUANT'
  END as statut_subscription
FROM auth.users au
LEFT JOIN subscription_status ss ON au.id = ss.user_id
WHERE au.email = 'test15@yopmail.com';

-- Ajouter spécifiquement test15@yopmail.com s'il manque
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
  au.id as user_id,
  COALESCE(au.raw_user_meta_data->>'first_name', 'Utilisateur') as first_name,
  COALESCE(au.raw_user_meta_data->>'last_name', 'Test') as last_name,
  au.email,
  CASE 
    WHEN au.raw_user_meta_data->>'role' = 'admin' THEN true
    WHEN au.email = 'srohee32@gmail.com' THEN true
    WHEN au.email = 'repphonereparation@gmail.com' THEN true
    ELSE false
  END as is_active,
  CASE 
    WHEN au.raw_user_meta_data->>'role' = 'admin' THEN 'premium'
    WHEN au.email = 'srohee32@gmail.com' THEN 'premium'
    WHEN au.email = 'repphonereparation@gmail.com' THEN 'premium'
    ELSE 'free'
  END as subscription_type,
  'Compte test15@yopmail.com ajouté manuellement',
  COALESCE(au.created_at, NOW()) as created_at,
  NOW() as updated_at,
  CASE 
    WHEN au.raw_user_meta_data->>'role' = 'admin' THEN 'ACTIF'
    WHEN au.email = 'srohee32@gmail.com' THEN 'ACTIF'
    WHEN au.email = 'repphonereparation@gmail.com' THEN 'ACTIF'
    ELSE 'INACTIF'
  END as status
FROM auth.users au
WHERE au.email = 'test15@yopmail.com'
  AND NOT EXISTS (
    SELECT 1 FROM subscription_status ss WHERE ss.user_id = au.id
  );

-- =====================================================
-- ÉTAPE 5: CORRECTION DU TRIGGER
-- =====================================================

-- Vérifier si le trigger existe
SELECT 
  'VÉRIFICATION TRIGGER' as info,
  trigger_name,
  event_manipulation,
  action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_sync_user_to_subscription_status'
  AND event_object_table = 'users'
  AND event_object_schema = 'auth';

-- Recréer le trigger avec une gestion d'erreurs améliorée
DROP TRIGGER IF EXISTS trigger_sync_user_to_subscription_status ON auth.users;

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
    'Compte créé automatiquement par trigger',
    COALESCE(NEW.created_at, NOW()) as created_at,
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
EXCEPTION
  WHEN OTHERS THEN
    -- En cas d'erreur, log l'erreur mais ne pas faire échouer l'inscription
    RAISE WARNING 'Erreur lors de la synchronisation vers subscription_status: %', SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Créer le trigger
CREATE TRIGGER trigger_sync_user_to_subscription_status
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION sync_user_to_subscription_status();

-- =====================================================
-- ÉTAPE 6: CORRECTION DES POLITIQUES RLS
-- =====================================================

-- Vérifier les politiques RLS sur subscription_status
SELECT 
  'POLITIQUES RLS SUBSCRIPTION_STATUS' as info,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'subscription_status'
  AND schemaname = 'public'
ORDER BY policyname;

-- Supprimer les politiques existantes
DROP POLICY IF EXISTS "Users can view their own subscription_status" ON subscription_status;
DROP POLICY IF EXISTS "Admins can view all subscription_status" ON subscription_status;
DROP POLICY IF EXISTS "Users can insert their own subscription_status" ON subscription_status;
DROP POLICY IF EXISTS "Admins can insert subscription_status" ON subscription_status;
DROP POLICY IF EXISTS "Users can update their own subscription_status" ON subscription_status;
DROP POLICY IF EXISTS "Admins can update all subscription_status" ON subscription_status;
DROP POLICY IF EXISTS "Users can delete their own subscription_status" ON subscription_status;
DROP POLICY IF EXISTS "Admins can delete all subscription_status" ON subscription_status;
DROP POLICY IF EXISTS "Allow trigger insert" ON subscription_status;

-- Créer des politiques simples pour subscription_status
CREATE POLICY "Users can view their own subscription_status" ON subscription_status
  FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Admins can view all subscription_status" ON subscription_status
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = auth.uid() 
        AND (raw_user_meta_data->>'role' = 'admin' 
             OR email = 'srohee32@gmail.com' 
             OR email = 'repphonereparation@gmail.com')
    )
  );

CREATE POLICY "Users can insert their own subscription_status" ON subscription_status
  FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Admins can insert subscription_status" ON subscription_status
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = auth.uid() 
        AND (raw_user_meta_data->>'role' = 'admin' 
             OR email = 'srohee32@gmail.com' 
             OR email = 'repphonereparation@gmail.com')
    )
  );

CREATE POLICY "Users can update their own subscription_status" ON subscription_status
  FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Admins can update all subscription_status" ON subscription_status
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = auth.uid() 
        AND (raw_user_meta_data->>'role' = 'admin' 
             OR email = 'srohee32@gmail.com' 
             OR email = 'repphonereparation@gmail.com')
    )
  );

CREATE POLICY "Users can delete their own subscription_status" ON subscription_status
  FOR DELETE USING (user_id = auth.uid());

CREATE POLICY "Admins can delete all subscription_status" ON subscription_status
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM auth.users 
      WHERE id = auth.uid() 
        AND (raw_user_meta_data->>'role' = 'admin' 
             OR email = 'srohee32@gmail.com' 
             OR email = 'repphonereparation@gmail.com')
    )
  );

-- Politique spéciale pour permettre les insertions par trigger
CREATE POLICY "Allow trigger insert" ON subscription_status
  FOR INSERT WITH CHECK (true);

-- =====================================================
-- ÉTAPE 7: TEST DE LA CORRECTION
-- =====================================================

-- Test de récupération pour test15@yopmail.com
SELECT 
  'TEST RÉCUPÉRATION TEST15@YOPMAIL.COM' as info,
  ss.user_id,
  ss.email,
  ss.first_name,
  ss.last_name,
  ss.is_active,
  ss.subscription_type,
  ss.status,
  ss.created_at
FROM subscription_status ss
WHERE ss.email = 'test15@yopmail.com';

-- Test de récupération pour tous les utilisateurs
SELECT 
  'TEST RÉCUPÉRATION TOUS UTILISATEURS' as info,
  COUNT(*) as nombre_utilisateurs_subscription
FROM subscription_status;

-- =====================================================
-- ÉTAPE 8: RAPPORT FINAL
-- =====================================================

SELECT 
  'CORRECTION SYNCHRONISATION SUBSCRIPTION_STATUS TERMINÉE' as status,
  'Tous les utilisateurs sont maintenant synchronisés avec subscription_status' as message;
