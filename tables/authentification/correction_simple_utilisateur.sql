-- Correction simple pour l'utilisateur actuel
-- Version simplifiée sans problèmes de syntaxe

-- 1. Identifier l'utilisateur actuel
SELECT 
  'Utilisateur actuel:' as info,
  auth.uid() as user_id;

-- 2. Vérifier si l'utilisateur existe déjà
SELECT 
  id,
  email,
  role,
  created_at
FROM public.users 
WHERE id = auth.uid();

-- 3. Essayer d'insérer avec le rôle 'admin'
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
  au.id,
  'Utilisateur',
  'Test',
  au.email,
  'admin',
  NOW(),
  NOW()
FROM auth.users au
WHERE au.id = auth.uid()
AND NOT EXISTS (
  SELECT 1 FROM public.users pu WHERE pu.id = au.id
);

-- 4. Si 'admin' ne fonctionne pas, essayer avec 'manager'
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
  au.id,
  'Utilisateur',
  'Test',
  au.email,
  'manager',
  NOW(),
  NOW()
FROM auth.users au
WHERE au.id = auth.uid()
AND NOT EXISTS (
  SELECT 1 FROM public.users pu WHERE pu.id = au.id
);

-- 5. Si 'manager' ne fonctionne pas, essayer avec 'technician'
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
  au.id,
  'Utilisateur',
  'Test',
  au.email,
  'technician',
  NOW(),
  NOW()
FROM auth.users au
WHERE au.id = auth.uid()
AND NOT EXISTS (
  SELECT 1 FROM public.users pu WHERE pu.id = au.id
);

-- 6. Vérifier le résultat final
SELECT 
  'Résultat final:' as info,
  id,
  email,
  role,
  created_at
FROM public.users 
WHERE id = auth.uid();
