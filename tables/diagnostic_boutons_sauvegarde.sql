-- DIAGNOSTIC BOUTONS DE SAUVEGARDE
-- Ce script vérifie l'état actuel de la table system_settings

-- 1. VÉRIFIER LA STRUCTURE DE LA TABLE
SELECT 
    'Structure table' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'system_settings' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. VÉRIFIER LES CONTRAINTES
SELECT 
    'Contraintes' as check_type,
    constraint_name,
    constraint_type
FROM information_schema.table_constraints 
WHERE table_name = 'system_settings' 
AND table_schema = 'public';

-- 3. VÉRIFIER LES POLITIQUES RLS
SELECT 
    'Politiques RLS' as check_type,
    policyname,
    permissive,
    cmd
FROM pg_policies 
WHERE tablename = 'system_settings' 
AND schemaname = 'public';

-- 4. COMPTER LES ENREGISTREMENTS
SELECT 
    'Nombre enregistrements' as check_type,
    COUNT(*) as total_count,
    COUNT(CASE WHEN user_id IS NULL THEN 1 END) as without_user_id,
    COUNT(CASE WHEN user_id IS NOT NULL THEN 1 END) as with_user_id
FROM public.system_settings;

-- 5. LISTER LES PARAMÈTRES PAR UTILISATEUR
SELECT 
    'Paramètres par utilisateur' as check_type,
    user_id,
    COUNT(*) as settings_count
FROM public.system_settings
GROUP BY user_id;

-- 6. TESTER UNE REQUÊTE SIMPLE
SELECT 
    'Test requête simple' as check_type,
    COUNT(*) as settings_count
FROM public.system_settings;
