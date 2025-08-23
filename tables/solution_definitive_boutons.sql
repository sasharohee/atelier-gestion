-- SOLUTION DÉFINITIVE BOUTONS DE SAUVEGARDE
-- Ce script corrige définitivement le problème

-- 1. NETTOYER COMPLÈTEMENT LA TABLE
TRUNCATE TABLE public.system_settings;

-- 2. S'ASSURER QUE LA COLONNE USER_ID EXISTE
ALTER TABLE public.system_settings 
ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES public.users(id);

-- 3. CRÉER L'INDEX
CREATE INDEX IF NOT EXISTS idx_system_settings_user_id ON public.system_settings(user_id);

-- 4. SUPPRIMER TOUTES LES CONTRAINTES
ALTER TABLE public.system_settings 
DROP CONSTRAINT IF EXISTS system_settings_key_key;

ALTER TABLE public.system_settings 
DROP CONSTRAINT IF EXISTS unique_user_key;

-- 5. SUPPRIMER TOUTES LES POLITIQUES
DROP POLICY IF EXISTS "system_settings_access" ON public.system_settings;
DROP POLICY IF EXISTS "system_settings_user_isolation" ON public.system_settings;

-- 6. CRÉER LA POLITIQUE RLS
CREATE POLICY "system_settings_user_isolation" ON public.system_settings
  FOR ALL USING (auth.uid() = user_id);

-- 7. CRÉER LES PARAMÈTRES POUR L'UTILISATEUR ACTUEL
INSERT INTO public.system_settings (user_id, key, value, description, category) VALUES
  (auth.uid(), 'workshop_name', 'Atelier de réparation', 'Nom de l''atelier', 'general'),
  (auth.uid(), 'workshop_address', '123 Rue de la Paix, 75001 Paris', 'Adresse de l''atelier', 'general'),
  (auth.uid(), 'workshop_phone', '01 23 45 67 89', 'Téléphone de contact', 'general'),
  (auth.uid(), 'workshop_email', 'contact@atelier.fr', 'Email de contact', 'general'),
  (auth.uid(), 'vat_rate', '20', 'Taux de TVA', 'billing'),
  (auth.uid(), 'currency', 'EUR', 'Devise', 'billing'),
  (auth.uid(), 'invoice_prefix', 'FACT-', 'Préfixe facture', 'billing'),
  (auth.uid(), 'date_format', 'dd/MM/yyyy', 'Format de date', 'billing'),
  (auth.uid(), 'auto_backup', 'true', 'Sauvegarde automatique', 'system'),
  (auth.uid(), 'notifications', 'true', 'Notifications', 'system'),
  (auth.uid(), 'backup_frequency', 'daily', 'Fréquence sauvegarde', 'system'),
  (auth.uid(), 'max_file_size', '10', 'Taille max fichiers', 'system');

-- 8. AJOUTER LA CONTRAINTE UNIQUE
ALTER TABLE public.system_settings 
ADD CONSTRAINT unique_user_key UNIQUE (user_id, key);

-- 9. VÉRIFICATION FINALE
SELECT 
    'SOLUTION DÉFINITIVE TERMINÉE' as status,
    COUNT(*) as total_settings,
    COUNT(CASE WHEN category = 'general' THEN 1 END) as general_settings,
    COUNT(CASE WHEN category = 'billing' THEN 1 END) as billing_settings,
    COUNT(CASE WHEN category = 'system' THEN 1 END) as system_settings
FROM public.system_settings 
WHERE user_id = auth.uid();
