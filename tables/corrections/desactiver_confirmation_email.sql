-- =====================================================
-- DÉSACTIVATION DE LA CONFIRMATION D'EMAIL
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T14:00:00.000Z

-- Désactiver la confirmation d'email pour permettre la connexion directe
-- Cette configuration doit être appliquée dans le dashboard Supabase

-- =====================================================
-- ÉTAPES À SUIVRE DANS LE DASHBOARD SUPABASE
-- =====================================================

-- 1. Aller dans le dashboard Supabase
-- 2. Naviguer vers Authentication > Settings
-- 3. Dans la section "Email Auth"
-- 4. Désactiver "Enable email confirmations"
-- 5. Sauvegarder les modifications

-- =====================================================
-- CONFIGURATION ALTERNATIVE VIA SQL
-- =====================================================

-- Vérifier la configuration actuelle
SELECT 
  'Configuration actuelle de l\'authentification' as info,
  auth.config() as current_config;

-- =====================================================
-- SCRIPT POUR ACTIVER LES UTILISATEURS EXISTANTS
-- =====================================================

-- Marquer tous les utilisateurs existants comme confirmés
UPDATE auth.users 
SET email_confirmed_at = COALESCE(email_confirmed_at, NOW())
WHERE email_confirmed_at IS NULL;

-- Afficher le nombre d'utilisateurs mis à jour
SELECT 
  'Utilisateurs activés' as action,
  COUNT(*) as count
FROM auth.users 
WHERE email_confirmed_at IS NOT NULL;

-- =====================================================
-- VÉRIFICATION DES UTILISATEURS
-- =====================================================

-- Lister tous les utilisateurs avec leur statut de confirmation
SELECT 
  id,
  email,
  email_confirmed_at,
  CASE 
    WHEN email_confirmed_at IS NOT NULL THEN '✅ Confirmé'
    ELSE '❌ Non confirmé'
  END as status
FROM auth.users
ORDER BY created_at DESC;

-- =====================================================
-- MESSAGE DE CONFIRMATION
-- =====================================================

SELECT 
  '🎉 Configuration terminée' as message,
  'Les utilisateurs peuvent maintenant se connecter sans confirmation d\'email' as details;
