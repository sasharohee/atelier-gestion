-- Script simple pour vérifier l'utilisateur
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier si l'utilisateur existe
SELECT 
    'Utilisateur trouve:' as info,
    id,
    email,
    created_at,
    email_confirmed_at,
    last_sign_in_at
FROM auth.users
WHERE email = 'sasharohee@icloud.com';

-- 2. Vérifier la synchronisation avec public.users
SELECT 
    'Synchronisation:' as info,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = (SELECT id FROM auth.users WHERE email = 'sasharohee@icloud.com')
        ) THEN 'OK - Present dans public.users'
        ELSE 'ERREUR - Manquant dans public.users'
    END as status;

-- 3. Vérifier les sessions actives
SELECT 
    'Sessions actives:' as info,
    COUNT(*) as nombre_sessions
FROM auth.sessions
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'sasharohee@icloud.com');

-- 4. Vérifier la configuration d'authentification
SELECT 
    'Configuration:' as info,
    key,
    value
FROM auth.config
WHERE key IN ('SITE_URL', 'DISABLE_SIGNUP', 'EMAIL_AUTOCONFIRM');




