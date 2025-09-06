-- =====================================================
-- CORRECTION COLONNES DATES - TABLE APPOINTMENTS
-- =====================================================
-- Objectif: Corriger les incohérences de noms de colonnes de dates
-- Date: 2025-01-23
-- =====================================================

-- 1. VÉRIFICATION INITIALE
SELECT '=== 1. VÉRIFICATION INITIALE ===' as section;

-- Vérifier toutes les colonnes existantes
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'appointments'
ORDER BY ordinal_position;

-- 2. ANALYSE DES INCOHÉRENCES
SELECT '=== 2. ANALYSE DES INCOHÉRENCES ===' as section;

-- Vérifier les colonnes de dates existantes
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'appointments'
    AND column_name IN ('start_date', 'start_time', 'end_date', 'end_time', 'date', 'time')
ORDER BY column_name;

-- 3. CORRECTION DES INCOHÉRENCES
SELECT '=== 3. CORRECTION DES INCOHÉRENCES ===' as section;

DO $$
BEGIN
    -- Si start_time existe mais pas start_date, renommer start_time en start_date
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'start_time'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'start_date'
    ) THEN
        ALTER TABLE public.appointments RENAME COLUMN start_time TO start_date;
        RAISE NOTICE '✅ Colonne start_time renommée en start_date';
    ELSE
        RAISE NOTICE '✅ Pas de renommage nécessaire pour start_time/start_date';
    END IF;
    
    -- Si end_time existe mais pas end_date, renommer end_time en end_date
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'end_time'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'end_date'
    ) THEN
        ALTER TABLE public.appointments RENAME COLUMN end_time TO end_date;
        RAISE NOTICE '✅ Colonne end_time renommée en end_date';
    ELSE
        RAISE NOTICE '✅ Pas de renommage nécessaire pour end_time/end_date';
    END IF;
    
    -- Si date existe mais pas start_date, renommer date en start_date
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'date'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'start_date'
    ) THEN
        ALTER TABLE public.appointments RENAME COLUMN date TO start_date;
        RAISE NOTICE '✅ Colonne date renommée en start_date';
    ELSE
        RAISE NOTICE '✅ Pas de renommage nécessaire pour date/start_date';
    END IF;
    
    -- Si time existe mais pas start_time, renommer time en start_time
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'time'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'start_time'
    ) THEN
        ALTER TABLE public.appointments RENAME COLUMN time TO start_time;
        RAISE NOTICE '✅ Colonne time renommée en start_time';
    ELSE
        RAISE NOTICE '✅ Pas de renommage nécessaire pour time/start_time';
    END IF;
END $$;

-- 4. AJOUT DES COLONNES MANQUANTES
SELECT '=== 4. AJOUT COLONNES MANQUANTES ===' as section;

DO $$
BEGIN
    -- Ajouter start_date si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'start_date'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN start_date TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ Colonne start_date ajoutée à appointments';
    ELSE
        RAISE NOTICE '✅ Colonne start_date existe déjà dans appointments';
    END IF;
    
    -- Ajouter end_date si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'end_date'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN end_date TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ Colonne end_date ajoutée à appointments';
    ELSE
        RAISE NOTICE '✅ Colonne end_date existe déjà dans appointments';
    END IF;
    
    -- Ajouter start_time si elle n'existe pas (pour compatibilité)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'start_time'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN start_time TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ Colonne start_time ajoutée à appointments';
    ELSE
        RAISE NOTICE '✅ Colonne start_time existe déjà dans appointments';
    END IF;
    
    -- Ajouter end_time si elle n'existe pas (pour compatibilité)
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'end_time'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN end_time TIMESTAMP WITH TIME ZONE;
        RAISE NOTICE '✅ Colonne end_time ajoutée à appointments';
    ELSE
        RAISE NOTICE '✅ Colonne end_time existe déjà dans appointments';
    END IF;
END $$;

-- 5. SYNCHRONISATION DES DONNÉES
SELECT '=== 5. SYNCHRONISATION DONNÉES ===' as section;

DO $$
BEGIN
    -- Synchroniser start_date et start_time
    UPDATE public.appointments 
    SET start_time = start_date 
    WHERE start_date IS NOT NULL AND start_time IS NULL;
    
    UPDATE public.appointments 
    SET start_date = start_time 
    WHERE start_time IS NOT NULL AND start_date IS NULL;
    
    -- Synchroniser end_date et end_time
    UPDATE public.appointments 
    SET end_time = end_date 
    WHERE end_date IS NOT NULL AND end_time IS NULL;
    
    UPDATE public.appointments 
    SET end_date = end_time 
    WHERE end_time IS NOT NULL AND end_date IS NULL;
    
    RAISE NOTICE '✅ Données de dates synchronisées';
END $$;

-- 6. SUPPRESSION DES CONTRAINTES NOT NULL PROBLÉMATIQUES
SELECT '=== 6. SUPPRESSION CONTRAINTES NOT NULL ===' as section;

DO $$
BEGIN
    -- Supprimer NOT NULL de start_time si elle existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'start_time'
            AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE public.appointments ALTER COLUMN start_time DROP NOT NULL;
        RAISE NOTICE '✅ Contrainte NOT NULL supprimée de start_time';
    ELSE
        RAISE NOTICE '✅ Colonne start_time n''a pas de contrainte NOT NULL';
    END IF;
    
    -- Supprimer NOT NULL de end_time si elle existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'end_time'
            AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE public.appointments ALTER COLUMN end_time DROP NOT NULL;
        RAISE NOTICE '✅ Contrainte NOT NULL supprimée de end_time';
    ELSE
        RAISE NOTICE '✅ Colonne end_time n''a pas de contrainte NOT NULL';
    END IF;
    
    -- Supprimer NOT NULL de start_date si elle existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'start_date'
            AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE public.appointments ALTER COLUMN start_date DROP NOT NULL;
        RAISE NOTICE '✅ Contrainte NOT NULL supprimée de start_date';
    ELSE
        RAISE NOTICE '✅ Colonne start_date n''a pas de contrainte NOT NULL';
    END IF;
    
    -- Supprimer NOT NULL de end_date si elle existe
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'end_date'
            AND is_nullable = 'NO'
    ) THEN
        ALTER TABLE public.appointments ALTER COLUMN end_date DROP NOT NULL;
        RAISE NOTICE '✅ Contrainte NOT NULL supprimée de end_date';
    ELSE
        RAISE NOTICE '✅ Colonne end_date n''a pas de contrainte NOT NULL';
    END IF;
END $$;

-- 7. VÉRIFICATION FINALE
SELECT '=== 7. VÉRIFICATION FINALE ===' as section;

-- Vérifier la structure finale
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'appointments'
ORDER BY ordinal_position;

-- 8. RAFRAÎCHISSEMENT CACHE POSTGREST
SELECT '=== 8. RAFRAÎCHISSEMENT CACHE ===' as section;

-- Rafraîchir le cache PostgREST
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(3);

-- 9. TEST D'INSERTION
SELECT '=== 9. TEST D INSERTION ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    test_appointment_id UUID;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Test d''insertion impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    RAISE NOTICE '🔍 Test d''insertion pour utilisateur: %', current_user_id;
    
    -- Test d'insertion avec start_date et end_date
    INSERT INTO public.appointments (
        user_id,
        assigned_user_id,
        title,
        description,
        start_date,
        end_date,
        status
    )
    VALUES (
        current_user_id,
        current_user_id,
        'Test Rendez-vous Dates',
        'Description de test avec dates',
        NOW(),
        NOW() + INTERVAL '1 hour',
        'scheduled'
    )
    RETURNING id INTO test_appointment_id;
    
    RAISE NOTICE '✅ Rendez-vous avec dates créé avec ID: %', test_appointment_id;
    
    -- Nettoyer
    DELETE FROM public.appointments WHERE id = test_appointment_id;
    RAISE NOTICE '🧹 Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test d''insertion: %', SQLERRM;
END $$;

SELECT 'CORRECTION COLONNES DATES APPOINTMENTS TERMINÉE' as status;
