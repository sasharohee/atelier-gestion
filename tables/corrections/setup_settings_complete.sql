-- SCRIPT COMPLET POUR CONFIGURER LA PAGE DES RÉGLAGES
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. CRÉATION DES TABLES UTILISATEUR

-- Table des profils utilisateur
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

-- Table des préférences utilisateur
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

-- 2. CRÉATION DE LA TABLE SYSTEM_SETTINGS

CREATE TABLE IF NOT EXISTS system_settings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  key VARCHAR(100) UNIQUE NOT NULL,
  value TEXT NOT NULL,
  description TEXT,
  category VARCHAR(50) DEFAULT 'general',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. CRÉATION DES INDEX

CREATE INDEX IF NOT EXISTS idx_user_profiles_user_id ON user_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_user_preferences_user_id ON user_preferences(user_id);
CREATE INDEX IF NOT EXISTS idx_system_settings_key ON system_settings(key);
CREATE INDEX IF NOT EXISTS idx_system_settings_category ON system_settings(category);

-- 4. CRÉATION DES TRIGGERS POUR UPDATED_AT

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_user_profiles_updated_at
    BEFORE UPDATE ON user_profiles
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_user_preferences_updated_at
    BEFORE UPDATE ON user_preferences
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_system_settings_updated_at
    BEFORE UPDATE ON system_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- 5. CONFIGURATION RLS (Row Level Security)

-- Activer RLS sur toutes les tables
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- 6. SUPPRESSION DES ANCIENNES POLITIQUES

-- User profiles
DROP POLICY IF EXISTS "Users can view their own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON user_profiles;
DROP POLICY IF EXISTS "Users can insert their own profile" ON user_profiles;
DROP POLICY IF EXISTS "Allow all operations on user_profiles" ON user_profiles;

-- User preferences
DROP POLICY IF EXISTS "Users can view their own preferences" ON user_preferences;
DROP POLICY IF EXISTS "Users can update their own preferences" ON user_preferences;
DROP POLICY IF EXISTS "Users can insert their own preferences" ON user_preferences;
DROP POLICY IF EXISTS "Allow all operations on user_preferences" ON user_preferences;

-- System settings
DROP POLICY IF EXISTS "Admins can view system settings" ON system_settings;
DROP POLICY IF EXISTS "Admins can update system settings" ON system_settings;
DROP POLICY IF EXISTS "Admins can create system settings" ON system_settings;
DROP POLICY IF EXISTS "Admins can delete system settings" ON system_settings;
DROP POLICY IF EXISTS "Allow read for authenticated users" ON system_settings;
DROP POLICY IF EXISTS "Allow update for admins" ON system_settings;
DROP POLICY IF EXISTS "Allow insert for admins" ON system_settings;
DROP POLICY IF EXISTS "Allow delete for admins" ON system_settings;
DROP POLICY IF EXISTS "Allow all operations" ON system_settings;
DROP POLICY IF EXISTS "Temporary allow all" ON system_settings;

-- 7. CRÉATION DES NOUVELLES POLITIQUES SIMPLES

-- Politiques pour user_profiles
CREATE POLICY "Allow all operations on user_profiles" ON user_profiles
  FOR ALL USING (true) WITH CHECK (true);

-- Politiques pour user_preferences
CREATE POLICY "Allow all operations on user_preferences" ON user_preferences
  FOR ALL USING (true) WITH CHECK (true);

-- Politiques pour system_settings
CREATE POLICY "Allow all operations on system_settings" ON system_settings
  FOR ALL USING (true) WITH CHECK (true);

-- 8. INSERTION DES DONNÉES PAR DÉFAUT

-- Données système par défaut
INSERT INTO system_settings (key, value, description, category) VALUES
  ('workshop_name', 'Atelier de réparation', 'Nom de l''atelier', 'general'),
  ('workshop_address', '123 Rue de la Paix, 75001 Paris', 'Adresse de l''atelier', 'general'),
  ('workshop_phone', '01 23 45 67 89', 'Numéro de téléphone de contact', 'general'),
  ('workshop_email', 'contact@atelier.fr', 'Adresse email de contact', 'general'),
  ('vat_rate', '20', 'Taux de TVA en pourcentage', 'billing'),
  ('currency', 'EUR', 'Devise utilisée pour les factures', 'billing'),
  ('invoice_prefix', 'FACT-', 'Préfixe pour les numéros de facture', 'billing'),
  ('date_format', 'dd/MM/yyyy', 'Format d''affichage des dates', 'billing'),
  ('auto_backup', 'true', 'Activer la sauvegarde automatique', 'system'),
  ('notifications', 'true', 'Activer les notifications', 'system'),
  ('backup_frequency', 'daily', 'Fréquence de sauvegarde', 'system'),
  ('max_file_size', '10', 'Taille maximale des fichiers en MB', 'system')
ON CONFLICT (key) DO UPDATE SET
  value = EXCLUDED.value,
  description = EXCLUDED.description,
  category = EXCLUDED.category,
  updated_at = NOW();

-- 9. CRÉATION AUTOMATIQUE DES PROFILS ET PRÉFÉRENCES POUR L'UTILISATEUR ACTUEL

-- Créer le profil utilisateur s'il n'existe pas
INSERT INTO user_profiles (user_id, first_name, last_name, email, phone)
SELECT 
  auth.uid(),
  COALESCE((SELECT user_metadata->>'firstName' FROM auth.users WHERE id = auth.uid()), 'Utilisateur'),
  COALESCE((SELECT user_metadata->>'lastName' FROM auth.users WHERE id = auth.uid()), 'Test'),
  (SELECT email FROM auth.users WHERE id = auth.uid()),
  ''
WHERE auth.uid() IS NOT NULL
ON CONFLICT (user_id) DO UPDATE SET
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name,
  email = EXCLUDED.email,
  phone = EXCLUDED.phone,
  updated_at = NOW();

-- Créer les préférences utilisateur s'il n'existent pas
INSERT INTO user_preferences (user_id)
SELECT auth.uid()
WHERE auth.uid() IS NOT NULL
ON CONFLICT (user_id) DO NOTHING;

-- 10. VÉRIFICATIONS FINALES

-- Vérifier que les tables existent
SELECT 'Tables créées' as info, 
       (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'user_profiles') as user_profiles,
       (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'user_preferences') as user_preferences,
       (SELECT COUNT(*) FROM information_schema.tables WHERE table_name = 'system_settings') as system_settings;

-- Vérifier le contenu des tables
SELECT 'Contenu user_profiles' as info, COUNT(*) as count FROM user_profiles;
SELECT 'Contenu user_preferences' as info, COUNT(*) as count FROM user_preferences;
SELECT 'Contenu system_settings' as info, COUNT(*) as count FROM system_settings;

-- Vérifier les politiques RLS
SELECT 'Politiques RLS' as info, tablename, policyname, permissive, cmd
FROM pg_policies 
WHERE tablename IN ('user_profiles', 'user_preferences', 'system_settings')
ORDER BY tablename, policyname;

-- Afficher les paramètres système
SELECT 'Paramètres système' as info, key, value, category 
FROM system_settings 
ORDER BY category, key;

-- Message de succès
SELECT '✅ Configuration terminée avec succès !' as status;
