-- =====================================================
-- RÉACTIVATION DES POLITIQUES RLS DE LA TABLE SUBSCRIPTION_STATUS
-- =====================================================

-- ÉTAPE 1: Activer RLS sur la table subscription_status
ALTER TABLE public.subscription_status ENABLE ROW LEVEL SECURITY;

-- ÉTAPE 2: Supprimer les anciennes politiques (si elles existent)
DROP POLICY IF EXISTS "admins_can_manage_subscriptions" ON public.subscription_status;
DROP POLICY IF EXISTS "service_role_full_access_subscription" ON public.subscription_status;
DROP POLICY IF EXISTS "subscription_status_select_policy" ON public.subscription_status;
DROP POLICY IF EXISTS "subscription_status_update_policy" ON public.subscription_status;
DROP POLICY IF EXISTS "users_can_insert_own_subscription" ON public.subscription_status;
DROP POLICY IF EXISTS "users_can_update_own_subscription" ON public.subscription_status;
DROP POLICY IF EXISTS "users_can_view_own_subscription" ON public.subscription_status;

-- ÉTAPE 3: Créer les 7 politiques RLS

-- 1. Politique: admins_can_manage_subscriptions
CREATE POLICY "admins_can_manage_subscriptions" ON public.subscription_status
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

-- 2. Politique: service_role_full_access_subscription
CREATE POLICY "service_role_full_access_subscription" ON public.subscription_status
    FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- 3. Politique: subscription_status_select_policy
CREATE POLICY "subscription_status_select_policy" ON public.subscription_status
    FOR SELECT
    TO public
    USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role IN ('admin', 'technician')
        )
    );

-- 4. Politique: subscription_status_update_policy
CREATE POLICY "subscription_status_update_policy" ON public.subscription_status
    FOR UPDATE
    TO public
    USING (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    )
    WITH CHECK (
        auth.uid() = user_id OR
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() 
            AND role = 'admin'
        )
    );

-- 5. Politique: users_can_insert_own_subscription
CREATE POLICY "users_can_insert_own_subscription" ON public.subscription_status
    FOR INSERT
    TO public
    WITH CHECK (auth.uid() = user_id);

-- 6. Politique: users_can_update_own_subscription
CREATE POLICY "users_can_update_own_subscription" ON public.subscription_status
    FOR UPDATE
    TO public
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- 7. Politique: users_can_view_own_subscription
CREATE POLICY "users_can_view_own_subscription" ON public.subscription_status
    FOR SELECT
    TO public
    USING (auth.uid() = user_id);

-- ÉTAPE 4: Vérification
SELECT 'RLS activé sur subscription_status' as status, 
       (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'subscription_status') as nb_policies;

-- Afficher les politiques créées
SELECT policyname, cmd, roles 
FROM pg_policies 
WHERE tablename = 'subscription_status' 
ORDER BY policyname;

