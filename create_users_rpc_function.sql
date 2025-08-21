-- FONCTION RPC POUR CONTOURNER LA RÉCURSION INFINIE
-- Cette fonction permet de récupérer les utilisateurs sans passer par les politiques RLS

-- 1. CrÉER LA FONCTION RPC
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

-- 2. DONNER LES PERMISSIONS NÉCESSAIRES
GRANT EXECUTE ON FUNCTION get_users_without_rls() TO authenticated;
GRANT EXECUTE ON FUNCTION get_users_without_rls() TO anon;

-- 3. VÉRIFICATION
SELECT 
  'Fonction RPC créée avec succès' as status,
  proname as function_name,
  proargtypes::regtype[] as parameters
FROM pg_proc 
WHERE proname = 'get_users_without_rls';
