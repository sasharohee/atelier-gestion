-- Correction définitive pour l'utilisateur manquant
-- Ce script vérifie d'abord les contraintes puis corrige le problème

-- ÉTAPE 1 : Vérifier les contraintes de la table users
SELECT 
  conname as constraint_name,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'public.users'::regclass
AND contype = 'c';

-- ÉTAPE 2 : Vérifier les valeurs actuelles dans la colonne role
SELECT DISTINCT role FROM public.users ORDER BY role;

-- ÉTAPE 3 : Vérifier la structure de la table
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- ÉTAPE 4 : Essayer différentes valeurs de rôle
-- Commençons par 'admin'
DO $$
BEGIN
  -- Essayer avec 'admin'
  BEGIN
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
    );
    RAISE NOTICE 'Utilisateur créé avec le rôle admin';
  EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'admin non autorisé, essai avec manager';
    
    -- Essayer avec 'manager'
    BEGIN
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
      );
      RAISE NOTICE 'Utilisateur créé avec le rôle manager';
    EXCEPTION WHEN check_violation THEN
      RAISE NOTICE 'manager non autorisé, essai avec technician';
      
      -- Essayer avec 'technician'
      BEGIN
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
          'technician',
          NOW(),
          NOW()
        );
        RAISE NOTICE 'Utilisateur créé avec le rôle technician';
      EXCEPTION WHEN check_violation THEN
        RAISE NOTICE 'Aucun rôle standard ne fonctionne. Vérifiez les contraintes.';
      END;
    END;
  END;
END $$;

-- ÉTAPE 5 : Vérifier le résultat
SELECT 
  id,
  first_name,
  last_name,
  email,
  role
FROM public.users 
WHERE id = '14577c87-1336-476b-9747-aa16f8413bfe';
