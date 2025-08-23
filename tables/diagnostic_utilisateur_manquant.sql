-- 🔍 DIAGNOSTIC - Utilisateur Manquant dans la Table Users
-- Script pour diagnostiquer et corriger le problème d'utilisateur manquant

-- 1. Vérifier l'utilisateur problématique
SELECT 
  'Utilisateur Auth' as source,
  id,
  email,
  created_at,
  updated_at
FROM auth.users 
WHERE id = 'a58d793a-3b9e-43d6-9e3b-44b00ae1aa02';

-- 2. Vérifier s'il existe dans la table users
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
WHERE id = 'a58d793a-3b9e-43d6-9e3b-44b00ae1aa02';

-- 3. Lister tous les utilisateurs Auth
SELECT 
  'Tous les utilisateurs Auth' as info,
  COUNT(*) as total_count
FROM auth.users;

-- 4. Lister tous les utilisateurs dans notre table
SELECT 
  'Tous les utilisateurs dans users' as info,
  COUNT(*) as total_count
FROM public.users;

-- 5. Comparer les utilisateurs Auth vs notre table
SELECT 
  au.id as auth_user_id,
  au.email as auth_email,
  au.created_at as auth_created_at,
  CASE 
    WHEN pu.id IS NOT NULL THEN '✅ Présent'
    ELSE '❌ Manquant'
  END as status_in_users_table,
  pu.first_name,
  pu.last_name,
  pu.role
FROM auth.users au
LEFT JOIN public.users pu ON au.id = pu.id
ORDER BY au.created_at DESC;

-- 6. Créer l'utilisateur manquant s'il n'existe pas
DO $$
DECLARE
  auth_user RECORD;
  user_exists BOOLEAN;
BEGIN
  -- Vérifier si l'utilisateur existe dans auth.users
  SELECT * INTO auth_user 
  FROM auth.users 
  WHERE id = 'a58d793a-3b9e-43d6-9e3b-44b00ae1aa02';
  
  IF auth_user.id IS NOT NULL THEN
    -- Vérifier s'il existe déjà dans notre table users
    SELECT EXISTS(
      SELECT 1 FROM public.users WHERE id = auth_user.id
    ) INTO user_exists;
    
    IF NOT user_exists THEN
      RAISE NOTICE 'Création de l''utilisateur manquant: %', auth_user.email;
      
      -- Insérer l'utilisateur dans notre table
      INSERT INTO public.users (
        id,
        first_name,
        last_name,
        email,
        role,
        avatar,
        created_at,
        updated_at
      ) VALUES (
        auth_user.id,
        COALESCE(auth_user.raw_user_meta_data->>'first_name', 'Utilisateur'),
        COALESCE(auth_user.raw_user_meta_data->>'last_name', 'Actuel'),
        auth_user.email,
        'admin', -- Rôle par défaut
        NULL,
        auth_user.created_at,
        auth_user.updated_at
      );
      
      RAISE NOTICE '✅ Utilisateur créé avec succès';
    ELSE
      RAISE NOTICE '⚠️ L''utilisateur existe déjà dans la table users';
    END IF;
  ELSE
    RAISE NOTICE '❌ Utilisateur non trouvé dans auth.users';
  END IF;
END $$;

-- 7. Vérifier le résultat après correction
SELECT 
  'Après correction' as info,
  id,
  email,
  first_name,
  last_name,
  role
FROM public.users 
WHERE id = 'a58d793a-3b9e-43d6-9e3b-44b00ae1aa02';

-- 8. Script pour synchroniser tous les utilisateurs Auth vers notre table
-- (Décommentez si nécessaire)
/*
DO $$
DECLARE
  auth_user RECORD;
  user_exists BOOLEAN;
BEGIN
  FOR auth_user IN SELECT * FROM auth.users LOOP
    -- Vérifier s'il existe déjà dans notre table users
    SELECT EXISTS(
      SELECT 1 FROM public.users WHERE id = auth_user.id
    ) INTO user_exists;
    
    IF NOT user_exists THEN
      RAISE NOTICE 'Création de l''utilisateur: %', auth_user.email;
      
      INSERT INTO public.users (
        id,
        first_name,
        last_name,
        email,
        role,
        avatar,
        created_at,
        updated_at
      ) VALUES (
        auth_user.id,
        COALESCE(auth_user.raw_user_meta_data->>'first_name', 'Utilisateur'),
        COALESCE(auth_user.raw_user_meta_data->>'last_name', 'Actuel'),
        auth_user.email,
        'admin',
        NULL,
        auth_user.created_at,
        auth_user.updated_at
      );
    END IF;
  END LOOP;
  
  RAISE NOTICE '✅ Synchronisation terminée';
END $$;
*/

-- 9. Statistiques finales
SELECT 
  'Statistiques finales' as info,
  (SELECT COUNT(*) FROM auth.users) as auth_users_count,
  (SELECT COUNT(*) FROM public.users) as local_users_count,
  (SELECT COUNT(*) FROM auth.users au 
   JOIN public.users pu ON au.id = pu.id) as synchronized_count;

-- 10. Message de confirmation
DO $$
BEGIN
  RAISE NOTICE '🔍 Diagnostic terminé!';
  RAISE NOTICE 'Vérifiez les résultats ci-dessus pour identifier les problèmes.';
  RAISE NOTICE 'Si des utilisateurs manquent, ils seront créés automatiquement.';
END $$;
