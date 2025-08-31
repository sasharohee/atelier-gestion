-- =====================================================
-- MISE À JOUR MONTANTS DES COMMANDES
-- =====================================================

SELECT 'MISE À JOUR MONTANTS DES COMMANDES' as section;

-- 1. AFFICHER LES COMMANDES AVEC MONTANT 0
-- =====================================================

SELECT 
    id,
    order_number,
    supplier_name,
    total_amount,
    status,
    created_at
FROM orders 
WHERE total_amount = 0 OR total_amount IS NULL
ORDER BY created_at DESC;

-- 2. METTRE À JOUR LES MONTANTS (EXEMPLE)
-- =====================================================

-- Mettre à jour les commandes avec des montants réalistes
UPDATE orders 
SET total_amount = CASE 
    WHEN order_number = '123456789' THEN 150.00
    WHEN order_number = '01 23 45 67 89' THEN 75.50
    WHEN order_number = '12nbghgh7' THEN 200.00
    ELSE 100.00  -- Montant par défaut pour les autres
END
WHERE total_amount = 0 OR total_amount IS NULL;

-- 3. VÉRIFIER LES MISE À JOUR
-- =====================================================

SELECT 
    id,
    order_number,
    supplier_name,
    total_amount,
    status,
    created_at
FROM orders 
ORDER BY created_at DESC;

-- 4. RECALCULER LES STATISTIQUES
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

-- 5. TESTER LA FONCTION STATISTIQUES
-- =====================================================

SELECT * FROM get_order_stats();

-- 6. RÉSULTAT
-- =====================================================

SELECT 
    'MISE À JOUR TERMINÉE' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Montants des commandes mis à jour' as description;

