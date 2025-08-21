-- SOLUTION SANS AUTH - BOUTONS DE SAUVEGARDE
-- Ce script corrige le problème sans utiliser auth.uid()

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

-- 7. CRÉER UNE FONCTION POUR INSÉRER LES PARAMÈTRES PAR DÉFAUT
CREATE OR REPLACE FUNCTION create_default_settings_for_user(user_uuid UUID)
RETURNS VOID AS $$
BEGIN
    -- Insérer les paramètres par défaut pour l'utilisateur spécifié
    INSERT INTO public.system_settings (user_id, key, value, description, category) VALUES
        (user_uuid, 'workshop_name', 'Atelier de réparation', 'Nom de l''atelier', 'general'),
        (user_uuid, 'workshop_address', '123 Rue de la Paix, 75001 Paris', 'Adresse de l''atelier', 'general'),
        (user_uuid, 'workshop_phone', '01 23 45 67 89', 'Téléphone de contact', 'general'),
        (user_uuid, 'workshop_email', 'contact@atelier.fr', 'Email de contact', 'general'),
        (user_uuid, 'vat_rate', '20', 'Taux de TVA', 'billing'),
        (user_uuid, 'currency', 'EUR', 'Devise', 'billing'),
        (user_uuid, 'invoice_prefix', 'FACT-', 'Préfixe facture', 'billing'),
        (user_uuid, 'date_format', 'dd/MM/yyyy', 'Format de date', 'billing'),
        (user_uuid, 'auto_backup', 'true', 'Sauvegarde automatique', 'system'),
        (user_uuid, 'notifications', 'true', 'Notifications', 'system'),
        (user_uuid, 'backup_frequency', 'daily', 'Fréquence sauvegarde', 'system'),
        (user_uuid, 'max_file_size', '10', 'Taille max fichiers', 'system')
    ON CONFLICT (user_id, key) DO NOTHING;
END;
$$ LANGUAGE plpgsql;

-- 8. CRÉER UNE FONCTION POUR CRÉER LES PARAMÈTRES POUR TOUS LES UTILISATEURS
CREATE OR REPLACE FUNCTION create_default_settings_for_all_users()
RETURNS VOID AS $$
DECLARE
    user_record RECORD;
BEGIN
    -- Parcourir tous les utilisateurs et créer leurs paramètres par défaut
    FOR user_record IN SELECT id FROM public.users LOOP
        PERFORM create_default_settings_for_user(user_record.id);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- 9. EXÉCUTER LA FONCTION POUR TOUS LES UTILISATEURS
SELECT create_default_settings_for_all_users();

-- 10. VÉRIFICATION FINALE
SELECT 
    'SOLUTION SANS AUTH TERMINÉE' as status,
    COUNT(*) as total_settings,
    COUNT(CASE WHEN category = 'general' THEN 1 END) as general_settings,
    COUNT(CASE WHEN category = 'billing' THEN 1 END) as billing_settings,
    COUNT(CASE WHEN category = 'system' THEN 1 END) as system_settings
FROM public.system_settings;

-- 11. AFFICHER LES PARAMÈTRES PAR UTILISATEUR
SELECT 
    user_id,
    COUNT(*) as settings_count
FROM public.system_settings 
GROUP BY user_id
ORDER BY user_id;

-- 12. AFFICHER UN EXEMPLE DE PARAMÈTRES
SELECT 
    key,
    value,
    category
FROM public.system_settings 
LIMIT 12
ORDER BY category, key;
