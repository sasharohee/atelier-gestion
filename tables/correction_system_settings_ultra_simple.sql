-- Correction ultra simple de system_settings
-- Version minimale sans contraintes ni données par défaut

-- 1. AJOUTER LES COLONNES MANQUANTES
ALTER TABLE system_settings ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
ALTER TABLE system_settings ADD COLUMN IF NOT EXISTS category VARCHAR(50);
ALTER TABLE system_settings ADD COLUMN IF NOT EXISTS key VARCHAR(100);
ALTER TABLE system_settings ADD COLUMN IF NOT EXISTS value TEXT;
ALTER TABLE system_settings ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE system_settings ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE system_settings ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 2. CRÉER LES INDEX
CREATE INDEX IF NOT EXISTS idx_system_settings_user_id ON system_settings(user_id);
CREATE INDEX IF NOT EXISTS idx_system_settings_category ON system_settings(category);
CREATE INDEX IF NOT EXISTS idx_system_settings_key ON system_settings(key);

-- 3. VÉRIFIER
SELECT 'Structure system_settings corrigée !' as message;
