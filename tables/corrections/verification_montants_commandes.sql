-- =====================================================
-- VÉRIFICATION MONTANTS DES COMMANDES
-- =====================================================

SELECT 'VÉRIFICATION MONTANTS DES COMMANDES' as section;

-- 1. AFFICHER TOUTES LES COMMANDES AVEC MONTANTS
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

-- 2. COMPTER LES COMMANDES PAR PLAGE DE MONTANTS
-- =====================================================

SELECT 
    CASE 
        WHEN total_amount = 0 THEN '0€'
        WHEN total_amount < 100 THEN '0-100€'
        WHEN total_amount < 500 THEN '100-500€'
        WHEN total_amount < 1000 THEN '500-1000€'
        WHEN total_amount < 5000 THEN '1000-5000€'
        ELSE '5000€+'
    END as plage_montant,
    COUNT(*) as nombre_commandes,
    AVG(total_amount) as montant_moyen,
    SUM(total_amount) as montant_total
FROM orders 
GROUP BY 
    CASE 
        WHEN total_amount = 0 THEN '0€'
        WHEN total_amount < 100 THEN '0-100€'
        WHEN total_amount < 500 THEN '100-500€'
        WHEN total_amount < 1000 THEN '500-1000€'
        WHEN total_amount < 5000 THEN '1000-5000€'
        ELSE '5000€+'
    END
ORDER BY nombre_commandes DESC;

-- 3. AFFICHER LES COMMANDES SANS MONTANT
-- =====================================================

SELECT 
    id,
    order_number,
    supplier_name,
    total_amount,
    status,
    created_at
FROM orders 
WHERE total_amount IS NULL OR total_amount = 0
ORDER BY created_at DESC;

-- 4. STATISTIQUES GÉNÉRALES
-- =====================================================

SELECT 
    COUNT(*) as total_commandes,
    COUNT(CASE WHEN total_amount > 0 THEN 1 END) as commandes_avec_montant,
    COUNT(CASE WHEN total_amount = 0 OR total_amount IS NULL THEN 1 END) as commandes_sans_montant,
    AVG(total_amount) as montant_moyen,
    MIN(total_amount) as montant_minimum,
    MAX(total_amount) as montant_maximum,
    SUM(total_amount) as montant_total
FROM orders;

-- 5. RÉSULTAT
-- =====================================================

SELECT 
    'VÉRIFICATION TERMINÉE' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Montants des commandes vérifiés' as description;
