-- Script pour ajouter l'isolation des données par utilisateur créateur

-- 1. Ajouter la colonne created_by à la table users
ALTER TABLE users ADD COLUMN IF NOT EXISTS created_by UUID REFERENCES auth.users(id);

-- 2. Mettre à jour les enregistrements existants avec l'ID de l'utilisateur actuel
-- (à exécuter manuellement pour chaque utilisateur existant)
-- UPDATE users SET created_by = id WHERE created_by IS NULL;

-- 3. Supprimer les anciennes politiques RLS
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Admins can update all users" ON users;
DROP POLICY IF EXISTS "Admins can create users" ON users;
DROP POLICY IF EXISTS "Admins can delete users" ON users;
DROP POLICY IF EXISTS "Users can view own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;

-- 4. Créer de nouvelles politiques RLS avec isolation
-- Politique pour permettre aux utilisateurs de voir leur propre profil
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth.uid() = id);

-- Politique pour permettre aux utilisateurs de modifier leur propre profil
CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

-- Politique pour permettre aux utilisateurs de voir les utilisateurs qu'ils ont créés
CREATE POLICY "Users can view created users" ON users
  FOR SELECT USING (created_by = auth.uid());

-- Politique pour permettre aux utilisateurs de modifier les utilisateurs qu'ils ont créés
CREATE POLICY "Users can update created users" ON users
  FOR UPDATE USING (created_by = auth.uid());

-- Politique pour permettre aux utilisateurs de supprimer les utilisateurs qu'ils ont créés
CREATE POLICY "Users can delete created users" ON users
  FOR DELETE USING (created_by = auth.uid());

-- Politique pour permettre aux utilisateurs de créer des utilisateurs
CREATE POLICY "Users can create users" ON users
  FOR INSERT WITH CHECK (auth.uid() = created_by);

-- 5. Créer un index sur created_by pour les performances
CREATE INDEX IF NOT EXISTS idx_users_created_by ON users(created_by);

-- 6. Fonction pour obtenir les utilisateurs créés par l'utilisateur actuel
CREATE OR REPLACE FUNCTION get_my_users()
RETURNS TABLE (
  id UUID,
  first_name TEXT,
  last_name TEXT,
  email TEXT,
  role TEXT,
  avatar TEXT,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT 
    u.id,
    u.first_name,
    u.last_name,
    u.email,
    u.role,
    u.avatar,
    u.created_at,
    u.updated_at
  FROM users u
  WHERE u.created_by = auth.uid()
  ORDER BY u.created_at DESC;
END;
$$;

-- 7. Donner les permissions d'exécution
GRANT EXECUTE ON FUNCTION get_my_users() TO authenticated;
