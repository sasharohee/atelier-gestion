-- =====================================================
-- CORRECTION CONTRAINTE ASSIGNED_USER_ID - TABLE APPOINTMENTS
-- =====================================================
-- Objectif: Corriger la contrainte de clé étrangère pour assigned_user_id
-- Date: 2025-01-23
-- =====================================================

-- 1. VÉRIFICATION INITIALE
SELECT '=== 1. VÉRIFICATION INITIALE ===' as section;

-- Vérifier les contraintes existantes
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name = 'appointments'
    AND kcu.column_name = 'assigned_user_id';

-- 2. SUPPRESSION DE L'ANCIENNE CONTRAINTE
SELECT '=== 2. SUPPRESSION ANCIENNE CONTRAINTE ===' as section;

DO $$
DECLARE
    constraint_name text;
BEGIN
    -- Trouver le nom de la contrainte
    SELECT tc.constraint_name INTO constraint_name
    FROM information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_schema = kcu.table_schema
    WHERE tc.constraint_type = 'FOREIGN KEY' 
        AND tc.table_name = 'appointments'
        AND kcu.column_name = 'assigned_user_id';
    
    IF constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE public.appointments DROP CONSTRAINT ' || constraint_name;
        RAISE NOTICE '✅ Contrainte supprimée: %', constraint_name;
    ELSE
        RAISE NOTICE '✅ Aucune contrainte trouvée pour assigned_user_id';
    END IF;
END $$;

-- 3. AJOUT DE LA NOUVELLE CONTRAINTE
SELECT '=== 3. AJOUT NOUVELLE CONTRAINTE ===' as section;

DO $$
BEGIN
    -- Ajouter la nouvelle contrainte qui permet les valeurs NULL
    ALTER TABLE public.appointments 
    ADD CONSTRAINT appointments_assigned_user_id_fkey 
    FOREIGN KEY (assigned_user_id) 
    REFERENCES auth.users(id) 
    ON DELETE SET NULL;
    
    RAISE NOTICE '✅ Nouvelle contrainte ajoutée pour assigned_user_id';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors de l''ajout de la contrainte: %', SQLERRM;
END $$;

-- 4. VÉRIFICATION DE LA COLONNE
SELECT '=== 4. VÉRIFICATION COLONNE ===' as section;

-- Vérifier que la colonne permet les valeurs NULL
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'appointments'
    AND column_name = 'assigned_user_id';

-- 5. MODIFICATION DE LA COLONNE SI NÉCESSAIRE
SELECT '=== 5. MODIFICATION COLONNE SI NÉCESSAIRE ===' as section;

DO $$
BEGIN
    -- S'assurer que la colonne permet les valeurs NULL
    ALTER TABLE public.appointments 
    ALTER COLUMN assigned_user_id DROP NOT NULL;
    
    RAISE NOTICE '✅ Colonne assigned_user_id modifiée pour accepter NULL';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'ℹ️ Colonne déjà configurée pour accepter NULL';
END $$;

-- 6. VÉRIFICATION FINALE
SELECT '=== 6. VÉRIFICATION FINALE ===' as section;

-- Vérifier les contraintes finales
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
    AND tc.table_name = 'appointments'
    AND kcu.column_name = 'assigned_user_id';

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
    
    -- Test 1: Insertion avec assigned_user_id NULL
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
        NULL,
        'Test Rendez-vous sans assignation',
        'Description de test',
        NOW(),
        NOW() + INTERVAL '1 hour',
        'scheduled'
    )
    RETURNING id INTO test_appointment_id;
    
    RAISE NOTICE '✅ Rendez-vous créé avec assigned_user_id NULL - ID: %', test_appointment_id;
    
    -- Nettoyer
    DELETE FROM public.appointments WHERE id = test_appointment_id;
    
    -- Test 2: Insertion avec assigned_user_id défini
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
        'Test Rendez-vous avec assignation',
        'Description de test',
        NOW(),
        NOW() + INTERVAL '1 hour',
        'scheduled'
    )
    RETURNING id INTO test_appointment_id;
    
    RAISE NOTICE '✅ Rendez-vous créé avec assigned_user_id défini - ID: %', test_appointment_id;
    
    -- Nettoyer
    DELETE FROM public.appointments WHERE id = test_appointment_id;
    RAISE NOTICE '🧹 Tests nettoyés';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test d''insertion: %', SQLERRM;
END $$;

-- 8. RAFRAÎCHISSEMENT CACHE POSTGREST
SELECT '=== 8. RAFRAÎCHISSEMENT CACHE ===' as section;

-- Rafraîchir le cache PostgREST
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(3);

SELECT 'CORRECTION CONTRAINTE ASSIGNED_USER_ID APPOINTMENTS TERMINÉE' as status;
