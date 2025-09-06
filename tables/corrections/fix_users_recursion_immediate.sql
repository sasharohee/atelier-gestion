-- SCRIPT IMMÉDIAT POUR CORRIGER LA RÉCURSION INFINIE DANS LA TABLE users
-- À exécuter dans l'interface SQL de Supabase

-- 1. DÉSACTIVER RLS TEMPORAIREMENT
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- 2. SUPPRIMER TOUTES LES POLITIQUES EXISTANTES
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

-- 3. RÉACTIVER RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 4. CRÉER UNE POLITIQUE SIMPLE ET SÉCURISÉE
-- Permet à l'utilisateur de voir et modifier son propre profil
CREATE POLICY "users_self_access" ON public.users 
FOR ALL USING (auth.uid() = id);

-- 5. VÉRIFICATION
SELECT 
    'Correction terminée' as status,
    COUNT(*) as policies_count
FROM pg_policies 
WHERE tablename = 'users' 
AND schemaname = 'public';
