-- =====================================================
-- VÉRIFICATION ÉTAT ACTUEL DES COMMANDES
-- =====================================================

SELECT 'VÉRIFICATION ÉTAT ACTUEL DES COMMANDES' as section;

-- 1. AFFICHER TOUTES LES COMMANDES
-- =====================================================

SELECT 
    id,
    order_number,
    supplier_name,
    supplier_email,
    status,
    total_amount,
    created_at,
    updated_at
FROM orders 
ORDER BY created_at DESC;

-- 2. COMPTER LES COMMANDES PAR STATUT
-- =====================================================

SELECT 
    status,
    COUNT(*) as nombre_commandes,
    SUM(total_amount) as montant_total
FROM orders 
GROUP BY status
ORDER BY nombre_commandes DESC;

-- 3. VÉRIFIER LES DOUBLONS DE NUMÉROS
-- =====================================================

SELECT 
    order_number,
    COUNT(*) as nombre_doublons
FROM orders 
GROUP BY order_number
HAVING COUNT(*) > 1
ORDER BY nombre_doublons DESC;

-- 4. VÉRIFIER LES IDS NON-UUID
-- =====================================================

SELECT 
    id,
    order_number,
    supplier_name,
    created_at
FROM orders 
WHERE id !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
ORDER BY created_at DESC;

-- 5. RÉSULTAT
-- =====================================================

SELECT 
    'VÉRIFICATION TERMINÉE' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'État actuel des commandes vérifié' as description;

