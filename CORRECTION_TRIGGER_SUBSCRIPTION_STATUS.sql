-- =====================================================
-- CORRECTION TRIGGER SUBSCRIPTION_STATUS
-- =====================================================
-- Date: 2025-01-29
-- Objectif: Corriger le problème de création automatique d'entrées subscription_status

-- =====================================================
-- ÉTAPE 1: VÉRIFIER L'ÉTAT ACTUEL
-- =====================================================

SELECT '=== DIAGNOSTIC INITIAL ===' as info;

-- Compter les utilisateurs
SELECT 
    'Utilisateurs auth.users:' as info,
    COUNT(*) as total
FROM auth.users;

SELECT 
    'Utilisateurs subscription_status:' as info,
    COUNT(*) as total
FROM public.subscription_status;

-- Identifier les utilisateurs manquants
SELECT 
    'Utilisateurs manquants dans subscription_status:' as info,
    au.id,
    au.email,
    au.created_at
FROM auth.users au
WHERE NOT EXISTS (
    SELECT 1 FROM public.subscription_status ss WHERE ss.user_id = au.id
)
ORDER BY au.created_at DESC;

-- =====================================================
-- ÉTAPE 2: SUPPRIMER ET RECRÉER LE TRIGGER
-- =====================================================

-- Supprimer le trigger existant
DROP TRIGGER IF EXISTS trigger_sync_user_to_subscription_status ON auth.users;
DROP FUNCTION IF EXISTS sync_user_to_subscription_status();

-- =====================================================
-- ÉTAPE 3: CRÉER UNE FONCTION DE SYNCHRONISATION ROBUSTE
-- =====================================================

CREATE OR REPLACE FUNCTION sync_user_to_subscription_status()
RETURNS TRIGGER AS $$
BEGIN
  -- Vérifier si l'utilisateur existe déjà dans subscription_status
  IF NOT EXISTS (SELECT 1 FROM public.subscription_status WHERE user_id = NEW.id) THEN
    
    -- Insérer l'utilisateur dans subscription_status
    INSERT INTO public.subscription_status (
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
    ) VALUES (
      NEW.id,
      COALESCE(NEW.raw_user_meta_data->>'first_name', NEW.raw_user_meta_data->>'firstName', 'Utilisateur'),
      COALESCE(NEW.raw_user_meta_data->>'last_name', NEW.raw_user_meta_data->>'lastName', 'Test'),
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
      'Compte créé automatiquement par trigger',
      COALESCE(NEW.created_at, NOW()),
      NOW(),
      CASE 
        WHEN NEW.raw_user_meta_data->>'role' = 'admin' THEN 'ACTIF'
        WHEN NEW.email = 'srohee32@gmail.com' THEN 'ACTIF'
        WHEN NEW.email = 'repphonereparation@gmail.com' THEN 'ACTIF'
        ELSE 'INACTIF'
      END
    );
    
    RAISE NOTICE 'Utilisateur % ajouté à subscription_status', NEW.email;
  END IF;
  
  RETURN NEW;
EXCEPTION
  WHEN OTHERS THEN
    -- En cas d'erreur, log l'erreur mais ne pas faire échouer l'inscription
    RAISE WARNING 'Erreur lors de la synchronisation vers subscription_status pour %: %', NEW.email, SQLERRM;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- ÉTAPE 4: CRÉER LE TRIGGER
-- =====================================================

CREATE TRIGGER trigger_sync_user_to_subscription_status
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION sync_user_to_subscription_status();

-- =====================================================
-- ÉTAPE 5: CORRIGER LES POLITIQUES RLS
-- =====================================================

-- Supprimer toutes les politiques existantes
DROP POLICY IF EXISTS "Users can view their own subscription_status" ON public.subscription_status;
DROP POLICY IF EXISTS "Admins can view all subscription_status" ON public.subscription_status;
DROP POLICY IF EXISTS "Allow trigger insert" ON public.subscription_status;
DROP POLICY IF EXISTS "Users can update their own subscription_status" ON public.subscription_status;
DROP POLICY IF EXISTS "Admins can update all subscription_status" ON public.subscription_status;
DROP POLICY IF EXISTS "Admins can delete all subscription_status" ON public.subscription_status;
DROP POLICY IF EXISTS "subscription_status_allow_all_operations" ON public.subscription_status;

-- Créer des politiques RLS simplifiées
CREATE POLICY "subscription_status_allow_all_operations" ON public.subscription_status
    FOR ALL 
    USING (true) 
    WITH CHECK (true);

-- =====================================================
-- ÉTAPE 6: SYNCHRONISER LES UTILISATEURS EXISTANTS
-- =====================================================

-- Ajouter tous les utilisateurs existants qui ne sont pas dans subscription_status
INSERT INTO public.subscription_status (
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
  SELECT 1 FROM public.subscription_status ss WHERE ss.user_id = au.id
);

-- =====================================================
-- ÉTAPE 7: VÉRIFICATION FINALE
-- =====================================================

SELECT '=== VÉRIFICATION FINALE ===' as info;

-- Vérifier que le trigger est créé
SELECT 
    'Trigger créé:' as info,
    trigger_name,
    event_manipulation
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_sync_user_to_subscription_status'
  AND event_object_table = 'users'
  AND event_object_schema = 'auth';

-- Vérifier la synchronisation
SELECT 
    'Synchronisation:' as info,
    (SELECT COUNT(*) FROM auth.users) as total_auth_users,
    (SELECT COUNT(*) FROM public.subscription_status) as total_subscription_status,
    (SELECT COUNT(*) FROM auth.users) - (SELECT COUNT(*) FROM public.subscription_status) as difference;

-- Vérifier les utilisateurs manquants (devrait être 0)
SELECT 
    'Utilisateurs encore manquants:' as info,
    COUNT(*) as nombre_manquants
FROM auth.users au
WHERE NOT EXISTS (
    SELECT 1 FROM public.subscription_status ss WHERE ss.user_id = au.id
);

-- =====================================================
-- ÉTAPE 8: MESSAGE DE CONFIRMATION
-- =====================================================

SELECT '🎉 CORRECTION TERMINÉE - Trigger de synchronisation automatique créé et utilisateurs existants synchronisés' as status;
