-- =====================================================
-- VÉRIFICATION ET CORRECTION DE L'ÉTAT DES SESSIONS
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T14:00:00.000Z

-- Ce script vérifie et corrige l'état des sessions Supabase
-- pour résoudre les erreurs "Auth session missing"

-- =====================================================
-- ÉTAPE 1: VÉRIFICATION DES SESSIONS ACTIVES
-- =====================================================

-- Vérifier les sessions actives dans la base de données
SELECT 
  'Sessions actives' as info,
  COUNT(*) as active_sessions
FROM auth.sessions 
WHERE not_after > NOW();

-- =====================================================
-- ÉTAPE 2: VÉRIFICATION DES UTILISATEURS
-- =====================================================

-- Lister tous les utilisateurs avec leur statut
SELECT 
  'Utilisateurs dans auth.users' as info,
  COUNT(*) as total_users,
  COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END) as confirmed_users,
  COUNT(CASE WHEN email_confirmed_at IS NULL THEN 1 END) as unconfirmed_users
FROM auth.users;

-- =====================================================
-- ÉTAPE 3: NETTOYAGE DES SESSIONS EXPIRÉES
-- =====================================================

-- Supprimer les sessions expirées
DELETE FROM auth.sessions 
WHERE not_after <= NOW();

-- Afficher le nombre de sessions supprimées
SELECT 
  'Sessions expirées supprimées' as action,
  COUNT(*) as deleted_sessions
FROM auth.sessions 
WHERE not_after <= NOW();

-- =====================================================
-- ÉTAPE 4: VÉRIFICATION DES TOKENS
-- =====================================================

-- Vérifier les tokens de rafraîchissement
SELECT 
  'Tokens de rafraîchissement' as info,
  COUNT(*) as refresh_tokens
FROM auth.refresh_tokens;

-- =====================================================
-- ÉTAPE 5: SYNCHRONISATION AVEC SUBSCRIPTION_STATUS
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
  'Vérification terminée' as status,
  'État des sessions vérifié et corrigé' as message;

-- Afficher un résumé de l'état actuel
SELECT 
  'État actuel du système' as info,
  (SELECT COUNT(*) FROM auth.users) as total_users,
  (SELECT COUNT(*) FROM auth.sessions WHERE not_after > NOW()) as active_sessions,
  (SELECT COUNT(*) FROM subscription_status) as subscription_records;
