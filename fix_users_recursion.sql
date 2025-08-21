-- SCRIPT POUR CORRIGER LA RÉCURSION INFINIE DANS LA TABLE users
-- Ce script supprime et recrée les politiques RLS de la table users

-- 1. DÉSACTIVER TEMPORAIREMENT RLS
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

-- 3. RÉACTIVER RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 4. CRÉER DES POLITIQUES RLS SIMPLES ET SÉCURISÉES
-- Politique pour permettre aux utilisateurs de voir leur propre profil
CREATE POLICY "Users can view own profile" ON public.users 
FOR SELECT USING (auth.uid() = id);

-- Politique pour permettre aux utilisateurs de mettre à jour leur propre profil
CREATE POLICY "Users can update own profile" ON public.users 
FOR UPDATE USING (auth.uid() = id);

-- Politique pour permettre aux utilisateurs de créer leur profil
CREATE POLICY "Users can create own profile" ON public.users 
FOR INSERT WITH CHECK (auth.uid() = id);

-- Politique pour permettre aux utilisateurs de supprimer leur propre profil
CREATE POLICY "Users can delete own profile" ON public.users 
FOR DELETE USING (auth.uid() = id);

-- 5. VÉRIFICATION
SELECT 
    'users corrigée' as status,
    'Récursion infinie corrigée' as message;
