-- =====================================================
-- ACTIVATION RAPIDE DES UTILISATEURS
-- =====================================================
-- Script ultra-simple pour activer tous les utilisateurs non confirmés

-- Activer tous les utilisateurs non confirmés
UPDATE auth.users 
SET email_confirmed_at = NOW()
WHERE email_confirmed_at IS NULL;

-- Vérifier le résultat
SELECT 
  'Utilisateurs activés' as action,
  COUNT(*) as total_users,
  COUNT(CASE WHEN email_confirmed_at IS NOT NULL THEN 1 END) as confirmed_users
FROM auth.users;
