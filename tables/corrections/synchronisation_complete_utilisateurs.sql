-- =====================================================
-- SYNCHRONISATION COMPLÈTE DES UTILISATEURS
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T14:40:00.000Z

-- Script pour synchroniser TOUS les utilisateurs manquants

-- =====================================================
-- ÉTAPE 1: VÉRIFICATION DE L'ÉTAT ACTUEL
-- =====================================================

-- Vérifier l'état actuel
SELECT 
  'État actuel' as info,
  (SELECT COUNT(*) FROM auth.users) as total_users_auth,
  (SELECT COUNT(*) FROM subscription_status) as total_users_subscription,
  (SELECT COUNT(*) FROM auth.users) - (SELECT COUNT(*) FROM subscription_status) as utilisateurs_manquants;

-- =====================================================
-- ÉTAPE 2: LISTE DES UTILISATEURS MANQUANTS
-- =====================================================

-- Afficher les utilisateurs qui ne sont pas dans subscription_status
SELECT 
  'Utilisateurs manquants' as info,
  u.id,
  u.email,
  u.created_at,
  u.raw_user_meta_data
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM subscription_status ss WHERE ss.user_id = u.id
)
ORDER BY u.created_at DESC;

-- =====================================================
-- ÉTAPE 3: SYNCHRONISATION COMPLÈTE
-- =====================================================

-- Ajouter TOUS les utilisateurs manquants
INSERT INTO subscription_status (
  user_id,
  first_name,
  last_name,
  email,
  is_active,
  subscription_type,
  notes,
  activated_at,
  created_at,
  updated_at
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
  CASE 
    WHEN u.raw_user_meta_data->>'role' = 'admin' THEN 'Administrateur - accès complet'
    WHEN u.email = 'srohee32@gmail.com' THEN 'Administrateur principal'
    WHEN u.email = 'repphonereparation@gmail.com' THEN 'Compte principal'
    ELSE 'Compte synchronisé automatiquement'
  END as notes,
  CASE 
    WHEN u.raw_user_meta_data->>'role' = 'admin' THEN u.created_at
    WHEN u.email = 'srohee32@gmail.com' THEN u.created_at
    WHEN u.email = 'repphonereparation@gmail.com' THEN u.created_at
    ELSE NULL
  END as activated_at,
  u.created_at,
  NOW() as updated_at
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM subscription_status ss WHERE ss.user_id = u.id
)
ON CONFLICT (user_id) DO UPDATE SET
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  email = EXCLUDED.email,
  is_active = EXCLUDED.is_active,
  subscription_type = EXCLUDED.subscription_type,
  notes = EXCLUDED.notes,
  activated_at = EXCLUDED.activated_at,
  updated_at = NOW();

-- =====================================================
-- ÉTAPE 4: VÉRIFICATION POST-SYNCHRONISATION
-- =====================================================

-- Vérifier l'état après synchronisation
SELECT 
  'État après synchronisation' as info,
  (SELECT COUNT(*) FROM auth.users) as total_users_auth,
  (SELECT COUNT(*) FROM subscription_status) as total_users_subscription,
  CASE 
    WHEN (SELECT COUNT(*) FROM auth.users) = (SELECT COUNT(*) FROM subscription_status) 
    THEN '✅ Synchronisation complète'
    ELSE '❌ Synchronisation incomplète'
  END as status;

-- =====================================================
-- ÉTAPE 5: LISTE COMPLÈTE DES UTILISATEURS
-- =====================================================

-- Afficher tous les utilisateurs avec leur statut
SELECT 
  'Liste complète' as info,
  ss.user_id,
  ss.first_name,
  ss.last_name,
  ss.email,
  ss.is_active,
  ss.subscription_type,
  ss.activated_at,
  ss.created_at
FROM subscription_status ss
ORDER BY ss.created_at DESC;

-- =====================================================
-- ÉTAPE 6: RAPPORT FINAL
-- =====================================================

SELECT 
  'Synchronisation terminée' as status,
  'Tous les utilisateurs ont été synchronisés avec subscription_status' as message;
