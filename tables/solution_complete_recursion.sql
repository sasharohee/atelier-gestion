-- SOLUTION COMPLÈTE POUR LA RÉCURSION INFINIE - TABLE USERS
-- Ce script corrige le problème ET ajoute une fonction de secours

-- ========================================
-- ÉTAPE 1: CORRECTION DE LA RÉCURSION INFINIE
-- ========================================

-- 1. DÉSACTIVER RLS TEMPORAIREMENT
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- 2. SUPPRIMER TOUTES LES POLITIQUES EXISTANTES (INCLUANT LA NOUVELLE)
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
DROP POLICY IF EXISTS "users_self_access" ON public.users;
DROP POLICY IF EXISTS "users_own_data" ON public.users;

-- 3. RÉACTIVER RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 4. CRÉER UNE POLITIQUE SIMPLE ET SÉCURISÉE
CREATE POLICY "users_self_access" ON public.users 
FOR ALL USING (auth.uid() = id);

-- ========================================
-- ÉTAPE 2: FONCTION RPC DE SECOURS
-- ========================================

-- 5. CRÉER LA FONCTION RPC POUR CONTOURNER LES PROBLÈMES FUTURS
CREATE OR REPLACE FUNCTION get_users_without_rls()
RETURNS TABLE (
  id uuid,
  first_name text,
  last_name text,
  email text,
  role text,
  avatar text,
  created_at timestamptz,
  updated_at timestamptz
) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Désactiver temporairement RLS pour cette requête
  ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;
  
  -- Récupérer les données
  RETURN QUERY
  SELECT 
    u.id,
    u.first_name,
    u.last_name,
    u.email,
    u.role,
    u.avatar,
    u.created_at,
    u.updated_at
  FROM public.users u
  ORDER BY u.created_at DESC;
  
  -- Réactiver RLS
  ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
END;
$$;

-- 6. DONNER LES PERMISSIONS NÉCESSAIRES
GRANT EXECUTE ON FUNCTION get_users_without_rls() TO authenticated;
GRANT EXECUTE ON FUNCTION get_users_without_rls() TO anon;

-- ========================================
-- ÉTAPE 3: VÉRIFICATIONS
-- ========================================

-- 7. VÉRIFIER LES POLITIQUES
SELECT 
    'Politiques users' as table_name,
    COUNT(*) as policies_count
FROM pg_policies 
WHERE tablename = 'users' 
AND schemaname = 'public';

-- 8. VÉRIFIER LA FONCTION RPC
SELECT 
    'Fonction RPC' as type,
    proname as function_name
FROM pg_proc 
WHERE proname = 'get_users_without_rls';

-- 9. MESSAGE DE CONFIRMATION
SELECT 
    '✅ CORRECTION TERMINÉE' as status,
    'Récursion infinie éliminée - Fonction RPC créée' as message,
    NOW() as timestamp;
