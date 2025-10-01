-- Script simple pour vérifier l'utilisateur (version finale)
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

-- 4. Vérifier les identités liées
SELECT 
    'Identites liees:' as info,
    provider,
    provider_id,
    created_at
FROM auth.identities
WHERE user_id = (SELECT id FROM auth.users WHERE email = 'sasharohee@icloud.com');

-- 5. Vérifier les politiques RLS sur les tables principales
SELECT 
    'Politiques RLS:' as info,
    tablename,
    policyname,
    cmd
FROM pg_policies
WHERE tablename IN ('users', 'clients', 'devices', 'expenses', 'expense_categories')
ORDER BY tablename, policyname;




