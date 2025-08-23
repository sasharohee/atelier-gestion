-- SOLUTION IMMÉDIATE - BOUTONS DE SAUVEGARDE
-- Ce script corrige immédiatement le problème en créant les paramètres manquants

-- 1. NETTOYER ET RECRÉER LA TABLE
DROP TABLE IF EXISTS public.system_settings CASCADE;

-- 2. CRÉER LA TABLE AVEC LA BONNE STRUCTURE
CREATE TABLE public.system_settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) NOT NULL,
    key TEXT NOT NULL,
    value TEXT NOT NULL,
    description TEXT,
    category TEXT DEFAULT 'general',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. CRÉER LES INDEX
CREATE INDEX idx_system_settings_user_id ON public.system_settings(user_id);
CREATE INDEX idx_system_settings_key ON public.system_settings(key);
CREATE INDEX idx_system_settings_category ON public.system_settings(category);

-- 4. CRÉER LA CONTRAINTE UNIQUE
ALTER TABLE public.system_settings 
ADD CONSTRAINT unique_user_key UNIQUE (user_id, key);

-- 5. ACTIVER RLS
ALTER TABLE public.system_settings ENABLE ROW LEVEL SECURITY;

-- 6. CRÉER LA POLITIQUE RLS
DROP POLICY IF EXISTS "system_settings_user_isolation" ON public.system_settings;
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

-- 8. VÉRIFICATION FINALE
SELECT 
    'SOLUTION IMMÉDIATE TERMINÉE' as status,
    COUNT(*) as total_settings,
    COUNT(CASE WHEN category = 'general' THEN 1 END) as general_settings,
    COUNT(CASE WHEN category = 'billing' THEN 1 END) as billing_settings,
    COUNT(CASE WHEN category = 'system' THEN 1 END) as system_settings
FROM public.system_settings 
WHERE user_id = auth.uid();

-- 9. AFFICHER TOUS LES PARAMÈTRES CRÉÉS
SELECT 
    key,
    value,
    category
FROM public.system_settings 
WHERE user_id = auth.uid()
ORDER BY category, key;
