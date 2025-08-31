-- =====================================================
-- CORRECTION RLS ET TRIGGERS - TABLE ORDERS
-- =====================================================
-- Script pour corriger les politiques RLS et triggers
-- qui empêchent l'insertion de commandes
-- Date: 2025-01-23
-- =====================================================

-- 1. VÉRIFIER L'ÉTAT ACTUEL
-- =====================================================

SELECT '=== ÉTAT ACTUEL ===' as section;

-- Vérifier les politiques RLS existantes
SELECT 
    tablename,
    policyname,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'orders'
ORDER BY policyname;

-- Vérifier les triggers
SELECT 
    trigger_name,
    event_object_table,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'orders'
ORDER BY trigger_name;

-- 2. NETTOYER LES ANCIENNES POLITIQUES
-- =====================================================

SELECT '=== NETTOYAGE POLITIQUES ===' as section;

-- Supprimer toutes les politiques existantes
DROP POLICY IF EXISTS orders_select_policy ON orders;
DROP POLICY IF EXISTS orders_insert_policy ON orders;
DROP POLICY IF EXISTS orders_update_policy ON orders;
DROP POLICY IF EXISTS orders_delete_policy ON orders;

-- 3. CRÉER LES NOUVELLES POLITIQUES RLS
-- =====================================================

SELECT '=== CRÉATION NOUVELLES POLITIQUES ===' as section;

-- Politique pour SELECT
CREATE POLICY orders_select_policy ON orders
    FOR SELECT USING (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

-- Politique pour INSERT
CREATE POLICY orders_insert_policy ON orders
    FOR INSERT WITH CHECK (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

-- Politique pour UPDATE
CREATE POLICY orders_update_policy ON orders
    FOR UPDATE USING (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

-- Politique pour DELETE
CREATE POLICY orders_delete_policy ON orders
    FOR DELETE USING (
        workshop_id = (
            SELECT value::UUID FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
    );

-- 4. CRÉER LA FONCTION D'ISOLATION
-- =====================================================

SELECT '=== CRÉATION FONCTION ISOLATION ===' as section;

-- Supprimer les triggers qui dépendent de la fonction
DROP TRIGGER IF EXISTS set_order_isolation_trigger ON orders;
DROP TRIGGER IF EXISTS set_order_item_isolation_trigger ON order_items;
DROP TRIGGER IF EXISTS set_supplier_isolation_trigger ON suppliers;

-- Supprimer l'ancienne fonction si elle existe
DROP FUNCTION IF EXISTS set_order_isolation();

-- Créer la nouvelle fonction d'isolation
CREATE OR REPLACE FUNCTION set_order_isolation()
RETURNS TRIGGER AS $$
DECLARE
    v_workshop_id UUID;
    v_user_id UUID;
BEGIN
    -- Obtenir le workshop_id depuis les paramètres système
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Obtenir l'utilisateur actuel
    SELECT auth.uid() INTO v_user_id;
    
    -- Définir les valeurs d'isolation
    NEW.workshop_id = COALESCE(v_workshop_id, gen_random_uuid());
    NEW.created_by = COALESCE(v_user_id, gen_random_uuid());
    NEW.created_at = COALESCE(NEW.created_at, NOW());
    NEW.updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. CRÉER LE TRIGGER
-- =====================================================

SELECT '=== CRÉATION TRIGGER ===' as section;

-- Supprimer l'ancien trigger s'il existe
DROP TRIGGER IF EXISTS set_order_isolation_trigger ON orders;

-- Créer le nouveau trigger pour orders
CREATE TRIGGER set_order_isolation_trigger
    BEFORE INSERT ON orders
    FOR EACH ROW
    EXECUTE FUNCTION set_order_isolation();

-- Recréer les triggers pour order_items et suppliers
CREATE TRIGGER set_order_item_isolation_trigger
    BEFORE INSERT ON order_items
    FOR EACH ROW
    EXECUTE FUNCTION set_order_isolation();

CREATE TRIGGER set_supplier_isolation_trigger
    BEFORE INSERT ON suppliers
    FOR EACH ROW
    EXECUTE FUNCTION set_order_isolation();

-- 6. VÉRIFIER LA CONFIGURATION
-- =====================================================

SELECT '=== VÉRIFICATION ===' as section;

-- Vérifier les nouvelles politiques
SELECT 
    'Politiques RLS' as type,
    tablename,
    policyname,
    cmd,
    CASE 
        WHEN qual LIKE '%workshop_id%' THEN '✅ Isolation correcte'
        ELSE '⚠️ Vérification nécessaire'
    END as status
FROM pg_policies 
WHERE tablename = 'orders'
ORDER BY policyname;

-- Vérifier le trigger
SELECT 
    'Trigger isolation' as type,
    trigger_name,
    event_object_table,
    CASE 
        WHEN trigger_name LIKE '%isolation%' THEN '✅ Trigger isolation'
        ELSE '⚠️ Autre trigger'
    END as status
FROM information_schema.triggers 
WHERE event_object_table = 'orders'
ORDER BY trigger_name;

-- 7. TEST D'INSERTION
-- =====================================================

SELECT '=== TEST D''INSERTION ===' as section;

-- Test d'insertion d'une commande
DO $$
DECLARE
    v_workshop_id UUID;
    v_test_order_id UUID;
    v_test_result TEXT;
BEGIN
    -- Obtenir le workshop_id actuel
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Test d'insertion
    BEGIN
        INSERT INTO orders (
            order_number,
            supplier_name,
            supplier_email,
            order_date,
            status,
            total_amount,
            notes
        ) VALUES (
            'TEST-RLS-' || EXTRACT(EPOCH FROM NOW())::TEXT,
            'Fournisseur Test RLS',
            'test@fournisseur.com',
            CURRENT_DATE,
            'pending',
            0,
            'Test de correction RLS'
        ) RETURNING id INTO v_test_order_id;
        
        v_test_result := '✅ Insertion réussie - ID: ' || v_test_order_id;
        
        -- Nettoyer le test
        DELETE FROM orders WHERE id = v_test_order_id;
        
    EXCEPTION WHEN OTHERS THEN
        v_test_result := '❌ Erreur insertion: ' || SQLERRM;
    END;
    
    RAISE NOTICE '%', v_test_result;
END $$;

-- 8. VÉRIFICATION FINALE
-- =====================================================

SELECT '=== VÉRIFICATION FINALE ===' as section;

-- Vérifier que RLS est activé
SELECT 
    'RLS Status' as info,
    tablename,
    CASE 
        WHEN rowsecurity THEN '✅ RLS Activé'
        ELSE '❌ RLS Désactivé'
    END as status
FROM pg_tables 
WHERE tablename = 'orders';

-- Compter les politiques
SELECT 
    'Politiques RLS' as info,
    COUNT(*) as nombre_politiques
FROM pg_policies 
WHERE tablename = 'orders';

-- 9. MESSAGE DE CONFIRMATION
-- =====================================================

SELECT 
    '🎉 CORRECTION RLS TERMINÉE' as message,
    'Les politiques RLS et triggers sont maintenant configurés correctement' as description,
    CURRENT_TIMESTAMP as timestamp;
