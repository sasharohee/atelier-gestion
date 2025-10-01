-- Script de diagnostic pour un utilisateur existant
-- À exécuter dans l'éditeur SQL de Supabase

-- 1. Vérifier l'état complet de l'utilisateur
SELECT 
    'État de l''utilisateur:' as info,
    id,
    email,
    created_at,
    updated_at,
    email_confirmed_at,
    phone_confirmed_at,
    last_sign_in_at,
    raw_app_meta_data,
    raw_user_meta_data,
    is_super_admin,
    role
FROM auth.users
WHERE email = 'sasharohee@icloud.com';

-- 2. Vérifier les identités liées
SELECT 
    'Identités liées:' as info,
    id,
    user_id,
    provider,
    provider_id,
    created_at,
    updated_at
FROM auth.identities
WHERE user_id = (
    SELECT id FROM auth.users WHERE email = 'sasharohee@icloud.com'
);

-- 3. Vérifier les sessions actives
SELECT 
    'Sessions actives:' as info,
    id,
    user_id,
    created_at,
    updated_at,
    factor_id,
    aal,
    not_after
FROM auth.sessions
WHERE user_id = (
    SELECT id FROM auth.users WHERE email = 'sasharohee@icloud.com'
);

-- 4. Vérifier la synchronisation avec public.users
SELECT 
    'Synchronisation public.users:' as info,
    u.id,
    u.email,
    u.created_at,
    u.updated_at,
    CASE 
        WHEN pu.id IS NULL THEN '❌ Manquant dans public.users'
        ELSE '✅ Présent dans public.users'
    END as sync_status
FROM auth.users u
LEFT JOIN public.users pu ON u.id = pu.id
WHERE u.email = 'sasharohee@icloud.com';

-- 5. Vérifier les politiques RLS
SELECT 
    'Politiques RLS:' as info,
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename IN ('users', 'clients', 'devices', 'expenses', 'expense_categories')
ORDER BY tablename, policyname;

-- 6. Vérifier la configuration d'authentification
SELECT 
    'Configuration auth:' as info,
    key,
    value
FROM auth.config
WHERE key IN ('SITE_URL', 'URI_ALLOW_LIST', 'DISABLE_SIGNUP', 'EMAIL_AUTOCONFIRM');

-- 7. Vérifier les tentatives de connexion récentes
SELECT 
    'Tentatives récentes:' as info,
    id,
    user_id,
    ip_address,
    user_agent,
    created_at,
    factor_id,
    aal,
    not_after
FROM auth.sessions
WHERE user_id = (
    SELECT id FROM auth.users WHERE email = 'sasharohee@icloud.com'
)
ORDER BY created_at DESC
LIMIT 5;
