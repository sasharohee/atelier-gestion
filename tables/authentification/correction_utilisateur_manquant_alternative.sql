-- Correction alternative pour l'utilisateur manquant dans la table users
-- Version qui gère les contraintes NOT NULL sur first_name et last_name

-- 1. Vérifier la structure de la table users
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Vérifier si l'utilisateur existe dans auth.users
SELECT 
  id,
  email,
  raw_user_meta_data,
  created_at,
  updated_at
FROM auth.users 
WHERE id = '14577c87-1336-476b-9747-aa16f8413bfe';

-- 3. Insérer l'utilisateur manquant avec des valeurs par défaut
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
  CASE 
    WHEN au.raw_user_meta_data->>'first_name' IS NOT NULL 
    THEN au.raw_user_meta_data->>'first_name'
    ELSE 'Utilisateur'
  END as first_name,
  CASE 
    WHEN au.raw_user_meta_data->>'last_name' IS NOT NULL 
    THEN au.raw_user_meta_data->>'last_name'
    ELSE 'Test'
  END as last_name,
  au.email,
  'user' as role,
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
  first_name,
  last_name,
  email,
  role,
  created_at,
  updated_at
FROM public.users 
WHERE id = '14577c87-1336-476b-9747-aa16f8413bfe';

-- 5. Si l'insertion a échoué, essayer avec des valeurs encore plus simples
-- (Script de secours)
DO $$
BEGIN
  -- Vérifier si l'utilisateur existe maintenant
  IF NOT EXISTS (
    SELECT 1 FROM public.users WHERE id = '14577c87-1336-476b-9747-aa16f8413bfe'
  ) THEN
    -- Insérer avec des valeurs minimales
    INSERT INTO public.users (
      id, 
      first_name, 
      last_name, 
      email, 
      role, 
      created_at, 
      updated_at
    ) VALUES (
      '14577c87-1336-476b-9747-aa16f8413bfe',
      'User',
      'Test',
      'test27@yopmail.com',
      'user',
      NOW(),
      NOW()
    );
    
    RAISE NOTICE 'Utilisateur créé avec des valeurs par défaut';
  ELSE
    RAISE NOTICE 'Utilisateur existe déjà';
  END IF;
END $$;

-- 6. Vérification finale
SELECT 
  'Utilisateur créé avec succès' as status,
  id,
  first_name,
  last_name,
  email,
  role
FROM public.users 
WHERE id = '14577c87-1336-476b-9747-aa16f8413bfe';
