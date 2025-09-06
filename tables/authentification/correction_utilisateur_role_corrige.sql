-- Correction pour l'utilisateur manquant avec le bon rôle
-- Exécuter ce script dans l'éditeur SQL Supabase

-- Insérer l'utilisateur avec le rôle 'admin' (probablement la valeur autorisée)
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
  'Utilisateur',
  'Test',
  'test27@yopmail.com',
  'admin',
  NOW(),
  NOW()
) ON CONFLICT (id) DO NOTHING;

-- Vérifier que l'insertion a fonctionné
SELECT 
  id,
  first_name,
  last_name,
  email,
  role
FROM public.users 
WHERE id = '14577c87-1336-476b-9747-aa16f8413bfe';

-- Alternative : essayer avec 'manager' si 'admin' ne fonctionne pas
-- Décommentez les lignes ci-dessous si 'admin' échoue
/*
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
  'Utilisateur',
  'Test',
  'test27@yopmail.com',
  'manager',
  NOW(),
  NOW()
) ON CONFLICT (id) DO NOTHING;
*/
