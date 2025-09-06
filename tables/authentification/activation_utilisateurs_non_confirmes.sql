-- =====================================================
-- ACTIVATION AUTOMATIQUE DES UTILISATEURS NON CONFIRMÉS
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T14:00:00.000Z

-- Ce script active automatiquement tous les utilisateurs non confirmés
-- pour permettre la connexion immédiate

-- =====================================================
-- ÉTAPE 1: IDENTIFICATION DES UTILISATEURS NON CONFIRMÉS
-- =====================================================

-- Lister les utilisateurs non confirmés
SELECT 
  'Utilisateurs non confirmés' as info,
  COUNT(*) as count
FROM auth.users 
WHERE email_confirmed_at IS NULL;

-- =====================================================
-- ÉTAPE 2: ACTIVATION DES UTILISATEURS
-- =====================================================

-- Activer tous les utilisateurs non confirmés
UPDATE auth.users 
SET 
  email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
  updated_at = NOW()
WHERE email_confirmed_at IS NULL;

-- =====================================================
-- ÉTAPE 3: VÉRIFICATION DES RÉSULTATS
-- =====================================================

-- Vérifier que tous les utilisateurs sont maintenant confirmés
SELECT 
  'Vérification post-activation' as info,
  COUNT(*) as total_users,
  COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END) as confirmed_users,
  COUNT(CASE WHEN email_confirmed_at IS NULL THEN 1 END) as unconfirmed_users
FROM auth.users;

-- =====================================================
-- ÉTAPE 4: SYNCHRONISATION AVEC SUBSCRIPTION_STATUS
-- =====================================================

-- S'assurer que tous les utilisateurs confirmés ont un statut d'abonnement
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
    ELSE 'Compte activé automatiquement'
  END as notes,
  u.email_confirmed_at as activated_at
FROM auth.users u
WHERE u.email_confirmed_at IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM subscription_status ss WHERE ss.user_id = u.id
  );

-- =====================================================
-- ÉTAPE 5: RAPPORT FINAL
-- =====================================================

-- Afficher le rapport final
SELECT 
  '🎉 Activation terminée' as status,
  'Tous les utilisateurs sont maintenant confirmés et peuvent se connecter' as message;

-- Afficher les utilisateurs activés
SELECT 
  u.email,
  u.raw_user_meta_data->>'first_name' as first_name,
  u.raw_user_meta_data->>'last_name' as last_name,
  u.raw_user_meta_data->>'role' as role,
  u.email_confirmed_at,
  CASE 
    WHEN ss.is_active THEN '✅ Actif'
    ELSE '⏳ En attente d''activation'
  END as subscription_status
FROM auth.users u
LEFT JOIN subscription_status ss ON u.id = ss.user_id
ORDER BY u.created_at DESC;
