-- =====================================================
-- CORRECTION ISOLATION DONNÉES - TABLE APPOINTMENTS
-- =====================================================
-- Objectif: Corriger l'isolation des données entre utilisateurs
-- Date: 2025-01-23
-- =====================================================

-- 1. VÉRIFICATION INITIALE
SELECT '=== 1. VÉRIFICATION INITIALE ===' as section;

-- Vérifier si RLS est activé
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'appointments';

-- Vérifier les politiques existantes
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'appointments';

-- Vérifier la structure de la table
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_schema = 'public' 
    AND table_name = 'appointments'
ORDER BY ordinal_position;

-- 2. ACTIVATION DE RLS
SELECT '=== 2. ACTIVATION RLS ===' as section;

DO $$
BEGIN
    -- Activer RLS sur la table appointments
    ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;
    RAISE NOTICE '✅ RLS activé sur la table appointments';
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'ℹ️ RLS déjà activé ou erreur: %', SQLERRM;
END $$;

-- 3. SUPPRESSION DES ANCIENNES POLITIQUES
SELECT '=== 3. SUPPRESSION ANCIENNES POLITIQUES ===' as section;

DO $$
DECLARE
    policy_record RECORD;
BEGIN
    -- Supprimer toutes les politiques existantes
    FOR policy_record IN 
        SELECT policyname 
        FROM pg_policies 
        WHERE tablename = 'appointments'
    LOOP
        EXECUTE 'DROP POLICY IF EXISTS "' || policy_record.policyname || '" ON public.appointments';
        RAISE NOTICE '✅ Politique supprimée: %', policy_record.policyname;
    END LOOP;
    
    RAISE NOTICE '✅ Toutes les anciennes politiques supprimées';
END $$;

-- 4. CRÉATION DES NOUVELLES POLITIQUES D'ISOLATION
SELECT '=== 4. CRÉATION NOUVELLES POLITIQUES ===' as section;

-- Politique pour SELECT : voir seulement ses propres rendez-vous
CREATE POLICY "users_view_own_appointments" ON public.appointments
    FOR SELECT
    USING (
        user_id = auth.uid() OR 
        assigned_user_id = auth.uid() OR
        auth.uid() IN (
            SELECT id FROM public.users WHERE role IN ('admin', 'manager')
        )
    );

-- Politique pour INSERT : créer seulement ses propres rendez-vous
CREATE POLICY "users_create_own_appointments" ON public.appointments
    FOR INSERT
    WITH CHECK (
        user_id = auth.uid()
    );

-- Politique pour UPDATE : modifier seulement ses propres rendez-vous ou ceux assignés
CREATE POLICY "users_update_own_appointments" ON public.appointments
    FOR UPDATE
    USING (
        user_id = auth.uid() OR 
        assigned_user_id = auth.uid() OR
        auth.uid() IN (
            SELECT id FROM public.users WHERE role IN ('admin', 'manager')
        )
    )
    WITH CHECK (
        user_id = auth.uid() OR 
        assigned_user_id = auth.uid() OR
        auth.uid() IN (
            SELECT id FROM public.users WHERE role IN ('admin', 'manager')
        )
    );

-- Politique pour DELETE : supprimer seulement ses propres rendez-vous
CREATE POLICY "users_delete_own_appointments" ON public.appointments
    FOR DELETE
    USING (
        user_id = auth.uid() OR
        auth.uid() IN (
            SELECT id FROM public.users WHERE role IN ('admin', 'manager')
        )
    );

-- 5. VÉRIFICATION DES POLITIQUES
SELECT '=== 5. VÉRIFICATION POLITIQUES ===' as section;

SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'appointments'
ORDER BY policyname;

-- 6. CORRECTION DES DONNÉES EXISTANTES
SELECT '=== 6. CORRECTION DONNÉES EXISTANTES ===' as section;

-- Vérifier les rendez-vous sans user_id
SELECT 
    COUNT(*) as appointments_sans_user_id
FROM public.appointments 
WHERE user_id IS NULL;

-- Mettre à jour les rendez-vous sans user_id (si nécessaire)
DO $$
DECLARE
    current_user_id UUID;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NOT NULL THEN
        -- Mettre à jour les rendez-vous sans user_id avec l'utilisateur actuel
        UPDATE public.appointments 
        SET user_id = current_user_id
        WHERE user_id IS NULL;
        
        RAISE NOTICE '✅ Rendez-vous sans user_id mis à jour pour l''utilisateur: %', current_user_id;
    ELSE
        RAISE NOTICE '⚠️ Aucun utilisateur connecté pour la mise à jour';
    END IF;
END $$;

-- 7. TEST D'ISOLATION
SELECT '=== 7. TEST D ISOLATION ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    test_appointment_id UUID;
    appointment_count INTEGER;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Test d''isolation impossible - aucun utilisateur connecté';
        RETURN;
    END IF;
    
    RAISE NOTICE '🔍 Test d''isolation pour utilisateur: %', current_user_id;
    
    -- Compter les rendez-vous de l'utilisateur actuel
    SELECT COUNT(*) INTO appointment_count
    FROM public.appointments 
    WHERE user_id = current_user_id;
    
    RAISE NOTICE '📊 Rendez-vous de l''utilisateur actuel: %', appointment_count;
    
    -- Créer un rendez-vous de test
    INSERT INTO public.appointments (
        user_id,
        title,
        description,
        start_date,
        end_date,
        status
    )
    VALUES (
        current_user_id,
        'Test Isolation',
        'Test d''isolation des données',
        NOW(),
        NOW() + INTERVAL '1 hour',
        'scheduled'
    )
    RETURNING id INTO test_appointment_id;
    
    RAISE NOTICE '✅ Rendez-vous de test créé - ID: %', test_appointment_id;
    
    -- Vérifier que le rendez-vous est visible
    SELECT COUNT(*) INTO appointment_count
    FROM public.appointments 
    WHERE user_id = current_user_id;
    
    RAISE NOTICE '📊 Rendez-vous après création: %', appointment_count;
    
    -- Nettoyer
    DELETE FROM public.appointments WHERE id = test_appointment_id;
    RAISE NOTICE '🧹 Test nettoyé';
    
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE '❌ Erreur lors du test d''isolation: %', SQLERRM;
END $$;

-- 8. VÉRIFICATION FINALE
SELECT '=== 8. VÉRIFICATION FINALE ===' as section;

-- Vérifier que RLS est activé
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'appointments';

-- Vérifier les politiques finales
SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'appointments'
ORDER BY policyname;

-- 9. RAFRAÎCHISSEMENT CACHE POSTGREST
SELECT '=== 9. RAFRAÎCHISSEMENT CACHE ===' as section;

-- Rafraîchir le cache PostgREST
NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(3);

-- 10. INSTRUCTIONS POUR LE FRONTEND
SELECT '=== 10. INSTRUCTIONS FRONTEND ===' as section;

SELECT 
    'L''isolation des données est maintenant active' as info,
    'Chaque utilisateur ne voit que ses propres rendez-vous' as isolation,
    'Les admins et managers peuvent voir tous les rendez-vous' as admin_access,
    'Les techniciens assignés peuvent voir leurs rendez-vous assignés' as technician_access;

SELECT 'CORRECTION ISOLATION APPOINTMENTS TERMINÉE' as status;
