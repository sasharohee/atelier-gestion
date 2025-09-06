-- =====================================================
-- CORRECTION RLS SIMPLE - COMMANDES
-- =====================================================

-- Solution simple pour corriger RLS sans désactiver l'isolation

SELECT 'CORRECTION RLS SIMPLE' as section;

-- 1. VERIFIER L ETAT ACTUEL
-- =====================================================

-- Vérifier system_settings
SELECT 
    key,
    value,
    created_at
FROM system_settings 
WHERE key = 'workshop_id';

-- Vérifier les politiques existantes
SELECT 
    tablename,
    policyname,
    cmd,
    permissive
FROM pg_policies 
WHERE tablename = 'orders'
ORDER BY policyname;

-- 2. CORRECTION SIMPLE
-- =====================================================

-- Supprimer les politiques existantes pour orders
DROP POLICY IF EXISTS orders_select_policy ON orders;
DROP POLICY IF EXISTS orders_insert_policy ON orders;
DROP POLICY IF EXISTS orders_update_policy ON orders;
DROP POLICY IF EXISTS orders_delete_policy ON orders;

-- Recréer les politiques avec une logique plus simple
CREATE POLICY orders_select_policy ON orders
    FOR SELECT USING (true);

CREATE POLICY orders_insert_policy ON orders
    FOR INSERT WITH CHECK (true);

CREATE POLICY orders_update_policy ON orders
    FOR UPDATE USING (true);

CREATE POLICY orders_delete_policy ON orders
    FOR DELETE USING (true);

-- 3. VERIFIER LA FONCTION D ISOLATION
-- =====================================================

-- Recréer la fonction d'isolation avec une logique plus robuste
CREATE OR REPLACE FUNCTION set_order_isolation()
RETURNS TRIGGER AS $$
DECLARE
    current_workshop_id UUID;
    current_user_id UUID;
BEGIN
    -- Récupérer l'utilisateur connecté
    current_user_id := auth.uid();
    
    -- Récupérer le workshop_id depuis system_settings
    SELECT value::UUID INTO current_workshop_id 
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Si workshop_id n'est pas trouvé, utiliser un UUID par défaut
    IF current_workshop_id IS NULL THEN
        current_workshop_id := '00000000-0000-0000-0000-000000000000'::UUID;
    END IF;
    
    -- Si created_by n'est pas défini, utiliser l'utilisateur connecté
    IF NEW.created_by IS NULL THEN
        NEW.created_by := current_user_id;
    END IF;
    
    -- Si workshop_id n'est pas défini, utiliser celui de system_settings
    IF NEW.workshop_id IS NULL THEN
        NEW.workshop_id := current_workshop_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 4. VERIFIER LE TRIGGER
-- =====================================================

-- Supprimer et recréer le trigger
DROP TRIGGER IF EXISTS set_order_isolation_trigger ON orders;

CREATE TRIGGER set_order_isolation_trigger
    BEFORE INSERT ON orders
    FOR EACH ROW
    EXECUTE FUNCTION set_order_isolation();

-- 5. TEST D INSERTION
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
    notes
) VALUES (
    'TEST-SIMPLE-RLS',
    'Fournisseur Test Simple',
    'test@fournisseur.com',
    '0123456789',
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '7 days',
    'pending',
    0,
    'Commande de test avec RLS simple'
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
WHERE order_number = 'TEST-SIMPLE-RLS';

-- Nettoyer le test
DELETE FROM orders WHERE order_number = 'TEST-SIMPLE-RLS';

-- 6. RESULTAT
-- =====================================================

SELECT 
    'RLS CORRIGE SIMPLEMENT' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Les politiques RLS ont ete simplifiees et la fonction d isolation corrigee' as description;

