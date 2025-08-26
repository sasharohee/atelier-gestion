-- =====================================================
-- CORRECTION RÉFÉRENCE USERS - TABLE APPOINTMENTS
-- =====================================================
-- Objectif: Corriger la référence de assigned_user_id pour pointer vers public.users
-- Date: 2025-01-23
-- =====================================================

-- 1. VÉRIFICATION INITIALE
SELECT '=== 1. VÉRIFICATION INITIALE ===' as section;

-- Vérifier les contraintes existantes sur assigned_user_id
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_schema AS foreign_schema,
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

-- Vérifier les utilisateurs dans public.users
SELECT 
    COUNT(*) as total_users,
    COUNT(CASE WHEN role = 'technician' THEN 1 END) as technicians,
    COUNT(CASE WHEN role = 'admin' THEN 1 END) as admins
FROM public.users;

-- Vérifier les utilisateurs dans auth.users
SELECT 
    COUNT(*) as total_auth_users
FROM auth.users;

-- 2. SUPPRESSION DE L'ANCIENNE CONTRAINTE
SELECT '=== 2. SUPPRESSION ANCIENNE CONTRAINTE ===' as section;

DO $$
DECLARE
    constraint_record RECORD;
BEGIN
    -- Supprimer toutes les contraintes de clé étrangère sur assigned_user_id
    FOR constraint_record IN 
        SELECT tc.constraint_name
        FROM information_schema.table_constraints AS tc 
        JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY' 
            AND tc.table_name = 'appointments'
            AND kcu.column_name = 'assigned_user_id'
    LOOP
        EXECUTE 'ALTER TABLE public.appointments DROP CONSTRAINT ' || constraint_record.constraint_name;
        RAISE NOTICE '✅ Contrainte supprimée: %', constraint_record.constraint_name;
    END LOOP;
    
    RAISE NOTICE '✅ Toutes les contraintes sur assigned_user_id supprimées';
END $$;

-- 3. CRÉATION DE LA NOUVELLE CONTRAINTE VERS PUBLIC.USERS
SELECT '=== 3. CRÉATION NOUVELLE CONTRAINTE VERS PUBLIC.USERS ===' as section;

DO $$
BEGIN
    -- Créer une nouvelle contrainte qui référence public.users
    ALTER TABLE public.appointments 
    ADD CONSTRAINT appointments_assigned_user_id_fkey 
    FOREIGN KEY (assigned_user_id) 
    REFERENCES public.users(id) 
    ON DELETE SET NULL;
    
    RAISE NOTICE '✅ Nouvelle contrainte vers public.users ajoutée';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors de l''ajout de la contrainte: %', SQLERRM;
    
    -- Si la contrainte échoue, on supprime complètement la colonne et on la recrée
    RAISE NOTICE '🔄 Tentative de recréation de la colonne...';
    
    BEGIN
        -- Supprimer la colonne
        ALTER TABLE public.appointments DROP COLUMN IF EXISTS assigned_user_id;
        RAISE NOTICE '✅ Colonne assigned_user_id supprimée';
        
        -- Recréer la colonne avec la bonne contrainte
        ALTER TABLE public.appointments 
        ADD COLUMN assigned_user_id UUID REFERENCES public.users(id) ON DELETE SET NULL;
        RAISE NOTICE '✅ Colonne assigned_user_id recréée avec contrainte vers public.users';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors de la recréation: %', SQLERRM;
        
        -- Dernière tentative : colonne sans contrainte
        BEGIN
            ALTER TABLE public.appointments 
            ADD COLUMN assigned_user_id UUID;
            RAISE NOTICE '✅ Colonne assigned_user_id recréée sans contrainte';
        EXCEPTION WHEN OTHERS THEN
            RAISE NOTICE '❌ Impossible de recréer la colonne: %', SQLERRM;
        END;
    END;
END $$;

-- 4. VÉRIFICATION FINALE
SELECT '=== 4. VÉRIFICATION FINALE ===' as section;

-- Vérifier la structure finale
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'appointments'
    AND column_name = 'assigned_user_id';

-- Vérifier les contraintes finales
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_schema AS foreign_schema,
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

-- 5. TEST D'INSERTION AVEC UTILISATEUR PUBLIC.USERS
SELECT '=== 5. TEST D INSERTION AVEC UTILISATEUR PUBLIC.USERS ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    test_technician_id UUID;
    test_appointment_id UUID;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Test d''insertion impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    -- Trouver un technicien dans public.users
    SELECT id INTO test_technician_id
    FROM public.users 
    WHERE role = 'technician' 
    LIMIT 1;
    
    IF test_technician_id IS NULL THEN
        RAISE NOTICE '❌ Aucun technicien trouvé dans public.users';
        RETURN;
    END IF;
    
    RAISE NOTICE '🔍 Test d''insertion pour utilisateur: %', current_user_id;
    RAISE NOTICE '🔍 Technicien trouvé: %', test_technician_id;
    
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
    
    -- Test 2: Insertion avec assigned_user_id défini (technicien)
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
        test_technician_id,
        'Test Rendez-vous avec technicien',
        'Description de test',
        NOW(),
        NOW() + INTERVAL '1 hour',
        'scheduled'
    )
    RETURNING id INTO test_appointment_id;
    
    RAISE NOTICE '✅ Rendez-vous créé avec technicien assigné - ID: %', test_appointment_id;
    
    -- Nettoyer
    DELETE FROM public.appointments WHERE id = test_appointment_id;
    RAISE NOTICE '🧹 Tests nettoyés';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test d''insertion: %', SQLERRM;
END $$;

-- 6. RAFRAÎCHISSEMENT CACHE POSTGREST
SELECT '=== 6. RAFRAÎCHISSEMENT CACHE ===' as section;

-- Rafraîchir le cache PostgREST
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(3);

-- 7. INFORMATIONS POUR LE FRONTEND
SELECT '=== 7. INFORMATIONS POUR LE FRONTEND ===' as section;

SELECT 
    'La contrainte assigned_user_id référence maintenant public.users' as info,
    'Les techniciens doivent exister dans public.users (pas auth.users)' as requirement,
    'Le frontend doit utiliser les IDs de public.users' as frontend_note;

-- Afficher les techniciens disponibles
SELECT 
    id,
    first_name,
    last_name,
    role,
    email
FROM public.users 
WHERE role = 'technician' 
ORDER BY created_at DESC;

SELECT 'CORRECTION RÉFÉRENCE USERS APPOINTMENTS TERMINÉE' as status;
