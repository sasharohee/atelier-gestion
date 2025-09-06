-- =====================================================
-- CORRECTION SIMPLE DE L'INSCRIPTION
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T14:00:00.000Z

-- Script simple pour corriger l'erreur 500 lors de l'inscription

-- =====================================================
-- ÉTAPE 1: CORRECTION DES PERMISSIONS
-- =====================================================

-- Donner tous les privilèges à authenticated sur auth.users
GRANT ALL PRIVILEGES ON TABLE auth.users TO authenticated;

-- Donner les privilèges sur les séquences
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA auth TO authenticated;

-- =====================================================
-- ÉTAPE 2: CORRECTION DES PERMISSIONS SUBSCRIPTION_STATUS
-- =====================================================

-- Désactiver RLS sur subscription_status
ALTER TABLE subscription_status DISABLE ROW LEVEL SECURITY;

-- Donner tous les privilèges sur subscription_status
GRANT ALL PRIVILEGES ON TABLE subscription_status TO authenticated;
GRANT ALL PRIVILEGES ON TABLE subscription_status TO anon;

-- =====================================================
-- ÉTAPE 3: CRÉATION DE LA FONCTION
-- =====================================================

-- Créer ou remplacer la fonction pour gérer les nouveaux utilisateurs
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
-- ÉTAPE 4: CRÉATION DU TRIGGER
-- =====================================================

-- Supprimer le trigger s'il existe déjà
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Créer le trigger sur la table auth.users
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION handle_new_user();

-- =====================================================
-- ÉTAPE 5: SYNCHRONISATION DES UTILISATEURS EXISTANTS
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
);

-- =====================================================
-- ÉTAPE 6: RAPPORT FINAL
-- =====================================================

-- Afficher le rapport final
SELECT 
  'Correction terminée' as status,
  'Permissions et trigger corrigés pour l''inscription' as message;

-- Vérifier l'état final
SELECT 
  'État final' as info,
  (SELECT COUNT(*) FROM auth.users) as total_users,
  (SELECT COUNT(*) FROM subscription_status) as total_subscriptions,
  (SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_name = 'on_auth_user_created') as trigger_exists;
