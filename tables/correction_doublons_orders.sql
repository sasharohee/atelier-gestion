-- =====================================================
-- CORRECTION DOUBLONS ORDERS - COMMANDES
-- =====================================================

-- Solution pour corriger les doublons de numéros de commande

SELECT 'CORRECTION DOUBLONS ORDERS' as section;

-- 1. VERIFIER LES DOUBLONS
-- =====================================================

SELECT 
    order_number,
    workshop_id,
    COUNT(*) as nombre_doublons
FROM orders 
GROUP BY order_number, workshop_id
HAVING COUNT(*) > 1
ORDER BY nombre_doublons DESC;

-- 2. AFFICHER TOUTES LES COMMANDES
-- =====================================================

SELECT 
    id,
    order_number,
    supplier_name,
    workshop_id,
    created_by,
    created_at
FROM orders 
ORDER BY created_at DESC;

-- 3. CORRIGER LES DOUBLONS
-- =====================================================

-- Supprimer les doublons en gardant la plus récente
DELETE FROM orders 
WHERE id IN (
    SELECT id FROM (
        SELECT id,
               ROW_NUMBER() OVER (
                   PARTITION BY order_number, workshop_id 
                   ORDER BY created_at DESC
               ) as rn
        FROM orders
    ) t
    WHERE t.rn > 1
);

-- 4. VERIFIER APRES CORRECTION
-- =====================================================

SELECT 
    order_number,
    workshop_id,
    COUNT(*) as nombre_doublons
FROM orders 
GROUP BY order_number, workshop_id
HAVING COUNT(*) > 1
ORDER BY nombre_doublons DESC;

-- 5. AFFICHER LES COMMANDES RESTANTES
-- =====================================================

SELECT 
    id,
    order_number,
    supplier_name,
    workshop_id,
    created_by,
    created_at
FROM orders 
ORDER BY created_at DESC;

-- 6. RESULTAT
-- =====================================================

SELECT 
    'DOUBLONS CORRIGES' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Les doublons de numeros de commande ont ete supprimes' as description;

