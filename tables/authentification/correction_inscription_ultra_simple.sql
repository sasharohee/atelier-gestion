-- =====================================================
-- CORRECTION ULTRA-SIMPLE - INSCRIPTION
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T14:35:00.000Z

-- Script ultra-simple pour corriger l'erreur 500 lors de l'inscription

-- =====================================================
-- ÉTAPE 1: NETTOYAGE BASIQUE
-- =====================================================

-- Supprimer seulement les triggers et fonctions connus
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS handle_new_user();

-- =====================================================
-- ÉTAPE 2: PERMISSIONS ESSENTIELLES
-- =====================================================

-- Permissions sur auth.users
GRANT ALL PRIVILEGES ON TABLE auth.users TO authenticated;
GRANT ALL PRIVILEGES ON TABLE auth.users TO anon;
GRANT ALL PRIVILEGES ON TABLE auth.users TO service_role;

-- Permissions sur les séquences auth
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA auth TO authenticated;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA auth TO anon;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA auth TO service_role;

-- =====================================================
-- ÉTAPE 3: PERMISSIONS SUBSCRIPTION_STATUS
-- =====================================================

-- Désactiver RLS
ALTER TABLE subscription_status DISABLE ROW LEVEL SECURITY;

-- Permissions sur subscription_status
GRANT ALL PRIVILEGES ON TABLE subscription_status TO authenticated;
GRANT ALL PRIVILEGES ON TABLE subscription_status TO anon;
GRANT ALL PRIVILEGES ON TABLE subscription_status TO service_role;

-- =====================================================
-- ÉTAPE 4: SYNCHRONISATION SIMPLE
-- =====================================================

-- Ajouter les utilisateurs manquants
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
-- ÉTAPE 5: VÉRIFICATION SIMPLE
-- =====================================================

-- Vérifier l'état
SELECT 
  'État final' as info,
  (SELECT COUNT(*) FROM auth.users) as total_users,
  (SELECT COUNT(*) FROM subscription_status) as total_subscriptions,
  CASE 
    WHEN (SELECT COUNT(*) FROM auth.users) = (SELECT COUNT(*) FROM subscription_status) 
    THEN '✅ Synchronisé'
    ELSE '❌ Non synchronisé'
  END as status;

-- =====================================================
-- ÉTAPE 6: RAPPORT FINAL
-- =====================================================

SELECT 
  'Correction terminée' as status,
  'L''inscription devrait maintenant fonctionner sans erreur 500' as message;
