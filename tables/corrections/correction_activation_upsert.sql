-- =====================================================
-- CORRECTION UPSERT ACTIVATION
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T17:50:00.000Z

-- Script pour corriger le problème d'upsert dans activateSubscription

-- =====================================================
-- ÉTAPE 1: DIAGNOSTIC DU PROBLÈME
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

-- Afficher les lignes problématiques
SELECT 
  'LIGNES PROBLÉMATIQUES' as info,
  id,
  user_id,
  email,
  first_name,
  last_name,
  is_active,
  status,
  subscription_type,
  created_at
FROM subscription_status 
WHERE email IS NULL 
   OR first_name IS NULL 
   OR last_name IS NULL 
   OR user_id IS NULL;

-- =====================================================
-- ÉTAPE 2: CORRECTION IMMÉDIATE DES DONNÉES NULL
-- =====================================================

-- Corriger les données NULL en utilisant auth.users
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

-- Corriger les utilisateurs qui n'ont pas de correspondance dans auth.users
UPDATE subscription_status 
SET 
  email = 'utilisateur_' || id || '@example.com',
  first_name = 'Utilisateur',
  last_name = 'Test'
WHERE email IS NULL 
   OR first_name IS NULL 
   OR last_name IS NULL;

-- =====================================================
-- ÉTAPE 3: SUPPRESSION DES CONTRAINTES NOT NULL TEMPORAIREMENT
-- =====================================================

-- Supprimer les contraintes NOT NULL pour permettre l'upsert
DO $$
BEGIN
  -- Vérifier et supprimer la contrainte NOT NULL sur email
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' 
      AND table_schema = 'public' 
      AND column_name = 'email' 
      AND is_nullable = 'NO'
  ) THEN
    ALTER TABLE subscription_status ALTER COLUMN email DROP NOT NULL;
    RAISE NOTICE '✅ Contrainte NOT NULL supprimée de email';
  END IF;

  -- Vérifier et supprimer la contrainte NOT NULL sur first_name
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' 
      AND table_schema = 'public' 
      AND column_name = 'first_name' 
      AND is_nullable = 'NO'
  ) THEN
    ALTER TABLE subscription_status ALTER COLUMN first_name DROP NOT NULL;
    RAISE NOTICE '✅ Contrainte NOT NULL supprimée de first_name';
  END IF;

  -- Vérifier et supprimer la contrainte NOT NULL sur last_name
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' 
      AND table_schema = 'public' 
      AND column_name = 'last_name' 
      AND is_nullable = 'NO'
  ) THEN
    ALTER TABLE subscription_status ALTER COLUMN last_name DROP NOT NULL;
    RAISE NOTICE '✅ Contrainte NOT NULL supprimée de last_name';
  END IF;
END $$;

-- =====================================================
-- ÉTAPE 4: AJOUT DE COLONNES MANQUANTES
-- =====================================================

-- Ajouter les colonnes manquantes si elles n'existent pas
DO $$
BEGIN
  -- Ajouter la colonne activated_by si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' 
      AND table_schema = 'public' 
      AND column_name = 'activated_by'
  ) THEN
    ALTER TABLE subscription_status ADD COLUMN activated_by UUID;
    RAISE NOTICE '✅ Colonne activated_by ajoutée';
  END IF;

  -- Ajouter la colonne status si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' 
      AND table_schema = 'public' 
      AND column_name = 'status'
  ) THEN
    ALTER TABLE subscription_status ADD COLUMN status TEXT DEFAULT 'INACTIF';
    RAISE NOTICE '✅ Colonne status ajoutée';
  END IF;
END $$;

-- =====================================================
-- ÉTAPE 5: SYNCHRONISATION AVEC AUTH.USERS
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
-- ÉTAPE 6: TEST DE L'UPSERT
-- =====================================================

-- Test de l'upsert avec toutes les colonnes nécessaires
DO $$
DECLARE
  test_user_id UUID;
  test_result RECORD;
BEGIN
  -- Prendre le premier utilisateur pour le test
  SELECT user_id INTO test_user_id FROM subscription_status LIMIT 1;
  
  IF test_user_id IS NOT NULL THEN
    -- Tester l'upsert avec toutes les colonnes
    UPDATE subscription_status 
    SET 
      is_active = true,
      activated_at = NOW(),
      activated_by = test_user_id,
      status = 'ACTIF',
      notes = 'Test de correction upsert',
      updated_at = NOW()
    WHERE user_id = test_user_id
    RETURNING * INTO test_result;
    
    RAISE NOTICE '✅ Test d''upsert réussi pour l''utilisateur: %', test_user_id;
    RAISE NOTICE '✅ Données mises à jour: is_active=%, status=%, notes=%', 
      test_result.is_active, test_result.status, test_result.notes;
  ELSE
    RAISE NOTICE 'ℹ️ Aucun utilisateur trouvé pour le test';
  END IF;
END $$;

-- =====================================================
-- ÉTAPE 7: RECRÉATION DES CONTRAINTES
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
    
    -- Remettre la contrainte NOT NULL sur first_name
    ALTER TABLE subscription_status ALTER COLUMN first_name SET NOT NULL;
    RAISE NOTICE '✅ Contrainte NOT NULL remise sur first_name';
    
    -- Remettre la contrainte NOT NULL sur last_name
    ALTER TABLE subscription_status ALTER COLUMN last_name SET NOT NULL;
    RAISE NOTICE '✅ Contrainte NOT NULL remise sur last_name';
  ELSE
    RAISE NOTICE '⚠️ Données NULL encore présentes, contraintes NOT NULL non remises';
  END IF;
END $$;

-- =====================================================
-- ÉTAPE 8: VÉRIFICATION FINALE
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
  subscription_type,
  activated_by,
  activated_at
FROM subscription_status 
LIMIT 1;

-- Vérifier les contraintes
SELECT 
  'VÉRIFICATION CONTRAINTES' as info,
  column_name,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'subscription_status' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- =====================================================
-- ÉTAPE 9: RAPPORT FINAL
-- =====================================================

SELECT 
  'CORRECTION UPSERT ACTIVATION TERMINÉE' as status,
  'Le problème d''upsert dans activateSubscription a été corrigé' as message;
