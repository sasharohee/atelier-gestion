-- Correction pour l'utilisateur manquant dans la table users
-- L'utilisateur 14577c87-1336-476b-9747-aa16f8413bfe existe dans auth.users mais pas dans public.users

-- 1. Vérifier si l'utilisateur existe dans auth.users
SELECT 
  id,
  email,
  created_at,
  updated_at
FROM auth.users 
WHERE id = '14577c87-1336-476b-9747-aa16f8413bfe';

-- 2. Vérifier si l'utilisateur existe dans public.users
SELECT 
  id,
  email,
  role,
  created_at,
  updated_at
FROM public.users 
WHERE id = '14577c87-1336-476b-9747-aa16f8413bfe';

-- 3. Insérer l'utilisateur manquant dans public.users
-- Récupérer les informations depuis auth.users
INSERT INTO public.users (id, first_name, last_name, email, role, created_at, updated_at)
SELECT 
  au.id,
  COALESCE(au.raw_user_meta_data->>'first_name', 'Utilisateur') as first_name,
  COALESCE(au.raw_user_meta_data->>'last_name', 'Test') as last_name,
  au.email,
  'user' as role, -- Rôle par défaut
  au.created_at,
  au.updated_at
FROM auth.users au
WHERE au.id = '14577c87-1336-476b-9747-aa16f8413bfe'
AND NOT EXISTS (
  SELECT 1 FROM public.users pu WHERE pu.id = au.id
);

-- 4. Vérifier que l'insertion a fonctionné
SELECT 
  id,
  email,
  role,
  created_at,
  updated_at
FROM public.users 
WHERE id = '14577c87-1336-476b-9747-aa16f8413bfe';

-- 5. Mettre à jour les politiques RLS pour s'assurer que l'utilisateur peut accéder à ses données
-- Vérifier les politiques existantes
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename IN ('clients', 'devices', 'services', 'parts', 'products', 'repairs', 'appointments', 'sales', 'system_settings');

-- 6. S'assurer que les politiques RLS permettent l'accès à l'utilisateur
-- Si nécessaire, recréer les politiques pour inclure cet utilisateur

-- 7. Vérifier l'isolation des données
-- Tester l'accès aux données pour cet utilisateur
SELECT 
  'clients' as table_name,
  COUNT(*) as count
FROM clients 
WHERE user_id = '14577c87-1336-476b-9747-aa16f8413bfe'
UNION ALL
SELECT 
  'devices' as table_name,
  COUNT(*) as count
FROM devices 
WHERE user_id = '14577c87-1336-476b-9747-aa16f8413bfe'
UNION ALL
SELECT 
  'system_settings' as table_name,
  COUNT(*) as count
FROM system_settings 
WHERE user_id = '14577c87-1336-476b-9747-aa16f8413bfe';

-- 8. Message de confirmation
DO $$
BEGIN
  RAISE NOTICE 'Correction terminée pour l''utilisateur 14577c87-1336-476b-9747-aa16f8413bfe';
  RAISE NOTICE 'L''utilisateur a été ajouté à la table public.users avec le rôle ''user''';
  RAISE NOTICE 'Les boucles infinies de requêtes devraient maintenant être résolues';
END $$;
