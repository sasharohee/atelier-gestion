-- =====================================================
-- CORRECTION COLONNES MANQUANTES POUR RLS
-- =====================================================
-- Source: dashboard
-- User: 84dbdd62-9341-4abb-aaa4-d263ae14784b
-- Date: 2025-08-25T18:40:00.000Z

-- Script pour corriger les colonnes manquantes avant d'activer RLS

-- =====================================================
-- ÉTAPE 1: DIAGNOSTIC DES COLONNES MANQUANTES
-- =====================================================

-- Vérifier les colonnes de chaque table
SELECT 
  'DIAGNOSTIC COLONNES CLIENTS' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'clients' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 
  'DIAGNOSTIC COLONNES DEVICES' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'devices' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 
  'DIAGNOSTIC COLONNES REPAIRS' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'repairs' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 
  'DIAGNOSTIC COLONNES PRODUCTS' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'products' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 
  'DIAGNOSTIC COLONNES SALES' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'sales' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 
  'DIAGNOSTIC COLONNES APPOINTMENTS' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'appointments' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 
  'DIAGNOSTIC COLONNES MESSAGES' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'messages' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

SELECT 
  'DIAGNOSTIC COLONNES DEVICE_MODELS' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'device_models' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- =====================================================
-- ÉTAPE 2: AJOUT DES COLONNES MANQUANTES
-- =====================================================

-- Ajouter les colonnes manquantes à la table clients
DO $$
BEGIN
  -- Ajouter created_by si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'clients' 
      AND table_schema = 'public' 
      AND column_name = 'created_by'
  ) THEN
    ALTER TABLE clients ADD COLUMN created_by UUID;
    RAISE NOTICE '✅ Colonne created_by ajoutée à clients';
  END IF;

  -- Ajouter workshop_id si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'clients' 
      AND table_schema = 'public' 
      AND column_name = 'workshop_id'
  ) THEN
    ALTER TABLE clients ADD COLUMN workshop_id UUID;
    RAISE NOTICE '✅ Colonne workshop_id ajoutée à clients';
  END IF;
END $$;

-- Ajouter les colonnes manquantes à la table devices
DO $$
BEGIN
  -- Ajouter created_by si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'devices' 
      AND table_schema = 'public' 
      AND column_name = 'created_by'
  ) THEN
    ALTER TABLE devices ADD COLUMN created_by UUID;
    RAISE NOTICE '✅ Colonne created_by ajoutée à devices';
  END IF;

  -- Ajouter workshop_id si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'devices' 
      AND table_schema = 'public' 
      AND column_name = 'workshop_id'
  ) THEN
    ALTER TABLE devices ADD COLUMN workshop_id UUID;
    RAISE NOTICE '✅ Colonne workshop_id ajoutée à devices';
  END IF;
END $$;

-- Ajouter les colonnes manquantes à la table repairs
DO $$
BEGIN
  -- Ajouter created_by si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'repairs' 
      AND table_schema = 'public' 
      AND column_name = 'created_by'
  ) THEN
    ALTER TABLE repairs ADD COLUMN created_by UUID;
    RAISE NOTICE '✅ Colonne created_by ajoutée à repairs';
  END IF;

  -- Ajouter workshop_id si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'repairs' 
      AND table_schema = 'public' 
      AND column_name = 'workshop_id'
  ) THEN
    ALTER TABLE repairs ADD COLUMN workshop_id UUID;
    RAISE NOTICE '✅ Colonne workshop_id ajoutée à repairs';
  END IF;
END $$;

-- Ajouter les colonnes manquantes à la table products
DO $$
BEGIN
  -- Ajouter created_by si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products' 
      AND table_schema = 'public' 
      AND column_name = 'created_by'
  ) THEN
    ALTER TABLE products ADD COLUMN created_by UUID;
    RAISE NOTICE '✅ Colonne created_by ajoutée à products';
  END IF;

  -- Ajouter workshop_id si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'products' 
      AND table_schema = 'public' 
      AND column_name = 'workshop_id'
  ) THEN
    ALTER TABLE products ADD COLUMN workshop_id UUID;
    RAISE NOTICE '✅ Colonne workshop_id ajoutée à products';
  END IF;
END $$;

-- Ajouter les colonnes manquantes à la table sales
DO $$
BEGIN
  -- Ajouter created_by si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'sales' 
      AND table_schema = 'public' 
      AND column_name = 'created_by'
  ) THEN
    ALTER TABLE sales ADD COLUMN created_by UUID;
    RAISE NOTICE '✅ Colonne created_by ajoutée à sales';
  END IF;

  -- Ajouter workshop_id si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'sales' 
      AND table_schema = 'public' 
      AND column_name = 'workshop_id'
  ) THEN
    ALTER TABLE sales ADD COLUMN workshop_id UUID;
    RAISE NOTICE '✅ Colonne workshop_id ajoutée à sales';
  END IF;
END $$;

-- Ajouter les colonnes manquantes à la table appointments
DO $$
BEGIN
  -- Ajouter created_by si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'appointments' 
      AND table_schema = 'public' 
      AND column_name = 'created_by'
  ) THEN
    ALTER TABLE appointments ADD COLUMN created_by UUID;
    RAISE NOTICE '✅ Colonne created_by ajoutée à appointments';
  END IF;

  -- Ajouter workshop_id si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'appointments' 
      AND table_schema = 'public' 
      AND column_name = 'workshop_id'
  ) THEN
    ALTER TABLE appointments ADD COLUMN workshop_id UUID;
    RAISE NOTICE '✅ Colonne workshop_id ajoutée à appointments';
  END IF;
END $$;

-- Ajouter les colonnes manquantes à la table messages
DO $$
BEGIN
  -- Ajouter created_by si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'messages' 
      AND table_schema = 'public' 
      AND column_name = 'created_by'
  ) THEN
    ALTER TABLE messages ADD COLUMN created_by UUID;
    RAISE NOTICE '✅ Colonne created_by ajoutée à messages';
  END IF;

  -- Ajouter workshop_id si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'messages' 
      AND table_schema = 'public' 
      AND column_name = 'workshop_id'
  ) THEN
    ALTER TABLE messages ADD COLUMN workshop_id UUID;
    RAISE NOTICE '✅ Colonne workshop_id ajoutée à messages';
  END IF;
END $$;

-- Ajouter les colonnes manquantes à la table device_models
DO $$
BEGIN
  -- Ajouter created_by si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'device_models' 
      AND table_schema = 'public' 
      AND column_name = 'created_by'
  ) THEN
    ALTER TABLE device_models ADD COLUMN created_by UUID;
    RAISE NOTICE '✅ Colonne created_by ajoutée à device_models';
  END IF;

  -- Ajouter workshop_id si elle n'existe pas
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'device_models' 
      AND table_schema = 'public' 
      AND column_name = 'workshop_id'
  ) THEN
    ALTER TABLE device_models ADD COLUMN workshop_id UUID;
    RAISE NOTICE '✅ Colonne workshop_id ajoutée à device_models';
  END IF;
END $$;

-- =====================================================
-- ÉTAPE 3: AJOUT DES COLONNES POUR AUTRES TABLES
-- =====================================================

-- Ajouter les colonnes manquantes pour toutes les autres tables
DO $$
DECLARE
  table_record RECORD;
BEGIN
  FOR table_record IN 
    SELECT tablename 
    FROM pg_tables 
    WHERE schemaname = 'public' 
      AND tablename NOT LIKE 'pg_%'
      AND tablename NOT LIKE 'sql_%'
      AND tablename NOT IN (
        'schema_migrations', 'ar_internal_metadata', 'clients', 'devices', 
        'repairs', 'products', 'sales', 'appointments', 'messages', 
        'device_models', 'subscription_status', 'user_profiles'
      )
  LOOP
    -- Ajouter created_by si elle n'existe pas
    EXECUTE format('
      DO $inner$
      BEGIN
        IF NOT EXISTS (
          SELECT 1 FROM information_schema.columns 
          WHERE table_name = %L 
            AND table_schema = ''public'' 
            AND column_name = ''created_by''
        ) THEN
          ALTER TABLE public.%I ADD COLUMN created_by UUID;
          RAISE NOTICE ''✅ Colonne created_by ajoutée à %I'';
        END IF;
      END $inner$;
    ', table_record.tablename, table_record.tablename, table_record.tablename);
    
    RAISE NOTICE '✅ Vérification terminée pour la table: %', table_record.tablename;
  END LOOP;
END $$;

-- =====================================================
-- ÉTAPE 4: VÉRIFICATION FINALE
-- =====================================================

-- Vérifier que toutes les colonnes nécessaires existent
SELECT 
  'VÉRIFICATION FINALE CLIENTS' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'clients' 
  AND table_schema = 'public'
  AND column_name IN ('created_by', 'workshop_id')
ORDER BY column_name;

SELECT 
  'VÉRIFICATION FINALE DEVICES' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'devices' 
  AND table_schema = 'public'
  AND column_name IN ('created_by', 'workshop_id')
ORDER BY column_name;

SELECT 
  'VÉRIFICATION FINALE REPAIRS' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'repairs' 
  AND table_schema = 'public'
  AND column_name IN ('created_by', 'workshop_id')
ORDER BY column_name;

SELECT 
  'VÉRIFICATION FINALE PRODUCTS' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'products' 
  AND table_schema = 'public'
  AND column_name IN ('created_by', 'workshop_id')
ORDER BY column_name;

SELECT 
  'VÉRIFICATION FINALE SALES' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'sales' 
  AND table_schema = 'public'
  AND column_name IN ('created_by', 'workshop_id')
ORDER BY column_name;

SELECT 
  'VÉRIFICATION FINALE APPOINTMENTS' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'appointments' 
  AND table_schema = 'public'
  AND column_name IN ('created_by', 'workshop_id')
ORDER BY column_name;

SELECT 
  'VÉRIFICATION FINALE MESSAGES' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'messages' 
  AND table_schema = 'public'
  AND column_name IN ('created_by', 'workshop_id')
ORDER BY column_name;

SELECT 
  'VÉRIFICATION FINALE DEVICE_MODELS' as info,
  column_name,
  data_type,
  is_nullable
FROM information_schema.columns 
WHERE table_name = 'device_models' 
  AND table_schema = 'public'
  AND column_name IN ('created_by', 'workshop_id')
ORDER BY column_name;

-- =====================================================
-- ÉTAPE 5: RAPPORT FINAL
-- =====================================================

SELECT 
  'CORRECTION COLONNES MANQUANTES TERMINÉE' as status,
  'Toutes les colonnes nécessaires pour RLS ont été ajoutées' as message;
