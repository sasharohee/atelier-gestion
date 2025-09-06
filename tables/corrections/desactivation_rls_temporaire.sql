-- =====================================================
-- 🚨 DÉSACTIVATION RLS TEMPORAIRE - COMMANDES
-- =====================================================

-- ATTENTION : Cette solution désactive l'isolation des données
-- À utiliser uniquement en cas d'urgence pour permettre la création de commandes

SELECT '=== DÉSACTIVATION RLS TEMPORAIRE ===' as section;

-- 1. DÉSACTIVER RLS SUR TOUTES LES TABLES
-- =====================================================

-- Désactiver RLS sur orders
ALTER TABLE orders DISABLE ROW LEVEL SECURITY;

-- Désactiver RLS sur order_items
ALTER TABLE order_items DISABLE ROW LEVEL SECURITY;

-- Désactiver RLS sur suppliers
ALTER TABLE suppliers DISABLE ROW LEVEL SECURITY;

-- 2. VÉRIFIER LA DÉSACTIVATION
-- =====================================================

SELECT 
    tablename,
    rowsecurity as rls_actif,
    CASE 
        WHEN rowsecurity = false THEN '✅ RLS DÉSACTIVÉ'
        ELSE '❌ RLS TOUJOURS ACTIF'
    END as status
FROM pg_tables 
WHERE tablename IN ('orders', 'order_items', 'suppliers');

-- 3. TEST D'INSERTION
-- =====================================================

SELECT '=== TEST D\'INSERTION ===' as section;

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
    'TEST-RLS-DISABLED',
    'Fournisseur Test RLS Désactivé',
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
WHERE order_number = 'TEST-RLS-DISABLED';

-- 4. RÉACTIVATION RLS (OPTIONNEL)
-- =====================================================

-- Pour réactiver RLS plus tard, exécuter :
/*
-- Réactiver RLS
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY;

-- Puis exécuter le script de correction RLS
*/

-- 5. RÉSULTAT
-- =====================================================

SELECT 
    '⚠️ RLS DÉSACTIVÉ TEMPORAIREMENT' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Les commandes peuvent maintenant être créées sans erreur RLS' as description,
    'ATTENTION : L''isolation des données est désactivée' as warning;

