-- =====================================================
-- CORRECTION COLONNES MANQUANTES - TABLE DEVICES
-- =====================================================
-- Objectif: Ajouter les colonnes manquantes à la table devices
-- Date: 2025-01-23
-- =====================================================

-- 1. VÉRIFICATION COLONNES ACTUELLES
SELECT '=== 1. VÉRIFICATION COLONNES ACTUELLES ===' as section;

SELECT 
    'Colonnes actuelles devices' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'devices'
ORDER BY ordinal_position;

-- 2. AJOUT DES COLONNES MANQUANTES
SELECT '=== 2. AJOUT DES COLONNES MANQUANTES ===' as section;

-- Ajouter la colonne type si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'devices' AND column_name = 'type'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN type VARCHAR(100);
        RAISE NOTICE '✅ Colonne type ajoutée à devices';
    ELSE
        RAISE NOTICE '✅ Colonne type existe déjà dans devices';
    END IF;
END $$;

-- Ajouter la colonne specifications si elle n'existe pas
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'devices' AND column_name = 'specifications'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN specifications TEXT;
        RAISE NOTICE '✅ Colonne specifications ajoutée à devices';
    ELSE
        RAISE NOTICE '✅ Colonne specifications existe déjà dans devices';
    END IF;
END $$;

-- Ajouter d'autres colonnes potentiellement manquantes
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'devices' AND column_name = 'purchase_date'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN purchase_date DATE;
        RAISE NOTICE '✅ Colonne purchase_date ajoutée à devices';
    ELSE
        RAISE NOTICE '✅ Colonne purchase_date existe déjà dans devices';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'devices' AND column_name = 'warranty_expiry'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN warranty_expiry DATE;
        RAISE NOTICE '✅ Colonne warranty_expiry ajoutée à devices';
    ELSE
        RAISE NOTICE '✅ Colonne warranty_expiry existe déjà dans devices';
    END IF;
END $$;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'devices' AND column_name = 'location'
    ) THEN
        ALTER TABLE public.devices ADD COLUMN location VARCHAR(255);
        RAISE NOTICE '✅ Colonne location ajoutée à devices';
    ELSE
        RAISE NOTICE '✅ Colonne location existe déjà dans devices';
    END IF;
END $$;

-- 3. VÉRIFICATION COLONNES APRÈS AJOUT
SELECT '=== 3. VÉRIFICATION COLONNES APRÈS AJOUT ===' as section;

SELECT 
    'Colonnes après ajout devices' as info,
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'devices'
ORDER BY ordinal_position;

-- 4. TEST D'INSERTION AVEC NOUVELLES COLONNES
SELECT '=== 4. TEST D INSERTION AVEC NOUVELLES COLONNES ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    test_device_id UUID;
    test_user_id UUID;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Test d''insertion impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    RAISE NOTICE '🔍 Test d''insertion avec nouvelles colonnes pour utilisateur: %', current_user_id;
    
    -- Test d'insertion dans devices avec toutes les colonnes
    INSERT INTO public.devices (
        brand, 
        model, 
        serial_number, 
        type, 
        specifications, 
        color, 
        condition_status, 
        purchase_date, 
        warranty_expiry, 
        location, 
        notes
    )
    VALUES (
        'Test Brand', 
        'Test Model', 
        'TESTSERIAL123', 
        'Smartphone', 
        'Test specifications', 
        'Black', 
        'Good', 
        '2024-01-01', 
        '2026-01-01', 
        'Office', 
        'Test device with all columns'
    )
    RETURNING id INTO test_device_id;
    
    RAISE NOTICE '✅ Device créé avec ID: %', test_device_id;
    
    -- Vérifier que le device appartient à l'utilisateur actuel
    SELECT user_id INTO test_user_id
    FROM public.devices 
    WHERE id = test_device_id;
    
    RAISE NOTICE '✅ Device créé par: %', test_user_id;
    
    -- Vérifier que toutes les colonnes ont été remplies
    RAISE NOTICE '✅ Test d''insertion réussi avec toutes les colonnes';
    
    -- Nettoyer
    DELETE FROM public.devices WHERE id = test_device_id;
    RAISE NOTICE '🧹 Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test d''insertion: %', SQLERRM;
END $$;

-- 5. VÉRIFICATION CACHE POSTGREST
SELECT '=== 5. VÉRIFICATION CACHE ===' as section;

-- Rafraîchir le cache PostgREST
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(2);

-- 6. RÉSUMÉ FINAL
SELECT '=== 6. RÉSUMÉ FINAL ===' as section;

-- Résumé des colonnes
SELECT 
    'Résumé colonnes devices' as info,
    COUNT(*) as nombre_colonnes,
    STRING_AGG(column_name, ', ' ORDER BY ordinal_position) as liste_colonnes
FROM information_schema.columns 
WHERE table_schema = 'public' AND table_name = 'devices';

SELECT 'CORRECTION COLONNES MANQUANTES DEVICES TERMINÉE' as status;
