-- =====================================================
-- VÉRIFICATION TRIGGER SUBSCRIPTION_STATUS
-- =====================================================
-- Date: 2025-01-29
-- Objectif: Vérifier si le trigger de synchronisation automatique fonctionne

-- =====================================================
-- ÉTAPE 1: VÉRIFIER L'EXISTENCE DU TRIGGER
-- =====================================================

SELECT 
    'VÉRIFICATION TRIGGER EXISTANT' as info,
    trigger_name,
    event_manipulation,
    action_statement,
    event_object_table,
    event_object_schema
FROM information_schema.triggers 
WHERE trigger_name = 'trigger_sync_user_to_subscription_status'
  AND event_object_table = 'users'
  AND event_object_schema = 'auth';

-- =====================================================
-- ÉTAPE 2: VÉRIFIER LA FONCTION ASSOCIÉE
-- =====================================================

SELECT 
    'VÉRIFICATION FONCTION' as info,
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name = 'sync_user_to_subscription_status'
  AND routine_schema = 'public';

-- =====================================================
-- ÉTAPE 3: COMPARER NOMBRE D'UTILISATEURS
-- =====================================================

SELECT 
    'COMPARAISON UTILISATEURS' as info,
    (SELECT COUNT(*) FROM auth.users) as total_auth_users,
    (SELECT COUNT(*) FROM public.subscription_status) as total_subscription_status,
    (SELECT COUNT(*) FROM auth.users) - (SELECT COUNT(*) FROM public.subscription_status) as difference;

-- =====================================================
-- ÉTAPE 4: IDENTIFIER LES UTILISATEURS MANQUANTS
-- =====================================================

SELECT 
    'UTILISATEURS MANQUANTS DANS SUBSCRIPTION_STATUS' as info,
    au.id as user_id,
    au.email,
    au.raw_user_meta_data->>'first_name' as first_name,
    au.raw_user_meta_data->>'last_name' as last_name,
    au.raw_user_meta_data->>'role' as role,
    au.created_at,
    au.email_confirmed_at
FROM auth.users au
WHERE NOT EXISTS (
    SELECT 1 FROM public.subscription_status ss WHERE ss.user_id = au.id
)
ORDER BY au.created_at DESC;

-- =====================================================
-- ÉTAPE 5: VÉRIFIER LES POLITIQUES RLS
-- =====================================================

SELECT 
    'POLITIQUES RLS SUBSCRIPTION_STATUS' as info,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'subscription_status' 
  AND schemaname = 'public'
ORDER BY policyname;

-- =====================================================
-- ÉTAPE 6: VÉRIFIER LES PERMISSIONS
-- =====================================================

SELECT 
    'PERMISSIONS TABLE SUBSCRIPTION_STATUS' as info,
    has_table_privilege('authenticated', 'public.subscription_status', 'SELECT') as can_select,
    has_table_privilege('authenticated', 'public.subscription_status', 'INSERT') as can_insert,
    has_table_privilege('authenticated', 'public.subscription_status', 'UPDATE') as can_update,
    has_table_privilege('authenticated', 'public.subscription_status', 'DELETE') as can_delete;

-- =====================================================
-- ÉTAPE 7: TESTER LA FONCTION MANUELLEMENT
-- =====================================================

-- Récupérer un utilisateur récent pour tester
SELECT 
    'UTILISATEUR RÉCENT POUR TEST' as info,
    id,
    email,
    created_at
FROM auth.users 
WHERE created_at >= NOW() - INTERVAL '1 day'
ORDER BY created_at DESC
LIMIT 1;
