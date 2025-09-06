-- =====================================================
-- CORRECTION DES PERMISSIONS SUBSCRIPTION_STATUS
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T14:00:00.000Z

-- Ce script corrige les permissions sur la table subscription_status
-- pour résoudre les erreurs 406 (Not Acceptable)

-- =====================================================
-- ÉTAPE 1: VÉRIFICATION DE LA TABLE
-- =====================================================

-- Vérifier que la table existe
SELECT 
  'Vérification de la table subscription_status' as info,
  EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'subscription_status' 
    AND table_schema = 'public'
  ) as table_exists;

-- =====================================================
-- ÉTAPE 2: DÉSACTIVATION DE RLS
-- =====================================================

-- Désactiver Row Level Security sur subscription_status
ALTER TABLE subscription_status DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- ÉTAPE 3: PERMISSIONS POUR AUTHENTICATED
-- =====================================================

-- Donner tous les privilèges aux utilisateurs authentifiés
GRANT ALL PRIVILEGES ON TABLE subscription_status TO authenticated;

-- Donner les privilèges sur la séquence si elle existe
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO authenticated;

-- =====================================================
-- ÉTAPE 4: PERMISSIONS POUR ANONYMOUS (si nécessaire)
-- =====================================================

-- Donner les privilèges de lecture aux utilisateurs anonymes
GRANT SELECT ON TABLE subscription_status TO anon;

-- =====================================================
-- ÉTAPE 5: VÉRIFICATION DES PERMISSIONS
-- =====================================================

-- Vérifier les permissions actuelles
SELECT 
  'Permissions sur subscription_status' as info,
  grantee,
  privilege_type,
  is_grantable
FROM information_schema.role_table_grants 
WHERE table_name = 'subscription_status'
ORDER BY grantee, privilege_type;

-- =====================================================
-- ÉTAPE 6: SYNCHRONISATION DES UTILISATEURS
-- =====================================================

-- S'assurer que tous les utilisateurs ont un statut d'abonnement
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
    ELSE 'Compte créé automatiquement'
  END as notes,
  COALESCE(u.email_confirmed_at, NOW()) as activated_at
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM subscription_status ss WHERE ss.user_id = u.id
);

-- =====================================================
-- ÉTAPE 7: RAPPORT FINAL
-- =====================================================

-- Afficher le rapport final
SELECT 
  'Correction terminée' as status,
  'Permissions corrigées et utilisateurs synchronisés' as message;

-- Compter les utilisateurs dans subscription_status
SELECT 
  'Utilisateurs dans subscription_status' as info,
  COUNT(*) as total_users,
  COUNT(CASE WHEN is_active THEN 1 END) as active_users,
  COUNT(CASE WHEN NOT is_active THEN 1 END) as inactive_users
FROM subscription_status;
