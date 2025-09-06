-- NETTOYAGE ET CORRECTION DE LA TABLE SYSTEM_SETTINGS
-- Ce script nettoie les données existantes et corrige la structure

-- 1. SUPPRIMER LA CONTRAINTE UNIQUE EXISTANTE SUR KEY
ALTER TABLE public.system_settings 
DROP CONSTRAINT IF EXISTS system_settings_key_key;

-- 2. SUPPRIMER TOUTES LES DONNÉES EXISTANTES
DELETE FROM public.system_settings;

-- 3. S'ASSURER QUE LA COLONNE USER_ID EXISTE
ALTER TABLE public.system_settings 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.users(id);

-- 4. CRÉER L'INDEX SUR USER_ID
CREATE INDEX IF NOT EXISTS idx_system_settings_user_id ON public.system_settings(user_id);

-- 5. METTRE À JOUR LES POLITIQUES RLS
DROP POLICY IF EXISTS "system_settings_access" ON public.system_settings;
DROP POLICY IF EXISTS "system_settings_user_isolation" ON public.system_settings;

-- Politique pour permettre à chaque utilisateur de voir et modifier ses propres paramètres
CREATE POLICY "system_settings_user_isolation" ON public.system_settings
  FOR ALL USING (auth.uid() = user_id);

-- 6. CRÉER DES PARAMÈTRES PAR DÉFAUT POUR L'UTILISATEUR ACTUEL
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
) AS default_settings(key, value, description, category);

-- 7. AJOUTER LA CONTRAINTE UNIQUE SUR USER_ID ET KEY
ALTER TABLE public.system_settings 
ADD CONSTRAINT unique_user_key UNIQUE (user_id, key);

-- 8. VÉRIFICATION FINALE
SELECT 
    'Nettoyage terminé' as status,
    COUNT(*) as total_settings,
    COUNT(CASE WHEN category = 'general' THEN 1 END) as general_settings,
    COUNT(CASE WHEN category = 'billing' THEN 1 END) as billing_settings,
    COUNT(CASE WHEN category = 'system' THEN 1 END) as system_settings
FROM public.system_settings 
WHERE user_id = auth.uid();
