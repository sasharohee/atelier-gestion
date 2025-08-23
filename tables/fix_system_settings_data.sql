-- SCRIPT POUR AJOUTER DES DONNÉES PAR DÉFAUT DANS system_settings
-- Ce script ajoute des paramètres système par défaut pour l'utilisateur connecté

-- 1. INSÉRER DES PARAMÈTRES SYSTÈME PAR DÉFAUT
-- Note: Ces données seront insérées pour l'utilisateur connecté via l'application

-- 2. VÉRIFIER LA STRUCTURE DE LA TABLE
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'system_settings' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 3. VÉRIFIER LES DONNÉES EXISTANTES
SELECT 
    COUNT(*) as total_settings,
    COUNT(DISTINCT user_id) as users_with_settings
FROM public.system_settings;

-- 4. MESSAGE D'INFORMATION
SELECT 
    'system_settings vérifiée' as status,
    'Utilisez l''application pour créer les paramètres par défaut' as message;
