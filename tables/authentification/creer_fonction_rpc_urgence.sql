-- CRÉATION URGENTE DE LA FONCTION RPC
-- Cette fonction permet de contourner la récursion infinie

-- 1. CRÉER LA FONCTION RPC
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

-- 2. DONNER LES PERMISSIONS
GRANT EXECUTE ON FUNCTION get_users_without_rls() TO authenticated;
GRANT EXECUTE ON FUNCTION get_users_without_rls() TO anon;

-- 3. VÉRIFICATION
SELECT 
    '✅ Fonction RPC créée' as status,
    proname as function_name
FROM pg_proc 
WHERE proname = 'get_users_without_rls';

-- 4. TEST DE LA FONCTION
SELECT 
    'Test fonction' as test,
    COUNT(*) as user_count
FROM get_users_without_rls();
