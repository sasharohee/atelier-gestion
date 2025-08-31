-- =====================================================
-- VÉRIFICATION ISOLATION COMPLÈTE
-- =====================================================

SELECT 'DIAGNOSTIC ISOLATION COMPLÈTE' as section;

-- 1. VÉRIFIER L'ÉTAT DES UTILISATEURS ET WORKSHOP_ID
-- =====================================================

SELECT 
    'UTILISATEURS ET WORKSHOP_ID' as verification,
    COUNT(*) as total_users,
    COUNT(workshop_id) as users_with_workshop_id,
    COUNT(*) - COUNT(workshop_id) as users_without_workshop_id
FROM subscription_status;

-- 2. VÉRIFIER LES DOUBLONS DE WORKSHOP_ID
-- =====================================================

SELECT 
    'DOUBLONS WORKSHOP_ID' as verification,
    workshop_id,
    COUNT(*) as nombre_utilisateurs,
    STRING_AGG(email, ', ') as emails
FROM subscription_status 
WHERE workshop_id IS NOT NULL
GROUP BY workshop_id 
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;

-- 3. VÉRIFIER LES COMMANDES ET LEUR WORKSHOP_ID
-- =====================================================

SELECT 
    'COMMANDES PAR WORKSHOP_ID' as verification,
    workshop_id,
    COUNT(*) as nombre_commandes,
    STRING_AGG(DISTINCT created_by::text, ', ') as created_by_users
FROM orders 
GROUP BY workshop_id 
ORDER BY COUNT(*) DESC;

-- 4. VÉRIFIER LA CORRESPONDANCE UTILISATEUR/WORKSHOP_ID
-- =====================================================

SELECT 
    'CORRESPONDANCE USER/WORKSHOP' as verification,
    o.workshop_id as order_workshop_id,
    ss.workshop_id as user_workshop_id,
    o.created_by,
    ss.email,
    CASE 
        WHEN o.workshop_id = ss.workshop_id THEN '✅ CORRECT'
        ELSE '❌ INCORRECT'
    END as status
FROM orders o
JOIN subscription_status ss ON o.created_by = ss.user_id
WHERE o.workshop_id != ss.workshop_id
ORDER BY o.created_at DESC;

-- 5. VÉRIFIER LES POLITIQUES RLS
-- =====================================================

SELECT 
    'POLITIQUES RLS ORDERS' as verification,
    policyname,
    cmd,
    permissive,
    roles,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'orders'
ORDER BY policyname;

-- 6. VÉRIFIER LA FONCTION D'ISOLATION
-- =====================================================

SELECT 
    'FONCTION ISOLATION' as verification,
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name = 'set_order_isolation'
ORDER BY routine_name;

-- 7. VÉRIFIER LE TRIGGER
-- =====================================================

SELECT 
    'TRIGGER ISOLATION' as verification,
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'orders'
ORDER BY trigger_name;

-- 8. TESTER L'AUTHENTIFICATION
-- =====================================================

SELECT 
    'TEST AUTHENTIFICATION' as verification,
    'Exécuter SELECT * FROM test_auth_status();' as instruction;

-- 9. VÉRIFIER LES DONNÉES DÉTAILLÉES
-- =====================================================

SELECT 
    'DONNÉES DÉTAILLÉES' as verification,
    'Utilisateurs:' as section;
    
SELECT 
    user_id,
    email,
    workshop_id,
    created_at
FROM subscription_status 
ORDER BY created_at;

SELECT 
    'Commandes:' as section;
    
SELECT 
    id,
    order_number,
    workshop_id,
    created_by,
    created_at,
    status
FROM orders 
ORDER BY created_at DESC
LIMIT 10;

-- 10. VÉRIFIER LES WORKSHOP_ID NULL
-- =====================================================

SELECT 
    'WORKSHOP_ID NULL' as verification,
    COUNT(*) as nombre_commandes_null
FROM orders 
WHERE workshop_id IS NULL;

-- 11. RÉSUMÉ DE L'ISOLATION
-- =====================================================

SELECT 
    'RÉSUMÉ ISOLATION' as verification,
    (SELECT COUNT(*) FROM subscription_status) as total_users,
    (SELECT COUNT(*) FROM subscription_status WHERE workshop_id IS NOT NULL) as users_with_workshop,
    (SELECT COUNT(*) FROM orders) as total_orders,
    (SELECT COUNT(*) FROM orders WHERE workshop_id IS NOT NULL) as orders_with_workshop,
    (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'orders') as rls_policies_count,
    (SELECT COUNT(*) FROM information_schema.routines WHERE routine_name = 'set_order_isolation') as isolation_function_count;

-- 12. RÉSULTAT
-- =====================================================

SELECT 
    'DIAGNOSTIC TERMINÉ' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Vérification complète de l''isolation effectuée' as description;
