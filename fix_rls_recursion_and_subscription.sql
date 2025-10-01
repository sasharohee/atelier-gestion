-- CORRECTION: Récursion infinie RLS et création subscription_status
-- Ce script corrige les politiques RLS problématiques et crée l'entrée subscription_status

-- 1. Désactiver temporairement RLS sur la table users pour corriger la récursion
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- 2. Supprimer toutes les politiques RLS problématiques sur users
DROP POLICY IF EXISTS "Users can view their own data" ON public.users;
DROP POLICY IF EXISTS "Users can update their own data" ON public.users;
DROP POLICY IF EXISTS "Users can insert their own data" ON public.users;
DROP POLICY IF EXISTS "Users can delete their own data" ON public.users;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.users;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.users;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON public.users;
DROP POLICY IF EXISTS "Enable delete for users based on user_id" ON public.users;

-- 3. Recréer des politiques RLS simples et sécurisées
CREATE POLICY "Users can view all users" ON public.users
    FOR SELECT USING (true);

CREATE POLICY "Users can insert their own data" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own data" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can delete their own data" ON public.users
    FOR DELETE USING (auth.uid() = id);

-- 4. Réactiver RLS sur users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 5. Corriger les permissions sur subscription_status
ALTER TABLE public.subscription_status DISABLE ROW LEVEL SECURITY;

-- 6. Supprimer les politiques problématiques sur subscription_status
DROP POLICY IF EXISTS "Users can view their own subscription" ON public.subscription_status;
DROP POLICY IF EXISTS "Users can update their own subscription" ON public.subscription_status;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.subscription_status;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.subscription_status;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON public.subscription_status;

-- 7. Recréer des politiques simples pour subscription_status
CREATE POLICY "Users can view all subscriptions" ON public.subscription_status
    FOR SELECT USING (true);

CREATE POLICY "Users can insert subscriptions" ON public.subscription_status
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Users can update subscriptions" ON public.subscription_status
    FOR UPDATE USING (true);

-- 8. Réactiver RLS sur subscription_status
ALTER TABLE public.subscription_status ENABLE ROW LEVEL SECURITY;

-- 9. Créer l'entrée subscription_status pour l'utilisateur existant
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

-- 10. Vérifier que l'entrée a été créée
SELECT 
    'Entrée subscription_status créée pour:' as info,
    user_id,
    first_name,
    last_name,
    email,
    is_active,
    subscription_type
FROM public.subscription_status 
WHERE user_id = '3f1ce915-f4ef-4169-b4db-5116b5fa2a5f';

-- 11. Message de confirmation
SELECT '✅ Politiques RLS corrigées et subscription_status créé' as status;
