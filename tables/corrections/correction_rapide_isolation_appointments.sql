-- =====================================================
-- CORRECTION RAPIDE ISOLATION APPOINTMENTS
-- =====================================================
-- Objectif: Corriger rapidement l'isolation des données
-- Date: 2025-01-23
-- =====================================================

-- 1. SUPPRESSION SÉCURISÉE DES POLITIQUES
SELECT '=== 1. SUPPRESSION SÉCURISÉE DES POLITIQUES ===' as section;

-- Supprimer les politiques une par une pour éviter les erreurs
DROP POLICY IF EXISTS "Users can view own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can create own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can update own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Users can delete own appointments" ON public.appointments;
DROP POLICY IF EXISTS "Admins can delete all appointments" ON public.appointments;
DROP POLICY IF EXISTS "users_view_own_appointments" ON public.appointments;
DROP POLICY IF EXISTS "users_create_own_appointments" ON public.appointments;
DROP POLICY IF EXISTS "users_update_own_appointments" ON public.appointments;
DROP POLICY IF EXISTS "users_delete_own_appointments" ON public.appointments;

-- 2. ACTIVATION RLS
SELECT '=== 2. ACTIVATION RLS ===' as section;

ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;

-- 3. CRÉATION DES NOUVELLES POLITIQUES (NOMS SANS ESPACES)
SELECT '=== 3. CRÉATION NOUVELLES POLITIQUES ===' as section;

-- Politique SELECT
CREATE POLICY "appointments_select_policy" ON public.appointments
    FOR SELECT
    USING (
        user_id = auth.uid() OR 
        assigned_user_id = auth.uid() OR
        auth.uid() IN (
            SELECT id FROM public.users WHERE role IN ('admin', 'manager')
        )
    );

-- Politique INSERT
CREATE POLICY "appointments_insert_policy" ON public.appointments
    FOR INSERT
    WITH CHECK (
        user_id = auth.uid()
    );

-- Politique UPDATE
CREATE POLICY "appointments_update_policy" ON public.appointments
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

-- Politique DELETE
CREATE POLICY "appointments_delete_policy" ON public.appointments
    FOR DELETE
    USING (
        user_id = auth.uid() OR
        auth.uid() IN (
            SELECT id FROM public.users WHERE role IN ('admin', 'manager')
        )
    );

-- 4. VÉRIFICATION
SELECT '=== 4. VÉRIFICATION ===' as section;

-- Vérifier RLS
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'appointments';

-- Vérifier les politiques
SELECT 
    policyname,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'appointments'
ORDER BY policyname;

-- 5. RAFRAÎCHISSEMENT CACHE
SELECT '=== 5. RAFRAÎCHISSEMENT CACHE ===' as section;

NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(3);

SELECT 'CORRECTION RAPIDE ISOLATION APPOINTMENTS TERMINÉE' as status;


