-- SOLUTION ALTERNATIVE - BOUTONS DE SAUVEGARDE
-- Ce script utilise une approche plus simple

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

-- 7. RÉCUPÉRER L'ID DU PREMIER UTILISATEUR (OU TOUS LES UTILISATEURS)
-- Créer les paramètres pour tous les utilisateurs existants
INSERT INTO public.system_settings (user_id, key, value, description, category)
SELECT 
    u.id as user_id,
    s.key,
    s.value,
    s.description,
    s.category
FROM public.users u
CROSS JOIN (
    VALUES 
        ('workshop_name', 'Atelier de réparation', 'Nom de l''atelier', 'general'),
        ('workshop_address', '123 Rue de la Paix, 75001 Paris', 'Adresse de l''atelier', 'general'),
        ('workshop_phone', '01 23 45 67 89', 'Téléphone de contact', 'general'),
        ('workshop_email', 'contact@atelier.fr', 'Email de contact', 'general'),
        ('vat_rate', '20', 'Taux de TVA', 'billing'),
        ('currency', 'EUR', 'Devise', 'billing'),
        ('invoice_prefix', 'FACT-', 'Préfixe facture', 'billing'),
        ('date_format', 'dd/MM/yyyy', 'Format de date', 'billing'),
        ('auto_backup', 'true', 'Sauvegarde automatique', 'system'),
        ('notifications', 'true', 'Notifications', 'system'),
        ('backup_frequency', 'daily', 'Fréquence sauvegarde', 'system'),
        ('max_file_size', '10', 'Taille max fichiers', 'system')
) AS s(key, value, description, category)
ON CONFLICT (user_id, key) DO NOTHING;

-- 8. VÉRIFICATION FINALE
SELECT 
    'SOLUTION ALTERNATIVE TERMINÉE' as status,
    COUNT(*) as total_settings,
    COUNT(CASE WHEN category = 'general' THEN 1 END) as general_settings,
    COUNT(CASE WHEN category = 'billing' THEN 1 END) as billing_settings,
    COUNT(CASE WHEN category = 'system' THEN 1 END) as system_settings
FROM public.system_settings;

-- 9. AFFICHER LES PARAMÈTRES PAR UTILISATEUR
SELECT 
    user_id,
    COUNT(*) as settings_count
FROM public.system_settings 
GROUP BY user_id
ORDER BY user_id;

-- 10. AFFICHER UN EXEMPLE DE PARAMÈTRES
SELECT 
    key,
    value,
    category
FROM public.system_settings 
LIMIT 12
ORDER BY category, key;
