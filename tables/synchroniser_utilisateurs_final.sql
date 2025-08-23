-- 🔧 SYNCHRONISATION FINALE - Tous les Utilisateurs Auth
-- Script pour synchroniser tous les utilisateurs Auth vers la table users

-- 1. Vérifier l'état actuel
SELECT 
  'État actuel' as info,
  (SELECT COUNT(*) FROM auth.users) as auth_users_count,
  (SELECT COUNT(*) FROM public.users) as local_users_count,
  (SELECT COUNT(*) FROM auth.users au 
   JOIN public.users pu ON au.id = pu.id) as synchronized_count;

-- 2. Lister tous les utilisateurs Auth
SELECT 
  'Tous les utilisateurs Auth' as info,
  id,
  email,
  created_at,
  raw_user_meta_data
FROM auth.users 
ORDER BY created_at DESC;

-- 3. Lister tous les utilisateurs dans notre table
SELECT 
  'Utilisateurs dans notre table' as info,
  id,
  email,
  first_name,
  last_name,
  role,
  created_at
FROM public.users 
ORDER BY created_at DESC;

-- 4. Identifier les utilisateurs manquants
SELECT 
  'Utilisateurs manquants' as info,
  au.id,
  au.email,
  au.created_at,
  'À synchroniser' as status
FROM auth.users au
WHERE NOT EXISTS (
  SELECT 1 FROM public.users pu WHERE pu.id = au.id
)
ORDER BY au.created_at DESC;

-- 5. Synchroniser tous les utilisateurs manquants
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
WHERE NOT EXISTS (
  SELECT 1 FROM public.users pu WHERE pu.id = au.id
);

-- 6. Vérifier le résultat final
SELECT 
  'Résultat final' as info,
  (SELECT COUNT(*) FROM auth.users) as auth_users_count,
  (SELECT COUNT(*) FROM public.users) as local_users_count,
  (SELECT COUNT(*) FROM auth.users au 
   JOIN public.users pu ON au.id = pu.id) as synchronized_count;

-- 7. Lister tous les utilisateurs synchronisés
SELECT 
  'Tous les utilisateurs synchronisés' as info,
  pu.id,
  pu.email,
  pu.first_name,
  pu.last_name,
  pu.role,
  pu.created_at
FROM public.users pu
ORDER BY pu.created_at DESC;

-- 8. Vérifier qu'il n'y a plus d'utilisateurs manquants
SELECT 
  'Vérification finale' as info,
  CASE 
    WHEN COUNT(*) = 0 THEN '✅ Tous les utilisateurs sont synchronisés'
    ELSE '❌ Il reste ' || COUNT(*) || ' utilisateur(s) non synchronisé(s)'
  END as status
FROM auth.users au
WHERE NOT EXISTS (
  SELECT 1 FROM public.users pu WHERE pu.id = au.id
);

-- 9. Message de confirmation
DO $$
DECLARE
  auth_count INTEGER;
  local_count INTEGER;
  synced_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO auth_count FROM auth.users;
  SELECT COUNT(*) INTO local_count FROM public.users;
  SELECT COUNT(*) INTO synced_count FROM auth.users au 
    JOIN public.users pu ON au.id = pu.id;
  
  RAISE NOTICE '✅ Synchronisation terminée!';
  RAISE NOTICE 'Utilisateurs Auth: %', auth_count;
  RAISE NOTICE 'Utilisateurs dans notre table: %', local_count;
  RAISE NOTICE 'Utilisateurs synchronisés: %', synced_count;
  
  IF auth_count = local_count AND auth_count = synced_count THEN
    RAISE NOTICE '🎉 Tous les utilisateurs sont parfaitement synchronisés!';
  ELSE
    RAISE NOTICE '⚠️ Il y a encore des utilisateurs non synchronisés.';
  END IF;
END $$;
