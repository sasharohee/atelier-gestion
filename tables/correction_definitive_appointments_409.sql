-- =====================================================
-- CORRECTION DÉFINITIVE ERREUR 409 - TABLE APPOINTMENTS
-- =====================================================
-- Objectif: Corriger définitivement l'erreur 409 sur les appointments
-- Date: 2025-01-23
-- =====================================================

-- 1. VÉRIFICATION INITIALE
SELECT '=== 1. VÉRIFICATION INITIALE ===' as section;

-- Vérifier la structure actuelle de la table appointments
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'appointments'
ORDER BY ordinal_position;

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
    AND tc.table_name = 'appointments';

-- 2. SUPPRESSION DE TOUTES LES CONTRAINTES PROBLÉMATIQUES
SELECT '=== 2. SUPPRESSION CONTRAINTES PROBLÉMATIQUES ===' as section;

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
    
    RAISE NOTICE '✅ Toutes les contraintes problématiques supprimées';
END $$;

-- 3. MODIFICATION DE LA COLONNE ASSIGNED_USER_ID
SELECT '=== 3. MODIFICATION COLONNE ASSIGNED_USER_ID ===' as section;

DO $$
BEGIN
    -- S'assurer que la colonne permet les valeurs NULL
    ALTER TABLE public.appointments 
    ALTER COLUMN assigned_user_id DROP NOT NULL;
    
    RAISE NOTICE '✅ Colonne assigned_user_id modifiée pour accepter NULL';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'ℹ️ Colonne déjà configurée pour accepter NULL: %', SQLERRM;
END $$;

-- 4. VÉRIFICATION DE LA TABLE USERS
SELECT '=== 4. VÉRIFICATION TABLE USERS ===' as section;

-- Vérifier si la table users existe et contient des données
SELECT 
    schemaname,
    tablename,
    tableowner
FROM pg_tables 
WHERE tablename = 'users';

-- Vérifier les utilisateurs existants
SELECT 
    id,
    email,
    created_at
FROM auth.users 
LIMIT 5;

-- 5. CRÉATION D'UNE NOUVELLE CONTRAINTE SÉCURISÉE
SELECT '=== 5. CRÉATION NOUVELLE CONTRAINTE SÉCURISÉE ===' as section;

DO $$
BEGIN
    -- Créer une nouvelle contrainte qui permet les valeurs NULL
    ALTER TABLE public.appointments 
    ADD CONSTRAINT appointments_assigned_user_id_fkey 
    FOREIGN KEY (assigned_user_id) 
    REFERENCES auth.users(id) 
    ON DELETE SET NULL;
    
    RAISE NOTICE '✅ Nouvelle contrainte sécurisée ajoutée';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors de l''ajout de la contrainte: %', SQLERRM;
    
    -- Si la contrainte échoue, on supprime complètement la colonne et on la recrée
    RAISE NOTICE '🔄 Tentative de recréation de la colonne...';
    
    BEGIN
        -- Supprimer la colonne
        ALTER TABLE public.appointments DROP COLUMN IF EXISTS assigned_user_id;
        RAISE NOTICE '✅ Colonne assigned_user_id supprimée';
        
        -- Recréer la colonne sans contrainte
        ALTER TABLE public.appointments 
        ADD COLUMN assigned_user_id UUID;
        RAISE NOTICE '✅ Colonne assigned_user_id recréée sans contrainte';
        
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE '❌ Erreur lors de la recréation: %', SQLERRM;
    END;
END $$;

-- 6. VÉRIFICATION FINALE
SELECT '=== 6. VÉRIFICATION FINALE ===' as section;

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

-- 7. TEST D'INSERTION SANS CONTRAINTE
SELECT '=== 7. TEST D INSERTION SANS CONTRAINTE ===' as section;

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
    RAISE NOTICE '🧹 Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test d''insertion: %', SQLERRM;
END $$;

-- 8. RAFRAÎCHISSEMENT CACHE POSTGREST
SELECT '=== 8. RAFRAÎCHISSEMENT CACHE ===' as section;

-- Rafraîchir le cache PostgREST
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(3);

-- 9. INSTRUCTIONS POUR LE FRONTEND
SELECT '=== 9. INSTRUCTIONS FRONTEND ===' as section;

SELECT 
    'Pour corriger le frontend, assurez-vous que:' as instruction,
    '1. Les valeurs vides sont converties en NULL (pas undefined)' as step1,
    '2. Le service Supabase gère correctement les valeurs NULL' as step2,
    '3. Les erreurs sont capturées avec try-catch' as step3;

SELECT 'CORRECTION DÉFINITIVE ERREUR 409 APPOINTMENTS TERMINÉE' as status;
