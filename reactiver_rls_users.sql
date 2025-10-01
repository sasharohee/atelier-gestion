-- =====================================================
-- RÉACTIVATION DES 8 POLITIQUES RLS DE LA TABLE USERS
-- =====================================================

-- Vérifier l'état actuel des politiques RLS
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'users' AND schemaname = 'public';

-- Vérifier les politiques existantes
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'users' AND schemaname = 'public'
ORDER BY policyname;

-- =====================================================
-- ÉTAPE 1: RÉACTIVER RLS SUR LA TABLE USERS
-- =====================================================

-- Activer Row Level Security sur la table users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- ÉTAPE 2: RÉACTIVER TOUTES LES POLITIQUES RLS
-- =====================================================

-- 1. Politique: admins_can_manage_all_users
CREATE POLICY "admins_can_manage_all_users" ON public.users
    FOR ALL
    TO public
    USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- 2. Politique: admins_can_view_all_users
CREATE POLICY "admins_can_view_all_users" ON public.users
    FOR SELECT
    TO public
    USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- 3. Politique: service_role_full_access_users
CREATE POLICY "service_role_full_access_users" ON public.users
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- 4. Politique: users_can_insert_own_profile
CREATE POLICY "users_can_insert_own_profile" ON public.users
    FOR INSERT
    TO public
    WITH CHECK (auth.uid() = id);

-- 5. Politique: users_can_update_own_profile
CREATE POLICY "users_can_update_own_profile" ON public.users
    FOR UPDATE
    TO public
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);

-- 6. Politique: users_can_view_own_profile
CREATE POLICY "users_can_view_own_profile" ON public.users
    FOR SELECT
    TO public
    USING (auth.uid() = id);

-- 7. Politique: users_select_policy
CREATE POLICY "users_select_policy" ON public.users
    FOR SELECT
    TO public
    USING (
        auth.uid() = id OR
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'technician')
        )
    );

-- 8. Politique: users_update_policy
CREATE POLICY "users_update_policy" ON public.users
    FOR UPDATE
    TO public
    USING (
        auth.uid() = id OR
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    )
    WITH CHECK (
        auth.uid() = id OR
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- =====================================================
-- ÉTAPE 3: VÉRIFICATION DES POLITIQUES RÉACTIVÉES
-- =====================================================

-- Vérifier que RLS est bien activé
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'users' AND schemaname = 'public';

-- Vérifier que toutes les politiques sont bien créées
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    CASE 
        WHEN qual IS NOT NULL THEN 'HAS USING CLAUSE'
        ELSE 'NO USING CLAUSE'
    END as using_clause,
    CASE 
        WHEN with_check IS NOT NULL THEN 'HAS WITH CHECK CLAUSE'
        ELSE 'NO WITH CHECK CLAUSE'
    END as with_check_clause
FROM pg_policies 
WHERE tablename = 'users' AND schemaname = 'public'
ORDER BY policyname;

-- =====================================================
-- ÉTAPE 4: TEST DES POLITIQUES
-- =====================================================

-- Test de lecture pour un utilisateur connecté
-- (À exécuter avec un utilisateur connecté)
-- SELECT COUNT(*) FROM public.users;

-- Test d'insertion pour un utilisateur connecté
-- (À exécuter avec un utilisateur connecté)
-- INSERT INTO public.users (id, email, role) VALUES (auth.uid(), 'test@example.com', 'user');

-- =====================================================
-- MESSAGES DE CONFIRMATION
-- =====================================================

DO $$
BEGIN
    RAISE NOTICE '✅ RLS activé sur la table users';
    RAISE NOTICE '✅ 8 politiques RLS créées/réactivées';
    RAISE NOTICE '✅ Vérifiez les résultats ci-dessus';
    RAISE NOTICE '🔧 Testez les politiques avec un utilisateur connecté';
END $$;
