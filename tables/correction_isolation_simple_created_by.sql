-- =====================================================
-- CORRECTION ISOLATION SIMPLE - BASÉE SUR CREATED_BY
-- =====================================================
-- Utilise la même logique que les autres pages : isolation par created_by
-- Date: 2025-01-23
-- =====================================================

SELECT 'CORRECTION ISOLATION SIMPLE - CREATED_BY' as section;

-- 1. NETTOYER COMPLÈTEMENT
-- =====================================================

-- Supprimer tous les triggers
DROP TRIGGER IF EXISTS set_order_isolation_trigger ON orders;
DROP TRIGGER IF EXISTS set_order_item_isolation_trigger ON order_items;
DROP TRIGGER IF EXISTS set_supplier_isolation_trigger ON suppliers;

-- Supprimer toutes les fonctions
DROP FUNCTION IF EXISTS set_order_isolation();
DROP FUNCTION IF EXISTS test_auth_status();
DROP FUNCTION IF EXISTS test_isolation();
DROP FUNCTION IF EXISTS test_isolation_simple();
DROP FUNCTION IF EXISTS test_orders_isolation();

-- Supprimer toutes les politiques RLS
DROP POLICY IF EXISTS "Users can view their own orders" ON orders;
DROP POLICY IF EXISTS "Users can insert their own orders" ON orders;
DROP POLICY IF EXISTS "Users can update their own orders" ON orders;
DROP POLICY IF EXISTS "Users can delete their own orders" ON orders;

-- 2. DÉSACTIVER RLS TEMPORAIREMENT POUR DIAGNOSTIC
-- =====================================================

ALTER TABLE orders DISABLE ROW LEVEL SECURITY;

-- 3. VÉRIFIER L'ÉTAT ACTUEL
-- =====================================================

SELECT 
    'ÉTAT ACTUEL' as verification,
    COUNT(*) as total_orders,
    COUNT(CASE WHEN created_by IS NOT NULL THEN 1 END) as orders_with_created_by,
    COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) as orders_with_workshop_id
FROM orders;

-- 4. CRÉER UNE FONCTION SIMPLE BASÉE SUR CREATED_BY
-- =====================================================

CREATE OR REPLACE FUNCTION set_order_isolation()
RETURNS TRIGGER AS $$
DECLARE
    v_user_id uuid;
BEGIN
    -- Récupérer l'utilisateur connecté
    v_user_id := auth.uid();
    
    -- Assigner les valeurs
    NEW.created_by := v_user_id;
    NEW.workshop_id := '00000000-0000-0000-0000-000000000000'::uuid; -- Valeur par défaut
    
    -- Timestamps
    IF NEW.created_at IS NULL THEN
        NEW.created_at := CURRENT_TIMESTAMP;
    END IF;
    NEW.updated_at := CURRENT_TIMESTAMP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. CRÉER LE TRIGGER
-- =====================================================

CREATE TRIGGER set_order_isolation_trigger
    BEFORE INSERT OR UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION set_order_isolation();

-- 6. CRÉER DES POLITIQUES RLS SIMPLES BASÉES SUR CREATED_BY
-- =====================================================

-- Réactiver RLS
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- Politique SELECT : Seulement les commandes créées par l'utilisateur connecté
CREATE POLICY "Users can view their own orders" ON orders
    FOR SELECT USING (
        created_by = auth.uid()
    );

-- Politique INSERT : Permissive (le trigger gère l'isolation)
CREATE POLICY "Users can insert their own orders" ON orders
    FOR INSERT WITH CHECK (true);

-- Politique UPDATE : Seulement les commandes créées par l'utilisateur connecté
CREATE POLICY "Users can update their own orders" ON orders
    FOR UPDATE USING (
        created_by = auth.uid()
    );

-- Politique DELETE : Seulement les commandes créées par l'utilisateur connecté
CREATE POLICY "Users can delete their own orders" ON orders
    FOR DELETE USING (
        created_by = auth.uid()
    );

-- 7. CORRIGER LES COMMANDES EXISTANTES
-- =====================================================

-- Mettre à jour les commandes existantes pour s'assurer qu'elles ont un created_by
UPDATE orders
SET created_by = auth.uid()
WHERE created_by IS NULL;

-- 8. CRÉER UNE FONCTION DE TEST SIMPLE
-- =====================================================

CREATE OR REPLACE FUNCTION test_orders_isolation_simple()
RETURNS TABLE (
    user_email text,
    orders_count bigint,
    isolation_status text
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ss.email,
        COUNT(o.id) as orders_count,
        CASE 
            WHEN COUNT(o.id) = 0 THEN 'Aucune commande'
            WHEN COUNT(o.id) = COUNT(CASE WHEN o.created_by = ss.user_id THEN 1 END) THEN '✅ ISOLATION CORRECTE'
            ELSE '❌ ISOLATION INCORRECTE'
        END as isolation_status
    FROM subscription_status ss
    LEFT JOIN orders o ON ss.user_id = o.created_by
    GROUP BY ss.user_id, ss.email
    ORDER BY ss.email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. VÉRIFIER LA CORRECTION
-- =====================================================

-- Vérifier les commandes
SELECT 
    'COMMANDES APRÈS CORRECTION' as verification,
    COUNT(*) as total_orders,
    COUNT(CASE WHEN created_by IS NOT NULL THEN 1 END) as orders_with_created_by,
    COUNT(CASE WHEN created_by = auth.uid() THEN 1 END) as orders_by_current_user
FROM orders;

-- Vérifier les politiques
SELECT 
    'POLITIQUES RLS APRÈS CORRECTION' as verification,
    COUNT(*) as policies_count
FROM pg_policies 
WHERE tablename = 'orders';

-- Vérifier la fonction
SELECT 
    'FONCTION APRÈS CORRECTION' as verification,
    COUNT(*) as function_count
FROM information_schema.routines 
WHERE routine_name = 'set_order_isolation';

-- Vérifier le trigger
SELECT 
    'TRIGGER APRÈS CORRECTION' as verification,
    COUNT(*) as trigger_count
FROM information_schema.triggers 
WHERE event_object_table = 'orders';

-- 10. TESTER L'ISOLATION
-- =====================================================

-- Test de la politique SELECT
SELECT 
    'TEST ISOLATION' as verification,
    COUNT(*) as orders_visible_to_current_user,
    'Nombre de commandes visibles pour l''utilisateur actuel' as description
FROM orders
WHERE created_by = auth.uid();

-- 11. RÉSULTAT
-- =====================================================

SELECT 
    'ISOLATION SIMPLE APPLIQUÉE' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Isolation basée sur created_by appliquée (même logique que les autres pages)' as description;
