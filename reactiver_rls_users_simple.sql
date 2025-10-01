-- =====================================================
-- RÉACTIVATION SIMPLE DES 8 POLITIQUES RLS USERS
-- =====================================================

-- ÉTAPE 1: Activer RLS sur la table users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- ÉTAPE 2: Supprimer les anciennes politiques (si elles existent)
DROP POLICY IF EXISTS "admins_can_manage_all_users" ON public.users;
DROP POLICY IF EXISTS "admins_can_view_all_users" ON public.users;
DROP POLICY IF EXISTS "service_role_full_access_users" ON public.users;
DROP POLICY IF EXISTS "users_can_insert_own_profile" ON public.users;
DROP POLICY IF EXISTS "users_can_update_own_profile" ON public.users;
DROP POLICY IF EXISTS "users_can_view_own_profile" ON public.users;
DROP POLICY IF EXISTS "users_select_policy" ON public.users;
DROP POLICY IF EXISTS "users_update_policy" ON public.users;

-- ÉTAPE 3: Créer les 8 politiques RLS

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

-- ÉTAPE 4: Vérification simple
SELECT 'RLS activé sur users' as status, 
       (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'users') as nb_policies;

-- Afficher les politiques créées
SELECT policyname, cmd, roles 
FROM pg_policies 
WHERE tablename = 'users' 
ORDER BY policyname;

