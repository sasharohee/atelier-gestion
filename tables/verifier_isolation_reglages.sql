-- VÉRIFIER L'ISOLATION DES DONNÉES - PAGE RÉGLAGES
-- Ce script vérifie que chaque utilisateur a ses propres paramètres

-- 1. VÉRIFIER LE NOMBRE TOTAL D'UTILISATEURS
SELECT 
    'Total utilisateurs' as check_type,
    COUNT(*) as count
FROM public.users;

-- 2. VÉRIFIER LES PARAMÈTRES PAR UTILISATEUR
SELECT 
    'Paramètres par utilisateur' as check_type,
    user_id,
    COUNT(*) as total_settings,
    COUNT(CASE WHEN category = 'profile' THEN 1 END) as profile_settings,
    COUNT(CASE WHEN category = 'general' THEN 1 END) as general_settings,
    COUNT(CASE WHEN category = 'billing' THEN 1 END) as billing_settings,
    COUNT(CASE WHEN category = 'system' THEN 1 END) as system_settings
FROM public.system_settings 
GROUP BY user_id
ORDER BY user_id;

-- 3. VÉRIFIER LES PARAMÈTRES DE L'ATELIER PAR UTILISATEUR
SELECT 
    'Paramètres atelier par utilisateur' as check_type,
    user_id,
    MAX(CASE WHEN key = 'workshop_name' THEN value END) as workshop_name,
    MAX(CASE WHEN key = 'workshop_address' THEN value END) as workshop_address,
    MAX(CASE WHEN key = 'workshop_phone' THEN value END) as workshop_phone,
    MAX(CASE WHEN key = 'workshop_email' THEN value END) as workshop_email,
    MAX(CASE WHEN key = 'vat_rate' THEN value END) as vat_rate,
    MAX(CASE WHEN key = 'currency' THEN value END) as currency
FROM public.system_settings 
WHERE key IN ('workshop_name', 'workshop_address', 'workshop_phone', 'workshop_email', 'vat_rate', 'currency')
GROUP BY user_id
ORDER BY user_id;

-- 4. VÉRIFIER LES PARAMÈTRES DU PROFIL PAR UTILISATEUR
SELECT 
    'Paramètres profil par utilisateur' as check_type,
    user_id,
    MAX(CASE WHEN key = 'user_first_name' THEN value END) as first_name,
    MAX(CASE WHEN key = 'user_last_name' THEN value END) as last_name,
    MAX(CASE WHEN key = 'user_email' THEN value END) as email,
    MAX(CASE WHEN key = 'user_phone' THEN value END) as phone
FROM public.system_settings 
WHERE key IN ('user_first_name', 'user_last_name', 'user_email', 'user_phone')
GROUP BY user_id
ORDER BY user_id;

-- 5. VÉRIFIER LES PARAMÈTRES DES PRÉFÉRENCES PAR UTILISATEUR
SELECT 
    'Paramètres préférences par utilisateur' as check_type,
    user_id,
    MAX(CASE WHEN key = 'notifications' THEN value END) as notifications,
    MAX(CASE WHEN key = 'language' THEN value END) as language
FROM public.system_settings 
WHERE key IN ('notifications', 'language')
GROUP BY user_id
ORDER BY user_id;

-- 6. VÉRIFIER QUE CHAQUE UTILISATEUR A TOUS LES PARAMÈTRES NÉCESSAIRES
SELECT 
    'Vérification complète' as check_type,
    user_id,
    CASE 
        WHEN COUNT(*) >= 16 THEN 'COMPLET'
        ELSE 'INCOMPLET'
    END as status,
    COUNT(*) as settings_count
FROM public.system_settings 
GROUP BY user_id
ORDER BY user_id;

-- 7. AFFICHER UN EXEMPLE DE PARAMÈTRES POUR L'UTILISATEUR ACTUEL
SELECT 
    'Paramètres utilisateur actuel' as check_type,
    key,
    value,
    category
FROM public.system_settings 
WHERE user_id = auth.uid()
ORDER BY category, key;
