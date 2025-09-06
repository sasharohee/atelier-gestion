-- Correction pour le nouvel utilisateur manquant
-- Utilisateur: c1502137-0e31-4354-ab06-eacdf7aa686a

-- 1. Vérifier si l'utilisateur existe dans auth.users
SELECT 
  id,
  email,
  raw_user_meta_data,
  created_at,
  updated_at
FROM auth.users 
WHERE id = 'c1502137-0e31-4354-ab06-eacdf7aa686a';

-- 2. Insérer l'utilisateur manquant
INSERT INTO public.users (
  id, 
  first_name, 
  last_name, 
  email, 
  role, 
  created_at, 
  updated_at
) VALUES (
  'c1502137-0e31-4354-ab06-eacdf7aa686a',
  'Utilisateur',
  'Test',
  'test27@yopmail.com',
  'admin',
  NOW(),
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- 3. Vérifier que l'insertion a fonctionné
SELECT 
  id,
  first_name,
  last_name,
  email,
  role,
  created_at
FROM public.users 
WHERE id = 'c1502137-0e31-4354-ab06-eacdf7aa686a';
