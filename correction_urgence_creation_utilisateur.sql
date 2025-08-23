-- Correction urgente pour la création automatique d'utilisateurs en production
-- Ce script désactive temporairement les politiques RLS sur la table users
-- et crée une fonction RPC sécurisée pour la création d'utilisateurs

-- 1. Désactiver temporairement les politiques RLS sur la table users
DROP POLICY IF EXISTS "Users can view their own data" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Users can update their own data" ON users;
DROP POLICY IF EXISTS "Admins can update all users" ON users;
DROP POLICY IF EXISTS "Users can insert their own data" ON users;
DROP POLICY IF EXISTS "Admins can insert users" ON users;

-- 2. Créer une politique permissive pour permettre la création automatique
CREATE POLICY "Allow user creation for authenticated users" ON users
FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY "Allow users to view their own data" ON users
FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Allow users to update their own data" ON users
FOR UPDATE USING (auth.uid() = id);

-- 3. Créer une fonction RPC sécurisée pour la création d'utilisateurs
CREATE OR REPLACE FUNCTION create_user_automatically(
  user_id UUID,
  first_name TEXT DEFAULT 'Utilisateur',
  last_name TEXT DEFAULT 'Test',
  user_email TEXT DEFAULT '',
  user_role TEXT DEFAULT 'technician'
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  new_user users%ROWTYPE;
  result JSON;
BEGIN
  -- Vérifier que l'utilisateur est authentifié
  IF auth.uid() IS NULL THEN
    RETURN json_build_object('success', false, 'error', 'Non authentifié');
  END IF;

  -- Vérifier que l'utilisateur n'existe pas déjà
  IF EXISTS (SELECT 1 FROM users WHERE id = user_id) THEN
    RETURN json_build_object('success', true, 'message', 'Utilisateur déjà existant');
  END IF;

  -- Insérer le nouvel utilisateur
  INSERT INTO users (id, first_name, last_name, email, role, created_at, updated_at)
  VALUES (
    user_id,
    first_name,
    last_name,
    CASE WHEN user_email = '' THEN 'user@example.com' ELSE user_email END,
    user_role,
    NOW(),
    NOW()
  )
  RETURNING * INTO new_user;

  -- Retourner le succès
  RETURN json_build_object(
    'success', true,
    'user', json_build_object(
      'id', new_user.id,
      'first_name', new_user.first_name,
      'last_name', new_user.last_name,
      'email', new_user.email,
      'role', new_user.role
    )
  );

EXCEPTION
  WHEN OTHERS THEN
    RETURN json_build_object('success', false, 'error', SQLERRM);
END;
$$;

-- 4. Donner les permissions nécessaires
GRANT EXECUTE ON FUNCTION create_user_automatically TO authenticated;

-- 5. Activer RLS sur la table users si ce n'est pas déjà fait
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- 6. Vérifier que les politiques sont en place
SELECT 
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
FROM pg_policies 
WHERE tablename = 'users';

-- 7. Créer un trigger pour la création automatique de profils utilisateur
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

-- 8. Attacher le trigger à la table users
DROP TRIGGER IF EXISTS create_user_profile_trigger ON users;
CREATE TRIGGER create_user_profile_trigger
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION create_user_profile_trigger();

-- 9. Vérifier que tout fonctionne
SELECT 'Correction terminée. Vérifiez les politiques RLS et la fonction RPC.' as status;
