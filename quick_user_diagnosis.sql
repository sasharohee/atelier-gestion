-- Diagnostic rapide de l'utilisateur
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier l'existence de l'utilisateur
SELECT 
    id,
    email,
    created_at,
    email_confirmed_at,
    last_sign_in_at,
    CASE 
        WHEN email_confirmed_at IS NULL THEN 'Email non confirme'
        ELSE 'Email confirme'
    END as email_status
FROM auth.users
WHERE email = 'sasharohee@icloud.com';

-- 2. Vérifier la synchronisation avec public.users
SELECT 
    'Synchronisation public.users' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM public.users 
            WHERE id = (SELECT id FROM auth.users WHERE email = 'sasharohee@icloud.com')
        ) THEN 'OK'
        ELSE 'MANQUANT'
    END as status;

-- 3. Compter les sessions actives
SELECT 
    'Sessions actives' as check_type,
    COUNT(*) as count
FROM auth.sessions
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'sasharohee@icloud.com');

-- 4. Vérifier les identités
SELECT 
    'Identites' as check_type,
    provider,
    created_at
FROM auth.identities
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'sasharohee@icloud.com');




