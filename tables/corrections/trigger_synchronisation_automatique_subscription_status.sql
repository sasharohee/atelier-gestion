-- =====================================================
-- TRIGGER SYNCHRONISATION AUTOMATIQUE SUBSCRIPTION_STATUS
-- =====================================================
-- Date: 2025-01-27
-- Objectif: Synchroniser automatiquement les nouveaux utilisateurs vers subscription_status

-- =====================================================
-- ÉTAPE 1: SUPPRESSION DU TRIGGER EXISTANT
-- =====================================================

-- Supprimer le trigger existant s'il existe
DROP TRIGGER IF EXISTS trigger_sync_user_to_subscription_status ON auth.users;
DROP FUNCTION IF EXISTS sync_user_to_subscription_status();

-- =====================================================
-- ÉTAPE 2: CRÉATION DE LA FONCTION DE SYNCHRONISATION
-- =====================================================

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
    COALESCE(NEW.raw_user_meta_data->>'first_name', NEW.raw_user_meta_data->>'firstName', 'Utilisateur') as first_name,
    COALESCE(NEW.raw_user_meta_data->>'last_name', NEW.raw_user_meta_data->>'lastName', 'Test') as last_name,
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
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- ÉTAPE 3: CRÉATION DU TRIGGER
-- =====================================================

CREATE TRIGGER trigger_sync_user_to_subscription_status
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION sync_user_to_subscription_status();

-- =====================================================
-- ÉTAPE 4: CORRECTION DES POLITIQUES RLS
-- =====================================================

-- Supprimer les politiques existantes problématiques
DROP POLICY IF EXISTS "Users can view their own subscription_status" ON subscription_status;
DROP POLICY IF EXISTS "Admins can view all subscription_status" ON subscription_status;
DROP POLICY IF EXISTS "Users can insert their own subscription_status" ON subscription_status;
DROP POLICY IF EXISTS "Admins can insert subscription_status" ON subscription_status;
DROP POLICY IF EXISTS "Users can update their own subscription_status" ON subscription_status;
DROP POLICY IF EXISTS "Admins can update all subscription_status" ON subscription_status;
DROP POLICY IF EXISTS "Users can delete their own subscription_status" ON subscription_status;
DROP POLICY IF EXISTS "Admins can delete all subscription_status" ON subscription_status;
DROP POLICY IF EXISTS "Allow trigger insert" ON subscription_status;

-- Créer des politiques RLS simplifiées et robustes
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

-- Politique pour permettre les insertions par trigger (SECURITY DEFINER)
CREATE POLICY "Allow trigger insert" ON subscription_status
  FOR INSERT WITH CHECK (true);

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

-- =====================================================
-- ÉTAPE 5: SYNCHRONISATION DES UTILISATEURS EXISTANTS
-- =====================================================

-- Ajouter tous les utilisateurs existants qui ne sont pas dans subscription_status
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
  COALESCE(au.raw_user_meta_data->>'first_name', au.raw_user_meta_data->>'firstName', 'Utilisateur') as first_name,
  COALESCE(au.raw_user_meta_data->>'last_name', au.raw_user_meta_data->>'lastName', 'Test') as last_name,
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
-- ÉTAPE 6: VÉRIFICATION
-- =====================================================

-- Vérifier que le trigger est bien créé
SELECT 
  'VÉRIFICATION TRIGGER' as info,
  trigger_name,
  event_manipulation,
  action_statement
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_sync_user_to_subscription_status'
  AND event_object_table = 'users'
  AND event_object_schema = 'auth';

-- Vérifier que tous les utilisateurs sont maintenant dans subscription_status
SELECT 
  'VÉRIFICATION SYNCHRONISATION' as info,
  COUNT(*) as nombre_utilisateurs_auth,
  (SELECT COUNT(*) FROM subscription_status) as nombre_utilisateurs_subscription,
  COUNT(*) - (SELECT COUNT(*) FROM subscription_status) as difference
FROM auth.users;

-- Vérifier les utilisateurs qui pourraient encore manquer
SELECT 
  'UTILISATEURS MANQUANTS' as info,
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
-- ÉTAPE 7: RAPPORT FINAL
-- =====================================================

SELECT 
  'TRIGGER SYNCHRONISATION AUTOMATIQUE CRÉÉ' as status,
  'Les nouveaux utilisateurs seront automatiquement ajoutés à subscription_status' as message;
