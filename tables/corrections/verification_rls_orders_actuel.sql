-- =====================================================
-- VÉRIFICATION RLS TABLE ORDERS
-- =====================================================

SELECT 'VÉRIFICATION RLS TABLE ORDERS' as section;

-- 1. VÉRIFIER SI RLS EST ACTIVÉ
-- =====================================================

SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_active
FROM pg_tables 
WHERE tablename = 'orders';

-- 2. VÉRIFIER LES POLITIQUES RLS EXISTANTES
-- =====================================================

SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'orders'
ORDER BY policyname;

-- 3. VÉRIFIER LES TRIGGERS SUR LA TABLE
-- =====================================================

SELECT 
    trigger_name,
    event_manipulation,
    action_statement,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'orders'
ORDER BY trigger_name;

-- 4. VÉRIFIER LA FONCTION D'ISOLATION
-- =====================================================

SELECT 
    routine_name,
    routine_type,
    data_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'set_order_isolation'
ORDER BY routine_name;

-- 5. VÉRIFIER LES DONNÉES ACTUELLES
-- =====================================================

SELECT 
    id,
    order_number,
    supplier_name,
    status,
    total_amount,
    workshop_id,
    created_by,
    created_at
FROM orders 
ORDER BY created_at DESC;

-- 6. VÉRIFIER LES WORKSHOP_ID DISTINCTS
-- =====================================================

SELECT 
    workshop_id,
    COUNT(*) as nombre_commandes,
    STRING_AGG(order_number, ', ') as numeros_commandes
FROM orders 
GROUP BY workshop_id
ORDER BY nombre_commandes DESC;

-- 7. VÉRIFIER LES CREATED_BY DISTINCTS
-- =====================================================

SELECT 
    created_by,
    COUNT(*) as nombre_commandes,
    STRING_AGG(order_number, ', ') as numeros_commandes
FROM orders 
GROUP BY created_by
ORDER BY nombre_commandes DESC;

-- 8. RÉSULTAT
-- =====================================================

SELECT 
    'VÉRIFICATION RLS TERMINÉE' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'État du RLS vérifié pour la table orders' as description;
