-- ISOLATION DES DONNÉES SYSTEM_SETTINGS PAR UTILISATEUR
-- Ce script ajoute l'isolation des données pour que chaque utilisateur ne voie que ses propres paramètres

-- 1. AJOUTER LA COLONNE USER_ID À LA TABLE SYSTEM_SETTINGS
ALTER TABLE public.system_settings 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.users(id);

-- 2. CRÉER UN INDEX SUR USER_ID POUR LES PERFORMANCES
CREATE INDEX IF NOT EXISTS idx_system_settings_user_id ON public.system_settings(user_id);

-- 3. METTRE À JOUR LES POLITIQUES RLS POUR L'ISOLATION
DROP POLICY IF EXISTS "system_settings_access" ON public.system_settings;

-- Politique pour permettre à chaque utilisateur de voir et modifier ses propres paramètres
CREATE POLICY "system_settings_user_isolation" ON public.system_settings
  FOR ALL USING (auth.uid() = user_id);

-- 4. CRÉER DES PARAMÈTRES PAR DÉFAUT POUR L'UTILISATEUR ACTUEL
-- (Ces paramètres seront créés pour l'utilisateur connecté)
INSERT INTO public.system_settings (user_id, key, value, description, category) 
SELECT 
  auth.uid() as user_id,
  key,
  value,
  description,
  category
FROM (
  VALUES
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
) AS default_settings(key, value, description, category)
WHERE NOT EXISTS (
  SELECT 1 FROM public.system_settings 
  WHERE user_id = auth.uid() AND key = default_settings.key
);

-- 5. VÉRIFICATION DE L'ISOLATION
SELECT 
    'Isolation configurée' as status,
    COUNT(*) as total_settings,
    COUNT(CASE WHEN category = 'general' THEN 1 END) as general_settings,
    COUNT(CASE WHEN category = 'billing' THEN 1 END) as billing_settings,
    COUNT(CASE WHEN category = 'system' THEN 1 END) as system_settings
FROM public.system_settings 
WHERE user_id = auth.uid();
