-- SCRIPT AGRESSIF POUR CORRIGER LA RÉCURSION INFINIE DANS LA TABLE users
-- Ce script supprime complètement toutes les politiques et les recrée proprement

-- 1. DÉSACTIVER COMPLÈTEMENT RLS
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- 2. SUPPRIMER TOUTES LES POLITIQUES EXISTANTES (MÊME CELLES QUI N'EXISTENT PAS)
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.users;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.users;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.users;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.users;
DROP POLICY IF EXISTS "Users can view own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
DROP POLICY IF EXISTS "Users can delete own profile" ON public.users;
DROP POLICY IF EXISTS "Users can create own profile" ON public.users;
DROP POLICY IF EXISTS "Admin can view all users" ON public.users;
DROP POLICY IF EXISTS "Admin can update all users" ON public.users;
DROP POLICY IF EXISTS "Admin can delete all users" ON public.users;
DROP POLICY IF EXISTS "Users can view own" ON public.users;
DROP POLICY IF EXISTS "Users can update own" ON public.users;
DROP POLICY IF EXISTS "Users can delete own" ON public.users;
DROP POLICY IF EXISTS "Users can create own" ON public.users;
DROP POLICY IF EXISTS "Enable read access" ON public.users;
DROP POLICY IF EXISTS "Enable insert" ON public.users;
DROP POLICY IF EXISTS "Enable update" ON public.users;
DROP POLICY IF EXISTS "Enable delete" ON public.users;

-- 3. ATTENDRE UN MOMENT POUR S'ASSURER QUE TOUT EST NETTOYÉ
SELECT pg_sleep(1);

-- 4. RÉACTIVER RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 5. CRÉER UNE SEULE POLITIQUE SIMPLE POUR TOUT
-- Cette politique permet à l'utilisateur connecté d'accéder à son propre profil
CREATE POLICY "users_own_data" ON public.users 
FOR ALL USING (auth.uid() = id);

-- 6. VÉRIFIER QUE LA POLITIQUE A ÉTÉ CRÉÉE
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'users' 
AND schemaname = 'public';

-- 7. TESTER LA POLITIQUE
-- Cette requête devrait fonctionner sans récursion
SELECT COUNT(*) as user_count FROM public.users WHERE auth.uid() = id;

-- 8. MESSAGE DE CONFIRMATION
SELECT 
    'users corrigée définitivement' as status,
    'Récursion infinie éliminée - Politique unique créée' as message;
