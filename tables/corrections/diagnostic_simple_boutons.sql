-- DIAGNOSTIC SIMPLE - BOUTONS DE SAUVEGARDE
-- Ce script vérifie l'état de la base de données sans erreur

-- 1. VÉRIFIER L'EXISTENCE DE LA TABLE
SELECT 
    'Existence table' as check_type,
    CASE
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'system_settings' AND table_schema = 'public')
        THEN 'Table existe'
        ELSE 'Table n''existe pas'
    END as status;

-- 2. VÉRIFIER LA STRUCTURE DE LA TABLE
SELECT 
    'Structure table' as check_type,
    column_name,
    data_type
FROM information_schema.columns 
WHERE table_name = 'system_settings' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. VÉRIFIER LES POLITIQUES RLS
SELECT 
    'Politiques RLS' as check_type,
    policyname,
    permissive,
    cmd
FROM pg_policies 
WHERE tablename = 'system_settings' 
AND schemaname = 'public';

-- 4. VÉRIFIER LE NOMBRE TOTAL D'ENREGISTREMENTS
SELECT 
    'Total enregistrements' as check_type,
    COUNT(*) as count
FROM public.system_settings;

-- 5. VÉRIFIER LES ENREGISTREMENTS POUR L'UTILISATEUR ACTUEL
SELECT 
    'Enregistrements utilisateur actuel' as check_type,
    COUNT(*) as count
FROM public.system_settings 
WHERE user_id = auth.uid();

-- 6. VÉRIFIER LES PARAMÈTRES POUR L'UTILISATEUR ACTUEL
SELECT 
    'Paramètres utilisateur actuel' as check_type,
    key,
    value,
    category
FROM public.system_settings 
WHERE user_id = auth.uid()
ORDER BY category, key;

-- 7. TEST D'INSERTION POUR L'UTILISATEUR ACTUEL
DO $$
DECLARE
    user_count INTEGER;
BEGIN
    -- Vérifier si l'utilisateur actuel a des paramètres
    SELECT COUNT(*) INTO user_count FROM public.system_settings WHERE user_id = auth.uid();
    
    IF user_count = 0 THEN
        RAISE NOTICE 'Aucun paramètre trouvé pour l''utilisateur actuel - Insertion des paramètres par défaut';
        
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
        
        RAISE NOTICE 'Paramètres par défaut insérés avec succès';
    ELSE
        RAISE NOTICE 'L''utilisateur actuel a déjà % paramètres', user_count;
    END IF;
END $$;

-- 8. VÉRIFICATION FINALE
SELECT 
    'Vérification finale' as check_type,
    COUNT(*) as total_settings,
    COUNT(CASE WHEN category = 'general' THEN 1 END) as general_settings,
    COUNT(CASE WHEN category = 'billing' THEN 1 END) as billing_settings,
    COUNT(CASE WHEN category = 'system' THEN 1 END) as system_settings
FROM public.system_settings 
WHERE user_id = auth.uid();
