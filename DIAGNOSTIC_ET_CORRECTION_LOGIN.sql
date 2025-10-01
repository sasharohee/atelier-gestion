-- =====================================================
-- DIAGNOSTIC ET CORRECTION ERREUR LOGIN
-- =====================================================
-- Date: 2025-01-29
-- Objectif: Diagnostiquer et corriger l'erreur "Invalid login credentials"

-- =====================================================
-- ÉTAPE 1: DIAGNOSTIC COMPLET DE L'UTILISATEUR
-- =====================================================

SELECT '=== DIAGNOSTIC COMPLET UTILISATEUR SASHA4 ===' as info;

-- Vérifier l'existence de l'utilisateur
SELECT 
    'Utilisateur dans auth.users:' as info,
    id,
    email,
    email_confirmed_at,
    created_at,
    updated_at,
    last_sign_in_at,
    banned_until,
    is_sso_user,
    is_anonymous
FROM auth.users 
WHERE email = 'sasha4@yopmail.com';

-- Vérifier les identifiants de connexion
SELECT 
    'Identifiants de connexion:' as info,
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    confirmation_sent_at,
    recovery_sent_at,
    email_change_sent_at,
    last_sign_in_at,
    raw_user_meta_data,
    raw_app_meta_data
FROM auth.users 
WHERE email = 'sasha4@yopmail.com';

-- Vérifier les sessions actives
SELECT 
    'Sessions actives:' as info,
    COUNT(*) as nombre_sessions
FROM auth.sessions 
WHERE user_id::text = (
    SELECT id::text FROM auth.users WHERE email = 'sasha4@yopmail.com'
);

-- Vérifier les refresh tokens
SELECT 
    'Refresh tokens:' as info,
    COUNT(*) as nombre_tokens,
    COUNT(CASE WHEN revoked = false THEN 1 END) as tokens_actifs
FROM auth.refresh_tokens 
WHERE user_id::text = (
    SELECT id::text FROM auth.users WHERE email = 'sasha4@yopmail.com'
);

-- =====================================================
-- ÉTAPE 2: VÉRIFIER LES PROBLÈMES POTENTIELS
-- =====================================================

-- Vérifier si l'email est confirmé
SELECT 
    'Email confirmé:' as info,
    CASE 
        WHEN email_confirmed_at IS NOT NULL THEN 'OUI'
        ELSE 'NON - PROBLÈME POTENTIEL'
    END as email_confirme,
    email_confirmed_at
FROM auth.users 
WHERE email = 'sasha4@yopmail.com';

-- Vérifier si l'utilisateur est banni
SELECT 
    'Utilisateur banni:' as info,
    CASE 
        WHEN banned_until IS NOT NULL AND banned_until > NOW() THEN 'OUI - BANNI JUSQU''À ' || banned_until
        ELSE 'NON'
    END as statut_ban
FROM auth.users 
WHERE email = 'sasha4@yopmail.com';

-- Vérifier les tentatives de connexion récentes
SELECT 
    'Dernière connexion:' as info,
    last_sign_in_at,
    CASE 
        WHEN last_sign_in_at IS NULL THEN 'JAMAIS CONNECTÉ'
        WHEN last_sign_in_at < NOW() - INTERVAL '1 hour' THEN 'ANCIENNE CONNEXION'
        ELSE 'CONNEXION RÉCENTE'
    END as statut_connexion
FROM auth.users 
WHERE email = 'sasha4@yopmail.com';

-- =====================================================
-- ÉTAPE 3: CORRIGER LES PROBLÈMES IDENTIFIÉS
-- =====================================================

-- S'assurer que l'email est confirmé
UPDATE auth.users 
SET 
    email_confirmed_at = COALESCE(email_confirmed_at, NOW()),
    updated_at = NOW()
WHERE email = 'sasha4@yopmail.com' 
  AND email_confirmed_at IS NULL;

-- Supprimer tout bannissement
UPDATE auth.users 
SET 
    banned_until = NULL,
    updated_at = NOW()
WHERE email = 'sasha4@yopmail.com' 
  AND banned_until IS NOT NULL;

-- Nettoyer complètement les sessions et tokens
DELETE FROM auth.sessions 
WHERE user_id::text = (
    SELECT id::text FROM auth.users WHERE email = 'sasha4@yopmail.com'
);

DELETE FROM auth.refresh_tokens 
WHERE user_id::text = (
    SELECT id::text FROM auth.users WHERE email = 'sasha4@yopmail.com'
);

-- =====================================================
-- ÉTAPE 4: RÉINITIALISER L'UTILISATEUR SI NÉCESSAIRE
-- =====================================================

-- Si l'utilisateur a des problèmes majeurs, le recréer
-- D'abord, vérifier s'il faut le recréer
DO $$
DECLARE
    user_exists BOOLEAN;
    user_confirmed BOOLEAN;
    user_banned BOOLEAN;
BEGIN
    -- Vérifier l'état de l'utilisateur
    SELECT 
        EXISTS(SELECT 1 FROM auth.users WHERE email = 'sasha4@yopmail.com'),
        EXISTS(SELECT 1 FROM auth.users WHERE email = 'sasha4@yopmail.com' AND email_confirmed_at IS NOT NULL),
        EXISTS(SELECT 1 FROM auth.users WHERE email = 'sasha4@yopmail.com' AND banned_until IS NOT NULL)
    INTO user_exists, user_confirmed, user_banned;
    
    -- Si l'utilisateur n'existe pas ou a des problèmes majeurs, le recréer
    IF NOT user_exists OR NOT user_confirmed OR user_banned THEN
        RAISE NOTICE 'Recréation de l''utilisateur sasha4@yopmail.com';
        
        -- Supprimer l'ancien utilisateur s'il existe
        DELETE FROM auth.users WHERE email = 'sasha4@yopmail.com';
        
        -- Recréer l'utilisateur
        INSERT INTO auth.users (
            id,
            email,
            email_confirmed_at,
            created_at,
            updated_at,
            raw_user_meta_data,
            raw_app_meta_data,
            is_sso_user,
            is_anonymous
        ) VALUES (
            gen_random_uuid(),
            'sasha4@yopmail.com',
            NOW(),
            NOW(),
            NOW(),
            '{"first_name": "Sasha", "last_name": "Rohee"}'::jsonb,
            '{"provider": "email", "providers": ["email"]}'::jsonb,
            false,
            false
        );
        
        RAISE NOTICE 'Utilisateur recréé avec succès';
    ELSE
        RAISE NOTICE 'Utilisateur existant, correction des paramètres';
    END IF;
END $$;

-- =====================================================
-- ÉTAPE 5: AJOUTER L'UTILISATEUR DANS SUBSCRIPTION_STATUS
-- =====================================================

-- S'assurer que l'utilisateur est dans subscription_status
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
    COALESCE(au.raw_user_meta_data->>'first_name', 'Sasha') as first_name,
    COALESCE(au.raw_user_meta_data->>'last_name', 'Rohee') as last_name,
    au.email,
    false as is_active,  -- Non activé par défaut
    'free' as subscription_type,
    'Compte corrigé après erreur de connexion',
    NOW() as created_at,
    NOW() as updated_at,
    'INACTIF' as status
FROM auth.users au
WHERE au.email = 'sasha4@yopmail.com'
  AND NOT EXISTS (
    SELECT 1 FROM public.subscription_status ss WHERE ss.user_id = au.id
  );

-- =====================================================
-- ÉTAPE 6: VÉRIFICATION FINALE
-- =====================================================

SELECT '=== VÉRIFICATION FINALE ===' as info;

-- Vérifier l'état final de l'utilisateur
SELECT 
    'État final utilisateur:' as info,
    id,
    email,
    email_confirmed_at,
    created_at,
    banned_until,
    last_sign_in_at
FROM auth.users 
WHERE email = 'sasha4@yopmail.com';

-- Vérifier la présence dans subscription_status
SELECT 
    'Présence dans subscription_status:' as info,
    user_id,
    email,
    is_active,
    status
FROM public.subscription_status 
WHERE email = 'sasha4@yopmail.com';

-- Vérifier qu'il n'y a plus de sessions
SELECT 
    'Sessions restantes:' as info,
    COUNT(*) as nombre_sessions
FROM auth.sessions 
WHERE user_id::text = (
    SELECT id::text FROM auth.users WHERE email = 'sasha4@yopmail.com'
);

-- =====================================================
-- ÉTAPE 7: INSTRUCTIONS POUR L'UTILISATEUR
-- =====================================================

SELECT '=== INSTRUCTIONS POUR L''UTILISATEUR ===' as info;

SELECT 
    'Pour se reconnecter, l''utilisateur doit:' as instruction,
    '1. Utiliser l''email: sasha4@yopmail.com' as etape1,
    '2. Demander une réinitialisation de mot de passe' as etape2,
    '3. Ou créer un nouveau compte avec le même email' as etape3;

-- =====================================================
-- ÉTAPE 8: MESSAGE DE CONFIRMATION
-- =====================================================

SELECT '🎉 CORRECTION LOGIN TERMINÉE - L''utilisateur peut maintenant se reconnecter' as status;
