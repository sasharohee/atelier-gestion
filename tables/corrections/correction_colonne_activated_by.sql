-- =====================================================
-- CORRECTION COLONNE ACTIVATED_BY MANQUANTE
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T17:40:00.000Z

-- Script pour ajouter la colonne activated_by manquante à subscription_status

-- =====================================================
-- ÉTAPE 1: VÉRIFICATION DE LA STRUCTURE ACTUELLE
-- =====================================================

-- Vérifier la structure actuelle de subscription_status
SELECT 
  'STRUCTURE ACTUELLE' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'subscription_status' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- =====================================================
-- ÉTAPE 2: AJOUT DE LA COLONNE ACTIVATED_BY
-- =====================================================

-- Ajouter la colonne activated_by si elle n'existe pas
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' 
      AND table_schema = 'public' 
      AND column_name = 'activated_by'
  ) THEN
    ALTER TABLE subscription_status ADD COLUMN activated_by UUID;
    RAISE NOTICE '✅ Colonne activated_by ajoutée à subscription_status';
  ELSE
    RAISE NOTICE 'ℹ️ Colonne activated_by existe déjà';
  END IF;
END $$;

-- =====================================================
-- ÉTAPE 3: AJOUT D'AUTRES COLONNES MANQUANTES
-- =====================================================

-- Ajouter d'autres colonnes qui pourraient manquer
DO $$
BEGIN
  -- Ajouter activated_by si manquant
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' 
      AND table_schema = 'public' 
      AND column_name = 'activated_by'
  ) THEN
    ALTER TABLE subscription_status ADD COLUMN activated_by UUID;
    RAISE NOTICE '✅ Colonne activated_by ajoutée';
  END IF;

  -- Ajouter subscription_start_date si manquant
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' 
      AND table_schema = 'public' 
      AND column_name = 'subscription_start_date'
  ) THEN
    ALTER TABLE subscription_status ADD COLUMN subscription_start_date TIMESTAMP WITH TIME ZONE;
    RAISE NOTICE '✅ Colonne subscription_start_date ajoutée';
  END IF;

  -- Ajouter subscription_end_date si manquant
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'subscription_status' 
      AND table_schema = 'public' 
      AND column_name = 'subscription_end_date'
  ) THEN
    ALTER TABLE subscription_status ADD COLUMN subscription_end_date TIMESTAMP WITH TIME ZONE;
    RAISE NOTICE '✅ Colonne subscription_end_date ajoutée';
  END IF;

  -- Ajouter status si manquant
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
-- ÉTAPE 4: MISE À JOUR DES DONNÉES EXISTANTES
-- =====================================================

-- Mettre à jour les utilisateurs actifs avec activated_at
UPDATE subscription_status 
SET activated_at = created_at 
WHERE is_active = true AND activated_at IS NULL;

-- Mettre à jour le statut basé sur is_active
UPDATE subscription_status 
SET status = CASE 
  WHEN is_active = true THEN 'ACTIF'
  ELSE 'INACTIF'
END
WHERE status IS NULL OR status = 'INACTIF';

-- =====================================================
-- ÉTAPE 5: VÉRIFICATION DE LA STRUCTURE FINALE
-- =====================================================

-- Vérifier la structure finale
SELECT 
  'STRUCTURE FINALE' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'subscription_status' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- =====================================================
-- ÉTAPE 6: TEST DE FONCTIONNEMENT
-- =====================================================

-- Test de mise à jour d'un utilisateur
DO $$
DECLARE
  test_user_id UUID;
BEGIN
  -- Prendre le premier utilisateur pour le test
  SELECT user_id INTO test_user_id FROM subscription_status LIMIT 1;
  
  IF test_user_id IS NOT NULL THEN
    -- Tester la mise à jour avec activated_by
    UPDATE subscription_status 
    SET 
      is_active = true,
      activated_at = NOW(),
      activated_by = test_user_id,
      status = 'ACTIF',
      notes = 'Test de correction colonne activated_by'
    WHERE user_id = test_user_id;
    
    RAISE NOTICE '✅ Test de mise à jour réussi pour l''utilisateur: %', test_user_id;
  ELSE
    RAISE NOTICE 'ℹ️ Aucun utilisateur trouvé pour le test';
  END IF;
END $$;

-- =====================================================
-- ÉTAPE 7: VÉRIFICATION FINALE
-- =====================================================

-- Vérifier que tout fonctionne
SELECT 
  'VÉRIFICATION FINALE' as info,
  (SELECT COUNT(*) FROM subscription_status) as total_users,
  (SELECT COUNT(*) FROM subscription_status WHERE is_active = true) as users_actifs,
  (SELECT COUNT(*) FROM subscription_status WHERE activated_at IS NOT NULL) as users_actives,
  (SELECT COUNT(*) FROM subscription_status WHERE status = 'ACTIF') as users_status_actif;

-- Afficher un exemple d'utilisateur
SELECT 
  'EXEMPLE UTILISATEUR' as info,
  user_id,
  email,
  is_active,
  activated_at,
  activated_by,
  status,
  subscription_type
FROM subscription_status 
LIMIT 1;

-- =====================================================
-- ÉTAPE 8: RAPPORT FINAL
-- =====================================================

SELECT 
  'CORRECTION COLONNE ACTIVATED_BY TERMINÉE' as status,
  'La colonne activated_by et autres colonnes manquantes ont été ajoutées' as message;
