-- Diagnostic de la contrainte de rôle dans la table users
-- Ce script va identifier et corriger le problème de contrainte

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

-- 2. Vérifier la contrainte de vérification sur role
SELECT 
  conname as constraint_name,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.users'::regclass
AND contype = 'c';

-- 3. Vérifier les valeurs actuelles dans la colonne role
SELECT DISTINCT role FROM public.users ORDER BY role;

-- 4. Vérifier les contraintes de clé primaire et uniques
SELECT 
  conname as constraint_name,
  contype as constraint_type,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.users'::regclass
AND contype IN ('p', 'u');

-- 5. Lister tous les utilisateurs pour voir les rôles utilisés
SELECT 
  id,
  email,
  role,
  created_at
FROM public.users 
ORDER BY created_at DESC;

-- 6. Tester différentes valeurs de rôle pour identifier les valeurs autorisées
DO $$
DECLARE
  test_roles TEXT[] := ARRAY['admin', 'user', 'manager', 'technician', 'employee', 'staff'];
  test_role TEXT;
  test_result BOOLEAN;
BEGIN
  RAISE NOTICE 'Test des valeurs de rôle autorisées:';
  
  FOREACH test_role IN ARRAY test_roles
  LOOP
    BEGIN
      -- Essayer d'insérer un utilisateur de test avec ce rôle
      INSERT INTO public.users (
        id,
        first_name,
        last_name,
        email,
        role,
        created_at,
        updated_at
      ) VALUES (
        gen_random_uuid(),
        'Test',
        'User',
        'test@example.com',
        test_role,
        NOW(),
        NOW()
      );
      
      RAISE NOTICE '✅ Rôle "%" est autorisé', test_role;
      
      -- Supprimer l'utilisateur de test
      DELETE FROM public.users WHERE email = 'test@example.com';
      
    EXCEPTION WHEN check_violation THEN
      RAISE NOTICE '❌ Rôle "%" n''est PAS autorisé', test_role;
    END;
  END LOOP;
END $$;

-- 7. Vérifier s'il y a des utilisateurs avec des rôles invalides
SELECT 
  id,
  email,
  role,
  created_at
FROM public.users 
WHERE role NOT IN (
  SELECT DISTINCT role FROM public.users WHERE role IS NOT NULL
);

-- 8. Message de diagnostic
DO $$
BEGIN
  RAISE NOTICE '=== DIAGNOSTIC TERMINÉ ===';
  RAISE NOTICE 'Vérifiez les résultats ci-dessus pour identifier les rôles autorisés';
  RAISE NOTICE 'Puis utilisez un rôle autorisé dans le code de création automatique';
END $$;
