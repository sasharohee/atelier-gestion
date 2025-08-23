-- Correction du trigger set_workshop_context qui cause une erreur
-- Le trigger essaie d'accéder à un champ created_by qui n'existe pas

-- 1. Supprimer le trigger problématique
DROP TRIGGER IF EXISTS set_workshop_context_trigger ON users;
DROP FUNCTION IF EXISTS set_workshop_context();

-- 2. Vérifier s'il y a d'autres triggers problématiques
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'users';

-- 3. Supprimer tous les triggers sur la table users pour éviter les conflits
DROP TRIGGER IF EXISTS create_user_profile_trigger ON users;
DROP FUNCTION IF EXISTS create_user_profile_trigger();

-- 4. Recréer le trigger simplifié pour la création de profils
CREATE OR REPLACE FUNCTION create_user_profile_trigger()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Créer automatiquement un profil utilisateur
  INSERT INTO user_profiles (user_id, first_name, last_name, email, created_at, updated_at)
  VALUES (
    NEW.id,
    NEW.first_name,
    NEW.last_name,
    NEW.email,
    NOW(),
    NOW()
  )
  ON CONFLICT (user_id) DO NOTHING;

  -- Créer automatiquement des préférences utilisateur par défaut
  INSERT INTO user_preferences (user_id, created_at, updated_at)
  VALUES (
    NEW.id,
    NOW(),
    NOW()
  )
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$;

-- 5. Attacher le trigger à la table users
CREATE TRIGGER create_user_profile_trigger
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION create_user_profile_trigger();

-- 6. Vérifier que le trigger est bien créé
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'users';

-- 7. Tester la fonction RPC
SELECT 'Test de la fonction RPC' as test,
       create_user_automatically(
         gen_random_uuid(),
         'Test',
         'Trigger',
         'test.trigger@example.com',
         'technician'
       ) as result;

-- 8. Nettoyer le test
DELETE FROM users WHERE email = 'test.trigger@example.com';

SELECT 'Correction du trigger terminée.' as status;
