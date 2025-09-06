-- Correction rapide pour l'utilisateur actuel
-- Ce script corrige le problème de contrainte de rôle

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

-- 3. Essayer d'insérer l'utilisateur avec différents rôles
DO $$
DECLARE
  current_user_id UUID;
  current_user_email TEXT;
  roles_to_try TEXT[] := ARRAY['admin', 'manager', 'technician', 'user'];
  test_role TEXT;
  success BOOLEAN := FALSE;
BEGIN
  -- Récupérer l'utilisateur actuel
  SELECT auth.uid() INTO current_user_id;
  SELECT email INTO current_user_email FROM auth.users WHERE id = current_user_id;
  
  IF current_user_id IS NULL THEN
    RAISE NOTICE '❌ Aucun utilisateur connecté';
    RETURN;
  END IF;
  
  RAISE NOTICE 'Tentative de création pour l''utilisateur: %', current_user_email;
  
  -- Essayer chaque rôle
  FOREACH test_role IN ARRAY roles_to_try
  LOOP
    IF NOT success THEN
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
          current_user_id,
          'Utilisateur',
          'Test',
          current_user_email,
          test_role,
          NOW(),
          NOW()
        );
        
        RAISE NOTICE '✅ Utilisateur créé avec succès avec le rôle: %', test_role;
        success := TRUE;
        
      EXCEPTION 
        WHEN check_violation THEN
          RAISE NOTICE '❌ Rôle "%" non autorisé', test_role;
        WHEN unique_violation THEN
          RAISE NOTICE '⚠️ Utilisateur existe déjà';
          success := TRUE;
        WHEN OTHERS THEN
          RAISE NOTICE '❌ Erreur inattendue avec le rôle "%": %', test_role, SQLERRM;
      END;
    END IF;
  END LOOP;
  
  IF NOT success THEN
    RAISE NOTICE '❌ Aucun rôle autorisé trouvé pour créer l''utilisateur';
  END IF;
END $$;

-- 4. Vérifier le résultat
SELECT 
  'Résultat final:' as info,
  id,
  email,
  role,
  created_at
FROM public.users 
WHERE id = auth.uid();
