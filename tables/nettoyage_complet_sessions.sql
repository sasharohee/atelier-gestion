-- =====================================================
-- NETTOYAGE COMPLET DES SESSIONS SUPABASE
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T14:00:00.000Z

-- Ce script nettoie complètement l'état des sessions pour résoudre
-- les problèmes d'authentification persistants

-- =====================================================
-- ÉTAPE 1: VÉRIFICATION DE L'ÉTAT ACTUEL
-- =====================================================

-- Vérifier l'état actuel des sessions
SELECT 
  'État actuel des sessions' as info,
  COUNT(*) as total_sessions
FROM auth.sessions;

-- Vérifier l'état actuel des tokens
SELECT 
  'État actuel des tokens' as info,
  COUNT(*) as total_tokens
FROM auth.refresh_tokens;

-- =====================================================
-- ÉTAPE 2: NETTOYAGE DES SESSIONS
-- =====================================================

-- Supprimer toutes les sessions existantes
DELETE FROM auth.sessions;

-- Afficher le nombre de sessions supprimées
SELECT 
  'Sessions supprimées' as action,
  COUNT(*) as deleted_sessions
FROM auth.sessions;

-- =====================================================
-- ÉTAPE 3: NETTOYAGE DES TOKENS
-- =====================================================

-- Supprimer tous les tokens de rafraîchissement
DELETE FROM auth.refresh_tokens;

-- Afficher le nombre de tokens supprimés
SELECT 
  'Tokens supprimés' as action,
  COUNT(*) as deleted_tokens
FROM auth.refresh_tokens;

-- =====================================================
-- ÉTAPE 4: VÉRIFICATION DES UTILISATEURS
-- =====================================================

-- Lister tous les utilisateurs avec leur statut
SELECT 
  'Utilisateurs dans auth.users' as info,
  COUNT(*) as total_users,
  COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END) as confirmed_users,
  COUNT(CASE WHEN email_confirmed_at IS NULL THEN 1 END) as unconfirmed_users
FROM auth.users;

-- =====================================================
-- ÉTAPE 5: SYNCHRONISATION SUBSCRIPTION_STATUS
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
    ELSE 'Compte synchronisé après nettoyage'
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
  'Nettoyage terminé' as status,
  'Toutes les sessions ont été nettoyées et les utilisateurs synchronisés' as message;

-- Afficher un résumé de l'état final
SELECT 
  'État final du système' as info,
  (SELECT COUNT(*) FROM auth.users) as total_users,
  (SELECT COUNT(*) FROM auth.sessions) as total_sessions,
  (SELECT COUNT(*) FROM auth.refresh_tokens) as total_tokens,
  (SELECT COUNT(*) FROM subscription_status) as subscription_records;
