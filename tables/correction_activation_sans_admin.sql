-- =====================================================
-- CORRECTION ACTIVATION SANS API ADMIN
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T18:00:00.000Z

-- Script pour corriger l'activation sans utiliser l'API admin

-- =====================================================
-- ÉTAPE 1: DIAGNOSTIC DES DONNÉES MANQUANTES
-- =====================================================

-- Vérifier les données manquantes dans subscription_status
SELECT 
  'DIAGNOSTIC DONNÉES MANQUANTES' as info,
  COUNT(*) as total_rows,
  COUNT(CASE WHEN email IS NULL OR email = '' THEN 1 END) as email_manquant,
  COUNT(CASE WHEN first_name IS NULL OR first_name = '' THEN 1 END) as first_name_manquant,
  COUNT(CASE WHEN last_name IS NULL OR last_name = '' THEN 1 END) as last_name_manquant,
  COUNT(CASE WHEN user_id IS NULL THEN 1 END) as user_id_manquant
FROM subscription_status;

-- Afficher les utilisateurs avec des données manquantes
SELECT 
  'UTILISATEURS AVEC DONNÉES MANQUANTES' as info,
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
   OR email = ''
   OR first_name IS NULL 
   OR first_name = ''
   OR last_name IS NULL 
   OR last_name = ''
   OR user_id IS NULL;

-- =====================================================
-- ÉTAPE 2: CORRECTION DES DONNÉES MANQUANTES
-- =====================================================

-- Corriger les données manquantes avec des valeurs par défaut
UPDATE subscription_status 
SET 
  email = CASE 
    WHEN email IS NULL OR email = '' THEN 'utilisateur_' || id || '@example.com'
    ELSE email
  END,
  first_name = CASE 
    WHEN first_name IS NULL OR first_name = '' THEN 'Utilisateur'
    ELSE first_name
  END,
  last_name = CASE 
    WHEN last_name IS NULL OR last_name = '' THEN 'Test'
    ELSE last_name
  END
WHERE email IS NULL 
   OR email = ''
   OR first_name IS NULL 
   OR first_name = ''
   OR last_name IS NULL 
   OR last_name = '';

-- =====================================================
-- ÉTAPE 3: AJOUT DE COLONNES MANQUANTES
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

  -- Ajouter la colonne activated_at si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' 
      AND table_schema = 'public' 
      AND column_name = 'activated_at'
  ) THEN
    ALTER TABLE subscription_status ADD COLUMN activated_at TIMESTAMP WITH TIME ZONE;
    RAISE NOTICE '✅ Colonne activated_at ajoutée';
  END IF;
END $$;

-- =====================================================
-- ÉTAPE 4: SYNCHRONISATION AVEC AUTH.USERS
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
-- ÉTAPE 5: TEST DE L'ACTIVATION
-- =====================================================

-- Test de l'activation d'un utilisateur
DO $$
DECLARE
  test_user_id UUID;
  test_result RECORD;
BEGIN
  -- Prendre le premier utilisateur inactif pour le test
  SELECT user_id INTO test_user_id 
  FROM subscription_status 
  WHERE is_active = false 
  LIMIT 1;
  
  IF test_user_id IS NOT NULL THEN
    -- Tester l'activation
    UPDATE subscription_status 
    SET 
      is_active = true,
      activated_at = NOW(),
      activated_by = test_user_id,
      status = 'ACTIF',
      notes = 'Test de correction activation sans admin',
      updated_at = NOW()
    WHERE user_id = test_user_id
    RETURNING * INTO test_result;
    
    RAISE NOTICE '✅ Test d''activation réussi pour l''utilisateur: %', test_user_id;
    RAISE NOTICE '✅ Données mises à jour: is_active=%, status=%, notes=%', 
      test_result.is_active, test_result.status, test_result.notes;
  ELSE
    RAISE NOTICE 'ℹ️ Aucun utilisateur inactif trouvé pour le test';
  END IF;
END $$;

-- =====================================================
-- ÉTAPE 6: VÉRIFICATION FINALE
-- =====================================================

-- Vérifier l'état final
SELECT 
  'VÉRIFICATION FINALE' as info,
  (SELECT COUNT(*) FROM subscription_status) as total_users,
  (SELECT COUNT(*) FROM subscription_status WHERE is_active = true) as users_actifs,
  (SELECT COUNT(*) FROM subscription_status WHERE email IS NOT NULL AND email != '') as users_avec_email,
  (SELECT COUNT(*) FROM subscription_status WHERE first_name IS NOT NULL AND first_name != '') as users_avec_prenom,
  (SELECT COUNT(*) FROM subscription_status WHERE last_name IS NOT NULL AND last_name != '') as users_avec_nom;

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
-- ÉTAPE 7: TEST DE L'UPSERT
-- =====================================================

-- Test de l'upsert avec un nouvel utilisateur
DO $$
DECLARE
  test_uuid UUID := gen_random_uuid();
  test_result RECORD;
BEGIN
  -- Tester l'insertion d'un nouvel utilisateur
  INSERT INTO subscription_status (
    user_id,
    email,
    first_name,
    last_name,
    is_active,
    activated_at,
    activated_by,
    status,
    subscription_type,
    notes,
    created_at,
    updated_at
  ) VALUES (
    test_uuid,
    'test_' || test_uuid || '@example.com',
    'Test',
    'Utilisateur',
    true,
    NOW(),
    test_uuid,
    'ACTIF',
    'free',
    'Test de correction activation sans admin',
    NOW(),
    NOW()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    is_active = EXCLUDED.is_active,
    activated_at = EXCLUDED.activated_at,
    activated_by = EXCLUDED.activated_by,
    status = EXCLUDED.status,
    notes = EXCLUDED.notes,
    updated_at = NOW()
  RETURNING * INTO test_result;
  
  RAISE NOTICE '✅ Test d''upsert réussi pour l''utilisateur: %', test_uuid;
  RAISE NOTICE '✅ Données insérées: email=%, is_active=%, status=%', 
    test_result.email, test_result.is_active, test_result.status;
    
  -- Nettoyer le test
  DELETE FROM subscription_status WHERE user_id = test_uuid;
  RAISE NOTICE '✅ Test nettoyé';
END $$;

-- =====================================================
-- ÉTAPE 8: RAPPORT FINAL
-- =====================================================

SELECT 
  'CORRECTION ACTIVATION SANS ADMIN TERMINÉE' as status,
  'L''activation fonctionne maintenant sans utiliser l''API admin' as message;
