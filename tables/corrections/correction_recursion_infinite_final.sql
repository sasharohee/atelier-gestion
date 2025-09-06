-- Correction définitive de la récursion infinie dans les politiques RLS
-- Date: 2024-01-24
-- Solution pour résoudre l'erreur "infinite recursion detected in policy for relation users"

-- ========================================
-- 1. SUPPRIMER TOUTES LES POLITIQUES PROBLÉMATIQUES
-- ========================================

-- Supprimer toutes les politiques sur users qui causent la récursion
DROP POLICY IF EXISTS "Users can view own data" ON public.users;
DROP POLICY IF EXISTS "Users can update own data" ON public.users;
DROP POLICY IF EXISTS "Admins can view all users" ON public.users;
DROP POLICY IF EXISTS "Admins can insert users" ON public.users;
DROP POLICY IF EXISTS "Admins can delete users" ON public.users;
DROP POLICY IF EXISTS "users_select_policy" ON public.users;
DROP POLICY IF EXISTS "users_insert_policy" ON public.users;
DROP POLICY IF EXISTS "users_update_policy" ON public.users;
DROP POLICY IF EXISTS "users_delete_policy" ON public.users;

-- Supprimer toutes les politiques sur subscription_status
DROP POLICY IF EXISTS "Users can view own subscription" ON subscription_status;
DROP POLICY IF EXISTS "Users can update own subscription" ON subscription_status;
DROP POLICY IF EXISTS "Admins can view all subscriptions" ON subscription_status;
DROP POLICY IF EXISTS "Admins can insert subscriptions" ON subscription_status;
DROP POLICY IF EXISTS "subscription_status_select_policy" ON subscription_status;
DROP POLICY IF EXISTS "subscription_status_insert_policy" ON subscription_status;
DROP POLICY IF EXISTS "subscription_status_update_policy" ON subscription_status;
DROP POLICY IF EXISTS "subscription_status_delete_policy" ON subscription_status;

-- ========================================
-- 2. DÉSACTIVER RLS TEMPORAIREMENT
-- ========================================

-- Désactiver RLS sur les tables problématiques
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_status DISABLE ROW LEVEL SECURITY;

-- ========================================
-- 3. CRÉER LES TABLES SI ELLES N'EXISTENT PAS
-- ========================================

-- Créer la table users si elle n'existe pas
CREATE TABLE IF NOT EXISTS public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT,
    role TEXT DEFAULT 'technician',
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Créer la table subscription_status si elle n'existe pas
CREATE TABLE IF NOT EXISTS subscription_status (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    is_active BOOLEAN DEFAULT FALSE,
    subscription_type TEXT DEFAULT 'free' CHECK (subscription_type IN ('free', 'premium', 'enterprise')),
    status TEXT DEFAULT 'INACTIF' CHECK (status IN ('ACTIF', 'INACTIF', 'SUSPENDU')),
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- ========================================
-- 4. RÉACTIVER RLS AVEC DES POLITIQUES SANS RÉCURSION
-- ========================================

-- Réactiver RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_status ENABLE ROW LEVEL SECURITY;

-- Politiques pour users - SANS RÉCURSION
-- Utiliser auth.uid() directement au lieu de faire des requêtes sur la table users
CREATE POLICY "users_can_view_own_profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "users_can_update_own_profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "users_can_insert_own_profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Politique pour les admins - utiliser une fonction au lieu de requête directe
CREATE POLICY "admins_can_view_all_users" ON public.users
    FOR SELECT USING (
        auth.jwt() ->> 'email' IN ('srohee32@gmail.com', 'repphonereparation@gmail.com')
    );

CREATE POLICY "admins_can_manage_all_users" ON public.users
    FOR ALL USING (
        auth.jwt() ->> 'email' IN ('srohee32@gmail.com', 'repphonereparation@gmail.com')
    );

-- Politiques pour subscription_status - SANS RÉCURSION
CREATE POLICY "users_can_view_own_subscription" ON subscription_status
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "users_can_update_own_subscription" ON subscription_status
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "users_can_insert_own_subscription" ON subscription_status
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Politique pour les admins sur subscription_status
CREATE POLICY "admins_can_manage_subscriptions" ON subscription_status
    FOR ALL USING (
        auth.jwt() ->> 'email' IN ('srohee32@gmail.com', 'repphonereparation@gmail.com')
    );

-- Politique pour le service role (nécessaire pour l'inscription)
CREATE POLICY "service_role_full_access_users" ON public.users
    FOR ALL USING (auth.role() = 'service_role')
    WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "service_role_full_access_subscription" ON subscription_status
    FOR ALL USING (auth.role() = 'service_role')
    WITH CHECK (auth.role() = 'service_role');

-- ========================================
-- 5. CRÉER UNE FONCTION RPC SÉCURISÉE
-- ========================================

-- Supprimer l'ancienne fonction si elle existe
DROP FUNCTION IF EXISTS create_user_default_data(UUID);
DROP FUNCTION IF EXISTS create_user_default_data(UUID, TEXT);

-- Créer une nouvelle fonction RPC sécurisée
CREATE OR REPLACE FUNCTION create_user_default_data(p_user_id UUID)
RETURNS JSON AS $$
DECLARE
    result JSON;
    user_email TEXT;
    user_first_name TEXT;
    user_last_name TEXT;
    is_admin BOOLEAN;
BEGIN
    -- Vérifier que l'utilisateur existe dans auth.users
    IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = p_user_id) THEN
        RETURN json_build_object(
            'success', false,
            'error', 'Utilisateur non trouvé dans auth.users'
        );
    END IF;

    -- Récupérer les informations de l'utilisateur
    SELECT email, raw_user_meta_data->>'first_name', raw_user_meta_data->>'last_name'
    INTO user_email, user_first_name, user_last_name
    FROM auth.users 
    WHERE id = p_user_id;

    -- Déterminer si c'est un admin
    is_admin := (user_email = 'srohee32@gmail.com' OR user_email = 'repphonereparation@gmail.com');

    BEGIN
        -- Créer l'entrée dans users
        INSERT INTO public.users (id, email, role)
        VALUES (p_user_id, user_email, CASE WHEN is_admin THEN 'admin' ELSE 'technician' END)
        ON CONFLICT (id) DO UPDATE SET
            email = EXCLUDED.email,
            role = EXCLUDED.role,
            updated_at = NOW();
        
        -- Créer le statut d'abonnement
        INSERT INTO subscription_status (
            user_id,
            first_name,
            last_name,
            email,
            is_active,
            subscription_type,
            status,
            notes
        ) VALUES (
            p_user_id,
            COALESCE(user_first_name, 'Utilisateur'),
            COALESCE(user_last_name, ''),
            COALESCE(user_email, ''),
            is_admin,
            CASE WHEN is_admin THEN 'premium' ELSE 'free' END,
            CASE WHEN is_admin THEN 'ACTIF' ELSE 'INACTIF' END,
            'Compte créé lors de l''inscription'
        ) ON CONFLICT (user_id) DO UPDATE SET
            first_name = EXCLUDED.first_name,
            last_name = EXCLUDED.last_name,
            email = EXCLUDED.email,
            updated_at = NOW();

        RETURN json_build_object(
            'success', true,
            'message', 'Données par défaut créées avec succès',
            'user_id', p_user_id,
            'is_admin', is_admin
        );
    EXCEPTION WHEN OTHERS THEN
        RETURN json_build_object(
            'success', false,
            'error', SQLERRM,
            'detail', SQLSTATE,
            'user_id', p_user_id
        );
    END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- 6. PERMISSIONS
-- ========================================

-- Donner les permissions d'exécution
GRANT EXECUTE ON FUNCTION create_user_default_data(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION create_user_default_data(UUID) TO anon;
GRANT EXECUTE ON FUNCTION create_user_default_data(UUID) TO service_role;

-- ========================================
-- 7. VÉRIFICATIONS
-- ========================================

-- Vérifier que les tables existent
SELECT 
    'VÉRIFICATION DES TABLES' as check_type,
    table_name,
    CASE 
        WHEN table_name IN ('users', 'subscription_status') THEN '✅ Table présente'
        ELSE '❓ ' || table_name
    END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'subscription_status');

-- Vérifier les politiques RLS
SELECT 
    'VÉRIFICATION DES POLITIQUES RLS' as check_type,
    schemaname,
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN cmd IN ('SELECT', 'INSERT', 'UPDATE', 'DELETE', 'ALL') THEN '✅ Politique présente'
        ELSE '⚠️ ' || cmd
    END as status
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'subscription_status')
ORDER BY tablename, cmd;

-- Vérifier que RLS est activé
SELECT 
    'VÉRIFICATION RLS' as check_type,
    schemaname,
    tablename,
    rowsecurity as rls_enabled,
    CASE 
        WHEN rowsecurity THEN '✅ RLS activé'
        ELSE '❌ RLS désactivé'
    END as status
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'subscription_status');

-- ========================================
-- 8. MESSAGES DE CONFIRMATION
-- ========================================

DO $$
BEGIN
    RAISE NOTICE '🎉 CORRECTION DE LA RÉCURSION INFINIE TERMINÉE !';
    RAISE NOTICE '✅ Toutes les politiques problématiques supprimées';
    RAISE NOTICE '✅ RLS réactivé avec des politiques sans récursion';
    RAISE NOTICE '✅ Tables créées/vérifiées';
    RAISE NOTICE '✅ Fonction RPC sécurisée créée';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 POLITIQUES CRÉÉES:';
    RAISE NOTICE '- users: accès à ses propres données + admins';
    RAISE NOTICE '- subscription_status: accès à ses propres données + admins';
    RAISE NOTICE '- service_role: accès complet pour l''inscription';
    RAISE NOTICE '';
    RAISE NOTICE '📋 TESTEZ MAINTENANT:';
    RAISE NOTICE '1. Rechargez votre application';
    RAISE NOTICE '2. L''erreur de récursion devrait être résolue';
    RAISE NOTICE '3. L''inscription devrait fonctionner !';
    RAISE NOTICE '4. Les requêtes subscription_status ne devraient plus donner d''erreur 500';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 FONCTION DISPONIBLE:';
    RAISE NOTICE '- create_user_default_data(user_id)';
    RAISE NOTICE '';
    RAISE NOTICE '⚠️ IMPORTANT:';
    RAISE NOTICE '- Les politiques utilisent auth.jwt() pour éviter la récursion';
    RAISE NOTICE '- Les admins sont identifiés par email dans le JWT';
    RAISE NOTICE '- Le service_role a accès complet pour l''inscription';
END $$;
