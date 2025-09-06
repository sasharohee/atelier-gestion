-- =====================================================
-- CORRECTION ISOLATION DONNÉES - TABLE ORDERS (CORRIGÉ)
-- =====================================================

-- 1. ACTIVER RLS SUR LA TABLE ORDERS
-- =====================================================

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- 2. SUPPRIMER LES ANCIENNES POLITIQUES (SI ELLES EXISTENT)
-- =====================================================

DROP POLICY IF EXISTS "Users can view their own orders" ON orders;
DROP POLICY IF EXISTS "Users can insert their own orders" ON orders;
DROP POLICY IF EXISTS "Users can update their own orders" ON orders;
DROP POLICY IF EXISTS "Users can delete their own orders" ON orders;

-- 3. SUPPRIMER LES ANCIENS TRIGGERS DÉPENDANTS (SI ILS EXISTENT)
-- =====================================================

-- Supprimer d'abord les triggers qui dépendent de la fonction
DROP TRIGGER IF EXISTS set_order_isolation_trigger ON orders;
DROP TRIGGER IF EXISTS set_order_item_isolation_trigger ON order_items;
DROP TRIGGER IF EXISTS set_supplier_isolation_trigger ON suppliers;

-- 4. SUPPRIMER L'ANCIENNE FONCTION (SI ELLE EXISTE)
-- =====================================================

DROP FUNCTION IF EXISTS set_order_isolation();

-- 5. CRÉER LA NOUVELLE FONCTION D'ISOLATION
-- =====================================================

CREATE OR REPLACE FUNCTION set_order_isolation()
RETURNS TRIGGER AS $$
BEGIN
    -- Récupérer le workshop_id de l'utilisateur connecté
    NEW.workshop_id := (auth.jwt() ->> 'workshop_id')::uuid;
    
    -- Récupérer l'ID de l'utilisateur connecté
    NEW.created_by := auth.uid();
    
    -- Si created_at n'est pas défini, le définir
    IF NEW.created_at IS NULL THEN
        NEW.created_at := CURRENT_TIMESTAMP;
    END IF;
    
    -- Toujours mettre à jour updated_at
    NEW.updated_at := CURRENT_TIMESTAMP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 6. CRÉER LE TRIGGER POUR LA TABLE ORDERS
-- =====================================================

CREATE TRIGGER set_order_isolation_trigger
    BEFORE INSERT OR UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION set_order_isolation();

-- 7. CRÉER LES TRIGGERS POUR LES AUTRES TABLES (SI ELLES EXISTENT)
-- =====================================================

-- Trigger pour order_items (si la table existe)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'order_items') THEN
        CREATE TRIGGER set_order_item_isolation_trigger
            BEFORE INSERT OR UPDATE ON order_items
            FOR EACH ROW
            EXECUTE FUNCTION set_order_isolation();
    END IF;
END $$;

-- Trigger pour suppliers (si la table existe)
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'suppliers') THEN
        CREATE TRIGGER set_supplier_isolation_trigger
            BEFORE INSERT OR UPDATE ON suppliers
            FOR EACH ROW
            EXECUTE FUNCTION set_order_isolation();
    END IF;
END $$;

-- 8. CRÉER LES POLITIQUES RLS POUR ORDERS
-- =====================================================

-- Politique pour SELECT (lecture)
CREATE POLICY "Users can view their own orders" ON orders
    FOR SELECT
    USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

-- Politique pour INSERT (création)
CREATE POLICY "Users can insert their own orders" ON orders
    FOR INSERT
    WITH CHECK (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

-- Politique pour UPDATE (modification)
CREATE POLICY "Users can update their own orders" ON orders
    FOR UPDATE
    USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid)
    WITH CHECK (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

-- Politique pour DELETE (suppression)
CREATE POLICY "Users can delete their own orders" ON orders
    FOR DELETE
    USING (workshop_id = (auth.jwt() ->> 'workshop_id')::uuid);

-- 9. CRÉER LES POLITIQUES RLS POUR ORDER_ITEMS (SI LA TABLE EXISTE)
-- =====================================================

DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'order_items') THEN
        -- Activer RLS sur order_items
        EXECUTE 'ALTER TABLE order_items ENABLE ROW LEVEL SECURITY';
        
        -- Politiques pour order_items
        EXECUTE 'DROP POLICY IF EXISTS "Users can view their own order items" ON order_items';
        EXECUTE 'CREATE POLICY "Users can view their own order items" ON order_items FOR SELECT USING (workshop_id = (auth.jwt() ->> ''workshop_id'')::uuid)';
        
        EXECUTE 'DROP POLICY IF EXISTS "Users can insert their own order items" ON order_items';
        EXECUTE 'CREATE POLICY "Users can insert their own order items" ON order_items FOR INSERT WITH CHECK (workshop_id = (auth.jwt() ->> ''workshop_id'')::uuid)';
        
        EXECUTE 'DROP POLICY IF EXISTS "Users can update their own order items" ON order_items';
        EXECUTE 'CREATE POLICY "Users can update their own order items" ON order_items FOR UPDATE USING (workshop_id = (auth.jwt() ->> ''workshop_id'')::uuid) WITH CHECK (workshop_id = (auth.jwt() ->> ''workshop_id'')::uuid)';
        
        EXECUTE 'DROP POLICY IF EXISTS "Users can delete their own order items" ON order_items';
        EXECUTE 'CREATE POLICY "Users can delete their own order items" ON order_items FOR DELETE USING (workshop_id = (auth.jwt() ->> ''workshop_id'')::uuid)';
    END IF;
END $$;

-- 10. CRÉER LES POLITIQUES RLS POUR SUPPLIERS (SI LA TABLE EXISTE)
-- =====================================================

DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'suppliers') THEN
        -- Activer RLS sur suppliers
        EXECUTE 'ALTER TABLE suppliers ENABLE ROW LEVEL SECURITY';
        
        -- Politiques pour suppliers
        EXECUTE 'DROP POLICY IF EXISTS "Users can view their own suppliers" ON suppliers';
        EXECUTE 'CREATE POLICY "Users can view their own suppliers" ON suppliers FOR SELECT USING (workshop_id = (auth.jwt() ->> ''workshop_id'')::uuid)';
        
        EXECUTE 'DROP POLICY IF EXISTS "Users can insert their own suppliers" ON suppliers';
        EXECUTE 'CREATE POLICY "Users can insert their own suppliers" ON suppliers FOR INSERT WITH CHECK (workshop_id = (auth.jwt() ->> ''workshop_id'')::uuid)';
        
        EXECUTE 'DROP POLICY IF EXISTS "Users can update their own suppliers" ON suppliers';
        EXECUTE 'CREATE POLICY "Users can update their own suppliers" ON suppliers FOR UPDATE USING (workshop_id = (auth.jwt() ->> ''workshop_id'')::uuid) WITH CHECK (workshop_id = (auth.jwt() ->> ''workshop_id'')::uuid)';
        
        EXECUTE 'DROP POLICY IF EXISTS "Users can delete their own suppliers" ON suppliers';
        EXECUTE 'CREATE POLICY "Users can delete their own suppliers" ON suppliers FOR DELETE USING (workshop_id = (auth.jwt() ->> ''workshop_id'')::uuid)';
    END IF;
END $$;

-- 11. VÉRIFIER LA CONFIGURATION
-- =====================================================

-- Vérifier que RLS est activé sur orders
SELECT 
    'RLS ACTIVÉ SUR ORDERS' as verification,
    tablename,
    rowsecurity as rls_active
FROM pg_tables 
WHERE tablename = 'orders';

-- Vérifier les politiques créées pour orders
SELECT 
    'POLITIQUES CRÉÉES POUR ORDERS' as verification,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'orders'
ORDER BY policyname;

-- Vérifier le trigger créé pour orders
SELECT 
    'TRIGGER CRÉÉ POUR ORDERS' as verification,
    trigger_name,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'orders'
ORDER BY trigger_name;

-- Vérifier la fonction créée
SELECT 
    'FONCTION CRÉÉE' as verification,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name = 'set_order_isolation'
ORDER BY routine_name;

-- 12. TESTER L'ISOLATION
-- =====================================================

-- Afficher les commandes actuelles (pour vérification)
SELECT 
    'COMMANDES ACTUELLES' as test,
    COUNT(*) as total_commandes,
    COUNT(DISTINCT workshop_id) as workshops_distincts,
    COUNT(DISTINCT created_by) as utilisateurs_distincts
FROM orders;

-- 13. RÉSULTAT
-- =====================================================

SELECT 
    'ISOLATION CORRIGÉE COMPLÈTE' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Isolation des données activée pour toutes les tables de commandes' as description;
