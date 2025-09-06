-- =====================================================
-- VÉRIFICATION ISOLATION ACTUELLE
-- =====================================================

SELECT 'VÉRIFICATION ISOLATION ACTUELLE' as section;

-- 1. VÉRIFIER LES WORKSHOP_ID DISTINCTS
-- =====================================================

SELECT 
    'WORKSHOP_ID DISTINCTS' as verification,
    workshop_id,
    COUNT(*) as nombre_commandes,
    STRING_AGG(order_number, ', ') as numeros_commandes
FROM orders 
GROUP BY workshop_id
ORDER BY nombre_commandes DESC;

-- 2. VÉRIFIER LES UTILISATEURS DISTINCTS
-- =====================================================

SELECT 
    'UTILISATEURS DISTINCTS' as verification,
    created_by,
    COUNT(*) as nombre_commandes,
    STRING_AGG(order_number, ', ') as numeros_commandes
FROM orders 
GROUP BY created_by
ORDER BY nombre_commandes DESC;

-- 3. VÉRIFIER LA CORRESPONDANCE WORKSHOP_ID / CREATED_BY
-- =====================================================

SELECT 
    'CORRESPONDANCE WORKSHOP/CREATED_BY' as verification,
    workshop_id,
    created_by,
    COUNT(*) as nombre_commandes,
    STRING_AGG(order_number, ', ') as numeros_commandes
FROM orders 
GROUP BY workshop_id, created_by
ORDER BY nombre_commandes DESC;

-- 4. VÉRIFIER LES POLITIQUES RLS
-- =====================================================

SELECT 
    'POLITIQUES RLS' as verification,
    policyname,
    cmd,
    permissive,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'orders'
ORDER BY policyname;

-- 5. VÉRIFIER LE RLS EST ACTIVÉ
-- =====================================================

SELECT 
    'RLS ACTIVÉ' as verification,
    tablename,
    rowsecurity as rls_active
FROM pg_tables 
WHERE tablename = 'orders';

-- 6. VÉRIFIER LA FONCTION D'ISOLATION
-- =====================================================

SELECT 
    'FONCTION ISOLATION' as verification,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name = 'set_order_isolation'
ORDER BY routine_name;

-- 7. VÉRIFIER LE TRIGGER
-- =====================================================

SELECT 
    'TRIGGER ISOLATION' as verification,
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'orders'
ORDER BY trigger_name;

-- 8. VÉRIFIER LES UTILISATEURS DANS SUBSCRIPTION_STATUS
-- =====================================================

SELECT 
    'UTILISATEURS SUBSCRIPTION_STATUS' as verification,
    user_id,
    email,
    workshop_id,
    status
FROM subscription_status 
ORDER BY created_at DESC;

-- 9. TESTER LA FONCTION AUTH.JWT() (SIMULATION)
-- =====================================================

-- Note : Cette requête doit être exécutée par un utilisateur connecté
SELECT 
    'TEST AUTH.JWT()' as test,
    'Cette requête doit être exécutée par un utilisateur connecté' as note,
    'Vérifier workshop_id dans le JWT' as instruction;

-- 10. RÉSULTAT
-- =====================================================

SELECT 
    'VÉRIFICATION TERMINÉE' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'État de l''isolation vérifié' as description;
