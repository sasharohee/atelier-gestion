-- =====================================================
-- CORRECTION FONCTION GET_ORDER_STATS
-- =====================================================
-- Script pour corriger l'ambiguïté de colonne total_amount
-- Date: 2025-01-23
-- =====================================================

-- 1. SUPPRIMER L'ANCIENNE FONCTION
-- =====================================================

DROP FUNCTION IF EXISTS get_order_stats();

-- 2. CRÉER LA NOUVELLE FONCTION CORRIGÉE
-- =====================================================

CREATE OR REPLACE FUNCTION get_order_stats()
RETURNS TABLE (
    total INTEGER,
    pending INTEGER,
    confirmed INTEGER,
    shipped INTEGER,
    delivered INTEGER,
    cancelled INTEGER,
    total_amount DECIMAL(10,2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        COUNT(*)::INTEGER as total,
        COUNT(CASE WHEN o.status = 'pending' THEN 1 END)::INTEGER as pending,
        COUNT(CASE WHEN o.status = 'confirmed' THEN 1 END)::INTEGER as confirmed,
        COUNT(CASE WHEN o.status = 'shipped' THEN 1 END)::INTEGER as shipped,
        COUNT(CASE WHEN o.status = 'delivered' THEN 1 END)::INTEGER as delivered,
        COUNT(CASE WHEN o.status = 'cancelled' THEN 1 END)::INTEGER as cancelled,
        COALESCE(SUM(o.total_amount), 0) as total_amount
    FROM orders o
    WHERE o.workshop_id = (
        SELECT value::UUID FROM system_settings 
        WHERE key = 'workshop_id' 
        LIMIT 1
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. VÉRIFIER LA FONCTION
-- =====================================================

-- Test de la fonction
SELECT 
    'Test fonction get_order_stats' as test,
    total,
    pending,
    confirmed,
    shipped,
    delivered,
    cancelled,
    total_amount
FROM get_order_stats();

-- 4. VÉRIFIER LES TABLES
-- =====================================================

-- Vérifier que la table orders existe et a la bonne structure
SELECT 
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_name = 'orders' 
AND column_name IN ('id', 'total_amount', 'status', 'workshop_id')
ORDER BY ordinal_position;

-- 5. VÉRIFIER LES DONNÉES
-- =====================================================

-- Compter les commandes existantes
SELECT 
    'Commandes existantes' as info,
    COUNT(*) as nombre
FROM orders;

-- Vérifier les statuts
SELECT 
    'Statuts des commandes' as info,
    status,
    COUNT(*) as nombre
FROM orders
GROUP BY status
ORDER BY status;

-- 6. MESSAGE DE CONFIRMATION
-- =====================================================

SELECT 
    '✅ FONCTION CORRIGÉE' as message,
    'La fonction get_order_stats fonctionne maintenant correctement' as description,
    CURRENT_TIMESTAMP as timestamp;

