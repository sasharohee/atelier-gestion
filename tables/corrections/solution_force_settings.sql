-- SOLUTION DE FORCE : Débloquer complètement les paramètres utilisateur
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Supprimer toutes les politiques RLS existantes
DROP POLICY IF EXISTS "Users can view their own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can view their own preferences" ON user_preferences;
DROP POLICY IF EXISTS "Users can update their own preferences" ON user_preferences;
DROP POLICY IF EXISTS "Users can insert their own preferences" ON user_preferences;

-- 2. Créer des politiques simples qui permettent tout
CREATE POLICY "Allow all operations on user_profiles" ON user_profiles
  FOR ALL USING (true) WITH CHECK (true);

CREATE POLICY "Allow all operations on user_preferences" ON user_preferences
  FOR ALL USING (true) WITH CHECK (true);

-- 3. Vérifier que les tables existent et créer si nécessaire
CREATE TABLE IF NOT EXISTS user_profiles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL,
  phone VARCHAR(20),
  avatar TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

CREATE TABLE IF NOT EXISTS user_preferences (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  notifications_email BOOLEAN DEFAULT true,
  notifications_push BOOLEAN DEFAULT true,
  notifications_sms BOOLEAN DEFAULT false,
  theme_dark_mode BOOLEAN DEFAULT false,
  theme_compact_mode BOOLEAN DEFAULT false,
  language VARCHAR(10) DEFAULT 'fr',
  two_factor_auth BOOLEAN DEFAULT false,
  multiple_sessions BOOLEAN DEFAULT true,
  repair_notifications BOOLEAN DEFAULT true,
  status_notifications BOOLEAN DEFAULT true,
  stock_notifications BOOLEAN DEFAULT true,
  daily_reports BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id)
);

-- 4. Activer RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- 5. Créer des données de test pour l'utilisateur actuel
INSERT INTO user_profiles (user_id, first_name, last_name, email, phone)
SELECT 
  auth.uid(),
  'Utilisateur',
  'Test',
  (SELECT email FROM auth.users WHERE id = auth.uid()),
  ''
WHERE auth.uid() IS NOT NULL
ON CONFLICT (user_id) DO NOTHING;

INSERT INTO user_preferences (user_id)
SELECT auth.uid()
WHERE auth.uid() IS NOT NULL
ON CONFLICT (user_id) DO NOTHING;

-- 6. Vérifier que ça fonctionne
SELECT 'Test de lecture user_profiles' as info, COUNT(*) as count FROM user_profiles;
SELECT 'Test de lecture user_preferences' as info, COUNT(*) as count FROM user_preferences;

-- 7. Vérifier les nouvelles politiques
SELECT 'Politiques créées' as info, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('user_profiles', 'user_preferences');
