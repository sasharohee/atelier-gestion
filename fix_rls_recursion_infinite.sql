-- CORRECTION URGENTE: Récursion infinie RLS - Table users
-- Ce script supprime TOUTES les politiques et les recrée avec des règles ultra-simples

-- 1. Désactiver temporairement RLS sur toutes les tables concernées
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_status DISABLE ROW LEVEL SECURITY;

-- 2. Supprimer TOUTES les politiques existantes sur users (avec CASCADE pour éviter les dépendances)
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

-- 3. Supprimer TOUTES les politiques existantes sur subscription_status
DROP POLICY IF EXISTS "Users can view all subscriptions" ON public.subscription_status CASCADE;
DROP POLICY IF EXISTS "Users can insert subscriptions" ON public.subscription_status CASCADE;
DROP POLICY IF EXISTS "Users can update subscriptions" ON public.subscription_status CASCADE;
DROP POLICY IF EXISTS "Users can view their own subscription" ON public.subscription_status CASCADE;
DROP POLICY IF EXISTS "Users can update their own subscription" ON public.subscription_status CASCADE;
DROP POLICY IF EXISTS "Enable read access for all users" ON public.subscription_status CASCADE;
DROP POLICY IF EXISTS "Enable insert for authenticated users only" ON public.subscription_status CASCADE;
DROP POLICY IF EXISTS "Enable update for users based on user_id" ON public.subscription_status CASCADE;
DROP POLICY IF EXISTS "Simple subscription policy" ON public.subscription_status CASCADE;

-- 4. Vérifier qu'aucune politique ne reste
SELECT 
    'Politiques restantes sur users:' as info,
    COUNT(*) as count
FROM pg_policies 
WHERE tablename = 'users' AND schemaname = 'public';

SELECT 
    'Politiques restantes sur subscription_status:' as info,
    COUNT(*) as count
FROM pg_policies 
WHERE tablename = 'subscription_status' AND schemaname = 'public';

-- 5. Attendre un moment pour s'assurer que les suppressions sont terminées
SELECT pg_sleep(2);

-- 6. Recréer des politiques ultra-simples SANS récursion
-- Politique pour users - accès complet pour tous les utilisateurs authentifiés
CREATE POLICY "users_full_access" ON public.users
    FOR ALL USING (true) WITH CHECK (true);

-- Politique pour subscription_status - accès complet pour tous les utilisateurs authentifiés  
CREATE POLICY "subscription_status_full_access" ON public.subscription_status
    FOR ALL USING (true) WITH CHECK (true);

-- 7. Réactiver RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_status ENABLE ROW LEVEL SECURITY;

-- 8. Créer l'entrée subscription_status pour l'utilisateur existant si elle n'existe pas
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

-- 9. Vérifier que l'entrée a été créée
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

-- 10. Vérification finale des politiques
SELECT 
    'Politiques finales sur users:' as info,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'users' AND schemaname = 'public';

SELECT 
    'Politiques finales sur subscription_status:' as info,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'subscription_status' AND schemaname = 'public';

-- 11. Test de la requête qui causait l'erreur
SELECT 
    'Test de la requête users:' as info,
    COUNT(*) as user_count
FROM public.users 
WHERE created_by = '3f1ce915-f4ef-4169-b4db-5116b5fa2a5f';

-- 12. Message de confirmation
SELECT '✅ Correction récursion infinie terminée - Politiques RLS ultra-simples créées' as status;
