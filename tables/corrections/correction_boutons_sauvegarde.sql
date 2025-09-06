-- CORRECTION BOUTONS DE SAUVEGARDE AVEC ISOLATION
-- Ce script corrige les boutons de sauvegarde en respectant l'isolation

-- 1. VÉRIFIER SI L'UTILISATEUR ACTUEL A DES PARAMÈTRES
SELECT 
    'Paramètres utilisateur actuel' as check_type,
    COUNT(*) as settings_count
FROM public.system_settings 
WHERE user_id = auth.uid();

-- 2. SI AUCUN PARAMÈTRE, EN CRÉER POUR L'UTILISATEUR ACTUEL
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

-- 3. S'ASSURER QUE LA COLONNE USER_ID EXISTE
ALTER TABLE public.system_settings 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.users(id);

-- 4. CRÉER L'INDEX SI IL N'EXISTE PAS
CREATE INDEX IF NOT EXISTS idx_system_settings_user_id ON public.system_settings(user_id);

-- 5. CONFIGURER LES POLITIQUES RLS
DROP POLICY IF EXISTS "system_settings_access" ON public.system_settings;
DROP POLICY IF EXISTS "system_settings_user_isolation" ON public.system_settings;

CREATE POLICY "system_settings_user_isolation" ON public.system_settings
  FOR ALL USING (auth.uid() = user_id);

-- 6. AJOUTER LA CONTRAINTE UNIQUE SI ELLE N'EXISTE PAS
ALTER TABLE public.system_settings 
DROP CONSTRAINT IF EXISTS unique_user_key;

ALTER TABLE public.system_settings 
ADD CONSTRAINT unique_user_key UNIQUE (user_id, key);

-- 7. VÉRIFICATION FINALE
SELECT 
    'Correction terminée' as status,
    COUNT(*) as total_settings,
    COUNT(CASE WHEN category = 'general' THEN 1 END) as general_settings,
    COUNT(CASE WHEN category = 'billing' THEN 1 END) as billing_settings,
    COUNT(CASE WHEN category = 'system' THEN 1 END) as system_settings
FROM public.system_settings 
WHERE user_id = auth.uid();
