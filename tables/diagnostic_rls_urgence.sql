-- =====================================================
-- 🚨 DIAGNOSTIC RLS URGENCE - COMMANDES
-- =====================================================

-- 1. VÉRIFIER L'ÉTAT ACTUEL
-- =====================================================

SELECT '=== ÉTAT ACTUEL RLS ===' as section;

-- Vérifier si les tables existent
SELECT 
    table_name,
    CASE WHEN table_name IS NOT NULL THEN '✅ Existe' ELSE '❌ Manquante' END as status
FROM information_schema.tables 
WHERE table_name IN ('orders', 'order_items', 'suppliers')
    AND table_schema = 'public';

-- Vérifier RLS activé
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_actif
FROM pg_tables 
WHERE tablename IN ('orders', 'order_items', 'suppliers');

-- Vérifier les politiques RLS
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename IN ('orders', 'order_items', 'suppliers')
ORDER BY tablename, policyname;

-- Vérifier les triggers
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name LIKE '%isolation%'
ORDER BY event_object_table, trigger_name;

-- Vérifier la fonction d'isolation
SELECT 
    proname as function_name,
    prosrc as function_source
FROM pg_proc 
WHERE proname = 'set_order_isolation';

-- Vérifier system_settings
SELECT 
    key,
    value,
    created_at
FROM system_settings 
WHERE key = 'workshop_id';

-- 2. CORRECTION FORCÉE RLS
-- =====================================================

SELECT '=== CORRECTION FORCÉE RLS ===' as section;

-- Supprimer TOUTES les politiques existantes
DROP POLICY IF EXISTS orders_select_policy ON orders;
DROP POLICY IF EXISTS orders_insert_policy ON orders;
DROP POLICY IF EXISTS orders_update_policy ON orders;
DROP POLICY IF EXISTS orders_delete_policy ON orders;

DROP POLICY IF EXISTS order_items_select_policy ON order_items;
DROP POLICY IF EXISTS order_items_insert_policy ON order_items;
DROP POLICY IF EXISTS order_items_update_policy ON order_items;
DROP POLICY IF EXISTS order_items_delete_policy ON order_items;

DROP POLICY IF EXISTS suppliers_select_policy ON suppliers;
DROP POLICY IF EXISTS suppliers_insert_policy ON suppliers;
DROP POLICY IF EXISTS suppliers_update_policy ON suppliers;
DROP POLICY IF EXISTS suppliers_delete_policy ON suppliers;

-- Supprimer TOUS les triggers
DROP TRIGGER IF EXISTS set_order_isolation_trigger ON orders;
DROP TRIGGER IF EXISTS set_order_item_isolation_trigger ON order_items;
DROP TRIGGER IF EXISTS set_supplier_isolation_trigger ON suppliers;
DROP TRIGGER IF EXISTS update_order_total_trigger ON order_items;

-- Supprimer la fonction
DROP FUNCTION IF EXISTS set_order_isolation() CASCADE;
DROP FUNCTION IF EXISTS update_order_total() CASCADE;

-- 3. RECRÉATION COMPLÈTE
-- =====================================================

SELECT '=== RECRÉATION COMPLÈTE ===' as section;

-- Recréer la fonction d'isolation
CREATE OR REPLACE FUNCTION set_order_isolation()
RETURNS TRIGGER AS $$
BEGIN
    -- Récupérer le workshop_id depuis system_settings
    SELECT value::UUID INTO NEW.workshop_id 
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Récupérer l'utilisateur connecté
    NEW.created_by := auth.uid();
    
    -- Si workshop_id n'est pas trouvé, utiliser un UUID par défaut
    IF NEW.workshop_id IS NULL THEN
        NEW.workshop_id := '00000000-0000-0000-0000-000000000000'::UUID;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recréer la fonction de mise à jour du total
CREATE OR REPLACE FUNCTION update_order_total()
RETURNS TRIGGER AS $$
BEGIN
    -- Mettre à jour le total_amount dans la table orders
    UPDATE orders 
    SET total_amount = (
        SELECT COALESCE(SUM(total_price), 0)
        FROM order_items 
        WHERE order_id = COALESCE(NEW.order_id, OLD.order_id)
    )
    WHERE id = COALESCE(NEW.order_id, OLD.order_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

-- Recréer TOUS les triggers
CREATE TRIGGER set_order_isolation_trigger
    BEFORE INSERT ON orders
    FOR EACH ROW
    EXECUTE FUNCTION set_order_isolation();

CREATE TRIGGER set_order_item_isolation_trigger
    BEFORE INSERT ON order_items
    FOR EACH ROW
    EXECUTE FUNCTION set_order_isolation();

CREATE TRIGGER set_supplier_isolation_trigger
    BEFORE INSERT ON suppliers
    FOR EACH ROW
    EXECUTE FUNCTION set_order_isolation();

CREATE TRIGGER update_order_total_trigger
    AFTER INSERT OR UPDATE OR DELETE ON order_items
    FOR EACH ROW
    EXECUTE FUNCTION update_order_total();

-- Recréer TOUTES les politiques RLS
-- Orders
CREATE POLICY orders_select_policy ON orders
    FOR SELECT USING (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' LIMIT 1
        )
    );

CREATE POLICY orders_insert_policy ON orders
    FOR INSERT WITH CHECK (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' LIMIT 1
        )
    );

CREATE POLICY orders_update_policy ON orders
    FOR UPDATE USING (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' LIMIT 1
        )
    );

CREATE POLICY orders_delete_policy ON orders
    FOR DELETE USING (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' LIMIT 1
        )
    );

-- Order Items
CREATE POLICY order_items_select_policy ON order_items
    FOR SELECT USING (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' LIMIT 1
        )
    );

CREATE POLICY order_items_insert_policy ON order_items
    FOR INSERT WITH CHECK (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' LIMIT 1
        )
    );

CREATE POLICY order_items_update_policy ON order_items
    FOR UPDATE USING (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' LIMIT 1
        )
    );

CREATE POLICY order_items_delete_policy ON order_items
    FOR DELETE USING (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' LIMIT 1
        )
    );

-- Suppliers
CREATE POLICY suppliers_select_policy ON suppliers
    FOR SELECT USING (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' LIMIT 1
        )
    );

CREATE POLICY suppliers_insert_policy ON suppliers
    FOR INSERT WITH CHECK (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' LIMIT 1
        )
    );

CREATE POLICY suppliers_update_policy ON suppliers
    FOR UPDATE USING (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' LIMIT 1
        )
    );

CREATE POLICY suppliers_delete_policy ON suppliers
    FOR DELETE USING (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' LIMIT 1
        )
    );

-- 4. VÉRIFICATION FINALE
-- =====================================================

SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier que RLS est activé
SELECT 
    tablename,
    rowsecurity as rls_actif
FROM pg_tables 
WHERE tablename IN ('orders', 'order_items', 'suppliers');

-- Vérifier les politiques créées
SELECT 
    tablename,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename IN ('orders', 'order_items', 'suppliers')
ORDER BY tablename, policyname;

-- Vérifier les triggers
SELECT 
    trigger_name,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE trigger_name LIKE '%isolation%' OR trigger_name LIKE '%total%'
ORDER BY event_object_table, trigger_name;

-- Test d'insertion
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
    notes
) VALUES (
    'TEST-001',
    'Fournisseur Test',
    'test@fournisseur.com',
    '0123456789',
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '7 days',
    'pending',
    0,
    'Commande de test pour vérification RLS'
) RETURNING id, order_number, workshop_id, created_by;

-- Vérifier l'insertion
SELECT 
    id,
    order_number,
    supplier_name,
    workshop_id,
    created_by,
    created_at
FROM orders 
WHERE order_number = 'TEST-001';

-- Nettoyer le test
DELETE FROM orders WHERE order_number = 'TEST-001';

-- 5. RÉSULTAT FINAL
-- =====================================================

SELECT 
    '✅ CORRECTION RLS TERMINÉE' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Toutes les politiques et triggers ont été recréés' as description;

