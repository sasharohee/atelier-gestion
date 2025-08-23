-- Création de la table users pour l'administration
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name TEXT NOT NULL,
  last_name TEXT NOT NULL,
  email TEXT NOT NULL UNIQUE,
  role TEXT NOT NULL DEFAULT 'technician' CHECK (role IN ('admin', 'manager', 'technician')),
  avatar TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Création d'un index sur l'email pour les recherches rapides
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Création d'un index sur le rôle pour les filtres
CREATE INDEX IF NOT EXISTS idx_users_role ON users(role);

-- Fonction pour mettre à jour automatiquement updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger pour mettre à jour automatiquement updated_at
CREATE TRIGGER update_users_updated_at 
  BEFORE UPDATE ON users 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- Politique RLS (Row Level Security) pour les utilisateurs
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Politique pour permettre aux administrateurs de voir tous les utilisateurs
CREATE POLICY "Admins can view all users" ON users
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Politique pour permettre aux administrateurs de modifier tous les utilisateurs
CREATE POLICY "Admins can update all users" ON users
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Politique pour permettre aux administrateurs de créer des utilisateurs
CREATE POLICY "Admins can create users" ON users
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Politique pour permettre aux administrateurs de supprimer des utilisateurs
CREATE POLICY "Admins can delete users" ON users
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Politique pour permettre aux utilisateurs de voir leur propre profil
CREATE POLICY "Users can view own profile" ON users
  FOR SELECT USING (auth.uid() = id);

-- Politique pour permettre aux utilisateurs de modifier leur propre profil
CREATE POLICY "Users can update own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

-- Insertion d'un utilisateur administrateur par défaut (si nécessaire)
-- Note: Cet utilisateur doit déjà exister dans auth.users
-- INSERT INTO users (id, first_name, last_name, email, role) 
-- VALUES ('user-uuid-here', 'Admin', 'System', 'admin@atelier.fr', 'admin')
-- ON CONFLICT (id) DO NOTHING;
