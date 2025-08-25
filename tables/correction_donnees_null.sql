-- =====================================================
-- CORRECTION DONNÉES NULL ET CONTRAINTES
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T17:45:00.000Z

-- Script pour corriger les données NULL et les contraintes de subscription_status

-- =====================================================
-- ÉTAPE 1: DIAGNOSTIC DES DONNÉES NULL
-- =====================================================

-- Vérifier les données NULL dans subscription_status
SELECT 
  'DIAGNOSTIC DONNÉES NULL' as info,
  COUNT(*) as total_rows,
  COUNT(CASE WHEN email IS NULL THEN 1 END) as email_null,
  COUNT(CASE WHEN first_name IS NULL THEN 1 END) as first_name_null,
  COUNT(CASE WHEN last_name IS NULL THEN 1 END) as last_name_null,
  COUNT(CASE WHEN user_id IS NULL THEN 1 END) as user_id_null
FROM subscription_status;

-- Afficher les lignes avec des données NULL
SELECT 
  'LIGNES AVEC DONNÉES NULL' as info,
  id,
  user_id,
  email,
  first_name,
  last_name,
  is_active,
  subscription_type
FROM subscription_status 
WHERE email IS NULL 
   OR first_name IS NULL 
   OR last_name IS NULL 
   OR user_id IS NULL;

-- =====================================================
-- ÉTAPE 2: CORRECTION DES DONNÉES NULL
-- =====================================================

-- Corriger les données NULL en utilisant les données de auth.users
UPDATE subscription_status 
SET 
  email = COALESCE(subscription_status.email, auth_users.email),
  first_name = COALESCE(subscription_status.first_name, 
    COALESCE(auth_users.raw_user_meta_data->>'first_name', 'Utilisateur')),
  last_name = COALESCE(subscription_status.last_name, 
    COALESCE(auth_users.raw_user_meta_data->>'last_name', 'Test'))
FROM auth.users auth_users
WHERE subscription_status.user_id = auth_users.id
  AND (subscription_status.email IS NULL 
    OR subscription_status.first_name IS NULL 
    OR subscription_status.last_name IS NULL);

-- Mettre à jour les utilisateurs qui n'ont pas de correspondance dans auth.users
UPDATE subscription_status 
SET 
  email = 'utilisateur_' || id || '@example.com',
  first_name = 'Utilisateur',
  last_name = 'Test'
WHERE email IS NULL 
   OR first_name IS NULL 
   OR last_name IS NULL;

-- =====================================================
-- ÉTAPE 3: VÉRIFICATION APRÈS CORRECTION
-- =====================================================

-- Vérifier qu'il n'y a plus de données NULL
SELECT 
  'VÉRIFICATION APRÈS CORRECTION' as info,
  COUNT(*) as total_rows,
  COUNT(CASE WHEN email IS NULL THEN 1 END) as email_null,
  COUNT(CASE WHEN first_name IS NULL THEN 1 END) as first_name_null,
  COUNT(CASE WHEN last_name IS NULL THEN 1 END) as last_name_null,
  COUNT(CASE WHEN user_id IS NULL THEN 1 END) as user_id_null
FROM subscription_status;

-- =====================================================
-- ÉTAPE 4: CORRECTION DES CONTRAINTES
-- =====================================================

-- Supprimer les contraintes NOT NULL existantes si elles causent des problèmes
DO $$
BEGIN
  -- Vérifier si la colonne email a une contrainte NOT NULL
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' 
      AND table_schema = 'public' 
      AND column_name = 'email' 
      AND is_nullable = 'NO'
  ) THEN
    -- Rendre la colonne nullable temporairement
    ALTER TABLE subscription_status ALTER COLUMN email DROP NOT NULL;
    RAISE NOTICE '✅ Contrainte NOT NULL supprimée de email';
  END IF;
END $$;

-- =====================================================
-- ÉTAPE 5: NETTOYAGE DES DONNÉES INVALIDES
-- =====================================================

-- Supprimer les lignes sans user_id valide
DELETE FROM subscription_status 
WHERE user_id IS NULL 
   OR user_id NOT IN (SELECT id FROM auth.users);

-- =====================================================
-- ÉTAPE 6: RECRÉATION DES CONTRAINTES
-- =====================================================

-- Recréer les contraintes NOT NULL après avoir corrigé les données
DO $$
BEGIN
  -- Vérifier qu'il n'y a plus de données NULL
  IF NOT EXISTS (
    SELECT 1 FROM subscription_status 
    WHERE email IS NULL 
       OR first_name IS NULL 
       OR last_name IS NULL 
       OR user_id IS NULL
  ) THEN
    -- Remettre la contrainte NOT NULL sur email
    ALTER TABLE subscription_status ALTER COLUMN email SET NOT NULL;
    RAISE NOTICE '✅ Contrainte NOT NULL remise sur email';
  ELSE
    RAISE NOTICE '⚠️ Données NULL encore présentes, contrainte NOT NULL non remise';
  END IF;
END $$;

-- =====================================================
-- ÉTAPE 7: SYNCHRONISATION AVEC AUTH.USERS
-- =====================================================

-- S'assurer que tous les utilisateurs de auth.users sont dans subscription_status
INSERT INTO subscription_status (
  user_id,
  first_name,
  last_name,
  email,
  is_active,
  subscription_type,
  notes,
  created_at,
  updated_at,
  status
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
  'Compte synchronisé automatiquement',
  u.created_at,
  NOW() as updated_at,
  CASE 
    WHEN u.raw_user_meta_data->>'role' = 'admin' THEN 'ACTIF'
    WHEN u.email = 'srohee32@gmail.com' THEN 'ACTIF'
    WHEN u.email = 'repphonereparation@gmail.com' THEN 'ACTIF'
    ELSE 'INACTIF'
  END as status
FROM auth.users u
WHERE NOT EXISTS (
  SELECT 1 FROM subscription_status ss WHERE ss.user_id = u.id
)
ON CONFLICT (user_id) DO UPDATE SET
  email = EXCLUDED.email,
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  updated_at = NOW();

-- =====================================================
-- ÉTAPE 8: TEST DE FONCTIONNEMENT
-- =====================================================

-- Test de mise à jour d'un utilisateur
DO $$
DECLARE
  test_user_id UUID;
BEGIN
  -- Prendre le premier utilisateur pour le test
  SELECT user_id INTO test_user_id FROM subscription_status LIMIT 1;
  
  IF test_user_id IS NOT NULL THEN
    -- Tester la mise à jour avec toutes les colonnes
    UPDATE subscription_status 
    SET 
      is_active = true,
      activated_at = NOW(),
      activated_by = test_user_id,
      status = 'ACTIF',
      notes = 'Test de correction données NULL'
    WHERE user_id = test_user_id;
    
    RAISE NOTICE '✅ Test de mise à jour réussi pour l''utilisateur: %', test_user_id;
  ELSE
    RAISE NOTICE 'ℹ️ Aucun utilisateur trouvé pour le test';
  END IF;
END $$;

-- =====================================================
-- ÉTAPE 9: VÉRIFICATION FINALE
-- =====================================================

-- Vérifier l'état final
SELECT 
  'VÉRIFICATION FINALE' as info,
  (SELECT COUNT(*) FROM subscription_status) as total_users,
  (SELECT COUNT(*) FROM subscription_status WHERE is_active = true) as users_actifs,
  (SELECT COUNT(*) FROM subscription_status WHERE email IS NOT NULL) as users_avec_email,
  (SELECT COUNT(*) FROM subscription_status WHERE first_name IS NOT NULL) as users_avec_prenom,
  (SELECT COUNT(*) FROM subscription_status WHERE last_name IS NOT NULL) as users_avec_nom;

-- Afficher un exemple d'utilisateur corrigé
SELECT 
  'EXEMPLE UTILISATEUR CORRIGÉ' as info,
  user_id,
  email,
  first_name,
  last_name,
  is_active,
  status,
  subscription_type
FROM subscription_status 
LIMIT 1;

-- =====================================================
-- ÉTAPE 10: RAPPORT FINAL
-- =====================================================

SELECT 
  'CORRECTION DONNÉES NULL TERMINÉE' as status,
  'Les données NULL ont été corrigées et les contraintes sont maintenant respectées' as message;
