-- AJOUTER LES PARAMÈTRES DU PROFIL UTILISATEUR
-- Ce script ajoute les paramètres manquants pour le profil utilisateur

-- 1. AJOUTER LES PARAMÈTRES DU PROFIL POUR TOUS LES UTILISATEURS
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
        ('user_first_name', '', 'Prénom de l''utilisateur', 'profile'),
        ('user_last_name', '', 'Nom de l''utilisateur', 'profile'),
        ('user_email', '', 'Email de l''utilisateur', 'profile'),
        ('user_phone', '', 'Téléphone de l''utilisateur', 'profile')
) AS s(key, value, description, category)
ON CONFLICT (user_id, key) DO NOTHING;

-- 2. METTRE À JOUR LES VALEURS AVEC LES DONNÉES DES UTILISATEURS
UPDATE public.system_settings 
SET value = u.first_name
FROM public.users u
WHERE public.system_settings.user_id = u.id 
AND public.system_settings.key = 'user_first_name'
AND (public.system_settings.value = '' OR public.system_settings.value IS NULL);

UPDATE public.system_settings 
SET value = u.last_name
FROM public.users u
WHERE public.system_settings.user_id = u.id 
AND public.system_settings.key = 'user_last_name'
AND (public.system_settings.value = '' OR public.system_settings.value IS NULL);

UPDATE public.system_settings 
SET value = u.email
FROM public.users u
WHERE public.system_settings.user_id = u.id 
AND public.system_settings.key = 'user_email'
AND (public.system_settings.value = '' OR public.system_settings.value IS NULL);

-- 3. VÉRIFICATION FINALE
SELECT 
    'PARAMÈTRES PROFIL AJOUTÉS' as status,
    COUNT(*) as total_settings,
    COUNT(CASE WHEN category = 'profile' THEN 1 END) as profile_settings,
    COUNT(CASE WHEN category = 'general' THEN 1 END) as general_settings,
    COUNT(CASE WHEN category = 'billing' THEN 1 END) as billing_settings,
    COUNT(CASE WHEN category = 'system' THEN 1 END) as system_settings
FROM public.system_settings;

-- 4. AFFICHER LES PARAMÈTRES PAR UTILISATEUR
SELECT 
    user_id,
    COUNT(*) as settings_count,
    COUNT(CASE WHEN category = 'profile' THEN 1 END) as profile_count
FROM public.system_settings 
GROUP BY user_id
ORDER BY user_id;

-- 5. AFFICHER UN EXEMPLE DE PARAMÈTRES DE PROFIL
SELECT 
    key,
    value,
    category
FROM public.system_settings 
WHERE category = 'profile'
LIMIT 8;
