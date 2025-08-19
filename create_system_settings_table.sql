-- Création de la table system_settings pour les paramètres système
CREATE TABLE IF NOT EXISTS system_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT NOT NULL UNIQUE,
  value TEXT,
  description TEXT,
  category TEXT NOT NULL DEFAULT 'general',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Création d'un index sur la clé pour les recherches rapides
CREATE INDEX IF NOT EXISTS idx_system_settings_key ON system_settings(key);

-- Création d'un index sur la catégorie pour les filtres
CREATE INDEX IF NOT EXISTS idx_system_settings_category ON system_settings(category);

-- Trigger pour mettre à jour automatiquement updated_at
CREATE TRIGGER update_system_settings_updated_at 
  BEFORE UPDATE ON system_settings 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- Politique RLS (Row Level Security) pour les paramètres système
ALTER TABLE system_settings ENABLE ROW LEVEL SECURITY;

-- Politique pour permettre aux administrateurs de voir tous les paramètres
CREATE POLICY "Admins can view system settings" ON system_settings
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Politique pour permettre aux administrateurs de modifier tous les paramètres
CREATE POLICY "Admins can update system settings" ON system_settings
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Politique pour permettre aux administrateurs de créer des paramètres
CREATE POLICY "Admins can create system settings" ON system_settings
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Politique pour permettre aux administrateurs de supprimer des paramètres
CREATE POLICY "Admins can delete system settings" ON system_settings
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM users 
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

-- Insertion des paramètres par défaut
INSERT INTO system_settings (key, value, description, category) VALUES
-- Paramètres généraux
('workshop_name', 'Atelier de réparation', 'Nom de l''atelier affiché dans l''application', 'general'),
('workshop_address', '123 Rue de la Paix, 75001 Paris', 'Adresse de l''atelier', 'general'),
('workshop_phone', '01 23 45 67 89', 'Numéro de téléphone de contact', 'general'),
('workshop_email', 'contact@atelier.fr', 'Adresse email de contact', 'general'),

-- Paramètres de facturation
('vat_rate', '20', 'Taux de TVA en pourcentage', 'billing'),
('currency', 'EUR', 'Devise utilisée pour les factures', 'billing'),
('invoice_prefix', 'FACT-', 'Préfixe pour les numéros de facture', 'billing'),
('date_format', 'dd/MM/yyyy', 'Format d''affichage des dates', 'billing'),

-- Paramètres système
('auto_backup', 'true', 'Activer la sauvegarde automatique', 'system'),
('notifications', 'true', 'Activer les notifications', 'system'),
('backup_frequency', 'daily', 'Fréquence de sauvegarde (daily, weekly, monthly)', 'system'),
('max_file_size', '10', 'Taille maximale des fichiers en MB', 'system')

ON CONFLICT (key) DO UPDATE SET
  value = EXCLUDED.value,
  description = EXCLUDED.description,
  category = EXCLUDED.category,
  updated_at = NOW();
