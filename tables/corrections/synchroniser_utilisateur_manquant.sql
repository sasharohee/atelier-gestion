-- 🔧 SYNCHRONISATION - Utilisateur Manquant Spécifique
-- Script pour synchroniser l'utilisateur 933023a4-d9aa-4775-ad8c-f7a7814e841c

-- 1. Vérifier l'utilisateur dans auth.users
SELECT 
  'Utilisateur Auth' as source,
  id,
  email,
  created_at,
  updated_at,
  raw_user_meta_data
FROM auth.users 
WHERE id = '933023a4-d9aa-4775-ad8c-f7a7814e841c';

-- 2. Vérifier s'il existe dans public.users
SELECT 
  'Table Users' as source,
  id,
  email,
  first_name,
  last_name,
  role,
  created_at,
  updated_at
FROM public.users 
WHERE id = '933023a4-d9aa-4775-ad8c-f7a7814e841c';

-- 3. Créer l'utilisateur manquant
INSERT INTO public.users (
  id,
  first_name,
  last_name,
  email,
  role,
  avatar,
  created_at,
  updated_at
)
SELECT 
  au.id,
  COALESCE(au.raw_user_meta_data->>'first_name', 'Utilisateur') as first_name,
  COALESCE(au.raw_user_meta_data->>'last_name', 'Actuel') as last_name,
  au.email,
  'admin' as role,
  NULL as avatar,
  au.created_at,
  au.updated_at
FROM auth.users au
WHERE au.id = '933023a4-d9aa-4775-ad8c-f7a7814e841c'
  AND NOT EXISTS (
    SELECT 1 FROM public.users pu WHERE pu.id = au.id
  );

-- 4. Vérifier le résultat
SELECT 
  'Après synchronisation' as info,
  id,
  email,
  first_name,
  last_name,
  role
FROM public.users 
WHERE id = '933023a4-d9aa-4775-ad8c-f7a7814e841c';

-- 5. Statistiques mises à jour
SELECT 
  'Statistiques finales' as info,
  (SELECT COUNT(*) FROM auth.users) as auth_users_count,
  (SELECT COUNT(*) FROM public.users) as local_users_count,
  (SELECT COUNT(*) FROM auth.users au 
   JOIN public.users pu ON au.id = pu.id) as synchronized_count;

-- 6. Message de confirmation
DO $$
BEGIN
  RAISE NOTICE '✅ Synchronisation de l''utilisateur terminée!';
  RAISE NOTICE 'L''utilisateur 933023a4-d9aa-4775-ad8c-f7a7814e841c devrait maintenant être disponible.';
END $$;
