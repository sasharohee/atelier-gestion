-- VÉRIFICATION DE LA TABLE SYSTEM_SETTINGS
-- Ce script vérifie si la table existe et contient des données

-- 1. VÉRIFIER SI LA TABLE EXISTE
SELECT 
    'Existence table' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'system_settings' AND table_schema = 'public')
        THEN 'Table existe'
        ELSE 'Table n''existe pas'
    END as status;

-- 2. VÉRIFIER LA STRUCTURE DE LA TABLE
SELECT 
    'Structure' as check_type,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'system_settings' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. COMPTER LES ENREGISTREMENTS
SELECT 
    'Nombre d''enregistrements' as check_type,
    COUNT(*) as count
FROM public.system_settings;

-- 4. LISTER TOUS LES PARAMÈTRES
SELECT 
    'Paramètres existants' as check_type,
    key,
    value,
    description,
    category
FROM public.system_settings
ORDER BY category, key;

-- 5. VÉRIFIER LES PERMISSIONS
SELECT 
    'Permissions' as check_type,
    grantee,
    privilege_type
FROM information_schema.role_table_grants 
WHERE table_name = 'system_settings' 
AND table_schema = 'public';

-- 6. TESTER UNE REQUÊTE SIMPLE
SELECT 
    'Test requête' as check_type,
    COUNT(*) as settings_count
FROM public.system_settings;
