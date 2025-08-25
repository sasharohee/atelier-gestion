-- =====================================================
-- CORRECTION COLONNE ASSIGNED_USER_ID - TABLE APPOINTMENTS
-- =====================================================
-- Objectif: Ajouter la colonne assigned_user_id si elle est manquante
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

-- 2. AJOUT DE LA COLONNE ASSIGNED_USER_ID
SELECT '=== 2. AJOUT COLONNE ASSIGNED_USER_ID ===' as section;

DO $$
BEGIN
    -- Ajouter la colonne assigned_user_id si elle n'existe pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'assigned_user_id'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN assigned_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;
        RAISE NOTICE '✅ Colonne assigned_user_id ajoutée à appointments';
    ELSE
        RAISE NOTICE '✅ Colonne assigned_user_id existe déjà dans appointments';
    END IF;
END $$;

-- 3. AJOUT D'AUTRES COLONNES ESSENTIELLES
SELECT '=== 3. AJOUT AUTRES COLONNES ESSENTIELLES ===' as section;

DO $$
BEGIN
    -- Ajouter d'autres colonnes essentielles si elles n'existent pas
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'user_id'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne user_id ajoutée à appointments';
    ELSE
        RAISE NOTICE '✅ Colonne user_id existe déjà dans appointments';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'client_id'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN client_id UUID REFERENCES public.clients(id) ON DELETE CASCADE;
        RAISE NOTICE '✅ Colonne client_id ajoutée à appointments';
    ELSE
        RAISE NOTICE '✅ Colonne client_id existe déjà dans appointments';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'repair_id'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN repair_id UUID REFERENCES public.repairs(id) ON DELETE SET NULL;
        RAISE NOTICE '✅ Colonne repair_id ajoutée à appointments';
    ELSE
        RAISE NOTICE '✅ Colonne repair_id existe déjà dans appointments';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'title'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN title VARCHAR(255) NOT NULL DEFAULT 'Rendez-vous';
        RAISE NOTICE '✅ Colonne title ajoutée à appointments';
    ELSE
        RAISE NOTICE '✅ Colonne title existe déjà dans appointments';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'description'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN description TEXT;
        RAISE NOTICE '✅ Colonne description ajoutée à appointments';
    ELSE
        RAISE NOTICE '✅ Colonne description existe déjà dans appointments';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'start_date'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN start_date TIMESTAMP WITH TIME ZONE NOT NULL;
        RAISE NOTICE '✅ Colonne start_date ajoutée à appointments';
    ELSE
        RAISE NOTICE '✅ Colonne start_date existe déjà dans appointments';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'end_date'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN end_date TIMESTAMP WITH TIME ZONE NOT NULL;
        RAISE NOTICE '✅ Colonne end_date ajoutée à appointments';
    ELSE
        RAISE NOTICE '✅ Colonne end_date existe déjà dans appointments';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'status'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN status VARCHAR(50) DEFAULT 'scheduled';
        RAISE NOTICE '✅ Colonne status ajoutée à appointments';
    ELSE
        RAISE NOTICE '✅ Colonne status existe déjà dans appointments';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'created_at'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ Colonne created_at ajoutée à appointments';
    ELSE
        RAISE NOTICE '✅ Colonne created_at existe déjà dans appointments';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' 
            AND table_name = 'appointments' 
            AND column_name = 'updated_at'
    ) THEN
        ALTER TABLE public.appointments ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE '✅ Colonne updated_at ajoutée à appointments';
    ELSE
        RAISE NOTICE '✅ Colonne updated_at existe déjà dans appointments';
    END IF;
END $$;

-- 4. MISE À JOUR DES DONNÉES EXISTANTES
SELECT '=== 4. MISE À JOUR DONNÉES EXISTANTES ===' as section;

DO $$
BEGIN
    -- Mettre à jour les enregistrements existants qui n'ont pas de user_id
    UPDATE public.appointments 
    SET user_id = COALESCE(user_id, assigned_user_id)
    WHERE user_id IS NULL AND assigned_user_id IS NOT NULL;
    
    RAISE NOTICE '✅ Données existantes mises à jour';
END $$;

-- 5. VÉRIFICATION FINALE
SELECT '=== 5. VÉRIFICATION FINALE ===' as section;

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

-- 6. RAFRAÎCHISSEMENT CACHE POSTGREST
SELECT '=== 6. RAFRAÎCHISSEMENT CACHE ===' as section;

-- Rafraîchir le cache PostgREST
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(3);

-- 7. TEST D'INSERTION
SELECT '=== 7. TEST D INSERTION ===' as section;

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
    
    -- Test d'insertion avec toutes les colonnes
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
        'Test Rendez-vous',
        'Description de test',
        NOW(),
        NOW() + INTERVAL '1 hour',
        'scheduled'
    )
    RETURNING id INTO test_appointment_id;
    
    RAISE NOTICE '✅ Rendez-vous créé avec ID: %', test_appointment_id;
    
    -- Nettoyer
    DELETE FROM public.appointments WHERE id = test_appointment_id;
    RAISE NOTICE '🧹 Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test d''insertion: %', SQLERRM;
END $$;

SELECT 'CORRECTION COLONNE ASSIGNED_USER_ID APPOINTMENTS TERMINÉE' as status;
