-- =====================================================
-- CORRECTION ISOLATION ORDERS - SYSTÈME STANDARD
-- =====================================================
-- Suit exactement le même système d'isolation que les autres pages
-- Utilise system_settings avec workshop_id
-- Date: 2025-01-23
-- =====================================================

SELECT 'CORRECTION ISOLATION ORDERS - SYSTÈME STANDARD' as section;

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

-- Supprimer toutes les politiques RLS
DROP POLICY IF EXISTS "Users can view their own orders" ON orders;
DROP POLICY IF EXISTS "Users can insert their own orders" ON orders;
DROP POLICY IF EXISTS "Users can update their own orders" ON orders;
DROP POLICY IF EXISTS "Users can delete their own orders" ON orders;

-- 2. S'ASSURER QUE RLS EST ACTIVÉ
-- =====================================================

ALTER TABLE orders ENABLE ROW LEVEL SECURITY;

-- 3. VÉRIFIER LE WORKSHOP_ID DANS SYSTEM_SETTINGS
-- =====================================================

SELECT 
    'VÉRIFICATION SYSTEM_SETTINGS' as verification,
    key,
    value,
    CASE 
        WHEN key = 'workshop_id' THEN '✅ Workshop ID'
        WHEN key = 'workshop_type' THEN '✅ Type Workshop'
        ELSE 'ℹ️ Autre paramètre'
    END as type_parametre
FROM system_settings 
WHERE key IN ('workshop_id', 'workshop_type', 'workshop_name');

-- 4. CRÉER UNE FONCTION D'ISOLATION STANDARD
-- =====================================================

CREATE OR REPLACE FUNCTION set_order_isolation()
RETURNS TRIGGER AS $$
DECLARE
    v_workshop_id uuid;
    v_user_id uuid;
BEGIN
    -- Récupérer le workshop_id depuis system_settings (même système que les autres pages)
    SELECT value::UUID INTO v_workshop_id
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1;
    
    -- Récupérer l'utilisateur connecté
    v_user_id := auth.uid();
    
    -- Si pas de workshop_id, utiliser un défaut
    IF v_workshop_id IS NULL THEN
        v_workshop_id := '00000000-0000-0000-0000-000000000000'::uuid;
    END IF;
    
    -- Assigner les valeurs (même logique que device_models)
    NEW.workshop_id := v_workshop_id;
    NEW.created_by := v_user_id;
    
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

-- 6. CRÉER DES POLITIQUES RLS STANDARD (MÊME SYSTÈME QUE DEVICE_MODELS)
-- =====================================================

-- Politique SELECT : Isolation par workshop_id (même que device_models)
CREATE POLICY "Users can view their own orders" ON orders
    FOR SELECT USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
        OR
        EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

-- Politique INSERT : Permissive (le trigger gère l'isolation)
CREATE POLICY "Users can insert their own orders" ON orders
    FOR INSERT WITH CHECK (true);

-- Politique UPDATE : Isolation par workshop_id (même que device_models)
CREATE POLICY "Users can update their own orders" ON orders
    FOR UPDATE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
        OR
        EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

-- Politique DELETE : Isolation par workshop_id (même que device_models)
CREATE POLICY "Users can delete their own orders" ON orders
    FOR DELETE USING (
        workshop_id = (
            SELECT value::UUID 
            FROM system_settings 
            WHERE key = 'workshop_id' 
            LIMIT 1
        )
        OR
        EXISTS (
            SELECT 1 FROM system_settings 
            WHERE key = 'workshop_type' 
            AND value = 'gestion'
            LIMIT 1
        )
    );

-- 7. CORRIGER LES COMMANDES EXISTANTES
-- =====================================================

-- Mettre à jour les commandes existantes avec le workshop_id correct
UPDATE orders
SET workshop_id = (
    SELECT value::UUID 
    FROM system_settings 
    WHERE key = 'workshop_id' 
    LIMIT 1
)
WHERE workshop_id IS NULL 
   OR workshop_id != (
       SELECT value::UUID 
       FROM system_settings 
       WHERE key = 'workshop_id' 
       LIMIT 1
   );

-- 8. CRÉER UNE FONCTION DE TEST STANDARD
-- =====================================================

CREATE OR REPLACE FUNCTION test_orders_isolation()
RETURNS TABLE (
    user_email text,
    workshop_id uuid,
    orders_count bigint,
    isolation_status text
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        ss.email,
        ss.workshop_id,
        COUNT(o.id) as orders_count,
        CASE 
            WHEN COUNT(o.id) = 0 THEN 'Aucune commande'
            WHEN COUNT(o.id) = COUNT(CASE WHEN o.workshop_id = (
                SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1
            ) THEN 1 END) THEN '✅ ISOLATION CORRECTE'
            ELSE '❌ ISOLATION INCORRECTE'
        END as isolation_status
    FROM subscription_status ss
    LEFT JOIN orders o ON ss.user_id = o.created_by
    GROUP BY ss.user_id, ss.email, ss.workshop_id
    ORDER BY ss.email;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 9. VÉRIFIER LA CORRECTION
-- =====================================================

-- Vérifier les utilisateurs
SELECT 
    'UTILISATEURS APRÈS CORRECTION' as verification,
    COUNT(*) as total_users,
    COUNT(DISTINCT workshop_id) as unique_workshop_ids
FROM subscription_status;

-- Vérifier les commandes
SELECT 
    'COMMANDES APRÈS CORRECTION' as verification,
    COUNT(*) as total_orders,
    COUNT(CASE WHEN workshop_id IS NOT NULL THEN 1 END) as orders_with_workshop_id,
    COUNT(CASE WHEN workshop_id = (
        SELECT value::UUID FROM system_settings WHERE key = 'workshop_id' LIMIT 1
    ) THEN 1 END) as orders_with_correct_workshop_id
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

-- 10. RÉSULTAT
-- =====================================================

SELECT 
    'ISOLATION ORDERS STANDARD APPLIQUÉE' as resultat,
    CURRENT_TIMESTAMP as timestamp,
    'Système d''isolation standard appliqué (même que device_models)' as description;
