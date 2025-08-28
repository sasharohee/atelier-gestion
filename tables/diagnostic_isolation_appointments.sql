-- =====================================================
-- DIAGNOSTIC COMPLET ISOLATION APPOINTMENTS
-- =====================================================
-- Objectif: Diagnostiquer et corriger le problème d'isolation
-- Date: 2025-01-23
-- =====================================================

-- 1. DIAGNOSTIC INITIAL
SELECT '=== 1. DIAGNOSTIC INITIAL ===' as section;

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

-- Vérifier si RLS est activé
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'appointments';

-- Vérifier les politiques existantes
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'appointments'
ORDER BY policyname;

-- 2. VÉRIFICATION DES DONNÉES
SELECT '=== 2. VÉRIFICATION DES DONNÉES ===' as section;

-- Compter les rendez-vous par utilisateur
SELECT 
    user_id,
    COUNT(*) as appointment_count
FROM public.appointments 
GROUP BY user_id
ORDER BY appointment_count DESC;

-- Vérifier les rendez-vous sans user_id
SELECT 
    COUNT(*) as appointments_sans_user_id
FROM public.appointments 
WHERE user_id IS NULL;

-- Vérifier l'utilisateur actuel
SELECT 
    'Utilisateur actuel' as info,
    auth.uid() as current_user_id;

-- 3. TEST D'ISOLATION MANUEL
SELECT '=== 3. TEST D ISOLATION MANUEL ===' as section;

-- Test 1: Compter tous les rendez-vous (sans RLS)
SELECT 
    'Total rendez-vous (sans RLS)' as test,
    COUNT(*) as count
FROM public.appointments;

-- Test 2: Compter les rendez-vous de l'utilisateur actuel
SELECT 
    'Rendez-vous utilisateur actuel' as test,
    COUNT(*) as count
FROM public.appointments 
WHERE user_id = auth.uid();

-- Test 3: Vérifier les politiques RLS
DO $$
DECLARE
    current_user_id UUID;
    total_count INTEGER;
    user_count INTEGER;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Aucun utilisateur connecté';
        RETURN;
    END IF;
    
    -- Compter tous les rendez-vous
    SELECT COUNT(*) INTO total_count FROM public.appointments;
    
    -- Compter les rendez-vous de l'utilisateur actuel
    SELECT COUNT(*) INTO user_count FROM public.appointments WHERE user_id = current_user_id;
    
    RAISE NOTICE '🔍 Diagnostic isolation:';
    RAISE NOTICE '   - Utilisateur actuel: %', current_user_id;
    RAISE NOTICE '   - Total rendez-vous: %', total_count;
    RAISE NOTICE '   - Rendez-vous utilisateur: %', user_count;
    
    IF total_count = user_count THEN
        RAISE NOTICE '✅ Isolation fonctionne correctement';
    ELSIF user_count = 0 THEN
        RAISE NOTICE '❌ Problème: Utilisateur ne voit aucun rendez-vous';
    ELSE
        RAISE NOTICE '❌ Problème: Utilisateur voit % rendez-vous sur % total', user_count, total_count;
    END IF;
END $$;

-- 4. CORRECTION DES DONNÉES
SELECT '=== 4. CORRECTION DES DONNÉES ===' as section;

-- Mettre à jour les rendez-vous sans user_id
DO $$
DECLARE
    current_user_id UUID;
    updated_count INTEGER;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NOT NULL THEN
        UPDATE public.appointments 
        SET user_id = current_user_id
        WHERE user_id IS NULL;
        
        GET DIAGNOSTICS updated_count = ROW_COUNT;
        RAISE NOTICE '✅ % rendez-vous sans user_id mis à jour', updated_count;
    ELSE
        RAISE NOTICE '⚠️ Aucun utilisateur connecté pour la mise à jour';
    END IF;
END $$;

-- 5. RÉACTIVATION COMPLÈTE DE RLS
SELECT '=== 5. RÉACTIVATION COMPLÈTE DE RLS ===' as section;

-- Désactiver RLS temporairement
ALTER TABLE public.appointments DISABLE ROW LEVEL SECURITY;

-- Supprimer toutes les politiques
DROP POLICY IF EXISTS "appointments_select_policy" ON public.appointments;
DROP POLICY IF EXISTS "appointments_insert_policy" ON public.appointments;
DROP POLICY IF EXISTS "appointments_update_policy" ON public.appointments;
DROP POLICY IF EXISTS "appointments_delete_policy" ON public.appointments;

-- Réactiver RLS
ALTER TABLE public.appointments ENABLE ROW LEVEL SECURITY;

-- 6. CRÉATION DE POLITIQUES SIMPLIFIÉES
SELECT '=== 6. CRÉATION POLITIQUES SIMPLIFIÉES ===' as section;

-- Politique SELECT simplifiée
CREATE POLICY "appointments_select_simple" ON public.appointments
    FOR SELECT
    USING (user_id = auth.uid());

-- Politique INSERT simplifiée
CREATE POLICY "appointments_insert_simple" ON public.appointments
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- Politique UPDATE simplifiée
CREATE POLICY "appointments_update_simple" ON public.appointments
    FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Politique DELETE simplifiée
CREATE POLICY "appointments_delete_simple" ON public.appointments
    FOR DELETE
    USING (user_id = auth.uid());

-- 7. TEST APRÈS CORRECTION
SELECT '=== 7. TEST APRÈS CORRECTION ===' as section;

DO $$
DECLARE
    current_user_id UUID;
    total_count INTEGER;
    user_count INTEGER;
BEGIN
    current_user_id := auth.uid();
    
    IF current_user_id IS NULL THEN
        RAISE NOTICE '❌ Aucun utilisateur connecté pour le test';
        RETURN;
    END IF;
    
    -- Compter tous les rendez-vous (devrait être filtré par RLS)
    SELECT COUNT(*) INTO total_count FROM public.appointments;
    
    -- Compter les rendez-vous de l'utilisateur actuel
    SELECT COUNT(*) INTO user_count FROM public.appointments WHERE user_id = current_user_id;
    
    RAISE NOTICE '🔍 Test après correction:';
    RAISE NOTICE '   - Rendez-vous visibles (avec RLS): %', total_count;
    RAISE NOTICE '   - Rendez-vous utilisateur: %', user_count;
    
    IF total_count = user_count THEN
        RAISE NOTICE '✅ Isolation fonctionne maintenant';
    ELSE
        RAISE NOTICE '❌ Problème persiste: % vs %', total_count, user_count;
    END IF;
END $$;

-- 8. VÉRIFICATION FINALE
SELECT '=== 8. VÉRIFICATION FINALE ===' as section;

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

-- 9. RAFRAÎCHISSEMENT CACHE
SELECT '=== 9. RAFRAÎCHISSEMENT CACHE ===' as section;

NOTIFY pgrst, 'reload schema';
SELECT pg_sleep(3);

-- 10. INSTRUCTIONS POUR LE FRONTEND
SELECT '=== 10. INSTRUCTIONS POUR LE FRONTEND ===' as section;

SELECT 
    'L''isolation est maintenant active avec des politiques simplifiées' as info,
    'Chaque utilisateur ne voit que ses propres rendez-vous' as isolation,
    'Testez en créant un rendez-vous et en changeant de compte' as test_instruction;

SELECT 'DIAGNOSTIC ISOLATION APPOINTMENTS TERMINÉ' as status;


