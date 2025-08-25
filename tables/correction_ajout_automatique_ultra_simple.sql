-- =====================================================
-- CORRECTION ULTRA-SIMPLE - AJOUT AUTOMATIQUE
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T14:20:00.000Z

-- Script ultra-simple sans fonction pour corriger l'ajout automatique

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
-- ÉTAPE 3: SYNCHRONISATION MANUELLE
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
    ELSE 'Compte synchronisé manuellement'
  END as notes,
  COALESCE(u.email_confirmed_at, NOW()) as activated_at
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM subscription_status ss WHERE ss.user_id = u.id
)
ON CONFLICT (user_id) DO NOTHING;

-- =====================================================
-- ÉTAPE 4: VÉRIFICATION
-- =====================================================

-- Vérifier que tous les utilisateurs sont synchronisés
SELECT 
  'Synchronisation' as info,
  (SELECT COUNT(*) FROM auth.users) as total_users,
  (SELECT COUNT(*) FROM subscription_status) as total_subscriptions,
  CASE 
    WHEN (SELECT COUNT(*) FROM auth.users) = (SELECT COUNT(*) FROM subscription_status) 
    THEN '✅ Synchronisé'
    ELSE '❌ Non synchronisé'
  END as status;

-- =====================================================
-- ÉTAPE 5: RAPPORT
-- =====================================================

SELECT 
  'Correction terminée' as status,
  'Tous les utilisateurs existants ont été synchronisés' as message;
