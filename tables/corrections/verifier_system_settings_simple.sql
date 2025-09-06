-- VÉRIFICATION SIMPLE DE LA TABLE SYSTEM_SETTINGS
-- Ce script vérifie si la table existe et contient des données

-- 1. VÉRIFIER SI LA TABLE EXISTE
SELECT 
    'Existence table' as check_type,
    CASE 
        WHEN EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'system_settings' AND table_schema = 'public')
        THEN 'EXISTE'
        ELSE 'NEXISTE_PAS'
    END as status;

-- 2. COMPTER LES ENREGISTREMENTS
SELECT 
    'Nombre enregistrements' as check_type,
    COUNT(*) as count
FROM public.system_settings;

-- 3. LISTER LES PARAMÈTRES PAR CATÉGORIE
SELECT 
    'Parametres par categorie' as check_type,
    category,
    COUNT(*) as count
FROM public.system_settings
GROUP BY category
ORDER BY category;

-- 4. TESTER UNE REQUÊTE SIMPLE
SELECT 
    'Test requete' as check_type,
    COUNT(*) as settings_count
FROM public.system_settings;
