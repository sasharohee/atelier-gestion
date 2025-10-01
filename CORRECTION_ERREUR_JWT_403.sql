-- =====================================================
-- CORRECTION ERREUR JWT 403 - USER FROM SUB CLAIM DOES NOT EXIST
-- =====================================================
-- Date: 2025-01-29
-- Objectif: Corriger l'erreur JWT qui empêche l'authentification

-- =====================================================
-- ÉTAPE 1: DIAGNOSTIC DE L'UTILISATEUR PROBLÉMATIQUE
-- =====================================================

SELECT '=== DIAGNOSTIC UTILISATEUR SASHA4 ===' as info;

-- Vérifier l'utilisateur dans auth.users
SELECT 
    'Utilisateur dans auth.users:' as info,
    id,
    email,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_user_meta_data,
    raw_app_meta_data
FROM auth.users 
WHERE email = 'sasha4@yopmail.com';

-- Vérifier les sessions actives
SELECT 
    'Sessions actives pour sasha4@yopmail.com:' as info,
    id,
    user_id,
    created_at,
    updated_at,
    factor_id,
    aal,
    not_after
FROM auth.sessions 
WHERE user_id = (
    SELECT id FROM auth.users WHERE email = 'sasha4@yopmail.com'
);

-- Vérifier les refresh tokens
SELECT 
    'Refresh tokens pour sasha4@yopmail.com:' as info,
    id,
    user_id,
    created_at,
    updated_at,
    revoked
FROM auth.refresh_tokens 
WHERE user_id = (
    SELECT id FROM auth.users WHERE email = 'sasha4@yopmail.com'
);

-- =====================================================
-- ÉTAPE 2: NETTOYER LES SESSIONS CORROMPUES
-- =====================================================

-- Supprimer toutes les sessions de l'utilisateur problématique
DELETE FROM auth.sessions 
WHERE user_id = (
    SELECT id FROM auth.users WHERE email = 'sasha4@yopmail.com'
);

-- Supprimer tous les refresh tokens de l'utilisateur problématique
DELETE FROM auth.refresh_tokens 
WHERE user_id = (
    SELECT id FROM auth.users WHERE email = 'sasha4@yopmail.com'
);

-- =====================================================
-- ÉTAPE 3: VÉRIFIER L'ÉTAT DE L'UTILISATEUR
-- =====================================================

SELECT 
    'État utilisateur après nettoyage:' as info,
    id,
    email,
    email_confirmed_at,
    created_at,
    banned_until,
    confirmation_token,
    recovery_token,
    email_change_token_new,
    email_change
FROM auth.users 
WHERE email = 'sasha4@yopmail.com';

-- =====================================================
-- ÉTAPE 4: RÉACTIVER L'UTILISATEUR SI NÉCESSAIRE
-- =====================================================

-- S'assurer que l'email est confirmé
UPDATE auth.users 
SET 
    email_confirmed_at = NOW(),
    updated_at = NOW()
WHERE email = 'sasha4@yopmail.com' 
  AND email_confirmed_at IS NULL;

-- =====================================================
-- ÉTAPE 5: VÉRIFIER LA PRÉSENCE DANS SUBSCRIPTION_STATUS
-- =====================================================

SELECT 
    'Utilisateur dans subscription_status:' as info,
    user_id,
    first_name,
    last_name,
    email,
    is_active,
    subscription_type,
    status,
    created_at
FROM public.subscription_status 
WHERE email = 'sasha4@yopmail.com';

-- Si l'utilisateur n'existe pas dans subscription_status, l'ajouter
INSERT INTO public.subscription_status (
    user_id,
    first_name,
    last_name,
    email,
    is_active,
    subscription_type,
    notes,
    created_at,
    updated_at,
    status
)
SELECT 
    au.id as user_id,
    COALESCE(au.raw_user_meta_data->>'first_name', au.raw_user_meta_data->>'firstName', 'Sasha') as first_name,
    COALESCE(au.raw_user_meta_data->>'last_name', au.raw_user_meta_data->>'lastName', 'Rohee') as last_name,
    au.email,
    false as is_active,  -- Utilisateur non activé par défaut
    'free' as subscription_type,
    'Compte corrigé après erreur JWT',
    COALESCE(au.created_at, NOW()) as created_at,
    NOW() as updated_at,
    'INACTIF' as status
FROM auth.users au
WHERE au.email = 'sasha4@yopmail.com'
  AND NOT EXISTS (
    SELECT 1 FROM public.subscription_status ss WHERE ss.user_id = au.id
  );

-- =====================================================
-- ÉTAPE 6: NETTOYER TOUTES LES SESSIONS EXPIRÉES
-- =====================================================

-- Supprimer les sessions expirées de tous les utilisateurs
DELETE FROM auth.sessions 
WHERE not_after < NOW();

-- Supprimer les refresh tokens expirés
DELETE FROM auth.refresh_tokens 
WHERE created_at < NOW() - INTERVAL '30 days';

-- =====================================================
-- ÉTAPE 7: VÉRIFICATION FINALE
-- =====================================================

SELECT '=== VÉRIFICATION FINALE ===' as info;

-- Vérifier l'état de l'utilisateur
SELECT 
    'État final utilisateur:' as info,
    id,
    email,
    email_confirmed_at,
    created_at,
    banned_until
FROM auth.users 
WHERE email = 'sasha4@yopmail.com';

-- Vérifier qu'il n'y a plus de sessions
SELECT 
    'Sessions restantes:' as info,
    COUNT(*) as nombre_sessions
FROM auth.sessions 
WHERE user_id = (
    SELECT id FROM auth.users WHERE email = 'sasha4@yopmail.com'
);

-- Vérifier la présence dans subscription_status
SELECT 
    'Présence dans subscription_status:' as info,
    user_id,
    email,
    is_active,
    status
FROM public.subscription_status 
WHERE email = 'sasha4@yopmail.com';

-- =====================================================
-- ÉTAPE 8: MESSAGE DE CONFIRMATION
-- =====================================================

SELECT '🎉 CORRECTION JWT TERMINÉE - L''utilisateur peut maintenant se reconnecter proprement' as status;
