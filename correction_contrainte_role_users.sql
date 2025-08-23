-- Correction de la contrainte de rôle dans la table users
-- Le problème vient de la contrainte "users_role_check" qui limite les rôles autorisés

-- 1. Vérifier la contrainte actuelle
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'users'::regclass 
AND conname = 'users_role_check';

-- 2. Supprimer la contrainte existante
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;

-- 3. Créer une nouvelle contrainte qui accepte tous les rôles nécessaires
ALTER TABLE users ADD CONSTRAINT users_role_check 
CHECK (role IN ('admin', 'manager', 'technician', 'user', 'client'));

-- 4. Vérifier que la contrainte est bien en place
SELECT 
    conname as constraint_name,
    pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'users'::regclass 
AND conname = 'users_role_check';

-- 5. Tester la fonction RPC avec différents rôles
SELECT 'Test avec rôle technician' as test, 
       create_user_automatically(
         gen_random_uuid(),
         'Test',
         'Technician',
         'tech@test.com',
         'technician'
       ) as result;

SELECT 'Test avec rôle manager' as test, 
       create_user_automatically(
         gen_random_uuid(),
         'Test',
         'Manager',
         'manager@test.com',
         'manager'
       ) as result;

SELECT 'Test avec rôle admin' as test, 
       create_user_automatically(
         gen_random_uuid(),
         'Test',
         'Admin',
         'admin@test.com',
         'admin'
       ) as result;

-- 6. Vérifier que les politiques RLS sont toujours en place
SELECT 
  policyname,
  permissive,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'users';

-- 7. Nettoyer les utilisateurs de test créés
DELETE FROM users WHERE email LIKE '%@test.com';

SELECT 'Correction de la contrainte de rôle terminée.' as status;
