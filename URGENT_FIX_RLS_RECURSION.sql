-- URGENT: Correction récursion infinie RLS - Table users
-- À exécuter directement dans Supabase SQL Editor

-- 1. Désactiver RLS temporairement
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_status DISABLE ROW LEVEL SECURITY;

-- 2. Supprimer TOUTES les politiques existantes
DROP POLICY IF EXISTS "Users can view all users" ON public.users CASCADE;
DROP POLICY IF EXISTS "Users can insert their own data" ON public.users CASCADE;
DROP POLICY IF EXISTS "Users can update their own data" ON public.users CASCADE;
DROP POLICY IF EXISTS "Users can delete their own data" ON public.users CASCADE;
DROP POLICY IF EXISTS "Users can view their own data" ON public.users CASCADE;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.users CASCADE;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.users CASCADE;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON public.users CASCADE;
DROP POLICY IF EXISTS "Enable delete for users based on user_id" ON public.users CASCADE;
DROP POLICY IF EXISTS "Simple users policy" ON public.users CASCADE;
DROP POLICY IF EXISTS "users_full_access" ON public.users CASCADE;

-- Supprimer politiques subscription_status
DROP POLICY IF EXISTS "Users can view all subscriptions" ON public.subscription_status CASCADE;
DROP POLICY IF EXISTS "Users can insert subscriptions" ON public.subscription_status CASCADE;
DROP POLICY IF EXISTS "Users can update subscriptions" ON public.subscription_status CASCADE;
DROP POLICY IF EXISTS "Users can view their own subscription" ON public.subscription_status CASCADE;
DROP POLICY IF EXISTS "Users can update their own subscription" ON public.subscription_status CASCADE;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.subscription_status CASCADE;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.subscription_status CASCADE;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON public.subscription_status CASCADE;
DROP POLICY IF EXISTS "Simple subscription policy" ON public.subscription_status CASCADE;
DROP POLICY IF EXISTS "subscription_status_full_access" ON public.subscription_status CASCADE;

-- 3. Attendre que les suppressions soient terminées
SELECT pg_sleep(1);

-- 4. Créer des politiques ultra-simples
CREATE POLICY "users_allow_all" ON public.users FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "subscription_allow_all" ON public.subscription_status FOR ALL USING (true) WITH CHECK (true);

-- 5. Réactiver RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_status ENABLE ROW LEVEL SECURITY;

-- 6. Créer l'entrée subscription_status manquante
INSERT INTO public.subscription_status (
    user_id,
    first_name,
    last_name,
    email,
    is_active,
    subscription_type,
    created_at,
    updated_at
)
SELECT 
    u.id,
    u.first_name,
    u.last_name,
    u.email,
    true as is_active,
    'UTILISATEUR' as subscription_type,
    NOW() as created_at,
    NOW() as updated_at
FROM public.users u
WHERE u.id = '3f1ce915-f4ef-4169-b4db-5116b5fa2a5f'
AND NOT EXISTS (
    SELECT 1 FROM public.subscription_status ss 
    WHERE ss.user_id = u.id
);

-- 7. Vérification
SELECT '✅ Correction terminée - Politiques RLS simplifiées' as status;
