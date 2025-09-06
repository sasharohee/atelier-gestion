-- Correction automatique de TOUS les utilisateurs manquants
-- Ce script synchronise tous les utilisateurs auth.users vers public.users

-- 1. Identifier tous les utilisateurs manquants
WITH missing_users AS (
  SELECT 
    au.id,
    au.email,
    au.raw_user_meta_data,
    au.created_at,
    au.updated_at
  FROM auth.users au
  WHERE NOT EXISTS (
    SELECT 1 FROM public.users pu WHERE pu.id = au.id
  )
)
SELECT 
  'Utilisateurs manquants trouvés:' as info,
  COUNT(*) as count
FROM missing_users;

-- 2. Insérer tous les utilisateurs manquants
WITH missing_users AS (
  SELECT 
    au.id,
    au.email,
    au.raw_user_meta_data,
    au.created_at,
    au.updated_at
  FROM auth.users au
  WHERE NOT EXISTS (
    SELECT 1 FROM public.users pu WHERE pu.id = au.id
  )
)
INSERT INTO public.users (
  id, 
  first_name, 
  last_name, 
  email, 
  role, 
  created_at, 
  updated_at
)
SELECT 
  mu.id,
  COALESCE(mu.raw_user_meta_data->>'first_name', 'Utilisateur') as first_name,
  COALESCE(mu.raw_user_meta_data->>'last_name', 'Test') as last_name,
  mu.email,
  'admin' as role,
  mu.created_at,
  mu.updated_at
FROM missing_users mu;

-- 3. Vérifier le résultat
SELECT 
  'Synchronisation terminée' as status,
  COUNT(*) as total_users_in_auth,
  (SELECT COUNT(*) FROM public.users) as total_users_in_public,
  COUNT(*) - (SELECT COUNT(*) FROM public.users) as difference
FROM auth.users;

-- 4. Lister tous les utilisateurs pour vérification
SELECT 
  'Utilisateurs dans public.users:' as info
UNION ALL
SELECT 
  CONCAT(id, ' - ', email, ' - ', role) as user_info
FROM public.users 
ORDER BY created_at DESC;

-- 5. Message de confirmation
DO $$
DECLARE
  missing_count INTEGER;
  total_auth INTEGER;
  total_public INTEGER;
BEGIN
  SELECT COUNT(*) INTO total_auth FROM auth.users;
  SELECT COUNT(*) INTO total_public FROM public.users;
  missing_count := total_auth - total_public;
  
  IF missing_count = 0 THEN
    RAISE NOTICE '✅ SUCCÈS : Tous les utilisateurs sont synchronisés';
    RAISE NOTICE '✅ Auth users: %, Public users: %', total_auth, total_public;
    RAISE NOTICE '✅ Les boucles infinies de requêtes devraient être résolues';
  ELSE
    RAISE NOTICE '⚠️ ATTENTION : Il reste % utilisateurs manquants', missing_count;
  END IF;
END $$;
