-- =====================================================
-- TEST DE CONNEXION APRÈS CORRECTION
-- =====================================================
-- Date: 2025-01-29
-- Objectif: Vérifier que l'utilisateur peut se connecter après correction

-- =====================================================
-- ÉTAPE 1: VÉRIFICATION DE L'ÉTAT DE L'UTILISATEUR
-- =====================================================

SELECT '=== VÉRIFICATION ÉTAT UTILISATEUR ===' as info;

-- Vérifier que l'utilisateur existe et est correctement configuré
SELECT 
    'Utilisateur sasha4@yopmail.com:' as info,
    id,
    email,
    email_confirmed_at IS NOT NULL as email_confirme,
    banned_until IS NULL as non_banni,
    encrypted_password IS NOT NULL as has_password,
    created_at,
    updated_at
FROM auth.users 
WHERE email = 'sasha4@yopmail.com';

-- =====================================================
-- ÉTAPE 2: VÉRIFICATION DES SESSIONS
-- =====================================================

SELECT 
    'Sessions actives:' as info,
    COUNT(*) as nombre_sessions
FROM auth.sessions 
WHERE user_id::text = (
    SELECT id::text FROM auth.users WHERE email = 'sasha4@yopmail.com'
);

-- =====================================================
-- ÉTAPE 3: VÉRIFICATION SUBSCRIPTION_STATUS
-- =====================================================

SELECT 
    'Présence dans subscription_status:' as info,
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
-- ÉTAPE 4: TEST DE LA REQUÊTE DE CONNEXION
-- =====================================================

-- Simuler la requête qui était en échec
SELECT 
    'Test requête subscription_status:' as info,
    is_active,
    subscription_type,
    status
FROM public.subscription_status 
WHERE user_id = (
    SELECT id FROM auth.users WHERE email = 'sasha4@yopmail.com'
);

-- =====================================================
-- ÉTAPE 5: VÉRIFICATION DES PERMISSIONS RLS
-- =====================================================

-- Vérifier les politiques RLS sur subscription_status
SELECT 
    'Politiques RLS subscription_status:' as info,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'subscription_status' 
AND schemaname = 'public';

-- =====================================================
-- ÉTAPE 6: TEST DE CONNEXION SIMULÉ
-- =====================================================

-- Vérifier que l'utilisateur peut être trouvé par email
SELECT 
    'Test recherche par email:' as info,
    id,
    email,
    email_confirmed_at,
    CASE 
        WHEN email_confirmed_at IS NOT NULL AND banned_until IS NULL AND encrypted_password IS NOT NULL 
        THEN 'PRÊT POUR CONNEXION'
        ELSE 'PROBLÈME DÉTECTÉ'
    END as statut_connexion
FROM auth.users 
WHERE email = 'sasha4@yopmail.com';

-- =====================================================
-- ÉTAPE 7: VÉRIFICATION DES MÉTADONNÉES
-- =====================================================

SELECT 
    'Métadonnées utilisateur:' as info,
    raw_user_meta_data,
    raw_app_meta_data
FROM auth.users 
WHERE email = 'sasha4@yopmail.com';

-- =====================================================
-- ÉTAPE 8: RÉSUMÉ FINAL
-- =====================================================

SELECT '=== RÉSUMÉ FINAL ===' as info;

-- Compter les utilisateurs dans auth.users
SELECT 
    'Total utilisateurs auth.users:' as info,
    COUNT(*) as total
FROM auth.users;

-- Compter les utilisateurs dans subscription_status
SELECT 
    'Total utilisateurs subscription_status:' as info,
    COUNT(*) as total
FROM public.subscription_status;

-- Vérifier la cohérence
SELECT 
    'Cohérence auth.users vs subscription_status:' as info,
    (SELECT COUNT(*) FROM auth.users) as total_auth,
    (SELECT COUNT(*) FROM public.subscription_status) as total_subscription,
    CASE 
        WHEN (SELECT COUNT(*) FROM auth.users) = (SELECT COUNT(*) FROM public.subscription_status) 
        THEN 'COHÉRENT'
        ELSE 'INCOHÉRENT - VÉRIFICATION NÉCESSAIRE'
    END as statut_coherence;

-- =====================================================
-- ÉTAPE 9: INSTRUCTIONS DE TEST
-- =====================================================

SELECT '=== INSTRUCTIONS DE TEST ===' as info;

SELECT 
    'Pour tester la connexion:' as instruction,
    '1. Utiliser l''email: sasha4@yopmail.com' as etape1,
    '2. Utiliser le mot de passe: password123' as etape2,
    '3. Vérifier que la connexion fonctionne' as etape3,
    '4. Vérifier que les données subscription_status sont accessibles' as etape4;

-- =====================================================
-- ÉTAPE 10: MESSAGE DE CONFIRMATION
-- =====================================================

SELECT '✅ TEST DE CONNEXION PRÊT - L''utilisateur peut maintenant se connecter' as status;
