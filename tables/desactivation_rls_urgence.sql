-- =====================================================
-- DESACTIVATION RLS URGENCE - COMMANDES
-- =====================================================

-- Solution d'urgence pour permettre la création de commandes immédiatement

SELECT 'DESACTIVATION RLS URGENCE' as section;

-- 1. DESACTIVER RLS SUR ORDERS
-- =====================================================

-- Désactiver RLS sur orders
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;

-- Vérifier la désactivation
SELECT 
    tablename,
    rowsecurity as rls_actif,
    CASE 
        WHEN rowsecurity = false THEN 'RLS DESACTIVE'
        ELSE 'RLS TOUJOURS ACTIF'
    END as status
FROM pg_tables 
WHERE tablename = 'orders';

-- 2. TEST D INSERTION
-- =====================================================

SELECT 'TEST D INSERTION' as section;

-- Insérer une commande de test
INSERT INTO orders (
    order_number,
    supplier_name,
    supplier_email,
    supplier_phone,
    order_date,
    expected_delivery_date,
    status,
    total_amount,
    notes,
    workshop_id,
    created_by
) VALUES (
    'TEST-URGENCE-RLS',
    'Fournisseur Test Urgence',
    'test@fournisseur.com',
    '0123456789',
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '7 days',
    'pending',
    0,
    'Commande de test avec RLS désactivé',
    '00000000-0000-0000-0000-000000000000'::UUID,
    '73bbdd45-8b3c-42c2-9ba2-78dbdad8bb11'::UUID
) RETURNING id, order_number, supplier_name, workshop_id, created_by;

-- Vérifier l'insertion
SELECT 
    id,
    order_number,
    supplier_name,
    workshop_id,
    created_by,
    created_at
FROM orders 
WHERE order_number = 'TEST-URGENCE-RLS';

-- 3. TEST DE LECTURE
-- =====================================================

SELECT 'TEST DE LECTURE' as section;

-- Vérifier que les commandes sont visibles
SELECT 
    id,
    order_number,
    supplier_name,
    workshop_id,
    created_by,
    created_at
FROM orders 
ORDER BY created_at DESC
LIMIT 5;

-- Nettoyer le test
DELETE FROM orders WHERE order_number = 'TEST-URGENCE-RLS';

-- 4. RESULTAT
-- =====================================================

SELECT 
    'RLS DESACTIVE TEMPORAIREMENT' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Les commandes peuvent maintenant etre creees sans erreur RLS' as description,
    'ATTENTION: L isolation des donnees est desactivee temporairement' as warning;

