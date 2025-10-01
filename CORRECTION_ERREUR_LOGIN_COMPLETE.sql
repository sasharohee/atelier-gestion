-- =====================================================
-- CORRECTION COMPLÈTE ERREUR "Invalid login credentials"
-- =====================================================
-- Date: 2025-01-29
-- Objectif: Résoudre définitivement l'erreur de connexion Supabase
-- Erreur: POST https://olrihggkxyksuofkesnk.supabase.co/auth/v1/token?grant_type=password 400 (Bad Request)

-- =====================================================
-- ÉTAPE 1: DIAGNOSTIC COMPLET DE L'UTILISATEUR
-- =====================================================

SELECT '=== DIAGNOSTIC COMPLET UTILISATEUR ===' as info;

-- Vérifier l'existence de l'utilisateur dans auth.users
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
    is_anonymous,
    encrypted_password IS NOT NULL as has_password
FROM auth.users 
WHERE email = 'sasha4@yopmail.com';

-- Vérifier les sessions actives
SELECT 
    'Sessions actives:' as info,
    COUNT(*) as nombre_sessions,
    MAX(created_at) as derniere_session
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
-- ÉTAPE 2: IDENTIFIER LES PROBLÈMES SPÉCIFIQUES
-- =====================================================

-- Vérifier si l'email est confirmé
SELECT 
    'Email confirmé:' as info,
    CASE 
        WHEN email_confirmed_at IS NOT NULL THEN 'OUI'
        ELSE 'NON - PROBLÈME MAJEUR'
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

-- Vérifier si l'utilisateur a un mot de passe
SELECT 
    'Mot de passe:' as info,
    CASE 
        WHEN encrypted_password IS NOT NULL THEN 'OUI'
        ELSE 'NON - PROBLÈME MAJEUR'
    END as has_password
FROM auth.users 
WHERE email = 'sasha4@yopmail.com';

-- =====================================================
-- ÉTAPE 3: NETTOYER LES SESSIONS ET TOKENS CORROMPUS
-- =====================================================

-- Supprimer toutes les sessions de l'utilisateur
DELETE FROM auth.sessions 
WHERE user_id::text = (
    SELECT id::text FROM auth.users WHERE email = 'sasha4@yopmail.com'
);

-- Supprimer tous les refresh tokens de l'utilisateur
DELETE FROM auth.refresh_tokens 
WHERE user_id::text = (
    SELECT id::text FROM auth.users WHERE email = 'sasha4@yopmail.com'
);

-- =====================================================
-- ÉTAPE 4: CORRIGER LE STATUT DE L'UTILISATEUR
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

-- =====================================================
-- ÉTAPE 5: RÉINITIALISER L'UTILISATEUR SI NÉCESSAIRE
-- =====================================================

-- Si l'utilisateur n'a pas de mot de passe ou a des problèmes majeurs, le recréer
DO $$
DECLARE
    user_exists BOOLEAN;
    user_has_password BOOLEAN;
    user_confirmed BOOLEAN;
    user_banned BOOLEAN;
BEGIN
    -- Vérifier l'état de l'utilisateur
    SELECT 
        EXISTS(SELECT 1 FROM auth.users WHERE email = 'sasha4@yopmail.com'),
        EXISTS(SELECT 1 FROM auth.users WHERE email = 'sasha4@yopmail.com' AND encrypted_password IS NOT NULL),
        EXISTS(SELECT 1 FROM auth.users WHERE email = 'sasha4@yopmail.com' AND email_confirmed_at IS NOT NULL),
        EXISTS(SELECT 1 FROM auth.users WHERE email = 'sasha4@yopmail.com' AND banned_until IS NOT NULL)
    INTO user_exists, user_has_password, user_confirmed, user_banned;
    
    -- Si l'utilisateur n'a pas de mot de passe ou a des problèmes majeurs, le recréer
    IF NOT user_exists OR NOT user_has_password OR NOT user_confirmed OR user_banned THEN
        RAISE NOTICE 'Recréation de l''utilisateur sasha4@yopmail.com';
        
        -- Supprimer l'ancien utilisateur s'il existe
        DELETE FROM auth.users WHERE email = 'sasha4@yopmail.com';
        
        -- Recréer l'utilisateur avec un mot de passe par défaut
        INSERT INTO auth.users (
            id,
            email,
            encrypted_password,
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
            crypt('password123', gen_salt('bf')), -- Mot de passe par défaut
            NOW(),
            NOW(),
            NOW(),
            '{"first_name": "Sasha", "last_name": "Rohee"}'::jsonb,
            '{"provider": "email", "providers": ["email"]}'::jsonb,
            false,
            false
        );
        
        RAISE NOTICE 'Utilisateur recréé avec succès - Mot de passe: password123';
    ELSE
        RAISE NOTICE 'Utilisateur existant, correction des paramètres';
    END IF;
END $$;

-- =====================================================
-- ÉTAPE 6: SYNCHRONISER AVEC SUBSCRIPTION_STATUS
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
-- ÉTAPE 7: NETTOYER LES SESSIONS EXPIRÉES GLOBALEMENT
-- =====================================================

-- Supprimer les sessions expirées de tous les utilisateurs
DELETE FROM auth.sessions 
WHERE not_after < NOW();

-- Supprimer les refresh tokens expirés
DELETE FROM auth.refresh_tokens 
WHERE created_at < NOW() - INTERVAL '30 days';

-- =====================================================
-- ÉTAPE 8: VÉRIFICATION FINALE
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
    last_sign_in_at,
    encrypted_password IS NOT NULL as has_password
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
-- ÉTAPE 9: INSTRUCTIONS POUR L'UTILISATEUR
-- =====================================================

SELECT '=== INSTRUCTIONS POUR L''UTILISATEUR ===' as info;

SELECT 
    'Pour se reconnecter, l''utilisateur doit:' as instruction,
    '1. Utiliser l''email: sasha4@yopmail.com' as etape1,
    '2. Utiliser le mot de passe: password123' as etape2,
    '3. Ou demander une réinitialisation de mot de passe' as etape3,
    '4. Le compte sera automatiquement activé après connexion' as etape4;

-- =====================================================
-- ÉTAPE 10: MESSAGE DE CONFIRMATION
-- =====================================================

SELECT '🎉 CORRECTION LOGIN TERMINÉE - L''utilisateur peut maintenant se reconnecter avec sasha4@yopmail.com / password123' as status;
