-- =====================================================
-- VÉRIFICATION NUMÉROS DE SUIVI
-- =====================================================

SELECT 'VÉRIFICATION NUMÉROS DE SUIVI' as section;

-- 1. AFFICHER TOUTES LES COMMANDES AVEC NUMÉROS DE SUIVI
-- =====================================================

SELECT 
    id,
    order_number,
    supplier_name,
    tracking_number,
    status,
    created_at
FROM orders 
ORDER BY created_at DESC;

-- 2. COMPTER LES COMMANDES AVEC/SANS NUMÉRO DE SUIVI
-- =====================================================

SELECT 
    CASE 
        WHEN tracking_number IS NULL OR tracking_number = '' THEN 'Sans numéro de suivi'
        ELSE 'Avec numéro de suivi'
    END as statut_suivi,
    COUNT(*) as nombre_commandes
FROM orders 
GROUP BY 
    CASE 
        WHEN tracking_number IS NULL OR tracking_number = '' THEN 'Sans numéro de suivi'
        ELSE 'Avec numéro de suivi'
    END
ORDER BY nombre_commandes DESC;

-- 3. AFFICHER LES COMMANDES SANS NUMÉRO DE SUIVI
-- =====================================================

SELECT 
    id,
    order_number,
    supplier_name,
    status,
    created_at
FROM orders 
WHERE tracking_number IS NULL OR tracking_number = ''
ORDER BY created_at DESC;

-- 4. AFFICHER LES COMMANDES AVEC NUMÉRO DE SUIVI
-- =====================================================

SELECT 
    id,
    order_number,
    supplier_name,
    tracking_number,
    status,
    created_at
FROM orders 
WHERE tracking_number IS NOT NULL AND tracking_number != ''
ORDER BY created_at DESC;

-- 5. RÉSULTAT
-- =====================================================

SELECT 
    'VÉRIFICATION TERMINÉE' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Numéros de suivi vérifiés' as description;

