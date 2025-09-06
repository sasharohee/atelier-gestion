-- 🔧 SYNCHRONISATION - Tous les Utilisateurs Auth
-- Script pour synchroniser tous les utilisateurs Auth vers la table users

-- 1. Vérifier l'état actuel
SELECT 
  'État actuel' as info,
  (SELECT COUNT(*) FROM auth.users) as auth_users_count,
  (SELECT COUNT(*) FROM public.users) as local_users_count,
  (SELECT COUNT(*) FROM auth.users au 
   JOIN public.users pu ON au.id = pu.id) as synchronized_count;

-- 2. Lister les utilisateurs Auth non synchronisés
SELECT 
  'Utilisateurs non synchronisés' as info,
  au.id,
  au.email,
  au.created_at,
  CASE 
    WHEN pu.id IS NOT NULL THEN '✅ Synchronisé'
    ELSE '❌ Non synchronisé'
  END as status
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
WHERE pu.id IS NULL
ORDER BY au.created_at DESC;

-- 3. Synchroniser tous les utilisateurs manquants
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

-- 4. Vérifier le résultat
SELECT 
  'Après synchronisation' as info,
  (SELECT COUNT(*) FROM auth.users) as auth_users_count,
  (SELECT COUNT(*) FROM public.users) as local_users_count,
  (SELECT COUNT(*) FROM auth.users au 
   JOIN public.users pu ON au.id = pu.id) as synchronized_count;

-- 5. Lister tous les utilisateurs synchronisés
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

-- 6. Message de confirmation
DO $$
DECLARE
  synced_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO synced_count FROM public.users;
  RAISE NOTICE '✅ Synchronisation terminée!';
  RAISE NOTICE 'Nombre total d''utilisateurs synchronisés: %', synced_count;
  RAISE NOTICE 'Tous les utilisateurs Auth sont maintenant dans la table users.';
END $$;
