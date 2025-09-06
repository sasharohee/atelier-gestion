-- =====================================================
-- VÉRIFICATION STATUTS DES COMMANDES
-- =====================================================

SELECT 'VÉRIFICATION STATUTS DES COMMANDES' as section;

-- 1. AFFICHER TOUTES LES COMMANDES AVEC LEURS STATUTS
-- =====================================================

SELECT 
    id,
    order_number,
    supplier_name,
    status,
    total_amount,
    created_at,
    updated_at
FROM orders 
ORDER BY updated_at DESC;

-- 2. COMPTER LES COMMANDES PAR STATUT
-- =====================================================

SELECT 
    status,
    COUNT(*) as nombre_commandes,
    STRING_AGG(order_number, ', ') as numeros_commandes
FROM orders 
GROUP BY status
ORDER BY nombre_commandes DESC;

-- 3. VÉRIFIER LES STATUTS VALIDES
-- =====================================================

SELECT 
    'STATUTS VALIDES' as info,
    'pending' as statut_1,
    'confirmed' as statut_2,
    'shipped' as statut_3,
    'delivered' as statut_4,
    'cancelled' as statut_5;

-- 4. IDENTIFIER LES STATUTS INVALIDES
-- =====================================================

SELECT 
    status,
    COUNT(*) as nombre_commandes,
    STRING_AGG(order_number, ', ') as numeros_commandes
FROM orders 
WHERE status NOT IN ('pending', 'confirmed', 'shipped', 'delivered', 'cancelled')
GROUP BY status;

-- 5. VÉRIFIER LES DERNIÈRES MODIFICATIONS
-- =====================================================

SELECT 
    id,
    order_number,
    supplier_name,
    status,
    created_at,
    updated_at,
    CASE 
        WHEN updated_at > created_at THEN 'Modifiée'
        ELSE 'Non modifiée'
    END as statut_modification
FROM orders 
ORDER BY updated_at DESC;

-- 6. RÉSULTAT
-- =====================================================

SELECT 
    'VÉRIFICATION TERMINÉE' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Statuts des commandes vérifiés' as description;

