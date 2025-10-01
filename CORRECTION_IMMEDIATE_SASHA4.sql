-- =====================================================
-- CORRECTION IMMÉDIATE - UTILISATEUR SASHA4 MANQUANT
-- =====================================================
-- Date: 2025-01-29
-- Objectif: Ajouter immédiatement l'utilisateur sasha4@yopmail.com dans subscription_status

-- =====================================================
-- ÉTAPE 1: VÉRIFIER L'UTILISATEUR DANS AUTH.USERS
-- =====================================================

SELECT '=== VÉRIFICATION UTILISATEUR SASHA4 ===' as info;

SELECT 
    'Utilisateur sasha4@yopmail.com dans auth.users:' as info,
    id,
    email,
    raw_user_meta_data->>'first_name' as first_name,
    raw_user_meta_data->>'last_name' as last_name,
    raw_user_meta_data->>'role' as role,
    created_at,
    email_confirmed_at
FROM auth.users 
WHERE email = 'sasha4@yopmail.com';

-- =====================================================
-- ÉTAPE 2: VÉRIFIER S'IL EXISTE DÉJÀ DANS SUBSCRIPTION_STATUS
-- =====================================================

SELECT 
    'Utilisateur sasha4@yopmail.com dans subscription_status:' as info,
    COUNT(*) as existe
FROM public.subscription_status 
WHERE email = 'sasha4@yopmail.com';

-- =====================================================
-- ÉTAPE 3: AJOUTER L'UTILISATEUR MANQUANT
-- =====================================================

-- Récupérer les informations de l'utilisateur depuis auth.users
WITH user_info AS (
    SELECT 
        id,
        email,
        raw_user_meta_data->>'first_name' as first_name,
        raw_user_meta_data->>'last_name' as last_name,
        raw_user_meta_data->>'role' as role,
        created_at
    FROM auth.users 
    WHERE email = 'sasha4@yopmail.com'
)
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
    ui.id as user_id,
    COALESCE(ui.first_name, 'Sasha') as first_name,
    COALESCE(ui.last_name, 'Rohee') as last_name,
    ui.email,
    CASE 
        WHEN ui.role = 'admin' THEN true
        WHEN ui.email = 'srohee32@gmail.com' THEN true
        WHEN ui.email = 'repphonereparation@gmail.com' THEN true
        ELSE false
    END as is_active,
    CASE 
        WHEN ui.role = 'admin' THEN 'premium'
        WHEN ui.email = 'srohee32@gmail.com' THEN 'premium'
        WHEN ui.email = 'repphonereparation@gmail.com' THEN 'premium'
        ELSE 'free'
    END as subscription_type,
    'Compte ajouté manuellement - correction immédiate',
    COALESCE(ui.created_at, NOW()) as created_at,
    NOW() as updated_at,
    CASE 
        WHEN ui.role = 'admin' THEN 'ACTIF'
        WHEN ui.email = 'srohee32@gmail.com' THEN 'ACTIF'
        WHEN ui.email = 'repphonereparation@gmail.com' THEN 'ACTIF'
        ELSE 'INACTIF'
    END as status
FROM user_info ui
WHERE NOT EXISTS (
    SELECT 1 FROM public.subscription_status ss WHERE ss.user_id = ui.id
);

-- =====================================================
-- ÉTAPE 4: VÉRIFIER L'AJOUT
-- =====================================================

SELECT 
    'Vérification ajout sasha4@yopmail.com:' as info,
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

-- =====================================================
-- ÉTAPE 5: IDENTIFIER TOUS LES AUTRES UTILISATEURS MANQUANTS
-- =====================================================

SELECT 
    'Autres utilisateurs manquants dans subscription_status:' as info,
    au.id,
    au.email,
    au.raw_user_meta_data->>'first_name' as first_name,
    au.raw_user_meta_data->>'last_name' as last_name,
    au.created_at
FROM auth.users au
WHERE NOT EXISTS (
    SELECT 1 FROM public.subscription_status ss WHERE ss.user_id = au.id
)
ORDER BY au.created_at DESC;

-- =====================================================
-- ÉTAPE 6: AJOUTER TOUS LES UTILISATEURS MANQUANTS
-- =====================================================

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
    COALESCE(au.raw_user_meta_data->>'first_name', au.raw_user_meta_data->>'firstName', 'Utilisateur') as first_name,
    COALESCE(au.raw_user_meta_data->>'last_name', au.raw_user_meta_data->>'lastName', 'Test') as last_name,
    au.email,
    CASE 
        WHEN au.raw_user_meta_data->>'role' = 'admin' THEN true
        WHEN au.email = 'srohee32@gmail.com' THEN true
        WHEN au.email = 'repphonereparation@gmail.com' THEN true
        ELSE false
    END as is_active,
    CASE 
        WHEN au.raw_user_meta_data->>'role' = 'admin' THEN 'premium'
        WHEN au.email = 'srohee32@gmail.com' THEN 'premium'
        WHEN au.email = 'repphonereparation@gmail.com' THEN 'premium'
        ELSE 'free'
    END as subscription_type,
    'Compte synchronisé automatiquement - correction',
    COALESCE(au.created_at, NOW()) as created_at,
    NOW() as updated_at,
    CASE 
        WHEN au.raw_user_meta_data->>'role' = 'admin' THEN 'ACTIF'
        WHEN au.email = 'srohee32@gmail.com' THEN 'ACTIF'
        WHEN au.email = 'repphonereparation@gmail.com' THEN 'ACTIF'
        ELSE 'INACTIF'
    END as status
FROM auth.users au
WHERE NOT EXISTS (
    SELECT 1 FROM public.subscription_status ss WHERE ss.user_id = au.id
);

-- =====================================================
-- ÉTAPE 7: VÉRIFICATION FINALE
-- =====================================================

SELECT '=== VÉRIFICATION FINALE ===' as info;

-- Compter les utilisateurs
SELECT 
    'Total utilisateurs auth.users:' as info,
    COUNT(*) as total
FROM auth.users;

SELECT 
    'Total utilisateurs subscription_status:' as info,
    COUNT(*) as total
FROM public.subscription_status;

-- Vérifier qu'il n'y a plus d'utilisateurs manquants
SELECT 
    'Utilisateurs encore manquants:' as info,
    COUNT(*) as nombre_manquants
FROM auth.users au
WHERE NOT EXISTS (
    SELECT 1 FROM public.subscription_status ss WHERE ss.user_id = au.id
);

-- Afficher tous les utilisateurs dans subscription_status
SELECT 
    'Tous les utilisateurs dans subscription_status:' as info,
    user_id,
    first_name,
    last_name,
    email,
    is_active,
    subscription_type,
    status,
    created_at
FROM public.subscription_status 
ORDER BY created_at DESC;

-- =====================================================
-- ÉTAPE 8: MESSAGE DE CONFIRMATION
-- =====================================================

SELECT '🎉 CORRECTION IMMÉDIATE TERMINÉE - Tous les utilisateurs synchronisés dans subscription_status' as status;
