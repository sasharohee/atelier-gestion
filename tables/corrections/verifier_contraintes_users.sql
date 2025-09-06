-- Vérifier les contraintes de la table users
-- Exécuter ce script pour comprendre les contraintes

-- 1. Vérifier la structure complète de la table
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Vérifier les contraintes de vérification
SELECT 
  conname as constraint_name,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.users'::regclass
AND contype = 'c';

-- 3. Vérifier les contraintes de clé primaire et uniques
SELECT 
  conname as constraint_name,
  contype as constraint_type,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.users'::regclass
AND contype IN ('p', 'u');

-- 4. Vérifier les valeurs actuelles dans la colonne role
SELECT DISTINCT role FROM public.users ORDER BY role;

-- 5. Vérifier les contraintes de clé étrangère
SELECT 
  conname as constraint_name,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.users'::regclass
AND contype = 'f';
