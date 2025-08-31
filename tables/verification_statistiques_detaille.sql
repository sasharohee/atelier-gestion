-- =====================================================
-- VÉRIFICATION DÉTAILLÉE DES STATISTIQUES
-- =====================================================

SELECT 'VÉRIFICATION DÉTAILLÉE DES STATISTIQUES' as section;

-- 1. AFFICHER TOUTES LES COMMANDES AVEC DÉTAILS
-- =====================================================

SELECT 
    id,
    order_number,
    supplier_name,
    status,
    total_amount,
    workshop_id,
    created_at,
    updated_at
FROM orders 
ORDER BY created_at DESC;

-- 2. COMPTER LES COMMANDES PAR STATUT
-- =====================================================

SELECT 
    status,
    COUNT(*) as nombre_commandes,
    SUM(total_amount) as montant_total_statut,
    STRING_AGG(order_number, ', ') as numeros_commandes
FROM orders 
GROUP BY status
ORDER BY nombre_commandes DESC;

-- 3. CALCULER LES STATISTIQUES GLOBALES
-- =====================================================

SELECT 
    COUNT(*) as total_commandes,
    COUNT(CASE WHEN status = 'pending' THEN 1 END) as en_attente,
    COUNT(CASE WHEN status = 'confirmed' THEN 1 END) as confirmees,
    COUNT(CASE WHEN status = 'shipped' THEN 1 END) as expediees,
    COUNT(CASE WHEN status = 'delivered' THEN 1 END) as livrees,
    COUNT(CASE WHEN status = 'cancelled' THEN 1 END) as annulees,
    COALESCE(SUM(total_amount), 0) as montant_total
FROM orders;

-- 4. VÉRIFIER LES MONTANTS NULL OU ZÉRO
-- =====================================================

SELECT 
    'MONTANTS PROBLÉMATIQUES' as type,
    COUNT(*) as nombre_commandes,
    STRING_AGG(order_number, ', ') as numeros_commandes
FROM orders 
WHERE total_amount IS NULL OR total_amount = 0;

-- 5. VÉRIFIER LES STATUTS INVALIDES
-- =====================================================

SELECT 
    'STATUTS INVALIDES' as type,
    status,
    COUNT(*) as nombre_commandes,
    STRING_AGG(order_number, ', ') as numeros_commandes
FROM orders 
WHERE status NOT IN ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled')
GROUP BY status;

-- 6. VÉRIFIER LES WORKSHOP_ID
-- =====================================================

SELECT 
    workshop_id,
    COUNT(*) as nombre_commandes,
    STRING_AGG(order_number, ', ') as numeros_commandes
FROM orders 
GROUP BY workshop_id
ORDER BY nombre_commandes DESC;

-- 7. RÉSULTAT
-- =====================================================

SELECT 
    'VÉRIFICATION TERMINÉE' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Statistiques détaillées vérifiées' as description;

