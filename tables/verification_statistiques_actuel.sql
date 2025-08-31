-- =====================================================
-- VÉRIFICATION STATISTIQUES ACTUELLES
-- =====================================================

SELECT 'VÉRIFICATION STATISTIQUES ACTUELLES' as section;

-- 1. AFFICHER TOUTES LES COMMANDES
-- =====================================================

SELECT 
    id,
    order_number,
    supplier_name,
    status,
    total_amount,
    created_at
FROM orders 
ORDER BY created_at DESC;

-- 2. COMPTER LES COMMANDES PAR STATUT
-- =====================================================

SELECT 
    status,
    COUNT(*) as nombre_commandes
FROM orders 
GROUP BY status
ORDER BY nombre_commandes DESC;

-- 3. CALCULER LES STATISTIQUES MANUELLEMENT
-- =====================================================

SELECT 
    COUNT(*) as total,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as pending,
    COUNT(CASE WHEN status = 'confirmed' THEN 1 END) as confirmed,
    COUNT(CASE WHEN status = 'shipped' THEN 1 END) as shipped,
    COUNT(CASE WHEN status = 'delivered' THEN 1 END) as delivered,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as cancelled,
    COALESCE(SUM(total_amount), 0) as total_amount
FROM orders;

-- 4. VÉRIFIER LA FONCTION SQL
-- =====================================================

-- Tester si la fonction existe
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name = 'get_order_stats';

-- 5. TESTER LA FONCTION
-- =====================================================

SELECT * FROM get_order_stats();

-- 6. RÉSULTAT
-- =====================================================

SELECT 
    'VÉRIFICATION TERMINÉE' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'État des statistiques vérifié' as description;

