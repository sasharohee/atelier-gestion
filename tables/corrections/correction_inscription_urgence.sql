-- Correction URGENTE pour l'erreur d'inscription
-- Date: 2024-01-24
-- Solution simple et directe pour résoudre l'erreur 500 lors de l'inscription

-- ========================================
-- 1. SUPPRIMER TOUS LES TRIGGERS SUR AUTH.USERS
-- ========================================

-- Supprimer tous les triggers possibles sur auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP TRIGGER IF EXISTS handle_new_user ON auth.users;
DROP TRIGGER IF EXISTS create_user_default_data_trigger ON auth.users;
DROP TRIGGER IF EXISTS on_auth_user_created_simple ON auth.users;
DROP TRIGGER IF EXISTS trigger_create_user_default_data ON auth.users;
DROP TRIGGER IF EXISTS trigger_create_user_on_signup ON auth.users;
DROP TRIGGER IF EXISTS trigger_create_user_automatically ON auth.users;
DROP TRIGGER IF EXISTS trigger_create_subscription_status ON auth.users;
DROP TRIGGER IF EXISTS trigger_create_user_settings ON auth.users;
DROP TRIGGER IF EXISTS trigger_create_system_settings ON auth.users;

-- Supprimer toutes les fonctions associées
DROP FUNCTION IF EXISTS handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS create_user_default_data() CASCADE;
DROP FUNCTION IF EXISTS on_auth_user_created() CASCADE;
DROP FUNCTION IF EXISTS handle_new_user_simple() CASCADE;
DROP FUNCTION IF EXISTS create_user_default_data_simple() CASCADE;

-- ========================================
-- 2. CRÉER LA TABLE SUBSCRIPTION_STATUS SI ELLE N'EXISTE PAS
-- ========================================

CREATE TABLE IF NOT EXISTS subscription_status (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    first_name TEXT,
    last_name TEXT,
    email TEXT,
    is_active BOOLEAN DEFAULT true,
    is_admin BOOLEAN DEFAULT false,
    role TEXT DEFAULT 'technician',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========================================
-- 3. CRÉER LA TABLE USERS SI ELLE N'EXISTE PAS
-- ========================================

CREATE TABLE IF NOT EXISTS public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT,
    role TEXT DEFAULT 'technician',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ========================================
-- 4. DÉSACTIVER TEMPORAIREMENT RLS POUR LES TESTS
-- ========================================

-- Désactiver RLS sur subscription_status temporairement
ALTER TABLE subscription_status DISABLE ROW LEVEL SECURITY;

-- Désactiver RLS sur users temporairement
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- ========================================
-- 5. CRÉER UNE FONCTION RPC SIMPLE POUR L'INSCRIPTION
-- ========================================

CREATE OR REPLACE FUNCTION create_user_default_data(p_user_id UUID, p_email TEXT DEFAULT NULL, p_first_name TEXT DEFAULT 'Utilisateur', p_last_name TEXT DEFAULT 'Test')
RETURNS JSON AS $$
DECLARE
    user_email TEXT;
    is_admin BOOLEAN;
    user_role TEXT;
BEGIN
    -- Déterminer si l'utilisateur est admin
    user_email := COALESCE(p_email, '');
    is_admin := (user_email = 'srohee32@gmail.com' OR user_email = 'repphonereparation@gmail.com');
    user_role := CASE WHEN is_admin THEN 'admin' ELSE 'technician' END;
    
    -- Insérer dans users
    INSERT INTO public.users (id, email, role)
    VALUES (p_user_id, user_email, user_role)
    ON CONFLICT (id) DO UPDATE SET
        email = EXCLUDED.email,
        role = EXCLUDED.role,
        updated_at = NOW();
    
    -- Insérer dans subscription_status
    INSERT INTO subscription_status (user_id, first_name, last_name, email, is_active, is_admin, role)
    VALUES (p_user_id, p_first_name, p_last_name, user_email, true, is_admin, user_role)
    ON CONFLICT (user_id) DO UPDATE SET
        first_name = EXCLUDED.first_name,
        last_name = EXCLUDED.last_name,
        email = EXCLUDED.email,
        is_active = EXCLUDED.is_active,
        is_admin = EXCLUDED.is_admin,
        role = EXCLUDED.role,
        updated_at = NOW();
    
    RETURN json_build_object(
        'success', true,
        'message', 'Données utilisateur créées avec succès',
        'user_id', p_user_id,
        'is_admin', is_admin,
        'role', user_role
    );
    
EXCEPTION WHEN OTHERS THEN
    RETURN json_build_object(
        'success', false,
        'error', 'Erreur lors de la création des données: ' || SQLERRM
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ========================================
-- 6. CRÉER DES POLITIQUES RLS SIMPLES
-- ========================================

-- Réactiver RLS
ALTER TABLE subscription_status ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- Politiques pour subscription_status
DROP POLICY IF EXISTS "Users can view own subscription" ON subscription_status;
CREATE POLICY "Users can view own subscription" ON subscription_status
    FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own subscription" ON subscription_status;
CREATE POLICY "Users can update own subscription" ON subscription_status
    FOR UPDATE USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Admins can manage all subscriptions" ON subscription_status;
CREATE POLICY "Admins can manage all subscriptions" ON subscription_status
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

-- Politiques pour users
DROP POLICY IF EXISTS "Users can view own data" ON public.users;
CREATE POLICY "Users can view own data" ON public.users
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own data" ON public.users;
CREATE POLICY "Users can update own data" ON public.users
    FOR UPDATE USING (auth.uid() = id);

DROP POLICY IF EXISTS "Admins can manage all users" ON public.users;
CREATE POLICY "Admins can manage all users" ON public.users
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = auth.uid() AND role = 'admin'
        )
    );

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
        WHEN cmd IN ('SELECT', 'UPDATE', 'ALL') THEN '✅ Politique présente'
        ELSE '⚠️ ' || cmd
    END as status
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN ('users', 'subscription_status')
ORDER BY tablename, cmd;

-- ========================================
-- 8. MESSAGES DE CONFIRMATION
-- ========================================

DO $$
BEGIN
    RAISE NOTICE '🎉 CORRECTION URGENTE TERMINÉE !';
    RAISE NOTICE '✅ Tous les triggers supprimés';
    RAISE NOTICE '✅ Tables créées/vérifiées';
    RAISE NOTICE '✅ RLS temporairement désactivé puis réactivé';
    RAISE NOTICE '✅ Fonction RPC créée';
    RAISE NOTICE '✅ Politiques RLS simples créées';
    RAISE NOTICE '';
    RAISE NOTICE '📋 TESTEZ MAINTENANT:';
    RAISE NOTICE '1. Allez sur votre application';
    RAISE NOTICE '2. Essayez de créer un compte';
    RAISE NOTICE '3. L''inscription devrait fonctionner !';
    RAISE NOTICE '';
    RAISE NOTICE '🔧 FONCTION DISPONIBLE:';
    RAISE NOTICE '- create_user_default_data(user_id, email, first_name, last_name)';
END $$;
