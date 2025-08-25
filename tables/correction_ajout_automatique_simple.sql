-- =====================================================
-- CORRECTION SIMPLE - AJOUT AUTOMATIQUE
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T14:15:00.000Z

-- Script simple pour corriger l'ajout automatique des utilisateurs

-- =====================================================
-- ÉTAPE 1: NETTOYAGE
-- =====================================================

-- Supprimer le trigger et la fonction existants
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- =====================================================
-- ÉTAPE 2: PERMISSIONS
-- =====================================================

-- Désactiver RLS sur subscription_status
ALTER TABLE subscription_status DISABLE ROW LEVEL SECURITY;

-- Donner tous les privilèges sur subscription_status
GRANT ALL PRIVILEGES ON TABLE subscription_status TO authenticated;
GRANT ALL PRIVILEGES ON TABLE subscription_status TO anon;
GRANT ALL PRIVILEGES ON TABLE subscription_status TO service_role;

-- =====================================================
-- ÉTAPE 3: CRÉATION FONCTION SIMPLE
-- =====================================================

-- Créer une fonction simple sans gestion d'erreur complexe
CREATE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
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
    COALESCE(NEW.raw_user_meta_data->>'first_name', 'Utilisateur'),
    COALESCE(NEW.raw_user_meta_data->>'last_name', 'Test'),
    NEW.email,
    false,
    'free',
    'Nouveau compte - en attente d''activation',
    NULL
  );
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- ÉTAPE 4: CRÉATION TRIGGER
-- =====================================================

-- Créer le trigger
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- =====================================================
-- ÉTAPE 5: SYNCHRONISATION
-- =====================================================

-- Ajouter les utilisateurs existants qui ne sont pas dans subscription_status
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
ON CONFLICT (user_id) DO NOTHING;

-- =====================================================
-- ÉTAPE 6: VÉRIFICATION
-- =====================================================

-- Vérifier que tout est en place
SELECT 
  'Vérification' as info,
  (SELECT COUNT(*) FROM auth.users) as total_users,
  (SELECT COUNT(*) FROM subscription_status) as total_subscriptions,
  (SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_name = 'on_auth_user_created') as trigger_exists,
  (SELECT COUNT(*) FROM information_schema.routines WHERE routine_name = 'handle_new_user') as function_exists;

-- =====================================================
-- ÉTAPE 7: RAPPORT
-- =====================================================

SELECT 
  'Correction terminée' as status,
  'Les nouveaux utilisateurs seront ajoutés automatiquement' as message;
