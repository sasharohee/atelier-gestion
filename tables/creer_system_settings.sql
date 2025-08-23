-- CRÉATION ET PEUPLEMENT DE LA TABLE SYSTEM_SETTINGS
-- Ce script crée la table et ajoute les paramètres par défaut

-- 1. CRÉER LA TABLE SI ELLE N'EXISTE PAS
CREATE TABLE IF NOT EXISTS public.system_settings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key TEXT NOT NULL UNIQUE,
  value TEXT,
  description TEXT,
  category TEXT NOT NULL DEFAULT 'general',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. CRÉER LES INDEX
CREATE INDEX IF NOT EXISTS idx_system_settings_key ON public.system_settings(key);
CREATE INDEX IF NOT EXISTS idx_system_settings_category ON public.system_settings(category);

-- 3. FONCTION POUR MISE À JOUR AUTOMATIQUE
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ language 'plpgsql';

-- 4. TRIGGER POUR MISE À JOUR AUTOMATIQUE
DROP TRIGGER IF EXISTS update_system_settings_updated_at ON public.system_settings;
CREATE TRIGGER update_system_settings_updated_at 
  BEFORE UPDATE ON public.system_settings 
  FOR EACH ROW 
  EXECUTE FUNCTION update_updated_at_column();

-- 5. ACTIVER RLS
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

-- 6. CRÉER LES POLITIQUES RLS
DROP POLICY IF EXISTS "system_settings_access" ON public.system_settings;
CREATE POLICY "system_settings_access" ON public.system_settings
  FOR ALL USING (true);

-- 7. INSÉRER LES PARAMÈTRES PAR DÉFAUT
INSERT INTO public.system_settings (key, value, description, category) VALUES
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

-- 8. VÉRIFICATION FINALE
SELECT 
    '✅ SYSTEM_SETTINGS CRÉÉE ET PEUPLÉE' as status,
    COUNT(*) as total_settings,
    COUNT(CASE WHEN category = 'general' THEN 1 END) as general_settings,
    COUNT(CASE WHEN category = 'billing' THEN 1 END) as billing_settings,
    COUNT(CASE WHEN category = 'system' THEN 1 END) as system_settings
FROM public.system_settings;
