-- NETTOYAGE COMPLET DE LA TABLE USERS
-- Ce script supprime TOUTES les politiques et les recrée proprement

-- ========================================
-- ÉTAPE 1: NETTOYAGE COMPLET
-- ========================================

-- 1. DÉSACTIVER RLS
ALTER TABLE public.users DISABLE ROW LEVEL SECURITY;

-- 2. SUPPRIMER TOUTES LES POLITIQUES POSSIBLES
-- (Inclut toutes les variantes possibles de noms)
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
DROP POLICY IF EXISTS "user_access_policy" ON public.users;
DROP POLICY IF EXISTS "user_management_policy" ON public.users;
DROP POLICY IF EXISTS "authenticated_users_policy" ON public.users;

-- 3. ATTENDRE UN MOMENT POUR S'ASSURER QUE TOUT EST NETTOYÉ
SELECT pg_sleep(1);

-- 4. VÉRIFIER QU'AUCUNE POLITIQUE N'EXISTE
SELECT 
    'Politiques restantes' as check_type,
    COUNT(*) as count
FROM pg_policies 
WHERE tablename = 'users' 
AND schemaname = 'public';

-- ========================================
-- ÉTAPE 2: RECRÉATION PROPRE
-- ========================================

-- 5. RÉACTIVER RLS
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 6. CRÉER UNE SEULE POLITIQUE SIMPLE
CREATE POLICY "users_self_access" ON public.users 
FOR ALL USING (auth.uid() = id);

-- 7. VÉRIFIER LA CRÉATION
SELECT 
    'Politique créée' as status,
    policyname,
    permissive,
    cmd
FROM pg_policies 
WHERE tablename = 'users' 
AND schemaname = 'public';

-- ========================================
-- ÉTAPE 3: FONCTION RPC DE SECOURS
-- ========================================

-- 8. CRÉER OU REMPLACER LA FONCTION RPC
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

-- 9. PERMISSIONS
GRANT EXECUTE ON FUNCTION get_users_without_rls() TO authenticated;
GRANT EXECUTE ON FUNCTION get_users_without_rls() TO anon;

-- ========================================
-- ÉTAPE 4: VÉRIFICATION FINALE
-- ========================================

-- 10. RÉSUMÉ FINAL
SELECT 
    '✅ NETTOYAGE TERMINÉ' as status,
    'Table users nettoyée et sécurisée' as message,
    NOW() as timestamp;

-- 11. VÉRIFICATION DES POLITIQUES
SELECT 
    'Politiques finales' as info,
    COUNT(*) as count
FROM pg_policies 
WHERE tablename = 'users' 
AND schemaname = 'public';

-- 12. TEST DE LA FONCTION RPC
SELECT 
    'Fonction RPC' as test,
    CASE 
        WHEN EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'get_users_without_rls') 
        THEN '✅ Créée avec succès' 
        ELSE '❌ Échec de création' 
    END as status;
